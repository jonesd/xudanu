use std::collections::HashMap;
use std::sync::Arc;

use crate::server::SessionId;

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct AuditEvent {
    pub timestamp: String,
    pub session_id: Option<u64>,
    pub remote_addr: Option<String>,
    pub kind: AuditEventKind,
    pub detail: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AuditEventKind {
    AuthSuccess,
    AuthFailure,
    PermissionDenied,
    ProtocolViolation,
    ResourceExhaustion,
    SuspiciousPattern,
    RateLimit,
    SessionOpened,
    SessionClosed,
    GrabConflict,
    StateCorruption,
}

pub trait AuditLog: Send + Sync + std::fmt::Debug {
    fn record(&self, event: AuditEvent);
}

#[derive(Debug)]
pub struct TracingAuditLog;

impl AuditLog for TracingAuditLog {
    fn record(&self, event: AuditEvent) {
        match event.kind {
            AuditEventKind::AuthSuccess
            | AuditEventKind::SessionOpened
            | AuditEventKind::SessionClosed => {
                tracing::info!(
                    kind = ?event.kind,
                    session = event.session_id,
                    remote = event.remote_addr,
                    "{}",
                    event.detail
                );
            }
            AuditEventKind::AuthFailure
            | AuditEventKind::PermissionDenied
            | AuditEventKind::GrabConflict => {
                tracing::warn!(
                    kind = ?event.kind,
                    session = event.session_id,
                    remote = event.remote_addr,
                    "{}",
                    event.detail
                );
            }
            AuditEventKind::ProtocolViolation
            | AuditEventKind::SuspiciousPattern
            | AuditEventKind::RateLimit => {
                tracing::warn!(
                    kind = ?event.kind,
                    session = event.session_id,
                    remote = event.remote_addr,
                    "{}",
                    event.detail
                );
            }
            AuditEventKind::ResourceExhaustion | AuditEventKind::StateCorruption => {
                tracing::error!(
                    kind = ?event.kind,
                    session = event.session_id,
                    remote = event.remote_addr,
                    "{}",
                    event.detail
                );
            }
        }
    }
}

#[derive(Debug)]
pub struct CollectorAuditLog {
    events: Arc<std::sync::Mutex<Vec<AuditEvent>>>,
}

impl CollectorAuditLog {
    pub fn new() -> Self {
        CollectorAuditLog {
            events: Arc::new(std::sync::Mutex::new(Vec::new())),
        }
    }

    pub fn events(&self) -> Vec<AuditEvent> {
        self.events.lock().unwrap().clone()
    }

    pub fn events_of_kind(&self, kind: AuditEventKind) -> Vec<AuditEvent> {
        self.events
            .lock()
            .unwrap()
            .iter()
            .filter(|e| e.kind == kind)
            .cloned()
            .collect()
    }

    pub fn clear(&self) {
        self.events.lock().unwrap().clear();
    }
}

impl AuditLog for CollectorAuditLog {
    fn record(&self, event: AuditEvent) {
        self.events.lock().unwrap().push(event);
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ThreatLevel {
    Normal,
    Elevated,
    High,
    Critical,
}

#[derive(Debug, Clone, Hash, PartialEq, Eq)]
struct SessionKey {
    session_id: u64,
    remote_addr: Option<String>,
}

#[derive(Debug, Clone, Hash, PartialEq, Eq)]
struct IpKey {
    addr: Option<String>,
}

impl IpKey {
    fn from_remote(remote: Option<std::net::SocketAddr>) -> Self {
        IpKey {
            addr: remote.map(|a| a.to_string()),
        }
    }
}

#[derive(Debug)]
struct SlidingCounter {
    count: u32,
    window_start: std::time::Instant,
    window_secs: u64,
}

impl SlidingCounter {
    fn new(window_secs: u64) -> Self {
        SlidingCounter {
            count: 0,
            window_start: std::time::Instant::now(),
            window_secs,
        }
    }

    fn bump(&mut self) -> u32 {
        if self.window_start.elapsed().as_secs() >= self.window_secs {
            self.count = 0;
            self.window_start = std::time::Instant::now();
        }
        self.count += 1;
        self.count
    }

    fn reset(&mut self) {
        self.count = 0;
        self.window_start = std::time::Instant::now();
    }

    fn count(&self) -> u32 {
        if self.window_start.elapsed().as_secs() >= self.window_secs {
            0
        } else {
            self.count
        }
    }
}

#[derive(Debug, Clone)]
pub struct SecurityConfig {
    pub max_auth_failures_per_minute: u32,
    pub max_protocol_violations_per_minute: u32,
    pub max_requests_per_second: u32,
    pub max_sessions_per_ip: u32,
    pub max_permission_denials_per_minute: u32,
    pub max_grab_conflicts_per_minute: u32,
}

impl Default for SecurityConfig {
    fn default() -> Self {
        SecurityConfig {
            max_auth_failures_per_minute: 10,
            max_protocol_violations_per_minute: 20,
            max_requests_per_second: 100,
            max_sessions_per_ip: 50,
            max_permission_denials_per_minute: 30,
            max_grab_conflicts_per_minute: 15,
        }
    }
}

#[derive(Debug)]
pub struct SecurityMonitor {
    audit: Arc<dyn AuditLog>,

    per_session: HashMap<SessionKey, SessionTrackers>,
    per_ip: HashMap<IpKey, IpTrackers>,
    active_sessions_per_ip: HashMap<IpKey, u32>,

    config: SecurityConfig,
}

#[derive(Debug, Default)]
struct SessionTrackers {
    auth_failures: Option<SlidingCounter>,
    protocol_violations: Option<SlidingCounter>,
    permission_denials: Option<SlidingCounter>,
    grab_conflicts: Option<SlidingCounter>,
    request_rate: Option<SlidingCounter>,
}

#[derive(Debug, Default)]
struct IpTrackers {
    auth_failures: Option<SlidingCounter>,
    protocol_violations: Option<SlidingCounter>,
    permission_denials: Option<SlidingCounter>,
    request_rate: Option<SlidingCounter>,
}

impl SecurityMonitor {
    pub fn new(audit: Arc<dyn AuditLog>) -> Self {
        SecurityMonitor {
            audit,
            per_session: HashMap::new(),
            per_ip: HashMap::new(),
            active_sessions_per_ip: HashMap::new(),
            config: SecurityConfig::default(),
        }
    }

    pub fn with_config(mut self, config: SecurityConfig) -> Self {
        self.config = config;
        self
    }

    fn emit(&self, event: AuditEvent) {
        self.audit.record(event);
    }

    fn skey(&self, session_id: SessionId, remote: Option<std::net::SocketAddr>) -> SessionKey {
        SessionKey {
            session_id: session_id.as_u64(),
            remote_addr: remote.map(|a| a.to_string()),
        }
    }

    fn ikey(&self, remote: Option<std::net::SocketAddr>) -> IpKey {
        IpKey::from_remote(remote)
    }

    fn bump_session_auth_failure(&mut self, key: &SessionKey) -> u32 {
        self.per_session
            .entry(key.clone())
            .or_default()
            .auth_failures
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_ip_auth_failure(&mut self, key: &IpKey) -> u32 {
        self.per_ip
            .entry(key.clone())
            .or_default()
            .auth_failures
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_session_protocol(&mut self, key: &SessionKey) -> u32 {
        self.per_session
            .entry(key.clone())
            .or_default()
            .protocol_violations
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_ip_protocol(&mut self, key: &IpKey) -> u32 {
        self.per_ip
            .entry(key.clone())
            .or_default()
            .protocol_violations
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_session_permission(&mut self, key: &SessionKey) -> u32 {
        self.per_session
            .entry(key.clone())
            .or_default()
            .permission_denials
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_ip_permission(&mut self, key: &IpKey) -> u32 {
        self.per_ip
            .entry(key.clone())
            .or_default()
            .permission_denials
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_session_grab_conflict(&mut self, key: &SessionKey) -> u32 {
        self.per_session
            .entry(key.clone())
            .or_default()
            .grab_conflicts
            .get_or_insert_with(|| SlidingCounter::new(60))
            .bump()
    }

    fn bump_session_request(&mut self, key: &SessionKey) -> u32 {
        self.per_session
            .entry(key.clone())
            .or_default()
            .request_rate
            .get_or_insert_with(|| SlidingCounter::new(1))
            .bump()
    }

    fn bump_ip_request(&mut self, key: &IpKey) -> u32 {
        self.per_ip
            .entry(key.clone())
            .or_default()
            .request_rate
            .get_or_insert_with(|| SlidingCounter::new(1))
            .bump()
    }

    fn classify(&self, count: u32, limit: u32) -> ThreatLevel {
        if count >= limit {
            ThreatLevel::Critical
        } else if count >= limit * 3 / 4 {
            ThreatLevel::High
        } else if count >= limit / 3 {
            ThreatLevel::Elevated
        } else {
            ThreatLevel::Normal
        }
    }

    pub fn on_auth_success(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let skey = self.skey(session_id, remote);
        if let Some(st) = self.per_session.get_mut(&skey) {
            if let Some(ref mut c) = st.auth_failures {
                c.reset();
            }
        }
        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::AuthSuccess,
            detail,
        });
    }

    pub fn on_auth_failure(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let skey = self.skey(session_id, remote);
        let ikey = self.ikey(remote);
        let limit = self.config.max_auth_failures_per_minute;

        let session_count = self.bump_session_auth_failure(&skey);
        let ip_count = self.bump_ip_auth_failure(&ikey);
        let level = self.classify(std::cmp::max(session_count, ip_count), limit);

        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::AuthFailure,
            detail: format!(
                "{} (session_failures={}, ip_failures={}, threat: {:?})",
                detail, session_count, ip_count, level
            ),
        });

        if level == ThreatLevel::Critical {
            self.emit(AuditEvent {
                timestamp: now_iso(),
                session_id: Some(session_id.as_u64()),
                remote_addr: remote.map(|a| a.to_string()),
                kind: AuditEventKind::RateLimit,
                detail: format!(
                    "auth failure rate limit: {} session failures, {} ip failures in 60s",
                    session_count, ip_count
                ),
            });
        }
    }

    pub fn on_permission_denied(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let skey = self.skey(session_id, remote);
        let ikey = self.ikey(remote);
        let limit = self.config.max_permission_denials_per_minute;

        let session_count = self.bump_session_permission(&skey);
        let ip_count = self.bump_ip_permission(&ikey);
        let level = self.classify(std::cmp::max(session_count, ip_count), limit);

        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::PermissionDenied,
            detail: format!(
                "{} (session_denials={}, ip_denials={}, threat: {:?})",
                detail, session_count, ip_count, level
            ),
        });

        if level == ThreatLevel::Critical {
            self.emit(AuditEvent {
                timestamp: now_iso(),
                session_id: Some(session_id.as_u64()),
                remote_addr: remote.map(|a| a.to_string()),
                kind: AuditEventKind::RateLimit,
                detail: format!(
                    "permission denial rate limit: {} session, {} ip in 60s",
                    session_count, ip_count
                ),
            });
        }
    }

    pub fn on_grab_conflict(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let skey = self.skey(session_id, remote);
        let limit = self.config.max_grab_conflicts_per_minute;

        let count = self.bump_session_grab_conflict(&skey);
        let level = self.classify(count, limit);

        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::GrabConflict,
            detail: format!("{} (conflicts={}, threat: {:?})", detail, count, level),
        });

        if level == ThreatLevel::Critical {
            self.emit(AuditEvent {
                timestamp: now_iso(),
                session_id: Some(session_id.as_u64()),
                remote_addr: remote.map(|a| a.to_string()),
                kind: AuditEventKind::RateLimit,
                detail: format!("grab conflict rate limit: {} in 60s", count),
            });
        }
    }

    pub fn on_protocol_violation(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let skey = self.skey(session_id, remote);
        let ikey = self.ikey(remote);
        let limit = self.config.max_protocol_violations_per_minute;

        let session_count = self.bump_session_protocol(&skey);
        let ip_count = self.bump_ip_protocol(&ikey);
        let level = self.classify(std::cmp::max(session_count, ip_count), limit);

        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::ProtocolViolation,
            detail: format!(
                "{} (session_violations={}, ip_violations={}, threat: {:?})",
                detail, session_count, ip_count, level
            ),
        });

        if level == ThreatLevel::Critical {
            self.emit(AuditEvent {
                timestamp: now_iso(),
                session_id: Some(session_id.as_u64()),
                remote_addr: remote.map(|a| a.to_string()),
                kind: AuditEventKind::RateLimit,
                detail: format!(
                    "protocol violation rate limit: {} session, {} ip in 60s",
                    session_count, ip_count
                ),
            });
        }
    }

    pub fn on_request(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
    ) -> ThreatLevel {
        let skey = self.skey(session_id, remote);
        let ikey = self.ikey(remote);
        let limit = self.config.max_requests_per_second;

        let session_count = self.bump_session_request(&skey);
        let ip_count = self.bump_ip_request(&ikey);
        let worst = std::cmp::max(session_count, ip_count);

        if worst > limit {
            self.emit(AuditEvent {
                timestamp: now_iso(),
                session_id: Some(session_id.as_u64()),
                remote_addr: remote.map(|a| a.to_string()),
                kind: AuditEventKind::RateLimit,
                detail: format!(
                    "request rate exceeded: {} session/sec, {} ip/sec",
                    session_count, ip_count
                ),
            });
            ThreatLevel::Critical
        } else if worst > limit * 3 / 4 {
            ThreatLevel::High
        } else if worst > limit / 2 {
            ThreatLevel::Elevated
        } else {
            ThreatLevel::Normal
        }
    }

    pub fn on_resource_exhaustion(
        &mut self,
        session_id: Option<SessionId>,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: session_id.map(|s| s.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::ResourceExhaustion,
            detail,
        });
    }

    pub fn on_session_opened(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let ikey = self.ikey(remote);
        let count = self.active_sessions_per_ip.entry(ikey.clone()).or_insert(0);
        *count += 1;
        let count_val = *count;
        let exceeded = count_val > self.config.max_sessions_per_ip;
        let addr_str = ikey.addr.clone();

        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::SessionOpened,
            detail: format!(
                "session opened from {} (active_from_ip={})",
                remote
                    .map(|a| a.to_string())
                    .unwrap_or_else(|| "unknown".to_string()),
                count_val
            ),
        });

        if exceeded {
            self.emit(AuditEvent {
                timestamp: now_iso(),
                session_id: Some(session_id.as_u64()),
                remote_addr: remote.map(|a| a.to_string()),
                kind: AuditEventKind::RateLimit,
                detail: format!(
                    "session limit per ip exceeded: {} active from {:?}",
                    count_val, addr_str
                ),
            });
        }
    }

    pub fn on_session_closed(
        &mut self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
        detail: String,
    ) {
        let skey = self.skey(session_id, remote);
        let ikey = self.ikey(remote);

        self.per_session.remove(&skey);

        if let Some(count) = self.active_sessions_per_ip.get_mut(&ikey) {
            *count = count.saturating_sub(1);
            if *count == 0 {
                self.active_sessions_per_ip.remove(&ikey);
            }
        }

        self.emit(AuditEvent {
            timestamp: now_iso(),
            session_id: Some(session_id.as_u64()),
            remote_addr: remote.map(|a| a.to_string()),
            kind: AuditEventKind::SessionClosed,
            detail,
        });
    }

    pub fn should_disconnect(
        &self,
        session_id: SessionId,
        remote: Option<std::net::SocketAddr>,
    ) -> bool {
        let skey = self.skey(session_id, remote);
        let ikey = self.ikey(remote);

        if let Some(st) = self.per_session.get(&skey) {
            if let Some(ref c) = st.auth_failures {
                if c.count() >= self.config.max_auth_failures_per_minute {
                    return true;
                }
            }
            if let Some(ref c) = st.protocol_violations {
                if c.count() >= self.config.max_protocol_violations_per_minute {
                    return true;
                }
            }
            if let Some(ref c) = st.permission_denials {
                if c.count() >= self.config.max_permission_denials_per_minute {
                    return true;
                }
            }
            if let Some(ref c) = st.grab_conflicts {
                if c.count() >= self.config.max_grab_conflicts_per_minute {
                    return true;
                }
            }
        }

        if let Some(it) = self.per_ip.get(&ikey) {
            if let Some(ref c) = it.auth_failures {
                if c.count() >= self.config.max_auth_failures_per_minute {
                    return true;
                }
            }
            if let Some(ref c) = it.protocol_violations {
                if c.count() >= self.config.max_protocol_violations_per_minute {
                    return true;
                }
            }
            if let Some(ref c) = it.permission_denials {
                if c.count() >= self.config.max_permission_denials_per_minute {
                    return true;
                }
            }
        }

        if let Some(count) = self.active_sessions_per_ip.get(&ikey) {
            if *count > self.config.max_sessions_per_ip {
                return true;
            }
        }

        false
    }

    pub fn active_sessions_for_ip(&self, remote: Option<std::net::SocketAddr>) -> u32 {
        let ikey = self.ikey(remote);
        self.active_sessions_per_ip.get(&ikey).copied().unwrap_or(0)
    }
}

