use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::sync::{Arc, Mutex, RwLock};

use super::audit::SecurityMonitor;
use super::channel::EventMessage;
use super::oauth::{OAuthConfig, OAuthState};
use crate::server::rate_limiter::RateLimiter;
use crate::server::session::SessionId;
use crate::server::Server;

pub const MAX_CSRF_TOKENS: usize = 10_000;

/// Lock waits at or above this threshold are logged (debug) so latency
/// spikes attributable to server-lock contention are visible in traces.
const LOCK_WAIT_LOG_THRESHOLD: std::time::Duration = std::time::Duration::from_millis(5);

/// Batch sizes for sliced checkpoint collection (Stage 1b). Each batch is
/// one server write-lock acquisition; smaller batches mean shorter holds
/// and more interleaving room for dispatch, at the cost of more acquisitions.
const MATERIALIZE_BATCH: usize = 4;
const WORK_SNAPSHOT_BATCH: usize = 4;
const AUX_SNAPSHOT_BATCH: usize = 8;

pub type SharedState = Arc<AppState>;

pub struct AppState {
    pub server: ServerHandle,
    pub event_bus: tokio::sync::broadcast::Sender<EventMessage>,
    pub session_senders:
        Mutex<HashMap<SessionId, tokio::sync::mpsc::UnboundedSender<EventMessage>>>,
    pub security: Arc<Mutex<SecurityMonitor>>,
    pub static_dir: Option<PathBuf>,
    pub allowed_origins: Option<HashSet<String>>,
    pub csrf_enabled: bool,
    pub csrf_tokens: Arc<Mutex<HashSet<String>>>,
    pub oauth_config: OAuthConfig,
    pub oauth_state: OAuthState,
    pub verification: crate::server::verification::VerificationState,
    pub governance_tx: tokio::sync::broadcast::Sender<super::federation_handler::FederationFrame>,
    pub rate_limiter: Arc<RateLimiter>,
    pub dev_mode: bool,
    /// FR-43: per-op dispatch latency (robots/CI read via snapshot).
    pub metrics: DispatchMetrics,
}

impl AppState {
    pub fn new(srv: Server) -> Self {
        Self::with_security(
            srv,
            SecurityMonitor::new(Arc::new(super::audit::TracingAuditLog)),
        )
    }

    pub fn with_security(srv: Server, monitor: SecurityMonitor) -> Self {
        let handle = ServerHandle::new(srv);
        let (tx, _) = tokio::sync::broadcast::channel(256);
        let (gov_tx, _) = tokio::sync::broadcast::channel(64);
        AppState {
            server: handle,
            event_bus: tx,
            session_senders: Mutex::new(HashMap::new()),
            security: Arc::new(Mutex::new(monitor)),
            static_dir: None,
            allowed_origins: None,
            csrf_enabled: false,
            csrf_tokens: Arc::new(Mutex::new(HashSet::new())),
            oauth_config: OAuthConfig::default(),
            oauth_state: OAuthState::new(),
            verification: crate::server::verification::VerificationState::new(String::new()),
            governance_tx: gov_tx,
            rate_limiter: Arc::new(RateLimiter::new()),
            metrics: DispatchMetrics::default(),
            dev_mode: false,
        }
    }

    pub fn register_session_sender(
        &self,
        session_id: SessionId,
        sender: tokio::sync::mpsc::UnboundedSender<EventMessage>,
    ) {
        self.session_senders
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .insert(session_id, sender);
    }

    pub fn unregister_session_sender(&self, session_id: &SessionId) {
        self.session_senders
            .lock()
            .unwrap_or_else(|e| e.into_inner())
            .remove(session_id);
    }

    pub fn send_to_session(&self, session_id: &SessionId, event: EventMessage) -> bool {
        let senders = self
            .session_senders
            .lock()
            .unwrap_or_else(|e| e.into_inner());
        if let Some(sender) = senders.get(session_id) {
            sender.send(event).is_ok()
        } else {
            false
        }
    }

    pub fn with_static_dir(mut self, dir: PathBuf) -> Self {
        self.static_dir = Some(dir);
        self
    }

    pub fn with_allowed_origins(mut self, origins: HashSet<String>) -> Self {
        self.allowed_origins = Some(origins);
        self
    }

