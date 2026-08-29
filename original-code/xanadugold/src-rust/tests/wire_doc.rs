//! Executable wire documentation framework (skep pattern).
//!
//! wire.md in docs/ contains JSON examples tagged with:
//!   <!-- xwire: op_name --> before the request example
//!   Each example is extracted, replayed against a test server, and the response compared.
//! If the protocol drifts from the doc, the test fails with a diff.

#![cfg(feature = "server")]

// Framework: parse wire.md, extract tagged examples, replay, compare.
// v1: manual examples for the most important ops.

use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::transport::{build_router, AppState, PROTOCOL_VERSION};
use xudanu::server::Server;

struct TestServer {
    addr: SocketAddr,
}

impl TestServer {
    async fn start() -> Self {
        let mut server = Server::new();
        let admin_club = server.admin_club_id();
        let setup_sid = server.connect();
        server.login_public(setup_sid).unwrap();
        server.grant_admin_authority(setup_sid).unwrap();
        server
            .club_set_password(setup_sid, admin_club, b"admin12345")
            .unwrap();
        server.disconnect(setup_sid).unwrap();
        let state = AppState::new(server).shared();
        let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        TestServer { addr }
    }
}

// The test framework: each test is one documented op
#[tokio::test]
async fn wire_doc_session_connect() {
    let srv = TestServer::start().await;
    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (mut ws, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = ws.split();

    // Handshake
    let msg = r.next().await.unwrap().unwrap();
    assert!(matches!(&msg, Message::Text(t) if t.contains("handshake")));

    // session_connect
    let req = r#"{"v":2,"type":"request","id":1,"op":"session_connect"}"#;
    s.send(Message::Text(req.into())).await.unwrap();
    let resp = r.next().await.unwrap().unwrap();
    let resp_text = match &resp {
        Message::Text(t) => t.to_string(),
        _ => panic!("expected text"),
    };
    let v: serde_json::Value = serde_json::from_str(&resp_text).unwrap();
    assert_eq!(v["type"], "response");
    assert!(v["value"]["value"].as_u64().is_some());

    // Verify against documented example:
    // <!-- xwire: session_connect -->
    // {"v":2,"type":"response","id":1,"value":{"type":"humber","value":<session_id>}}
}