fn now_iso() -> String {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn audit_event_serialization() {
        let event = AuditEvent {
            timestamp: "12345".to_string(),
            session_id: Some(42),
            remote_addr: Some("127.0.0.1:8080".to_string()),
            kind: AuditEventKind::AuthFailure,
            detail: "login failed".to_string(),
        };
        let json = serde_json::to_string(&event).unwrap();
        assert!(json.contains("auth_failure"));
        assert!(json.contains("127.0.0.1"));
    }

    #[test]
    fn auth_failure_escalates_per_session() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_auth_failures_per_minute: 10,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let sid = SessionId::new(1);

        for _ in 0..3 {
            monitor.on_auth_failure(sid, None, "fail".to_string());
        }
        let failures = collector.events_of_kind(AuditEventKind::AuthFailure);
        assert!(failures[2].detail.contains("threat: Elevated"));

        for _ in 3..8 {
            monitor.on_auth_failure(sid, None, "fail".to_string());
        }
        let failures = collector.events_of_kind(AuditEventKind::AuthFailure);
        assert!(failures.last().unwrap().detail.contains("threat: High"));
    }

    #[test]
    fn auth_success_resets_session_counter() {
        let collector = Arc::new(CollectorAuditLog::new());
        let mut monitor = SecurityMonitor::new(collector.clone());
        let sid = SessionId::new(1);

        monitor.on_auth_failure(sid, None, "fail".to_string());
        monitor.on_auth_success(sid, None, "ok".to_string());
        monitor.on_auth_failure(sid, None, "fail again".to_string());

        let failures = collector.events_of_kind(AuditEventKind::AuthFailure);
        assert!(failures[1].detail.contains("session_failures=1"));
    }

    #[test]
    fn rate_limit_triggers_disconnect() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_auth_failures_per_minute: 3,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let sid = SessionId::new(1);

        for _ in 0..3 {
            monitor.on_auth_failure(sid, None, "fail".to_string());
        }

        assert!(monitor.should_disconnect(sid, None));
        let rate_limits = collector.events_of_kind(AuditEventKind::RateLimit);
        assert_eq!(rate_limits.len(), 1);
    }

    fn localhost(port: u16) -> Option<std::net::SocketAddr> {
        Some(std::net::SocketAddr::from(([127, 0, 0, 1], port)))
    }

    #[test]
    fn ip_tracking_aggregates_across_sessions() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_auth_failures_per_minute: 4,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);

        let sid1 = SessionId::new(1);
        let sid2 = SessionId::new(2);
        let addr = localhost(5000);

        monitor.on_auth_failure(sid1, addr, "fail".to_string());
        monitor.on_auth_failure(sid1, addr, "fail".to_string());
        monitor.on_auth_failure(sid2, addr, "fail".to_string());
        monitor.on_auth_failure(sid2, addr, "fail".to_string());

        assert!(monitor.should_disconnect(sid1, addr));
        assert!(monitor.should_disconnect(sid2, addr));
    }

    #[test]
    fn different_ips_independent() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_auth_failures_per_minute: 3,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);

        let sid1 = SessionId::new(1);
        let sid2 = SessionId::new(2);
        let addr1 = localhost(5000);
        let addr2 = localhost(5001);

        for _ in 0..3 {
            monitor.on_auth_failure(sid1, addr1, "fail".to_string());
        }

        assert!(monitor.should_disconnect(sid1, addr1));
        assert!(!monitor.should_disconnect(sid2, addr2));
    }

    #[test]
    fn protocol_violation_sliding_window() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_protocol_violations_per_minute: 3,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let sid = SessionId::new(1);

        monitor.on_protocol_violation(sid, None, "bad".to_string());
        monitor.on_protocol_violation(sid, None, "bad".to_string());
        monitor.on_protocol_violation(sid, None, "bad".to_string());

        assert!(monitor.should_disconnect(sid, None));
    }

    #[test]
    fn permission_denial_escalates() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_permission_denials_per_minute: 3,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let sid = SessionId::new(1);

        for _ in 0..3 {
            monitor.on_permission_denied(sid, None, "denied".to_string());
        }

        assert!(monitor.should_disconnect(sid, None));
        let rate_limits = collector.events_of_kind(AuditEventKind::RateLimit);
        assert_eq!(rate_limits.len(), 1);
    }

    #[test]
    fn grab_conflict_escalates() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_grab_conflicts_per_minute: 3,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let sid = SessionId::new(1);

        for _ in 0..3 {
            monitor.on_grab_conflict(sid, None, "conflict".to_string());
        }

        assert!(monitor.should_disconnect(sid, None));
    }

    #[test]
    fn session_close_clears_state() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_auth_failures_per_minute: 1,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let sid1 = SessionId::new(1);
        let sid2 = SessionId::new(2);
        let addr1 = localhost(5000);
        let addr2 = localhost(5001);

        monitor.on_auth_failure(sid1, addr1, "fail".to_string());
        assert!(monitor.should_disconnect(sid1, addr1));

        monitor.on_session_closed(sid1, addr1, "done".to_string());

        // Session cleared, but IP still has the failure count
        // A new session from a DIFFERENT IP should be fine
        assert!(!monitor.should_disconnect(sid2, addr2));
    }

    #[test]
    fn session_count_per_ip() {
        let collector = Arc::new(CollectorAuditLog::new());
        let mut monitor = SecurityMonitor::new(collector.clone());
        let addr = localhost(5000);

        monitor.on_session_opened(SessionId::new(1), addr, "opened".to_string());
        monitor.on_session_opened(SessionId::new(2), addr, "opened".to_string());
        assert_eq!(monitor.active_sessions_for_ip(addr), 2);

        monitor.on_session_closed(SessionId::new(1), addr, "done".to_string());
        assert_eq!(monitor.active_sessions_for_ip(addr), 1);
    }

    #[test]
    fn session_limit_per_ip() {
        let collector = Arc::new(CollectorAuditLog::new());
        let config = SecurityConfig {
            max_sessions_per_ip: 2,
            ..Default::default()
        };
        let mut monitor = SecurityMonitor::new(collector.clone()).with_config(config);
        let addr = localhost(5000);

        monitor.on_session_opened(SessionId::new(1), addr, "opened".to_string());
        monitor.on_session_opened(SessionId::new(2), addr, "opened".to_string());
        monitor.on_session_opened(SessionId::new(3), addr, "opened".to_string());

        assert!(monitor.should_disconnect(SessionId::new(3), addr));
        let limits = collector.events_of_kind(AuditEventKind::RateLimit);
        assert!(limits.iter().any(|e| e.detail.contains("session limit per ip")));
    }

    #[test]
    fn sliding_counter_window_expiry() {
        let mut counter = SlidingCounter::new(1);
        assert_eq!(counter.bump(), 1);
        assert_eq!(counter.bump(), 2);
        std::thread::sleep(std::time::Duration::from_millis(1100));
        assert_eq!(counter.count(), 0);
        assert_eq!(counter.bump(), 1);
    }

    #[test]
    fn classify_levels() {
        let monitor = SecurityMonitor::new(Arc::new(CollectorAuditLog::new()));
        assert_eq!(monitor.classify(0, 10), ThreatLevel::Normal);
        assert_eq!(monitor.classify(3, 10), ThreatLevel::Elevated);
        assert_eq!(monitor.classify(7, 10), ThreatLevel::High);
        assert_eq!(monitor.classify(10, 10), ThreatLevel::Critical);
        assert_eq!(monitor.classify(15, 10), ThreatLevel::Critical);
    }
}