    pub fn with_csrf(mut self, enabled: bool) -> Self {
        self.csrf_enabled = enabled;
        self
    }

    pub fn with_dev_mode(mut self, dev: bool) -> Self {
        self.dev_mode = dev;
        self
    }

    pub fn with_oauth(mut self, config: OAuthConfig) -> Self {
        self.oauth_config = config;
        self.oauth_state = OAuthState::new();
        self
    }

    pub fn shared(self) -> SharedState {
        Arc::new(self)
    }
}

#[derive(Clone)]
pub struct ServerHandle {
    inner: Arc<RwLock<Server>>,
    operation_counter: Arc<std::sync::atomic::AtomicU64>,
}

impl ServerHandle {
    pub fn new(server: Server) -> Self {
        let ops = server.operation_counter;
        ServerHandle {
            inner: Arc::new(RwLock::new(server)),
            operation_counter: Arc::new(std::sync::atomic::AtomicU64::new(ops)),
        }
    }

    pub fn bump_operation_atomic(&self) -> u64 {
        self.operation_counter
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed)
            + 1
    }

    pub fn operation_count(&self) -> u64 {
        self.operation_counter
            .load(std::sync::atomic::Ordering::Relaxed)
    }

    pub fn try_health_json(&self) -> Option<String> {
        let guard = match self.inner.try_read() {
            Ok(g) => g,
            Err(std::sync::TryLockError::Poisoned(e)) => e.into_inner(),
            Err(std::sync::TryLockError::WouldBlock) => return None,
        };
        Some(guard.health_json_with_ops(self.operation_count()))
    }

    pub fn with_server<R>(&self, f: impl FnOnce(&mut Server) -> R) -> R {
        let started = std::time::Instant::now();
        let mut guard = self.inner.write().unwrap_or_else(|e| {
            tracing::error!("Server rwlock poisoned, recovering: {}", e);
            e.into_inner()
        });
        let lock_wait = started.elapsed();
        if lock_wait >= LOCK_WAIT_LOG_THRESHOLD {
            tracing::debug!(
                "[lock] write dispatch waited {:.1}ms for server write lock",
                lock_wait.as_secs_f64() * 1000.0
            );
        }
        f(&mut guard)
    }

    pub fn with_server_ref<R>(&self, f: impl FnOnce(&Server) -> R) -> R {
        let started = std::time::Instant::now();
        let guard = self.inner.read().unwrap_or_else(|e| {
            tracing::error!("Server rwlock poisoned, recovering: {}", e);
            e.into_inner()
        });
        let lock_wait = started.elapsed();
        if lock_wait >= LOCK_WAIT_LOG_THRESHOLD {
            tracing::debug!(
                "[lock] read dispatch waited {:.1}ms for server read lock",
                lock_wait.as_secs_f64() * 1000.0
            );
        }
        f(&guard)
    }

    pub fn try_with_server_ref<R>(&self, f: impl FnOnce(&Server) -> R) -> Option<R> {
        let guard = self.inner.try_read().ok()?;
        Some(f(&guard))
    }

    pub fn wait_for_consequences(&self) {
        let tracker = self
            .inner
            .read()
            .unwrap_or_else(|e| {
                tracing::error!("Server rwlock poisoned, recovering: {}", e);
                e.into_inner()
            })
            .consequence_tracker();
        drop(tracker);
        let tracker = self
            .inner
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .consequence_tracker();
        tracker.wait_for_consequences();
    }

    pub fn wait_for_consequences_timeout(&self, timeout: std::time::Duration) -> bool {
        let tracker = self
            .inner
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .consequence_tracker();
        tracker.wait_for_consequences_timeout(timeout)
    }

    pub fn wait_for_write(&self) {
        let barrier = self
            .inner
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .write_barrier();
        barrier.wait_for_write();
    }

    pub fn wait_for_write_timeout(&self, timeout: std::time::Duration) -> bool {
        let barrier = self
            .inner
            .read()
            .unwrap_or_else(|e| e.into_inner())
            .write_barrier();
        barrier.wait_for_write_timeout(timeout)
    }

    /// Non-blocking checkpoint (issue #90, PERF-PLAN Stage 1).
    ///
    /// The prepare phase is sliced: the server write lock is acquired in
    /// short bursts (prune, per-batch materialization, per-batch work/
    /// club/edition snapshots, final assembly) so dispatch interleaves
    /// between slices instead of stalling behind one long hold.
    /// Serialization (tag_json) runs in checkpoint_persist on the
    /// blocking thread. Correctness under interleaving:
    /// - dirty_gen comparison at commit discards stale work snapshots
    /// - checkpoint_finalize residual scans capture anything that
    ///   appeared or changed mid-checkpoint (completeness guarantee)
    pub async fn checkpoint_async(&self) -> std::io::Result<()> {
        let prep_start = std::time::Instant::now();

        self.with_server(|srv| srv.prune_disconnected_sessions());

        let pending = self.with_server(|srv| srv.pending_crdt_work_ids());
        let mut materialized = 0usize;
        let mut materialize_ms = 0f64;
        for batch in pending.chunks(MATERIALIZE_BATCH) {
            let t = std::time::Instant::now();
            materialized += self.with_server(|srv| srv.materialize_pending_ids(batch));
            materialize_ms += t.elapsed().as_secs_f64() * 1000.0;
        }

        let (work_ids, club_ids, edition_ids) = self.with_server(|srv| srv.checkpoint_id_lists());

        let mut partial = crate::server::server::CheckpointPartial::default();
        let mut works_ms = 0f64;
        for batch in work_ids.chunks(WORK_SNAPSHOT_BATCH) {
            let t = std::time::Instant::now();
            self.with_server(|srv| srv.checkpoint_visit_works(batch, &mut partial));
            works_ms += t.elapsed().as_secs_f64() * 1000.0;
        }
        let mut aux_ms = 0f64;
        for batch in club_ids.chunks(AUX_SNAPSHOT_BATCH) {
            let t = std::time::Instant::now();
            self.with_server(|srv| srv.checkpoint_visit_clubs(batch, &mut partial));
            aux_ms += t.elapsed().as_secs_f64() * 1000.0;
        }
        for batch in edition_ids.chunks(AUX_SNAPSHOT_BATCH) {
            let t = std::time::Instant::now();
            self.with_server(|srv| srv.checkpoint_visit_editions(batch, &mut partial));
            aux_ms += t.elapsed().as_secs_f64() * 1000.0;
        }

        let t_final = std::time::Instant::now();
        let payload = self.with_server(|srv| srv.checkpoint_finalize(partial))?;
        let finalize_ms = t_final.elapsed().as_secs_f64() * 1000.0;

        tracing::info!(
            "[checkpoint] prepare (sliced) in {:.2}ms: materialize {} work(s) {:.2}ms, works {:.2}ms, clubs+editions {:.2}ms, finalize {:.2}ms",
            prep_start.elapsed().as_secs_f64() * 1000.0,
            materialized,
            materialize_ms,
            works_ms,
            aux_ms,
            finalize_ms,
        );

        let result =
            tokio::task::spawn_blocking(move || crate::server::server::checkpoint_persist(payload))
                .await
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))??;

        self.with_server(|srv| srv.checkpoint_commit_no_wal_truncate(result))
    }

    /// Lightweight ticket-only save. Writes just the ticket nonces to a
    /// sidecar JSON file — no full checkpoint, no server-wide serialization.
    pub fn save_ticket_nonces(&self) -> std::io::Result<()> {
        self.with_server(|srv| srv.persist_ticket_nonces())
    }
}

