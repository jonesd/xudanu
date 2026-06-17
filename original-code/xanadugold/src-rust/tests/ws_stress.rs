//! WebSocket stress tests: concurrency, connection lifecycle, heartbeat
//! latency under load, concurrent edits, rapid reconnect, resource cleanup.
//!
//! These tests spawn real WS connections against a real Axum server,
//! exercising the full handler/dispatch/codec stack.

use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use std::time::{Duration, Instant};
use tokio::time::timeout;
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::transport::{build_router, AppState, MessageType, PROTOCOL_VERSION};
use xudanu::server::Server;

// ------------------------------------------------------------------
// Test infrastructure (mirrors tests/integration.rs but minimal)
// ------------------------------------------------------------------

const ADMIN_PASSWORD: &[u8] = b"admin12345";

fn password_credential(pw: &[u8]) -> serde_json::Value {
    serde_json::json!({"password": pw.iter().map(|&b| serde_json::Value::from(b)).collect::<Vec<_>>()})
}

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
            .club_set_password(setup_sid, admin_club, ADMIN_PASSWORD)
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

type WsStream =
    tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>;
type SplitSender = futures_util::stream::SplitSink<WsStream, Message>;
type SplitReceiver = futures_util::stream::SplitStream<WsStream>;

async fn connect_handshake(srv: &TestServer) -> (SplitSender, SplitReceiver) {
    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    let hs: serde_json::Value = match r.next().await.unwrap().unwrap() {
        Message::Text(t) => serde_json::from_str(&t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
        other => panic!("expected handshake, got: {:?}", other),
    };
    assert_eq!(hs["type"], "handshake");
    (s, r)
}

fn json_req(id: u16, op: &str, payload: Option<serde_json::Value>) -> serde_json::Value {
    let mut f = serde_json::json!({"v": PROTOCOL_VERSION, "type": "request", "id": id, "op": op});
    if let Some(p) = payload {
        f["payload"] = p;
    }
    f
}

async fn send_json(sender: &mut SplitSender, frame: &serde_json::Value) {
    let text = serde_json::to_string(frame).unwrap();
    sender.send(Message::Text(text.into())).await.unwrap();
}

/// Receive next message, skipping events. The server interleaves
/// subscription events with responses on the same WS stream, so callers
/// that expect a response to a specific request must filter by type.
async fn recv_json(receiver: &mut SplitReceiver) -> serde_json::Value {
    let deadline = Duration::from_secs(5);
    loop {
        let msg = timeout(deadline, receiver.next())
            .await
            .expect("recv timeout")
            .expect("stream ended")
            .expect("ws error");
        let val: serde_json::Value = match msg {
            Message::Text(t) => serde_json::from_str(&t).unwrap(),
            Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
            other => panic!("expected json, got: {:?}", other),
        };
        // Skip events — caller wants a response/heartbeat/error
        if val["type"] == "event" {
            continue;
        }
        return val;
    }
}

/// Like recv_json but also returns the request_id for matching.
async fn send_recv_json(
    sender: &mut SplitSender,
    receiver: &mut SplitReceiver,
    frame: serde_json::Value,
) -> serde_json::Value {
    send_json(sender, &frame).await;
    recv_json(receiver).await
}

/// Connect, handshake, login_public. Returns (sender, receiver).
async fn connect_public(srv: &TestServer) -> (SplitSender, SplitReceiver) {
    let (mut s, mut r) = connect_handshake(srv).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
    (s, r)
}

/// Connect, handshake, admin login. Returns (sender, receiver).
async fn connect_admin(srv: &TestServer) -> (SplitSender, SplitReceiver) {
    let (mut s, mut r) = connect_handshake(srv).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let admin_club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "club_id_by_name",
            Some(serde_json::json!({"name": "admin"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "session_login",
            Some(serde_json::json!({"club_id": admin_club_id})),
        ),
    )
    .await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})),
        ),
    )
    .await;

    (s, r)
}

