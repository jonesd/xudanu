use std::collections::{HashMap, HashSet, VecDeque};
use std::path::PathBuf;
use std::sync::{Arc, Mutex, RwLock};

use super::audit::SecurityMonitor;
use super::channel::EventMessage;
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
    pub csrf_tokens: Arc<Mutex<VecDeque<String>>>,
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
            csrf_tokens: Arc::new(Mutex::new(VecDeque::new())),
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

    pub fn shared(self) -> SharedState {
        Arc::new(self)
    }
}

#[derive(Clone)]
pub struct ServerHandle {
    inner: Arc<RwLock<Server>>,
}

impl ServerHandle {
    pub fn new(server: Server) -> Self {
        ServerHandle {
            inner: Arc::new(RwLock::new(server)),
        }
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
}

impl std::fmt::Debug for ServerHandle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ServerHandle").finish()
    }
}