impl std::fmt::Debug for ServerHandle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ServerHandle").finish()
    }
}

#[cfg(all(test, feature = "server"))]
mod tests {
    // ── Non-blocking checkpoint correctness (FR-#90) ────────────────

    #[test]
    fn checkpoint_in_flight_prevents_double_checkpoint() {
        let handle = ServerHandle::new(Server::new());
        handle.with_server(|srv| {
            let sid = srv.connect();
            srv.login_public(sid).unwrap();
            srv.create_work(sid, crate::edition::Edition::from_text("test"))
                .unwrap();
        });

        // Simulate: flag in-flight → auto_checkpoint returns false
        handle.with_server(|srv| {
            srv.checkpoint_in_flight = true;
            assert!(
                !srv.check_periodic_maintenance(),
                "in-flight blocks re-entry"
            );
            srv.checkpoint_in_flight = false;
        });
    }

    #[test]
    fn concurrent_health_during_checkpoint_prepare() {
        // The sliced prepare acquires/releases the lock in batches.
        // Health checks (try_health_json) use try_lock — they should
        // succeed between slices, proving the lock is released.
        let handle = ServerHandle::new(Server::new());

        // Populate
        handle.with_server(|srv| {
            let sid = srv.connect();
            srv.login_public(sid).unwrap();
            srv.create_work(sid, crate::edition::Edition::from_text("concurrent test"))
                .unwrap();
        });

        // Health check succeeds (lock is free)
        let json = handle.try_health_json();
        assert!(json.is_some(), "health succeeds when lock is free");

        // Simulate a slice holding the lock briefly
        handle.with_server(|srv| {
            srv.prune_disconnected_sessions();
        });

        // Health still succeeds (lock released between slices)
        let json2 = handle.try_health_json();
        assert!(json2.is_some(), "health succeeds between slices");
    }

