use std::collections::{HashMap, HashSet};
use std::path::PathBuf;
use std::sync::{Arc, Mutex, RwLock};

use super::audit::SecurityMonitor;
use super::channel::EventMessage;
use super::oauth::{OAuthConfig, OAuthState};
use crate::server::session::SessionId;
use crate::server::Server;

pub const MAX_CSRF_TOKENS: usize = 10_000;

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
        self.operation_counter.fetch_add(1, std::sync::atomic::Ordering::Relaxed) + 1
    }

    pub fn operation_count(&self) -> u64 {
        self.operation_counter.load(std::sync::atomic::Ordering::Relaxed)
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
        let mut guard = self.inner.write().unwrap_or_else(|e| {
            tracing::error!("Server rwlock poisoned, recovering: {}", e);
            e.into_inner()
        });
        f(&mut guard)
    }

    pub fn with_server_ref<R>(&self, f: impl FnOnce(&Server) -> R) -> R {
        let guard = self.inner.read().unwrap_or_else(|e| {
            tracing::error!("Server rwlock poisoned, recovering: {}", e);
            e.into_inner()
        });
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

    pub async fn checkpoint_async(&self) -> std::io::Result<()> {
        let payload = self.with_server(|srv| -> std::io::Result<_> {
            let _ = srv.prune_disconnected_sessions();
            srv.materialize_all_pending();
            srv.checkpoint_prepare()
        })?;

        let result =
            tokio::task::spawn_blocking(move || crate::server::server::checkpoint_persist(payload))
                .await
                .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e))??;

        self.with_server(|srv| srv.checkpoint_commit(result))
    }
}

impl std::fmt::Debug for ServerHandle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ServerHandle").finish()
    }
}

#[cfg(all(test, feature = "server"))]
mod tests {
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
}
