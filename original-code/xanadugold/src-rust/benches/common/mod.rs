//! Shared benchmark harness: boots an in-memory Server wrapped in a
//! SharedState (the same ServerHandle + AppState used by the real transport),
//! seeds works/sessions, and exposes helpers to dispatch WireRequests directly.
//!
//! This measures the real dispatch path (including the RwLock on ServerHandle)
//! without the WebSocket / codec overhead.

use xudanu::edition::{BeId, Edition};
use xudanu::server::transport::{AppState, WireRequest};
use xudanu::server::transport::dispatch::dispatch;
use xudanu::server::transport::shared::SharedState;
use xudanu::server::{Server, SessionId};

/// A pre-seeded server ready for benchmarking.
pub struct BenchState {
    pub state: SharedState,
    pub session: SessionId,
    pub work_ids: Vec<BeId>,
}

impl BenchState {
    /// Boot a fresh server, log in a public session, and seed `n_works` works.
    pub fn seeded(n_works: usize) -> Self {
        let mut server = Server::new();
        let session = server.connect();
        server.login_public(session).unwrap();

        let mut work_ids = Vec::with_capacity(n_works);
        for i in 0..n_works {
            let edition = Edition::from_text(&format!("Work {} — benchmark seed", i));
            let id = server.create_work(session, edition).unwrap();
            work_ids.push(id);
        }

        let state = AppState::new(server).shared();
        BenchState {
            state,
            session,
            work_ids,
        }
    }

    /// Boot a server with a data directory (enables checkpoint), seed works.
    pub fn seeded_with_data_dir(n_works: usize, data_dir: &std::path::Path) -> Self {
        let mut server = Server::new();
        server.init_data_dir(data_dir, None).unwrap();
        let session = server.connect();
        server.login_public(session).unwrap();

        let mut work_ids = Vec::with_capacity(n_works);
        for i in 0..n_works {
            let edition = Edition::from_text(&format!("Work {} — benchmark seed", i));
            let id = server.create_work(session, edition).unwrap();
            work_ids.push(id);
        }

        let state = AppState::new(server).shared();
        BenchState {
            state,
            session,
            work_ids,
        }
    }

    /// Dispatch a WireRequest synchronously through the real dispatch path.
    pub fn dispatch(&self, req: WireRequest) -> xudanu::server::transport::ResponseValue {
        dispatch(&self.state, self.session, req).expect("dispatch failed in bench")
    }

    /// Dispatch a read-only request through the read lock path (for B7 comparison).
    pub fn dispatch_read(&self, req: WireRequest) {
        self.state.server.with_server_ref(|srv| {
            // Simulate the read path: just touch the data the op would read.
            // This is what B7 will route through `with_server_ref`.
            let _ = srv.work_count();
        });
    }

    /// Dispatch a WireRequest, ignoring the result (for throughput benches).
    pub fn dispatch_discard(&self, req: WireRequest) {
        let _ = dispatch(&self.state, self.session, req);
    }

    /// Dispatch under a fresh session (to simulate concurrent users).
    pub fn dispatch_as(&self, session: SessionId, req: WireRequest) {
        let _ = dispatch(&self.state, session, req);
    }
}

/// Create a work via dispatch and return its id.
pub fn create_work_via_dispatch(
    state: &SharedState,
    session: SessionId,
    text: &str,
) -> BeId {
    let req = WireRequest::WorkCreate {
        edition: xudanu::server::transport::EditionPayload::Text(text.to_string()),
    };
    match dispatch(state, session, req).unwrap() {
        xudanu::server::transport::ResponseValue::Id(id) => id,
        other => panic!("expected Id, got {:?}", other),
    }
}

/// Connect and login a new public session on an existing SharedState.
pub fn new_session(state: &SharedState) -> SessionId {
    state.server.with_server(|srv| {
        let sid = srv.connect();
        srv.login_public(sid).unwrap();
        sid
    })
}