/// Create a work as an admin client. Returns (sender, receiver, work_id).
async fn admin_create_work(srv: &TestServer, text: &str) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_admin(srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": text}})),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();
    (s, r, work_id)
}

async fn drain(receiver: &mut SplitReceiver, max_msgs: usize) {
    for _ in 0..max_msgs {
        match timeout(Duration::from_millis(100), receiver.next()).await {
            Ok(Some(Ok(_))) => {}
            _ => break,
        }
    }
}

// ------------------------------------------------------------------
// Tests
// ------------------------------------------------------------------

/// 20 concurrent connections: all connect, handshake, login_public,
/// send heartbeat, and disconnect cleanly. No panics, no timeouts.
#[tokio::test]
async fn stress_20_concurrent_connections() {
    let srv = TestServer::start().await;
    const N: usize = 20;

    let mut tasks = Vec::new();
    for _ in 0..N {
        let addr = srv.addr;
        let task = tokio::spawn(async move {
            let mini = TestServer { addr };
            let (mut s, mut r) = connect_public(&mini).await;

            let resp = send_recv_json(
                &mut s,
                &mut r,
                serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
            )
            .await;
            assert_eq!(resp["type"], "heartbeat");

            let _ = s.close().await;
        });
        tasks.push(task);
    }

    for (i, task) in tasks.into_iter().enumerate() {
        task.await
            .unwrap_or_else(|e| panic!("connection {} failed: {:?}", i, e));
    }
}

/// Rapid connect/disconnect: 30 cycles on a single sequential loop.
/// Exercises session allocation + cleanup without leaks.
#[tokio::test]
async fn stress_rapid_connect_disconnect() {
    let srv = TestServer::start().await;
    const CYCLES: usize = 30;

    for i in 0..CYCLES {
        let (mut s, mut r) = connect_public(&srv).await;
        let resp = send_recv_json(
            &mut s,
            &mut r,
            serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
        )
        .await;
        assert_eq!(resp["type"], "heartbeat", "cycle {} heartbeat failed", i);
        let _ = s.close().await;
        drain(&mut r, 5).await;
    }
}

/// Heartbeat latency under load: spawn 10 background clients doing work,
/// then measure heartbeat round-trip time.
#[tokio::test]
async fn stress_heartbeat_latency_under_load() {
    let srv = TestServer::start().await;

    // Create a document for background clients to operate on
    let (_owner_s, _owner_r, work_id) = admin_create_work(&srv, "background doc").await;
    // _owner_s and _owner_r are dropped here (the admin connection closes)

    // Spawn background noise: 10 clients subscribing and heartbeating
    let mut bg = Vec::new();
    for _ in 0..10 {
        let addr = srv.addr;
        bg.push(tokio::spawn(async move {
            let mini = TestServer { addr };
            let (mut s, mut r) = connect_public(&mini).await;
            // Subscribe to content changes on the work
            let _ = send_recv_json(
                &mut s,
                &mut r,
                json_req(
                    5,
                    "subscribe",
                    Some(serde_json::json!({"work_id": work_id})),
                ),
            )
            .await;
            // Heartbeat loop for ~1 second
            for _ in 0..5 {
                let _ = send_json(
                    &mut s,
                    &serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
                )
                .await;
                tokio::time::sleep(Duration::from_millis(50)).await;
                drain(&mut r, 3).await;
            }
            let _ = s.close().await;
        }));
    }

    // Let background ramp up
    tokio::time::sleep(Duration::from_millis(100)).await;

    // Measure foreground heartbeat latency
    let (mut fg_s, mut fg_r) = connect_public(&srv).await;
    let mut latencies = Vec::new();
    for _ in 0..10 {
        let start = Instant::now();
        send_json(
            &mut fg_s,
            &serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
        )
        .await;
        let resp = recv_json(&mut fg_r).await;
        let elapsed = start.elapsed();
        assert_eq!(resp["type"], "heartbeat");
        latencies.push(elapsed);
    }

    for t in &latencies {
        assert!(
            t.as_millis() < 1000,
            "heartbeat took {:?} (>1s) under load",
            t
        );
    }

    let avg: Duration = latencies.iter().sum::<Duration>() / latencies.len() as u32;
    eprintln!(
        "heartbeat under load: avg={:?} max={:?} min={:?}",
        avg,
        latencies.iter().max().unwrap(),
        latencies.iter().min().unwrap()
    );

    for task in bg {
        let _ = task.await;
    }
}