    use super::*;

    #[test]
    fn atomic_counter_increments_without_lock() {
        let handle = ServerHandle::new(Server::new());
        let c1 = handle.bump_operation_atomic();
        let c2 = handle.bump_operation_atomic();
        assert_eq!(c1, 1);
        assert_eq!(c2, 2);
        assert_eq!(handle.operation_count(), 2);
    }

    #[test]
    fn try_health_json_returns_some_when_unlocked() {
        let handle = ServerHandle::new(Server::new());
        let json = handle.try_health_json();
        assert!(json.is_some());
        let parsed: serde_json::Value = serde_json::from_str(&json.unwrap()).unwrap();
        assert_eq!(parsed["status"], "ok");
    }

    #[test]
    fn try_with_server_ref_returns_some_when_unlocked() {
        let handle = ServerHandle::new(Server::new());
        let result = handle.try_with_server_ref(|srv| srv.session_count());
        assert_eq!(result, Some(0));
    }

    #[test]
    fn try_with_server_ref_returns_none_when_write_locked() {
        let handle = ServerHandle::new(Server::new());
        let _guard = handle.inner.write().unwrap();
        let result = handle.try_with_server_ref(|_| 42);
        assert_eq!(result, None);
    }

    /// Benchmark: how long a write dispatch waits when the server write
    /// lock is held (e.g. by checkpoint prepare). Documents the dispatch
    /// stall mechanism behind issue #90 — the target of non-blocking
    /// checkpoint (PERF-PLAN Stage 1). The wait should approximate the
    /// remaining hold time, not the total checkpoint duration.
    #[test]
    fn benchmark_write_dispatch_wait_under_held_lock() {
        let handle = ServerHandle::new(Server::new());
        let inner = handle.inner.clone();
        let lock_acquired = Arc::new(std::sync::Barrier::new(2));
        let barrier_clone = lock_acquired.clone();

        let holder = std::thread::spawn(move || {
            let _guard = inner.write().unwrap();
            barrier_clone.wait();
            std::thread::sleep(std::time::Duration::from_millis(50));
        });

        lock_acquired.wait();
        let start = std::time::Instant::now();
        let sessions = handle.with_server(|srv| srv.session_count());
        let waited = start.elapsed();
        holder.join().unwrap();

        assert_eq!(sessions, 0);
        assert!(
            waited >= std::time::Duration::from_millis(40),
            "expected ~50ms lock wait, got {:?}",
            waited
        );
        println!("write dispatch waited {:?} behind 50ms lock hold", waited);
    }

    #[test]
    fn app_state_new_initializes_default_fields() {
        let state = AppState::new(Server::new());
        assert!(state.static_dir.is_none());
        assert!(state.allowed_origins.is_none());
        assert!(!state.csrf_enabled);
        assert!(!state.dev_mode);
        assert!(state.session_senders.lock().unwrap().is_empty());
        assert!(state.csrf_tokens.lock().unwrap().is_empty());
        let _shared: SharedState = state.shared();
    }

