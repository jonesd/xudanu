use std::path::PathBuf;
use std::sync::{Arc, Mutex};

use crate::server::Server;
use super::audit::SecurityMonitor;
use super::channel::EventMessage;

pub type SharedState = Arc<AppState>;

pub struct AppState {
    pub server: ServerHandle,
    pub event_bus: tokio::sync::broadcast::Sender<EventMessage>,
    pub security: Arc<Mutex<SecurityMonitor>>,
    pub static_dir: Option<PathBuf>,
}

impl AppState {
    pub fn new(srv: Server) -> Self {
        Self::with_security(srv, SecurityMonitor::new(Arc::new(super::audit::TracingAuditLog)))
    }

    pub fn with_security(srv: Server, monitor: SecurityMonitor) -> Self {
        let handle = ServerHandle::new(srv);
        let (tx, _) = tokio::sync::broadcast::channel(256);
        AppState {
            server: handle,
            event_bus: tx,
            security: Arc::new(Mutex::new(monitor)),
            static_dir: None,
        }
    }

    pub fn with_static_dir(mut self, dir: PathBuf) -> Self {
        self.static_dir = Some(dir);
        self
    }

    pub fn shared(self) -> SharedState {
        Arc::new(self)
    }
}

#[derive(Clone)]
pub struct ServerHandle {
    inner: Arc<Mutex<Server>>,
}

impl ServerHandle {
    pub fn new(server: Server) -> Self {
        ServerHandle {
            inner: Arc::new(Mutex::new(server)),
        }
    }

    pub fn with_server<R>(&self, f: impl FnOnce(&mut Server) -> R) -> R {
        let mut guard = self.inner.lock().unwrap();
        f(&mut guard)
    }

    pub fn with_server_ref<R>(&self, f: impl FnOnce(&Server) -> R) -> R {
        let guard = self.inner.lock().unwrap();
        f(&guard)
    }
}

impl std::fmt::Debug for ServerHandle {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("ServerHandle").finish()
    }
}