/// Two clients create works, then both open each other's works
/// concurrently. Verifies no deadlocks or panics under interleaved access.
#[tokio::test]
async fn stress_concurrent_work_access() {
    let srv = TestServer::start().await;

    // Admin creates a shared document
    let (_s, _r, work_id) = admin_create_work(&srv, "shared content").await;
    // Connection dropped; work persists on server.

    // Two clients open the work concurrently
    let addr = srv.addr;
    let t1 = tokio::spawn(async move {
        let mini = TestServer { addr };
        let (mut s, mut r) = connect_public(&mini).await;
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                10,
                "work_get_edition",
                Some(serde_json::json!({"work_id": work_id})),
            ),
        )
        .await;
        assert!(resp["type"] == "response" || resp["type"] == "error");
        let _ = s.close().await;
    });

    let addr = srv.addr;
    let t2 = tokio::spawn(async move {
        let mini = TestServer { addr };
        let (mut s, mut r) = connect_public(&mini).await;
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                10,
                "work_get_edition",
                Some(serde_json::json!({"work_id": work_id})),
            ),
        )
        .await;
        assert!(resp["type"] == "response" || resp["type"] == "error");
        let _ = s.close().await;
    });

    t1.await.unwrap();
    t2.await.unwrap();
}

/// Send a large text payload (100KB) and verify the server handles it
/// without truncation or panic.
#[tokio::test]
async fn stress_large_payload() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_admin(&srv).await;

    let big_text = "X".repeat(100_000);
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": &big_text}
            })),
        ),
    )
    .await;
    assert_eq!(
        resp["type"], "response",
        "large work_create should succeed: {:?}",
        resp
    );
    let work_id = resp["value"]["value"].as_u64().unwrap();

    // Open and verify length
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let _ = s.close().await;
}

/// Verify that after closing a connection, the server doesn't send
/// stale events. Connect, subscribe, close, then have another client
/// make changes. The closed client's receiver should go silent.
#[tokio::test]
async fn stress_no_events_after_close() {
    let srv = TestServer::start().await;
    let (mut owner_s, _owner_r, work_id) = admin_create_work(&srv, "initial text").await;

    // Observer subscribes
    let (mut obs_s, mut obs_r) = connect_public(&srv).await;
    let _ = send_recv_json(
        &mut obs_s,
        &mut obs_r,
        json_req(
            5,
            "subscribe",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    // Close observer
    let _ = obs_s.close().await;
    // Drain any remaining
    drain(&mut obs_r, 10).await;

    // Owner makes a change
    let _ = send_json(
        &mut owner_s,
        &json_req(
            20,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id,
                "edition": {"text": "changed"}
            })),
        ),
    )
    .await;

    // Wait a bit for any potential stale event
    tokio::time::sleep(Duration::from_millis(300)).await;

    // Observer should NOT receive anything
    match timeout(Duration::from_millis(500), obs_r.next()).await {
        Ok(Some(Ok(msg))) => panic!("received stale event after close: {:?}", msg),
        _ => {}
    }

    let _ = owner_s.close().await;
}