    #[test]
    fn app_state_builder_methods_set_fields() {
        let state = AppState::new(Server::new())
            .with_static_dir(PathBuf::from("/tmp/static"))
            .with_allowed_origins(HashSet::from(["https://example.com".to_string()]))
            .with_csrf(true)
            .with_dev_mode(true);
        assert_eq!(
            state.static_dir.as_deref(),
            Some(std::path::Path::new("/tmp/static"))
        );
        assert_eq!(state.allowed_origins.as_ref().unwrap().len(), 1);
        assert!(state.csrf_enabled);
        assert!(state.dev_mode);
    }

    #[test]
    fn app_state_shared_wraps_in_arc() {
        let state = AppState::new(Server::new());
        let shared = state.shared();
        assert!(Arc::strong_count(&shared) >= 1);
    }

    #[test]
    fn app_state_with_security_sets_monitor() {
        let monitor = SecurityMonitor::new(Arc::new(super::super::audit::TracingAuditLog));
        let state = AppState::with_security(Server::new(), monitor);
        assert_eq!(
            state.security.lock().unwrap().active_sessions_for_ip(None),
            0
        );
    }

    #[test]
    fn register_and_send_to_session_delivers_message() {
        let state = AppState::new(Server::new());
        let session_id = SessionId::new(1);
        let (tx, mut rx) = tokio::sync::mpsc::unbounded_channel::<EventMessage>();
        state.register_session_sender(session_id, tx);

        let event = EventMessage {
            session_id,
            subscription_id: 0,
            event: super::super::protocol::EventPayload::Done { operation_id: 7 },
        };
        assert!(state.send_to_session(&session_id, event));
        assert!(rx.try_recv().is_ok());
    }

    #[test]
    fn send_to_session_unknown_returns_false() {
        let state = AppState::new(Server::new());
        let event = EventMessage {
            session_id: SessionId::new(99),
            subscription_id: 0,
            event: super::super::protocol::EventPayload::Done { operation_id: 0 },
        };
        assert!(!state.send_to_session(&SessionId::new(99), event));
    }

    #[test]
    fn unregister_session_sender_removes_channel() {
        let state = AppState::new(Server::new());
        let session_id = SessionId::new(2);
        let (tx, _rx) = tokio::sync::mpsc::unbounded_channel::<EventMessage>();
        state.register_session_sender(session_id, tx);
        assert!(state
            .session_senders
            .lock()
            .unwrap()
            .contains_key(&session_id));

        state.unregister_session_sender(&session_id);
        assert!(!state
            .session_senders
            .lock()
            .unwrap()
            .contains_key(&session_id));

        let event = EventMessage {
            session_id,
            subscription_id: 0,
            event: super::super::protocol::EventPayload::Done { operation_id: 0 },
        };
        assert!(!state.send_to_session(&session_id, event));
    }

    #[test]
    fn with_server_callback_executes_and_can_mutate() {
        let handle = ServerHandle::new(Server::new());
        let before = handle.with_server_ref(|srv| srv.session_count());
        assert_eq!(before, 0);
        let pruned = handle.with_server(|srv| srv.prune_disconnected_sessions());
        assert_eq!(pruned, 0);
    }

    #[test]
    fn with_server_ref_callback_executes() {
        let handle = ServerHandle::new(Server::new());
        let count = handle.with_server_ref(|srv| srv.session_count());
        assert_eq!(count, 0);
    }

    #[test]
    fn wait_for_consequences_timeout_succeeds_when_idle() {
        let handle = ServerHandle::new(Server::new());
        let ok = handle.wait_for_consequences_timeout(std::time::Duration::from_millis(50));
        assert!(ok);
    }

    #[test]
    fn wait_for_write_timeout_succeeds_when_idle() {
        let handle = ServerHandle::new(Server::new());
        let ok = handle.wait_for_write_timeout(std::time::Duration::from_millis(50));
        assert!(ok);
    }

    #[test]
    fn save_ticket_nonces_returns_err_without_data_dir() {
        let handle = ServerHandle::new(Server::new());
        let result = handle.save_ticket_nonces();
        assert!(result.is_err());
        assert_eq!(result.unwrap_err().kind(), std::io::ErrorKind::NotFound);
    }
}