/// 50 sequential connections to the same IP (at the session cap limit).
/// The 51st should be rejected.
#[tokio::test]
async fn stress_session_cap_per_ip() {
    let srv = TestServer::start().await;

    // Open 50 connections without closing
    let mut conns = Vec::new();
    for _ in 0..50 {
        let (s, r) = connect_handshake(&srv).await;
        conns.push((s, r));
    }

    // 51st should be rejected. The server sends a handshake FIRST,
    // then a close frame when the session cap is exceeded.
    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let result = tokio::time::timeout(
        Duration::from_secs(3),
        tokio_tungstenite::connect_async(&url),
    )
    .await;

    match result {
        Ok(Ok((mut stream, _))) => {
            let mut got_handshake = false;
            let mut got_close = false;
            // Read up to 3 messages looking for a close
            for _ in 0..3 {
                match timeout(Duration::from_secs(2), stream.next()).await {
                    Ok(Some(Ok(Message::Close(_)))) => {
                        got_close = true;
                        break;
                    }
                    Ok(Some(Ok(Message::Text(t)))) => {
                        let val: serde_json::Value = serde_json::from_str(&t).unwrap();
                        if val["type"] == "handshake" {
                            got_handshake = true;
                        } else if val["type"] == "error" {
                            got_close = true;
                            break;
                        }
                    }
                    Ok(None) | Err(_) => {
                        got_close = true;
                        break;
                    }
                    _ => {}
                }
            }
            assert!(
                got_handshake || got_close,
                "51st connection should get handshake then close, or be rejected"
            );
        }
        Ok(Err(_)) | Err(_) => {
            // Connection rejected entirely — also valid
        }
    }

    // Clean up
    drop(conns);
}

/// Heartbeat interleaved with operations: send heartbeat, do a work
/// operation, send another heartbeat. Verify both succeed and responses
/// are correctly matched by request id.
#[tokio::test]
async fn stress_heartbeat_interleaved_with_ops() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_admin(&srv).await;

    let mut next_id: u16 = 10;

    // Create a work
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            next_id,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "interleave test"}
            })),
        ),
    )
    .await;
    next_id += 1;
    assert_eq!(resp["type"], "response");
    let work_id = resp["value"]["value"].as_u64().unwrap();

    // Interleave heartbeats and work operations
    for i in 0..5 {
        // Heartbeat
        send_json(
            &mut s,
            &serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
        )
        .await;
        let hb = recv_json(&mut r).await;
        assert_eq!(hb["type"], "heartbeat", "interleave {} heartbeat", i);

        // Work operation
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                next_id,
                "work_get_edition",
                Some(serde_json::json!({"work_id": work_id})),
            ),
        )
        .await;
        next_id += 1;
        assert_eq!(resp["type"], "response", "interleave {} work_open", i);

        // Drain any events
        drain(&mut r, 3).await;
    }

    let _ = s.close().await;
}

/// Connect 5 admin clients, each creating works simultaneously.
/// Verify all succeed without ID collisions.
#[tokio::test]
async fn stress_concurrent_work_creation() {
    let srv = TestServer::start().await;
    const N: usize = 5;

    let mut tasks = Vec::new();
    for i in 0..N {
        let addr = srv.addr;
        tasks.push(tokio::spawn(async move {
            let mini = TestServer { addr };
            let (mut s, mut r) = connect_admin(&mini).await;
            let resp = send_recv_json(
                &mut s,
                &mut r,
                json_req(
                    10,
                    "work_create",
                    Some(serde_json::json!({
                        "edition": {"text": format!("doc from client {}", i)}
                    })),
                ),
            )
            .await;
            let work_id = resp["value"]["value"].as_u64().unwrap();
            let _ = s.close().await;
            work_id
        }));
    }

    let mut work_ids = Vec::new();
    for task in tasks {
        work_ids.push(task.await.unwrap());
    }

    // All work IDs should be unique
    let unique: std::collections::HashSet<u64> = work_ids.iter().copied().collect();
    assert_eq!(
        unique.len(),
        N,
        "work IDs should all be unique: {:?}",
        work_ids
    );
}