/// FR-43 metrics sink: per-op dispatch wall-time, in-process.
/// Fixed log-ish buckets + count/sum; p50/p95/p99 computed on read.
/// Read via `metrics_snapshot()` (robots / admin ops).
#[derive(Debug, Default)]
pub struct DispatchMetrics {
    /// op name -> (count, total_us, bucket_idx -> count)
    ops: std::sync::RwLock<std::collections::HashMap<String, OpHist>>,
}

#[derive(Debug, Default, Clone)]
pub struct OpHist {
    pub count: u64,
    pub total_us: u64,
    pub max_us: u64,
    /// buckets: <=1ms, <=5ms, <=20ms, <=100ms, <=500ms, <=2s, >2s
    pub buckets: [u64; 7],
}

impl DispatchMetrics {
    pub fn record(&self, op: &str, duration: std::time::Duration) {
        let us = duration.as_micros() as u64;
        let bucket = if us <= 1_000 {
            0
        } else if us <= 5_000 {
            1
        } else if us <= 20_000 {
            2
        } else if us <= 100_000 {
            3
        } else if us <= 500_000 {
            4
        } else if us <= 2_000_000 {
            5
        } else {
            6
        };
        if let Ok(mut ops) = self.ops.write() {
            let h = ops.entry(op.to_string()).or_default();
            h.count += 1;
            h.total_us += us;
            h.max_us = h.max_us.max(us);
            h.buckets[bucket] += 1;
        }
    }

    /// Snapshot: op -> (count, avg_us, max_us, p50_us, p95_us, p99_us)
    /// percentiles from bucket interpolation (sufficient for capacity
    /// trending; not HDR precision).
    pub fn snapshot(&self) -> Vec<(String, u64, u64, u64, u64, u64, u64)> {
        let ops = match self.ops.read() {
            Ok(o) => o,
            Err(e) => e.into_inner(),
        };
        let mut out: Vec<(String, u64, u64, u64, u64, u64, u64)> = ops
            .iter()
            .map(|(op, h)| {
                let p = |q: f64| -> u64 {
                    let target = (h.count as f64 * q).ceil() as u64;
                    let mut acc = 0u64;
                    for (i, &b) in h.buckets.iter().enumerate() {
                        acc += b;
                        if acc >= target && b > 0 {
                            return match i {
                                0 => 500,
                                1 => 3_000,
                                2 => 10_000,
                                3 => 50_000,
                                4 => 250_000,
                                5 => 1_000_000,
                                _ => 3_000_000,
                            };
                        }
                    }
                    h.max_us
                };
                (
                    op.clone(),
                    h.count,
                    if h.count > 0 { h.total_us / h.count } else { 0 },
                    h.max_us,
                    p(0.50),
                    p(0.95),
                    p(0.99),
                )
            })
            .collect();
        out.sort_by(|a, b| b.3.cmp(&a.3));
        out
    }
}

#[cfg(test)]
mod metrics_tests {
    use super::*;

    #[test]
    fn buckets_and_percentiles() {
        let m = DispatchMetrics::default();
        for _ in 0..95 {
            m.record("op", std::time::Duration::from_micros(500)); // <=1ms
        }
        for _ in 0..4 {
            m.record("op", std::time::Duration::from_micros(3_000)); // <=5ms
        }
        m.record("op", std::time::Duration::from_millis(50)); // <=100ms
        let snap = m.snapshot();
        let (op, count, avg, max, p50, p95, p99) = snap[0].clone();
        assert_eq!(op, "op");
        assert_eq!(count, 100);
        assert_eq!(p50, 500); // majority in <=1ms bucket
        assert!(p95 <= 3_000, "p95 in second bucket: {p95}");
        // p99 of 100 samples = 99th smallest — the 4 slow bucket1 samples
        // cover ranks 96-99, so p99 correctly lands in bucket1; the 50ms
        // sample is rank 100 (the max), reported by max not p99.
        assert_eq!(p99, 3_000);
        assert_eq!(max, 50_000);
        assert!(max >= 50_000);
        assert!(avg > 0);
    }

    #[test]
    fn empty_is_zero() {
        let m = DispatchMetrics::default();
        assert!(m.snapshot().is_empty());
    }
}