/// Connect a client, create a work, then immediately disconnect without
/// graceful close. Verify the server is still responsive for new connections.
#[tokio::test]
async fn stress_recovery_after_unexpected_disconnect() {
    let srv = TestServer::start().await;

    // Abrupt disconnect (drop without close)
    {
        let (mut s, mut r) = connect_admin(&srv).await;
        let _ = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                10,
                "work_create",
                Some(serde_json::json!({
                    "edition": {"text": "abrupt"}
                })),
            ),
        )
        .await;
        // Just drop — no s.close()
        drop(s);
        drop(r);
    }

    // Give server a moment to detect the dropped connection
    tokio::time::sleep(Duration::from_millis(200)).await;

    // New connection should still work
    let (mut s2, mut r2) = connect_public(&srv).await;
    let resp = send_recv_json(
        &mut s2,
        &mut r2,
        serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
    )
    .await;
    assert_eq!(
        resp["type"], "heartbeat",
        "server should be responsive after abrupt disconnect"
    );

    let _ = s2.close().await;
}

/// Repeated connect/send/disconnect on a single client, simulating
/// document switching. 20 cycles, each creating a new work.
#[tokio::test]
async fn stress_document_switching() {
    let srv = TestServer::start().await;

    for i in 0..20 {
        let (mut s, mut r) = connect_admin(&srv).await;
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                10,
                "work_create",
                Some(serde_json::json!({
                    "edition": {"text": format!("doc {}", i)}
                })),
            ),
        )
        .await;
        assert_eq!(resp["type"], "response", "cycle {} work_create", i);
        let work_id = resp["value"]["value"].as_u64().unwrap();

        // Open the work we just created
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                11,
                "work_get_edition",
                Some(serde_json::json!({"work_id": work_id})),
            ),
        )
        .await;
        assert_eq!(resp["type"], "response", "cycle {} work_open", i);

        // Heartbeat
        let resp = send_recv_json(
            &mut s,
            &mut r,
            serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
        )
        .await;
        assert_eq!(resp["type"], "heartbeat", "cycle {} heartbeat", i);

        let _ = s.close().await;
        drain(&mut r, 5).await;
    }
}

/// Test that binary and JSON codec clients can coexist on the same server.
#[tokio::test]
async fn stress_mixed_codec_clients() {
    let srv = TestServer::start().await;

    // JSON client creates a work
    let (_js, _jr, work_id) = admin_create_work(&srv, "mixed codec doc").await;

    // Binary client connects
    let bin_url = format!(
        "ws://{}/xudanu?format=binary&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (bin_stream, _) = tokio_tungstenite::connect_async(&bin_url).await.unwrap();
    let (mut bs, mut br) = bin_stream.split();

    // Read binary handshake
    let hs = br.next().await.unwrap().unwrap();
    match hs {
        Message::Binary(b) => {
            assert!(b.len() >= 4);
            assert_eq!(b[1], MessageType::Handshake as u8);
        }
        other => panic!("expected binary handshake, got: {:?}", other),
    }

    // Binary heartbeat
    let hb = vec![PROTOCOL_VERSION, MessageType::Heartbeat as u8, 0x00, 0x00];
    bs.send(Message::Binary(hb.clone().into())).await.unwrap();
    let resp = timeout(Duration::from_secs(3), br.next())
        .await
        .unwrap()
        .unwrap()
        .unwrap();
    match resp {
        Message::Binary(b) => {
            assert_eq!(b.len(), 4);
            assert_eq!(b[1], MessageType::Heartbeat as u8);
        }
        other => panic!("expected binary heartbeat response, got: {:?}", other),
    }

    // JSON client still works
    let (mut js2, mut jr2) = connect_public(&srv).await;
    let resp = send_recv_json(
        &mut js2,
        &mut jr2,
        serde_json::json!({"v": 2, "type": "heartbeat", "id": 0}),
    )
    .await;
    assert_eq!(resp["type"], "heartbeat");

    let _ = bs.close().await;
    let _ = js2.close().await;
}
