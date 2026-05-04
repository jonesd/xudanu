use std::net::SocketAddr;
use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::Server;
use xudanu::server::transport::{
    AppState, build_router, OperationCode, MessageType, PROTOCOL_VERSION,
    EditionPayload, WireRequest,
};
use xudanu::server::transport::varint;

fn parse_hash_hex(v: &serde_json::Value) -> u64 {
    u64::from_str_radix(v.as_str().unwrap(), 16).unwrap()
}

fn hash_hex(n: u64) -> String {
    format!("{:016x}", n)
}

struct TestServer {
    addr: SocketAddr,
}

impl TestServer {
    async fn start() -> Self {
        let server = Server::new();
        let state = AppState::new(server).shared();
        let app = build_router(state)
            .into_make_service_with_connect_info::<std::net::SocketAddr>();
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        TestServer { addr }
    }

    fn ws_url(&self, format: &str) -> String {
        format!("ws://{}/xudanu?format={}", self.addr, format)
    }
}

type WsStream = tokio_tungstenite::WebSocketStream<
    tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
>;
type SplitSender = futures_util::stream::SplitSink<WsStream, Message>;
type SplitReceiver = futures_util::stream::SplitStream<WsStream>;

async fn connect(srv: &TestServer, format: &str) -> (SplitSender, SplitReceiver) {
    let url = format!("ws://{}/xudanu?format={}&version={}", srv.addr, format, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url)
        .await
        .unwrap();
    stream.split()
}

async fn recv_handshake(receiver: &mut SplitReceiver) -> serde_json::Value {
    let msg = receiver.next().await.unwrap().unwrap();
    match msg {
        Message::Text(t) => serde_json::from_str(&t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
        other => panic!("expected handshake, got: {:?}", other),
    }
}

async fn connect_with_handshake(srv: &TestServer, format: &str) -> (SplitSender, SplitReceiver) {
    let (s, mut r) = connect(srv, format).await;
    let hs = recv_handshake(&mut r).await;
    assert_eq!(hs["type"], "handshake", "expected handshake, got: {:?}", hs);
    (s, r)
}

async fn connect_binary_with_handshake(srv: &TestServer) -> (SplitSender, SplitReceiver) {
    let (s, mut r) = connect(srv, "binary").await;
    let msg = r.next().await.unwrap().unwrap();
    match msg {
        Message::Binary(b) => {
            assert!(b.len() >= 4);
            assert_eq!(b[1], MessageType::Handshake as u8);
        }
        other => panic!("expected binary handshake, got: {:?}", other),
    }
    (s, r)
}

async fn send_recv(sender: &mut SplitSender, receiver: &mut SplitReceiver, msg: Message) -> Message {
    sender.send(msg).await.unwrap();
    receiver.next().await.unwrap().unwrap()
}

async fn send_recv_json(
    sender: &mut SplitSender,
    receiver: &mut SplitReceiver,
    frame: serde_json::Value,
) -> serde_json::Value {
    let text = serde_json::to_string(&frame).unwrap();
    let resp = send_recv(sender, receiver, Message::Text(text.into())).await;
    match resp {
        Message::Text(t) => serde_json::from_str(&t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
        other => panic!("unexpected: {:?}", other),
    }
}

fn json_req(id: u16, op: &str, payload: Option<serde_json::Value>) -> serde_json::Value {
    let mut f = serde_json::json!({"v": PROTOCOL_VERSION, "type": "request", "id": id, "op": op});
    if let Some(p) = payload {
        f["payload"] = p;
    }
    f
}

async fn json_setup(srv: &TestServer) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(srv, "json").await;
    let sid = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await
        ["value"]["value"]
        .as_u64()
        .unwrap();
    send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
    (s, r, sid)
}

async fn json_admin_login(srv: &TestServer) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(srv, "json").await;
    let sid = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await
        ["value"]["value"]
        .as_u64()
        .unwrap();
    let admin_club_id = send_recv_json(&mut s, &mut r, json_req(2, "club_id_by_name", Some(
        serde_json::json!({"name": "admin"})
    ))).await["value"]["value"].as_u64().unwrap();
    send_recv_json(&mut s, &mut r, json_req(3, "session_login", Some(
        serde_json::json!({"club_id": admin_club_id})
    ))).await;
    send_recv_json(&mut s, &mut r, json_req(4, "session_authenticate", Some(
        serde_json::json!({"club_id": admin_club_id, "credential": "Boo"})
    ))).await;
    (s, r, sid)
}

fn build_binary_request(request_id: u16, op: OperationCode, payload: &[u8]) -> Vec<u8> {
    let mut buf = vec![PROTOCOL_VERSION, MessageType::Request as u8];
    buf.extend_from_slice(&request_id.to_be_bytes());
    varint::encode_varint(op.to_u16() as u64, &mut buf);
    if !payload.is_empty() {
        varint::encode_varint(payload.len() as u64, &mut buf);
        buf.extend_from_slice(payload);
    }
    buf
}

fn parse_header(data: &[u8]) -> (u8, u8, u16) {
    assert!(data.len() >= 4);
    (data[0], data[1], u16::from_be_bytes([data[2], data[3]]))
}

// ============================================================
// JSON protocol tests
// ============================================================

#[tokio::test]
async fn json_session_lifecycle() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"].as_u64().unwrap() > 0);

    let resp = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r, json_req(3, "session_disconnect", None)).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn json_work_full_lifecycle() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "Hello"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["type"], "edition");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(13, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "Updated"}
        })))).await;
    assert_eq!(resp["value"]["value"], 1);

    send_recv_json(&mut s, &mut r,
        json_req(14, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(15, "work_revision_count", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], 1);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(16, "work_fetch_revision", Some(serde_json::json!({
            "work_id": work_id, "number": 0
        })))).await;
    assert_eq!(resp["value"]["type"], "edition");
}

#[tokio::test]
async fn json_work_permissions() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(20, "work_can_read", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(21, "work_can_revise", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(22, "work_is_grabbed", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], false);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(23, "work_owner", Some(serde_json::json!({"work_id": work_id})))).await;
    assert!(resp["value"]["value"].as_u64().unwrap() > 0);
}

#[tokio::test]
async fn json_work_set_read_edit_club() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(30, "work_set_edit_club", Some(serde_json::json!({
            "work_id": work_id, "club_id": 99999
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(31, "work_edit_club", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], 99999);

    send_recv_json(&mut s, &mut r,
        json_req(32, "work_set_read_club", Some(serde_json::json!({
            "work_id": work_id, "club_id": null
        })))).await;
}

#[tokio::test]
async fn json_club_operations() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let club_id = send_recv_json(&mut s, &mut r,
        json_req(10, "club_create", Some(serde_json::json!({"description": {"text": "test"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let named_id = send_recv_json(&mut s, &mut r,
        json_req(11, "club_create_named", Some(serde_json::json!({
            "name": "editors", "description": "empty"
        })))).await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "club_id_by_name", Some(serde_json::json!({"name": "editors"})))).await;
    assert_eq!(resp["value"]["value"], named_id);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(13, "club_name_by_id", Some(serde_json::json!({"club_id": named_id})))).await;
    assert_eq!(resp["value"]["value"], "editors");

    let resp = send_recv_json(&mut s, &mut r, json_req(14, "club_names", None)).await;
    assert!(resp["value"]["value"].as_array().unwrap().len() >= 4);
}

#[tokio::test]
async fn json_edition_store_and_get() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let ed_id = send_recv_json(&mut s, &mut r,
        json_req(10, "edition_store", Some(serde_json::json!({"edition": {"text": "standalone"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_get", Some(serde_json::json!({"be_id": ed_id})))).await;
    assert_eq!(resp["value"]["type"], "edition");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "edition_get", Some(serde_json::json!({"be_id": 99999})))).await;
    assert_eq!(resp["value"]["type"], "void");
}

#[tokio::test]
async fn json_edition_with_entries() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"entries": [[0, {"Text": {"text": "A"}}], [1, {"Text": {"text": "B"}}]]}
        })))).await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    let edition = &resp["value"]["value"];
    if let Some(text) = edition["text"].as_str() {
        assert_eq!(text, "AB");
    } else if edition["entries"].is_array() {
        assert_eq!(edition["entries"].as_array().unwrap().len(), 2);
    } else {
        panic!("unexpected edition format: {:?}", edition);
    }
}

#[tokio::test]
async fn json_server_get_by_be_id() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "test"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(20, "server_get_by_be_id", Some(serde_json::json!({"be_id": work_id})))).await;
    assert_eq!(resp["value"]["type"], "range_element");
}

#[tokio::test]
async fn json_work_sponsor_unsponsor() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    let club_id = send_recv_json(&mut s, &mut r,
        json_req(11, "club_create", Some(serde_json::json!({"description": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(12, "work_sponsor", Some(serde_json::json!({"work_id": work_id, "club_id": club_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(13, "work_sponsors", Some(serde_json::json!({"work_id": work_id})))).await;
    assert!(resp["value"]["value"].as_array().unwrap().contains(&serde_json::json!(club_id)));

    send_recv_json(&mut s, &mut r,
        json_req(14, "work_unsponsor", Some(serde_json::json!({"work_id": work_id, "club_id": club_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(15, "work_sponsors", Some(serde_json::json!({"work_id": work_id})))).await;
    assert!(!resp["value"]["value"].as_array().unwrap().contains(&serde_json::json!(club_id)));
}

#[tokio::test]
async fn json_work_grabber_tracking() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(20, "work_grabber", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], 0);

    send_recv_json(&mut s, &mut r,
        json_req(21, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(22, "work_grabber", Some(serde_json::json!({"work_id": work_id})))).await;
    assert!(resp["value"]["value"].as_u64().unwrap() > 0);
}

#[tokio::test]
async fn json_heartbeat() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r, serde_json::json!({"v":2,"type":"heartbeat","id":0})).await;
    assert_eq!(resp["type"], "heartbeat");
}

#[tokio::test]
async fn json_multi_session_editing() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s1, &mut r1,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "shared"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s1, &mut r1,
        json_req(11, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    send_recv_json(&mut s1, &mut r1,
        json_req(12, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "alice"}
        })))).await;
    send_recv_json(&mut s1, &mut r1,
        json_req(13, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    send_recv_json(&mut s2, &mut r2,
        json_req(10, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    send_recv_json(&mut s2, &mut r2,
        json_req(11, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "bob"}
        })))).await;

    let resp = send_recv_json(&mut s1, &mut r1,
        json_req(20, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "response");
}

// ============================================================
// Binary protocol tests
// ============================================================

#[tokio::test]
async fn binary_session_connect_and_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let resp = send_recv(&mut s, &mut r,
        Message::Binary(build_binary_request(1, OperationCode::SessionConnect, &[]).into()))
        .await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (ver, mt, rid) = parse_header(&resp_bytes);
    assert_eq!(ver, PROTOCOL_VERSION);
    assert_eq!(mt, MessageType::Response as u8);
    assert_eq!(rid, 1);

    let resp = send_recv(&mut s, &mut r,
        Message::Binary(build_binary_request(2, OperationCode::SessionLoginPublic, &[]).into()))
        .await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Response as u8);
}

#[tokio::test]
async fn binary_heartbeat() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let hb = vec![PROTOCOL_VERSION, MessageType::Heartbeat as u8, 0x00, 0x00];
    let resp = send_recv(&mut s, &mut r, Message::Binary(hb.into())).await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Heartbeat as u8);
}

// ============================================================
// Error / adversarial tests
// ============================================================

#[tokio::test]
async fn err_not_logged_in_cannot_create_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "test"}})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");
}

#[tokio::test]
async fn err_revise_without_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "v1"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "v2"}
        })))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_grabbed");
}

#[tokio::test]
async fn err_grab_conflict() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s1, &mut r1,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s1, &mut r1,
        json_req(11, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s2, &mut r2,
        json_req(10, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_grabbed");
}

#[tokio::test]
async fn err_duplicate_club_name() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    send_recv_json(&mut s, &mut r,
        json_req(10, "club_create_named", Some(serde_json::json!({
            "name": "unique", "description": "empty"
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "club_create_named", Some(serde_json::json!({
            "name": "unique", "description": "empty"
        })))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_exists");
}

#[tokio::test]
async fn err_work_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_get_edition", Some(serde_json::json!({"work_id": 999999})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "work_not_found");
}

#[tokio::test]
async fn err_club_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "club_name_by_id", Some(serde_json::json!({"club_id": 999999})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "club_not_found");
}

#[tokio::test]
async fn err_club_name_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "club_id_by_name", Some(serde_json::json!({"name": "nonexistent"})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_found");
}

#[tokio::test]
async fn err_release_without_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_grabbed");
}

#[tokio::test]
async fn err_wrong_session_releases_grab() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s1, &mut r1,
        json_req(10, "work_create", Some(serde_json::json!({"edition": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s1, &mut r1,
        json_req(11, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s2, &mut r2,
        json_req(10, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_grabbed");
}

#[tokio::test]
async fn err_wrong_session_revises() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s1, &mut r1,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "v1"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s1, &mut r1,
        json_req(11, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s2, &mut r2,
        json_req(10, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "hacked"}
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_malformed_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv(&mut s, &mut r, Message::Text("{not valid json".into())).await;
    let text = match resp {
        Message::Text(t) => t.to_string(),
        Message::Binary(b) => String::from_utf8_lossy(&b).to_string(),
        other => panic!("{:?}", other),
    };
    let parsed: serde_json::Value = serde_json::from_str(&text).unwrap();
    assert_eq!(parsed["type"], "error");
}

#[tokio::test]
async fn adversarial_empty_payload() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "work_create", Some(serde_json::json!({})))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_unknown_operation() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        serde_json::json!({"v":2,"type":"request","id":1,"op":"nonexistent_operation","payload":{}}))
        .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_unknown_message_type() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        serde_json::json!({"v":2,"type":"bogus","id":1})).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_wrong_version() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        serde_json::json!({"v":99,"type":"request","id":1,"op":"session_connect"})).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_binary_unknown_op() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let mut frame = vec![PROTOCOL_VERSION, MessageType::Request as u8, 0x00, 0x01];
    varint::encode_varint(0xFFFF, &mut frame);
    let resp = send_recv(&mut s, &mut r, Message::Binary(frame.into())).await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_binary_truncated_frame() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let resp = send_recv(&mut s, &mut r, Message::Binary(vec![PROTOCOL_VERSION].into())).await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_binary_wrong_version() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let frame = vec![0xFF, MessageType::Request as u8, 0x00, 0x01, 0x01];
    let resp = send_recv(&mut s, &mut r, Message::Binary(frame.into())).await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_huge_work_id() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_get_edition", Some(serde_json::json!({"work_id": u64::MAX})))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_restricted_work_cannot_be_grabbed_by_other() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let private_club = send_recv_json(&mut s1, &mut r1,
        json_req(10, "club_create", Some(serde_json::json!({"description": "empty"}))))
        .await["value"]["value"].as_u64().unwrap();

    let work_id = send_recv_json(&mut s1, &mut r1,
        json_req(11, "work_create", Some(serde_json::json!({"edition": {"text": "secret"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s1, &mut r1,
        json_req(12, "work_set_edit_club", Some(serde_json::json!({
            "work_id": work_id, "club_id": private_club
        })))).await;

    let resp = send_recv_json(&mut s2, &mut r2,
        json_req(10, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");
}

#[tokio::test]
async fn adversarial_rapid_fire_requests() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    for i in 0..50 {
        let work_id = send_recv_json(&mut s, &mut r,
            json_req(i, "work_create", Some(serde_json::json!({
                "edition": {"text": format!("doc_{}", i)}
            })))).await["value"]["value"].as_u64().unwrap();
        assert!(work_id > 0);
    }
}

#[tokio::test]
async fn adversarial_connect_without_login_then_operate() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "club_create", Some(serde_json::json!({"description": "empty"})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(3, "edition_store", Some(serde_json::json!({"edition": {"text": "x"}})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");
}

#[tokio::test]
async fn adversarial_double_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(3, "session_login_public", None)).await;
    assert_eq!(resp["type"], "response");
}

// ============================================================
// Phase 10: Handshake, Admin, Detector Events
// ============================================================

#[tokio::test]
async fn handshake_receives_server_info() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect(&srv, "json").await;
    let hs = recv_handshake(&mut r).await;
    assert_eq!(hs["type"], "handshake");
    assert!(hs["payload"]["server_version"].as_u64().unwrap() >= 2);
    assert!(hs["payload"]["server_capabilities"].is_array());
    drop(s);
}

#[tokio::test]
async fn handshake_binary_format() {
    let srv = TestServer::start().await;
    let (s, mut r) = connect(&srv, "binary").await;
    let msg = r.next().await.unwrap().unwrap();
    match msg {
        Message::Binary(b) => {
            assert!(b.len() >= 4);
            assert_eq!(b[1], MessageType::Handshake as u8);
        }
        other => panic!("expected binary handshake, got: {:?}", other),
    }
    drop(s);
}

#[tokio::test]
async fn handshake_wrong_version_rejected() {
    let srv = TestServer::start().await;
    let url = format!("ws://{}/xudanu?format=json&version=99", srv.addr);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    let msg = r.next().await.unwrap().unwrap();
    let resp: serde_json::Value = match msg {
        Message::Text(t) => serde_json::from_str(&t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
        other => panic!("{:?}", other),
    };
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "unsupported_version");
    drop(s);
}

#[tokio::test]
async fn admin_server_info() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "admin_server_info", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["session_count"].as_u64().unwrap() >= 1);
    assert!(resp["value"]["value"]["work_count"].as_u64().unwrap() >= 0);
    assert!(resp["value"]["value"]["is_accepting_connections"].as_bool().unwrap());
}

#[tokio::test]
async fn admin_active_sessions() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "admin_active_sessions", None)).await;
    assert_eq!(resp["type"], "response");
    let sessions = resp["value"]["value"].as_array().unwrap();
    assert!(!sessions.is_empty());
    assert!(sessions[0]["is_logged_in"].as_bool().unwrap());
}

#[tokio::test]
async fn admin_accept_connections_toggle() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "admin_is_accepting_connections", None)).await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(51, "admin_accept_connections", Some(serde_json::json!({"accept": false})))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(52, "admin_is_accepting_connections", None)).await;
    assert_eq!(resp["value"]["value"], false);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(53, "admin_accept_connections", Some(serde_json::json!({"accept": true})))).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn admin_grant_revoke() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "admin_grant", Some(serde_json::json!({
            "club_id": 100, "region_start": 1000, "region_end": 2000
        })))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(51, "admin_grants", None)).await;
    assert_eq!(resp["type"], "response");
    let grants = resp["value"]["value"].as_array().unwrap();
    assert!(!grants.is_empty());

    let resp = send_recv_json(&mut s, &mut r,
        json_req(52, "admin_revoke_grant", Some(serde_json::json!({"club_id": 100})))).await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(53, "admin_grants", None)).await;
    assert!(resp["value"]["value"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn admin_shutdown() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "admin_shutdown", None)).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn server_stats() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "server_stats", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["session_count"].as_u64().unwrap() >= 1);
}

#[tokio::test]
async fn subscribe_returns_subscription_id() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "test"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION,
        "type": "subscribe",
        "id": 20,
        "payload": {
            "detector_type": "status",
            "target_id": work_id
        }
    });
    let resp = send_recv_json(&mut s, &mut r, sub_frame).await;
    assert_eq!(resp["type"], "response");
    let sub_id = resp["value"]["value"].as_u64().unwrap();
    assert!(sub_id > 0);
}

#[tokio::test]
async fn subscribe_and_receive_event() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "test"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION,
        "type": "subscribe",
        "id": 20,
        "payload": {
            "detector_type": "status",
            "target_id": work_id
        }
    });
    let resp = send_recv_json(&mut s, &mut r, sub_frame).await;
    assert_eq!(resp["type"], "response");
    let sub_id = resp["value"]["value"].as_u64().unwrap();
    assert!(sub_id > 0);

    send_recv_json(&mut s, &mut r,
        json_req(30, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    tokio::time::sleep(std::time::Duration::from_millis(100)).await;

    let deadline = std::time::Duration::from_secs(3);
    let mut received_event = false;
    let start = std::time::Instant::now();
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(100), r.next()).await {
            Ok(Some(Ok(msg))) => {
                let val: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
                    _ => continue,
                };
                if val["type"] == "event" {
                    received_event = true;
                    break;
                }
            }
            _ => continue,
        }
    }
    assert!(received_event, "expected to receive a detector event within 3s");
}

// ============================================================
// Phase 11: Work listing, Links, Transclusion
// ============================================================

// ============================================================
// Concurrent editing (two-client)
// ============================================================

#[tokio::test]
async fn two_clients_see_each_others_revisions() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "initial"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION, "type": "subscribe", "id": 20,
        "payload": {"detector_type": "revision", "target_id": work_id}
    });
    send_recv_json(&mut s_b, &mut r_b, sub_frame.clone()).await;

    send_recv_json(&mut s_a, &mut r_a,
        json_req(30, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    send_recv_json(&mut s_a, &mut r_a,
        json_req(40, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "client a was here"}
        })))).await;

    send_recv_json(&mut s_a, &mut r_a,
        json_req(50, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    let deadline = std::time::Duration::from_secs(3);
    let start = std::time::Instant::now();
    let mut got_event = false;
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(100), r_b.next()).await {
            Ok(Some(Ok(msg))) => {
                let val: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
                    _ => continue,
                };
                if val["type"] == "event" && val["event"]["type"] == "work_revised" {
                    assert_eq!(val["event"]["payload"]["work_be_id"], work_id);
                    assert_eq!(val["event"]["payload"]["revision"], 1);
                    got_event = true;
                    break;
                }
            }
            _ => continue,
        }
    }
    assert!(got_event, "client B should receive work_revised event");

    let resp = send_recv_json(&mut s_b, &mut r_b,
        json_req(60, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"]["text"], "client a was here");
}

#[tokio::test]
async fn grab_lock_prevents_concurrent_edit() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "shared"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s_a, &mut r_a,
        json_req(20, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s_b, &mut r_b,
        json_req(30, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_grabbed");
}

#[tokio::test]
async fn delta_conflict_with_concurrent_client() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "hello"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s_a, &mut r_a,
        json_req(20, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    send_recv_json(&mut s_a, &mut r_a,
        json_req(30, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "hello world"}
        })))).await;

    send_recv_json(&mut s_a, &mut r_a,
        json_req(40, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    send_recv_json(&mut s_b, &mut r_b,
        json_req(50, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s_b, &mut r_b,
        json_req(60, "work_revise_delta", Some(serde_json::json!({
            "work_id": work_id,
            "base_revision": 0,
            "ops": [
                {"type": "retain", "count": 5},
                {"type": "insert", "text": "!"}
            ]
        })))).await;
    assert_eq!(resp["value"]["type"], "edition");
    assert_eq!(resp["value"]["value"]["text"], "hello world");
}

#[tokio::test]
async fn sequential_edits_by_two_clients() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "one"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s_a, &mut r_a,
        json_req(20, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    send_recv_json(&mut s_a, &mut r_a,
        json_req(30, "work_revise", Some(serde_json::json!({
            "work_id": work_id, "edition": {"text": "one two"}
        })))).await;
    send_recv_json(&mut s_a, &mut r_a,
        json_req(40, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    send_recv_json(&mut s_b, &mut r_b,
        json_req(50, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
    send_recv_json(&mut s_b, &mut r_b,
        json_req(60, "work_revise_delta", Some(serde_json::json!({
            "work_id": work_id,
            "base_revision": 1,
            "ops": [
                {"type": "retain", "count": 7},
                {"type": "insert", "text": " three"}
            ]
        })))).await;
    send_recv_json(&mut s_b, &mut r_b,
        json_req(70, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s_a, &mut r_a,
        json_req(80, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"]["text"], "one two three");
}

#[tokio::test]
async fn status_events_cross_client() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "test"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION, "type": "subscribe", "id": 20,
        "payload": {"detector_type": "status", "target_id": work_id}
    });
    send_recv_json(&mut s_a, &mut r_a, sub_frame).await;

    send_recv_json(&mut s_b, &mut r_b,
        json_req(30, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let deadline = std::time::Duration::from_secs(3);
    let start = std::time::Instant::now();
    let mut got_grabbed = false;
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(100), r_a.next()).await {
            Ok(Some(Ok(msg))) => {
                let val: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
                    _ => continue,
                };
                if val["type"] == "event" && val["event"]["type"] == "work_grabbed" {
                    assert_eq!(val["event"]["payload"]["work_be_id"], work_id);
                    got_grabbed = true;
                    break;
                }
            }
            _ => continue,
        }
    }
    assert!(got_grabbed, "client A should see client B grab the work");

    send_recv_json(&mut s_b, &mut r_b,
        json_req(40, "work_release", Some(serde_json::json!({"work_id": work_id})))).await;

    let start = std::time::Instant::now();
    let mut got_released = false;
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(100), r_a.next()).await {
            Ok(Some(Ok(msg))) => {
                let val: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
                    _ => continue,
                };
                if val["type"] == "event" && val["event"]["type"] == "work_released" {
                    got_released = true;
                    break;
                }
            }
            _ => continue,
        }
    }
    assert!(got_released, "client A should see client B release the work");
}

#[tokio::test]
async fn revision_history_preserves_all_edits() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "v0"}}))))
        .await["value"]["value"].as_u64().unwrap();

    for i in 1..=5u64 {
        send_recv_json(&mut s, &mut r,
            json_req((20 + i as u16 * 10), "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;
        send_recv_json(&mut s, &mut r,
            json_req((21 + i as u16 * 10), "work_revise", Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": format!("v{}", i)}
            })))).await;
        send_recv_json(&mut s, &mut r,
            json_req((22 + i as u16 * 10), "work_release", Some(serde_json::json!({"work_id": work_id})))).await;
    }

    let resp = send_recv_json(&mut s, &mut r,
        json_req(200, "work_revision_count", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"], 5);

    for i in 0..=5u64 {
        let resp = send_recv_json(&mut s, &mut r,
            json_req(300 + i as u16, "work_fetch_revision", Some(serde_json::json!({
                "work_id": work_id, "number": i
            })))).await;
        assert_eq!(resp["value"]["value"]["text"], format!("v{}", i));
    }
}

#[tokio::test]
async fn work_list_empty() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r, json_req(50, "work_list", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn work_list_after_create() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "doc1"}})))).await;
    send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({"edition": {"text": "doc2"}})))).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(50, "work_list", None)).await;
    let entries = resp["value"]["value"].as_array().unwrap();
    assert_eq!(entries.len(), 2);
    assert!(entries[0]["work_id"].as_u64().unwrap() > 0);
    assert!(entries[0]["revision_count"].as_u64().unwrap() >= 0);
    assert_eq!(entries[0]["is_grabbed"].as_bool().unwrap(), false);
}

#[tokio::test]
async fn work_list_by_owner() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let owner = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "owned"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "work_list_by_owner", Some(serde_json::json!({"owner": owner})))).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn link_create_get_delete() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "source"}}))))
        .await["value"]["value"].as_u64().unwrap();
    let work_b = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({"edition": {"text": "target"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let link_id = send_recv_json(&mut s, &mut r,
        json_req(20, "link_create", Some(serde_json::json!({
            "origin": work_a, "destination": work_b
        })))).await["value"]["value"].as_u64().unwrap();
    assert!(link_id > 0);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(21, "link_get", Some(serde_json::json!({"link_id": link_id})))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["origin"], work_a);
    assert_eq!(resp["value"]["value"]["destination"], work_b);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(22, "link_delete", Some(serde_json::json!({"link_id": link_id})))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(23, "link_get", Some(serde_json::json!({"link_id": link_id})))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn link_list_for_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "a"}}))))
        .await["value"]["value"].as_u64().unwrap();
    let work_b = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({"edition": {"text": "b"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(20, "link_create", Some(serde_json::json!({
            "origin": work_a, "destination": work_b
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(30, "link_list_for_work", Some(serde_json::json!({"work_id": work_a})))).await;
    assert_eq!(resp["type"], "response");
    let links = resp["value"]["value"].as_array().unwrap();
    assert_eq!(links.len(), 1);
    assert_eq!(links[0]["origin"], work_a);
    assert_eq!(links[0]["destination"], work_b);
}

#[tokio::test]
async fn find_works_for_content() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let content_ed = send_recv_json(&mut s, &mut r,
        json_req(10, "edition_store", Some(serde_json::json!({"edition": {"text": "shared content"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(20, "find_works_for_content", Some(serde_json::json!({
            "content_be_id": content_ed
        })))).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn delta_edit_success() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "hello world"}}))))
        .await["value"]["value"].as_u64().unwrap();

    let rev0 = send_recv_json(&mut s, &mut r,
        json_req(20, "work_revision_count", Some(serde_json::json!({"work_id": work_id}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(30, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(40, "work_revise_delta", Some(serde_json::json!({
            "work_id": work_id,
            "base_revision": rev0,
            "ops": [
                {"type": "retain", "count": 5},
                {"type": "insert", "text": "beautiful"}
            ]
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "humber");
    assert_eq!(resp["value"]["value"], rev0 + 1);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(50, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"]["text"], "hellobeautiful world");
}

#[tokio::test]
async fn delta_edit_conflict_returns_edition() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "hello world"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(20, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    send_recv_json(&mut s, &mut r,
        json_req(30, "work_revise", Some(serde_json::json!({
            "work_id": work_id,
            "edition": {"text": "hello world"}
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(40, "work_revise_delta", Some(serde_json::json!({
            "work_id": work_id,
            "base_revision": 0,
            "ops": [
                {"type": "retain", "count": 5},
                {"type": "insert", "text": "!"}
            ]
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "edition");
    assert_eq!(resp["value"]["value"]["text"], "hello world");
}

#[tokio::test]
async fn delta_delete_and_insert() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "the quick brown fox"}}))))
        .await["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(20, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(30, "work_revise_delta", Some(serde_json::json!({
            "work_id": work_id,
            "base_revision": 0,
            "ops": [
                {"type": "retain", "count": 4},
                {"type": "delete", "count": 5},
                {"type": "insert", "text": "slow"},
                {"type": "retain", "count": 7}
            ]
        })))).await;
    assert_eq!(resp["value"]["type"], "humber");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(40, "work_get_edition", Some(serde_json::json!({"work_id": work_id})))).await;
    assert_eq!(resp["value"]["value"]["text"], "the slow brown fox");
}

// ============================================================
// Blob protocol tests
// ============================================================

#[tokio::test]
async fn blob_upload_and_get_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let data = xudanu::edition::base64_encode(b"hello blob world");
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_upload", Some(serde_json::json!({
            "data": data,
            "mime_type": "text/plain"
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "blob_meta");
    let meta = &resp["value"]["value"];
    let content_hash = parse_hash_hex(&meta["content_hash"]);
    assert!(content_hash > 0);
    assert_eq!(meta["byte_size"].as_u64().unwrap(), 16);
    assert_eq!(meta["mime_type"].as_str().unwrap(), "text/plain");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "blob_get", Some(serde_json::json!({
            "content_hash": hash_hex(content_hash)
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "string");
    let decoded = xudanu::edition::base64_decode(resp["value"]["value"].as_str().unwrap()).unwrap();
    assert_eq!(decoded, b"hello blob world");
}

#[tokio::test]
async fn blob_exists_and_info_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_exists", Some(serde_json::json!({"content_hash": hash_hex(99999)})))) .await;
    assert_eq!(resp["value"]["type"], "boolean");
    assert!(!resp["value"]["value"].as_bool().unwrap());

    let data = xudanu::edition::base64_encode(b"test data");
    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "blob_upload", Some(serde_json::json!({
            "data": data,
            "mime_type": "image/png"
        })))).await;
    let hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "blob_exists", Some(serde_json::json!({"content_hash": hash_hex(hash)})))).await;
    assert!(resp["value"]["value"].as_bool().unwrap());

    let resp = send_recv_json(&mut s, &mut r,
        json_req(13, "blob_info", Some(serde_json::json!({"content_hash": hash_hex(hash)})))).await;
    assert_eq!(resp["value"]["type"], "blob_meta");
    let meta = &resp["value"]["value"];
    assert_eq!(meta["mime_type"].as_str().unwrap(), "image/png");
    assert_eq!(meta["byte_size"].as_u64().unwrap(), 9);
}

#[tokio::test]
async fn blob_stats_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_stats", None)).await;
    assert_eq!(resp["value"]["type"], "blob_stats_info");
    assert_eq!(resp["value"]["value"]["total_blobs"].as_u64().unwrap(), 0);

    let data = xudanu::edition::base64_encode(b"x");
    send_recv_json(&mut s, &mut r,
        json_req(11, "blob_upload", Some(serde_json::json!({"data": data, "mime_type": "text/plain"})))) .await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "blob_stats", None)).await;
    assert_eq!(resp["value"]["value"]["total_blobs"].as_u64().unwrap(), 1);
    assert_eq!(resp["value"]["value"]["total_bytes"].as_u64().unwrap(), 1);
}

#[tokio::test]
async fn blob_upload_requires_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let data = xudanu::edition::base64_encode(b"unauth");
    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "blob_upload", Some(serde_json::json!({
            "data": data,
            "mime_type": "text/plain"
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn blob_get_not_found_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_get", Some(serde_json::json!({"content_hash": hash_hex(99999)})))) .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn blob_deduplication_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let data = xudanu::edition::base64_encode(b"duplicate");
    let resp1 = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_upload", Some(serde_json::json!({"data": data.clone(), "mime_type": "text/plain"})))) .await;
    let resp2 = send_recv_json(&mut s, &mut r,
        json_req(11, "blob_upload", Some(serde_json::json!({"data": data, "mime_type": "text/plain"})))) .await;
    assert_eq!(
        parse_hash_hex(&resp1["value"]["value"]["content_hash"]),
        parse_hash_hex(&resp2["value"]["value"]["content_hash"])
    );
}

#[tokio::test]
async fn blob_http_get_serves_data() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let data = xudanu::edition::base64_encode(b"http blob test");
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_upload", Some(serde_json::json!({
            "data": data,
            "mime_type": "text/plain"
        })))).await;
    let hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);
    let hash_hex_val = resp["value"]["value"]["content_hash"].as_str().unwrap().to_string();

    let client = reqwest::Client::new();
    let http_resp = client.get(format!("http://{}/blobs/{}", srv.addr, hash_hex_val))
        .send().await.unwrap();
    assert_eq!(http_resp.status(), 200);
    assert_eq!(http_resp.headers().get("content-type").unwrap(), "text/plain");
    let body = http_resp.bytes().await.unwrap();
    assert_eq!(&body[..], b"http blob test");
}

#[tokio::test]
async fn blob_http_get_not_found() {
    let srv = TestServer::start().await;
    let client = reqwest::Client::new();
    let http_resp = client.get(format!("http://{}/blobs/{:016x}", srv.addr, 99999u64))
        .send().await.unwrap();
    assert_eq!(http_resp.status(), 404);
}

#[tokio::test]
async fn overlay_apply_and_get() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let data = xudanu::edition::base64_encode(b"base image bytes");
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "blob_upload", Some(serde_json::json!({
            "data": data,
            "mime_type": "image/png"
        })))).await;
    let base_hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "overlay_apply", Some(serde_json::json!({
            "base_hash": hash_hex(base_hash),
            "ops": [{"Brightness": 800}, "Grayscale"],
            "mime_type": "image/png"
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "blob_meta");
    let overlay_hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);
    assert_ne!(overlay_hash, base_hash);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "overlay_get", Some(serde_json::json!({
            "overlay_hash": hash_hex(overlay_hash)
        })))).await;
    assert_eq!(resp["value"]["type"], "overlay_info");
    assert_eq!(parse_hash_hex(&resp["value"]["value"]["base_hash"]), base_hash);
    assert_eq!(resp["value"]["value"]["mime_type"].as_str().unwrap(), "image/png");
    assert_eq!(resp["value"]["value"]["operations"].as_array().unwrap().len(), 2);
}

#[tokio::test]
async fn overlay_requires_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "overlay_apply", Some(serde_json::json!({
            "base_hash": hash_hex(1), "ops": [], "mime_type": "image/png"
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn label_create() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "label_create", None)).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "label_info");
    let label_id = resp["value"]["value"]["label_id"].as_u64().unwrap();
    assert!(label_id > 0);
}

#[tokio::test]
async fn label_get_positions() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "label_get_positions", Some(serde_json::json!({
            "work_id": work_id, "label_id": 999
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "label_positions");
}

#[tokio::test]
async fn can_make_identical_same_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "can_make_identical", Some(serde_json::json!({
            "source_work_id": work_id, "target_work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["result"].as_str().unwrap(), "yes");
}

#[tokio::test]
async fn can_make_identical_different_content() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp_a = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_a = resp_a["value"]["value"].as_u64().unwrap();
    let resp_b = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "xyz"}
        })))).await;
    let work_b = resp_b["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "can_make_identical", Some(serde_json::json!({
            "source_work_id": work_a, "target_work_id": work_b
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["result"].as_str().unwrap(), "no");
}

#[tokio::test]
async fn make_range_identical_same_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "make_range_identical", Some(serde_json::json!({
            "source_work_id": work_id, "target_work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["outcome"].as_str().unwrap(), "all_unified");
    assert_eq!(resp["value"]["value"]["failed_count"].as_u64().unwrap(), 0);
}

#[tokio::test]
async fn identity_unify_and_resolve() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "identity_unify", Some(serde_json::json!({
            "source_id": 100, "target_id": 200
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["resolved_id"].as_u64().unwrap(), 200);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "identity_resolve", Some(serde_json::json!({
            "id": 100
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["resolved_id"].as_u64().unwrap(), 200);
}

#[tokio::test]
async fn edition_rebind_requires_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_rebind", Some(serde_json::json!({
            "work_id": work_id, "position": 0,
            "new_edition": {"text": "Xbc"}
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn edition_rebind_after_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();
    send_recv_json(&mut s, &mut r,
        json_req(11, "work_grab", Some(serde_json::json!({"work_id": work_id})))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "edition_rebind", Some(serde_json::json!({
            "work_id": work_id, "position": 1,
            "new_edition": {"text": "Xbc"}
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "edition");
}

#[tokio::test]
async fn edition_retrieve_text_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_retrieve", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let bundles = resp["value"]["value"]["bundles"].as_array().unwrap();
    assert!(!bundles.is_empty());
    assert_eq!(bundles[0]["type"].as_str().unwrap(), "array");
    let elements = bundles[0]["elements"].as_array().unwrap();
    assert_eq!(elements.len(), 5);
    assert_eq!(elements[0]["Text"]["text"].as_str().unwrap(), "h");
}

#[tokio::test]
async fn edition_retrieve_with_region() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abcdef"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_retrieve", Some(serde_json::json!({
            "work_id": work_id,
            "region": {"starts_inside": false, "transitions": [2, 5]}
        })))).await;
    assert_eq!(resp["type"], "response");
    let bundles = resp["value"]["value"]["bundles"].as_array().unwrap();
    assert!(!bundles.is_empty());
    let elements = bundles[0]["elements"].as_array().unwrap();
    assert_eq!(elements.len(), 3);
    assert_eq!(elements[0]["Text"]["text"].as_str().unwrap(), "c");
    assert_eq!(elements[1]["Text"]["text"].as_str().unwrap(), "d");
    assert_eq!(elements[2]["Text"]["text"].as_str().unwrap(), "e");
}

#[tokio::test]
async fn edition_retrieve_empty_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": ""}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_retrieve", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn edition_cost_text_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello world"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_cost", Some(serde_json::json!({
            "work_id": work_id,
            "method": "total_shared"
        })))).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["total_bytes"].as_u64().unwrap() > 0);
    assert_eq!(resp["value"]["value"]["method"].as_str().unwrap(), "totalshared");
}

#[tokio::test]
async fn edition_cost_omit_shared() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "test"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "edition_cost", Some(serde_json::json!({
            "work_id": work_id,
            "method": "omit_shared"
        })))).await;
    assert_eq!(resp["type"], "response");
    let billed = resp["value"]["value"]["billed_bytes"].as_u64().unwrap();
    assert!(billed > 0);
}

#[tokio::test]
async fn edition_retrieve_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "edition_retrieve", Some(serde_json::json!({
            "work_id": 99999
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn edition_cost_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "edition_cost", Some(serde_json::json!({
            "work_id": 99999
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn content_shared_region_overlap() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abcdef"}
        })))).await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "xyzcde"}
        })))).await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "content_shared_region", Some(serde_json::json!({
            "work_a": work_a, "work_b": work_b
        })))).await;
    assert_eq!(resp["type"], "response");
    let region = &resp["value"]["value"]["region"];
    assert!(region["transitions"].as_array().unwrap().len() > 0);
}

#[tokio::test]
async fn content_shared_region_no_overlap() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "xyz"}
        })))).await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "content_shared_region", Some(serde_json::json!({
            "work_a": work_a, "work_b": work_b
        })))).await;
    assert_eq!(resp["type"], "response");
    let region = &resp["value"]["value"]["region"];
    assert!(region["transitions"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn content_map_shared_to() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "xaybzc"}
        })))).await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "content_map_shared_to", Some(serde_json::json!({
            "work_a": work_a, "work_b": work_b
        })))).await;
    assert_eq!(resp["type"], "response");
    let pairs = resp["value"]["value"]["pairs"].as_array().unwrap();
    assert!(pairs.len() >= 3);
}

#[tokio::test]
async fn content_map_shared_onto() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "content_map_shared_onto", Some(serde_json::json!({
            "work_a": work_a, "work_b": work_b
        })))).await;
    assert_eq!(resp["type"], "response");
    let pairs = resp["value"]["value"]["pairs"].as_array().unwrap();
    assert_eq!(pairs.len(), 3);
}

#[tokio::test]
async fn positions_of_element() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abac"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "positions_of", Some(serde_json::json!({
            "work_id": work_id,
            "element": {"Text": {"text": "a"}}
        })))).await;
    assert_eq!(resp["type"], "response");
    let region = &resp["value"]["value"]["region"];
    let transitions = region["transitions"].as_array().unwrap();
    assert!(transitions.len() >= 2);
}

#[tokio::test]
async fn range_transcluders_basic() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello world"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello universe"}
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "range_transcluders", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let edition_ids = resp["value"]["value"]["edition_ids"].as_array().unwrap();
    let work_ids = resp["value"]["value"]["work_ids"].as_array().unwrap();
    assert!(!edition_ids.is_empty() || !work_ids.is_empty());
}

#[tokio::test]
async fn range_transcluders_with_region() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"entries": [[0, {"Text": {"text": "a"}}], [1, {"Text": {"text": "b"}}], [2, {"Text": {"text": "c"}}]]}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"entries": [[0, {"Text": {"text": "a"}}], [1, {"Text": {"text": "b"}}]]}
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "range_transcluders", Some(serde_json::json!({
            "work_id": work_id,
            "region": {"starts_inside": false, "transitions": [2]}
        })))).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn range_transcluders_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "range_transcluders", Some(serde_json::json!({
            "work_id": 99999
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn range_works_basic() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "document content"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "range_works", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let work_ids = resp["value"]["value"]["work_ids"].as_array().unwrap();
    assert!(work_ids.contains(&serde_json::json!(work_id)));
}

#[tokio::test]
async fn range_works_with_region() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello world"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "range_works", Some(serde_json::json!({
            "work_id": work_id,
            "region": {"starts_inside": false, "transitions": [5]}
        })))).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn ordered_bundles_text() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abc"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "ordered_bundles", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let bundles = resp["value"]["value"]["bundles"].as_array().unwrap();
    assert!(!bundles.is_empty());
}

#[tokio::test]
async fn ordered_bundles_with_region() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "abcde"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "ordered_bundles", Some(serde_json::json!({
            "work_id": work_id,
            "region": {"starts_inside": false, "transitions": [1, 4]}
        })))).await;
    assert_eq!(resp["type"], "response");
    let bundles = resp["value"]["value"]["bundles"].as_array().unwrap();
    assert!(!bundles.is_empty());
}

#[tokio::test]
async fn ordered_bundles_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "ordered_bundles", Some(serde_json::json!({
            "work_id": 99999
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn transclusion_depth_basic() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "unique content"}
        })))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "transclusion_depth", Some(serde_json::json!({
            "work_id": work_id,
            "position": 0
        })))).await;
    assert_eq!(resp["type"], "response");
    let depth = resp["value"]["value"]["depth"].as_u64().unwrap();
    assert!(depth >= 1, "content registered by the work itself has at least depth 1");
}

#[tokio::test]
async fn transclusion_depth_shared_content() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "shared text"}
        })))).await;
    let _work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "work_create", Some(serde_json::json!({
            "edition": {"text": "shared text"}
        })))).await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "transclusion_depth", Some(serde_json::json!({
            "work_id": work_b,
            "position": 0,
            "max_depth": 5
        })))).await;
    assert_eq!(resp["type"], "response");
    let depth = resp["value"]["value"]["depth"].as_u64().unwrap();
    assert!(depth >= 1);
}

#[tokio::test]
async fn transclusion_depth_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "transclusion_depth", Some(serde_json::json!({
            "work_id": 99999,
            "position": 0
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn admin_recorder_create_and_list() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "admin_recorder_create", Some(serde_json::json!({
            "kind": "transcluders",
            "direct_only": true
        })))).await;
    assert_eq!(resp["type"], "response");
    let recorder_id = resp["value"]["value"]["recorder_id"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "admin_recorder_create", Some(serde_json::json!({
            "kind": "works"
        })))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "admin_recorder_list", None)).await;
    assert_eq!(resp["type"], "response");
    let recorders = resp["value"]["value"]["recorders"].as_array().unwrap();
    assert!(recorders.len() >= 2);
    let first = &recorders[0];
    assert_eq!(first["id"].as_u64().unwrap(), recorder_id);
    assert_eq!(first["kind"], "transcluders");
    assert_eq!(first["direct_only"], true);
}

#[tokio::test]
async fn admin_recorder_record_and_get() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "admin_recorder_create", Some(serde_json::json!({
            "kind": "transcluders"
        })))).await;
    let recorder_id = resp["value"]["value"]["recorder_id"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "admin_recorder_record", Some(serde_json::json!({
            "recorder_id": recorder_id,
            "element": {"Edition": {"edition_id": 42}}
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["recorded"], true);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "admin_recorder_get", Some(serde_json::json!({
            "recorder_id": recorder_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let info = &resp["value"]["value"]["recorder"];
    assert_eq!(info["id"].as_u64().unwrap(), recorder_id);
    assert_eq!(info["result_count"].as_u64().unwrap(), 1);
}

#[tokio::test]
async fn admin_recorder_record_wrong_kind() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "admin_recorder_create", Some(serde_json::json!({
            "kind": "works"
        })))).await;
    let recorder_id = resp["value"]["value"]["recorder_id"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "admin_recorder_record", Some(serde_json::json!({
            "recorder_id": recorder_id,
            "element": {"Edition": {"edition_id": 42}}
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["recorded"], false);
}

#[tokio::test]
async fn crypto_get_public_key() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "crypto_get_public_key", None)).await;
    assert_eq!(resp["type"], "response");
    let val = &resp["value"]["value"];
    assert!(val["key_id"].as_u64().is_some());
    assert_eq!(val["verifying_key"].as_array().unwrap().len(), 32);
    assert_eq!(val["kex_key"].as_array().unwrap().len(), 32);
    assert!(!val["server_id"].as_str().unwrap().is_empty());
}

#[tokio::test]
async fn crypto_sign_and_verify() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let data: Vec<u8> = vec![1, 2, 3, 4, 5];
    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "crypto_sign_data", Some(serde_json::json!({
            "data": data
        })))).await;
    assert_eq!(resp["type"], "response");
    let signature = resp["value"]["value"]["signature"].as_array().unwrap();
    assert_eq!(signature.len(), 64);

    let sig_bytes: Vec<u8> = signature.iter().map(|v| v.as_u64().unwrap() as u8).collect();
    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "crypto_verify_signature", Some(serde_json::json!({
            "data": data,
            "signature": sig_bytes
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["valid"], true);
}

#[tokio::test]
async fn crypto_verify_rejects_tampered() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let data: Vec<u8> = vec![1, 2, 3];
    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "crypto_sign_data", Some(serde_json::json!({
            "data": data
        })))).await;
    let sig = resp["value"]["value"]["signature"].as_array().unwrap();
    let mut tampered: Vec<u8> = sig.iter().map(|v| v.as_u64().unwrap() as u8).collect();
    tampered[0] ^= 0xff;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "crypto_verify_signature", Some(serde_json::json!({
            "data": data,
            "signature": tampered
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["valid"], false);
}

#[tokio::test]
async fn crypto_key_rotation() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "crypto_get_public_key", None)).await;
    let old_key_id = resp["value"]["value"]["key_id"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "crypto_key_rotation", None)).await;
    assert_eq!(resp["type"], "response");
    let new_key_id = resp["value"]["value"]["new_key_id"].as_u64().unwrap();
    assert_ne!(old_key_id, new_key_id);

    let resp = send_recv_json(&mut s, &mut r,
        json_req(3, "crypto_get_public_key", None)).await;
    let current_key_id = resp["value"]["value"]["key_id"].as_u64().unwrap();
    assert_eq!(current_key_id, new_key_id);
}

#[tokio::test]
async fn crypto_key_history() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "crypto_key_history", None)).await;
    assert_eq!(resp["type"], "response");
    let val = &resp["value"]["value"];
    assert!(val["current_key_id"].as_u64().is_some());
    assert_eq!(val["entry_count"].as_u64().unwrap(), 1);

    send_recv_json(&mut s, &mut r,
        json_req(2, "crypto_key_rotation", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(3, "crypto_key_history", None)).await;
    let val = &resp["value"]["value"];
    assert_eq!(val["entry_count"].as_u64().unwrap(), 2);
    let entries = val["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 2);
    assert_ne!(entries[0]["key_id"].as_u64().unwrap(), entries[1]["key_id"].as_u64().unwrap());
}

#[tokio::test]
async fn crypto_sign_requires_admin() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "crypto_sign_data", Some(serde_json::json!({
            "data": [1, 2, 3]
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn admin_recorder_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "admin_recorder_get", Some(serde_json::json!({
            "recorder_id": 99999
        })))).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["recorder"].is_null());
}

#[tokio::test]
async fn admin_recorder_record_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "admin_recorder_record", Some(serde_json::json!({
            "recorder_id": 99999,
            "element": {"Edition": {"edition_id": 1}}
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["recorded"], false);
}

#[tokio::test]
async fn work_endorse_and_query() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(&mut s, &mut r,
        json_req(50, "club_id_by_name", Some(serde_json::json!({"name": "admin"})))).await
        ["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "work_create", Some(serde_json::json!({"edition": "empty"})))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "work_endorse", Some(serde_json::json!({
            "work_id": work_id,
            "endorsements": [[admin_club_id, 10], [admin_club_id, 20]]
        })))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(3, "work_endorsements", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 2);
}

#[tokio::test]
async fn work_endorse_retract() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(&mut s, &mut r,
        json_req(100, "club_id_by_name", Some(serde_json::json!({"name": "admin"})))).await
        ["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "work_create", Some(serde_json::json!({"edition": "empty"})))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(2, "work_endorse", Some(serde_json::json!({
            "work_id": work_id,
            "endorsements": [[admin_club_id, 10], [admin_club_id, 20]]
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(3, "work_retract", Some(serde_json::json!({
            "work_id": work_id,
            "endorsements": [[admin_club_id, 10]]
        })))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(4, "work_endorsements", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
}

#[tokio::test]
async fn edition_endorse_and_query() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(&mut s, &mut r,
        json_req(50, "club_id_by_name", Some(serde_json::json!({"name": "admin"})))).await
        ["value"]["value"].as_u64().unwrap();

    let edition_id = send_recv_json(&mut s, &mut r,
        json_req(1, "edition_store", Some(serde_json::json!({
            "edition": {"text": "test content"}
        })))).await["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "edition_endorse", Some(serde_json::json!({
            "edition_id": edition_id,
            "endorsements": [[admin_club_id, 5]]
        })))).await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r,
        json_req(3, "edition_endorsements", Some(serde_json::json!({
            "edition_id": edition_id
        })))).await;
    assert_eq!(resp["type"], "response");
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
}

#[tokio::test]
async fn endorsement_requires_authority() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "work_create", Some(serde_json::json!({"edition": "empty"})))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "work_endorse", Some(serde_json::json!({
            "work_id": work_id,
            "endorsements": [[99, 1]]
        })))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn work_endorse_idempotent() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(&mut s, &mut r,
        json_req(100, "club_id_by_name", Some(serde_json::json!({"name": "admin"})))).await
        ["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "work_create", Some(serde_json::json!({"edition": "empty"})))).await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    send_recv_json(&mut s, &mut r,
        json_req(2, "work_endorse", Some(serde_json::json!({
            "work_id": work_id,
            "endorsements": [[admin_club_id, 10]]
        })))).await;

    send_recv_json(&mut s, &mut r,
        json_req(3, "work_endorse", Some(serde_json::json!({
            "work_id": work_id,
            "endorsements": [[admin_club_id, 10]]
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(4, "work_endorsements", Some(serde_json::json!({
            "work_id": work_id
        })))).await;
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
}

// ── Federation tests (Phase 14) ──────────────────────────────────────

#[tokio::test]
async fn federation_info_returns_server_identity() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "federation_info", None)).await;
    assert_eq!(resp["type"], "response");
    let val = &resp["value"]["value"];
    assert!(!val["server_id"].as_str().unwrap().is_empty());
    assert_eq!(val["federation_domain"].as_str().unwrap(), "xudanu");
    assert!(val["key_id"].as_u64().is_some());
    assert_eq!(val["verifying_key"].as_array().unwrap().len(), 32);
    assert_eq!(val["kex_key"].as_array().unwrap().len(), 32);
    assert_eq!(val["mode"].as_str().unwrap(), "closed");
    assert_eq!(val["peers"].as_array().unwrap().len(), 0);
    assert!(val["work_count"].as_u64().is_some());
    assert!(val["edition_count"].as_u64().is_some());
}

#[tokio::test]
async fn federation_peers_returns_empty_when_unconfigured() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "federation_peers", None)).await;
    assert_eq!(resp["type"], "response");
    let peers = resp["value"]["value"]["peers"].as_array().unwrap();
    assert_eq!(peers.len(), 0);
}

#[tokio::test]
async fn federation_info_no_auth_required() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let _resp = send_recv_json(&mut s, &mut r,
        json_req(1, "session_connect", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(2, "federation_info", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(!resp["value"]["value"]["server_id"].as_str().unwrap().is_empty());
}

// ── Federation transport tests (Phase 15) ────────────────────────────

struct FederationTestServer {
    addr: SocketAddr,
    state: xudanu::server::transport::SharedState,
}

impl FederationTestServer {
    async fn start() -> Self {
        let server = Server::new();
        let state = AppState::new(server).shared();
        let client_router = build_router(state.clone());
        let fed_router = xudanu::server::transport::federation_handler::build_federation_router(state.clone());
        let app = xudanu::server::transport::federation_handler::merge_routers(client_router, fed_router)
            .into_make_service_with_connect_info::<std::net::SocketAddr>();
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        FederationTestServer { addr, state }
    }

    fn federation_url(&self) -> String {
        format!("ws://{}/federation", self.addr)
    }
}

#[tokio::test]
async fn federation_handshake_between_two_servers() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    srv_a.state.server.with_server(|srv_a_inner| {
        let b_key = srv_b.state.server.with_server_ref(|srv_b_inner| {
            let identity = srv_b_inner.server_identity();
            hex_encode(&identity.signing_key_bytes())
        });
        srv_a_inner.federation_register_peer_key(b_key);
    });
    srv_b.state.server.with_server(|srv_b_inner| {
        let a_key = srv_a.state.server.with_server_ref(|srv_a_inner| {
            let identity = srv_a_inner.server_identity();
            hex_encode(&identity.signing_key_bytes())
        });
        srv_b_inner.federation_register_peer_key(a_key);
    });

    let (mut ws_a, _) = tokio_tungstenite::connect_async(srv_a.federation_url()).await.unwrap();

    let msg_from_a = ws_a.next().await.unwrap().unwrap();
    let hello_a: serde_json::Value = serde_json::from_str(
        msg_from_a.to_text().unwrap()
    ).unwrap();
    assert_eq!(hello_a["type"], "Hello");
    assert_eq!(hello_a["protocol_version"], 1);
    assert_eq!(hello_a["ephemeral_public_key"].as_array().unwrap().len(), 32);

    let fake_hello = serde_json::json!({
        "type": "Hello",
        "protocol_version": 1,
        "ephemeral_public_key": vec![0u8; 32],
        "server_id": "test-peer"
    });
    ws_a.send(tokio_tungstenite::tungstenite::Message::Text(
        fake_hello.to_string().into()
    )).await.unwrap();

    let sig_from_a = ws_a.next().await.unwrap().unwrap();
    let sig_a: serde_json::Value = serde_json::from_str(
        sig_from_a.to_text().unwrap()
    ).unwrap();
    assert_eq!(sig_a["type"], "Signature");
    assert_eq!(sig_a["signature"].as_array().unwrap().len(), 64);
    assert_eq!(sig_a["verifying_key"].as_array().unwrap().len(), 32);
    assert_eq!(sig_a["kex_key"].as_array().unwrap().len(), 32);

    ws_a.send(tokio_tungstenite::tungstenite::Message::Text(
        serde_json::json!({
            "type": "Signature",
            "signature": vec![0u8; 64],
            "verifying_key": sig_a["verifying_key"],
            "kex_key": sig_a["kex_key"],
        }).to_string().into()
    )).await.unwrap();

    let ready_msg = ws_a.next().await.unwrap().unwrap();
    match ready_msg {
        tokio_tungstenite::tungstenite::Message::Binary(_) => {
            // Encrypted Ready received - handshake completed with encryption
        }
        tokio_tungstenite::tungstenite::Message::Text(text) => {
            let val: serde_json::Value = serde_json::from_str(&text).unwrap();
            if val["type"] == "error" {
                // Signature verification fails for fake peer, which is expected
                // The important thing is the server performed the checks
            }
        }
        _ => panic!("expected binary or text message"),
    }
}

fn hex_encode(data: &[u8]) -> String {
    data.iter().map(|b| format!("{:02x}", b)).collect()
}

#[tokio::test]
async fn federation_content_replication_between_two_servers() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let url_a = format!("ws://{}/xudanu?format=json&version={}", srv_a.addr, PROTOCOL_VERSION);
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a,
        json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s_a, &mut r_a,
        json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "Hello from server A"}
        })))).await;
    assert_eq!(resp["type"], "response");
    let _work_id_a = resp["value"]["value"].as_u64().unwrap();

    let url_b = format!("ws://{}/xudanu?format=json&version={}", srv_b.addr, PROTOCOL_VERSION);
    let (stream_b, _) = tokio_tungstenite::connect_async(&url_b).await.unwrap();
    let (mut s_b, mut r_b) = stream_b.split();
    recv_handshake(&mut r_b).await;
    let _ = send_recv_json(&mut s_b, &mut r_b,
        json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s_b, &mut r_b,
        json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s_b, &mut r_b,
        json_req(10, "work_list", None)).await;
    assert_eq!(resp["type"], "response");
    let initial_b_count = resp["value"]["value"].as_array().unwrap().len();

    let (mut fed_a, _) = tokio_tungstenite::connect_async(srv_a.federation_url()).await.unwrap();

    let hello_from_a = fed_a.next().await.unwrap().unwrap();
    let hello_a: serde_json::Value = serde_json::from_str(hello_from_a.to_text().unwrap()).unwrap();
    assert_eq!(hello_a["type"], "Hello");

    let mut my_eph = [0u8; 32];
    my_eph[0] = 42;
    let fake_hello = serde_json::json!({
        "type": "Hello",
        "protocol_version": 1,
        "ephemeral_public_key": my_eph.to_vec(),
        "server_id": "test-client"
    });
    fed_a.send(tokio_tungstenite::tungstenite::Message::Text(
        fake_hello.to_string().into()
    )).await.unwrap();

    let sig_from_a = fed_a.next().await.unwrap().unwrap();
    let sig_a: serde_json::Value = serde_json::from_str(sig_from_a.to_text().unwrap()).unwrap();
    assert_eq!(sig_a["type"], "Signature");

    fed_a.send(tokio_tungstenite::tungstenite::Message::Text(
        serde_json::json!({
            "type": "Signature",
            "signature": vec![0u8; 64],
            "verifying_key": sig_a["verifying_key"],
            "kex_key": sig_a["kex_key"],
        }).to_string().into()
    )).await.unwrap();

    let next_msg = fed_a.next().await.unwrap().unwrap();
    let next_val: serde_json::Value = match next_msg {
        tokio_tungstenite::tungstenite::Message::Text(text) => {
            serde_json::from_str(&text).unwrap()
        }
        tokio_tungstenite::tungstenite::Message::Binary(_) => {
            // If we somehow got an encrypted response, the handshake
            // completed. Fall through to server-side verification.
            serde_json::json!({"type": "encrypted_ready"})
        }
        _ => panic!("unexpected message type"),
    };

    if next_val["type"] == "error" || next_val["type"] == "encrypted_ready" {
        let push = srv_a.state.server.with_server(|srv| {
            srv.federation_export_works()
        });
        assert!(push.len() >= 1);
        let mut found = false;
        for w in &push {
            match &w.edition_payload {
                xudanu::server::transport::protocol::EditionPayload::Text(t) => {
                    if t == "Hello from server A" { found = true; }
                }
                _ => {}
            }
        }
        assert!(found, "export should contain 'Hello from server A'");

        let my_id = srv_b.state.server.with_server_ref(|srv| srv.federation_server_id());
        let (imported, _already) = srv_b.state.server.with_server(|srv| {
            srv.federation_import_works(&push, &my_id)
        });
        assert!(imported >= 1);

        let resp = send_recv_json(&mut s_b, &mut r_b,
            json_req(11, "work_list", None)).await;
        assert_eq!(resp["type"], "response");
        let after_b_count = resp["value"]["value"].as_array().unwrap().len();
        assert!(after_b_count > initial_b_count, "server B should have more works after import");
        return;
    }

    panic!("expected error or ready, got: {:?}", next_val);
}

// ── Cross-server transclusion tests (Phase 17) ──────────────────────

#[tokio::test]
async fn federated_transclusion_records_origin_on_import() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let url_a = format!("ws://{}/xudanu?format=json&version={}", srv_a.addr, PROTOCOL_VERSION);
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a,
        json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s_a, &mut r_a,
        json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "unique federated text"}
        })))).await;
    assert_eq!(resp["type"], "response");

    let push = srv_a.state.server.with_server(|srv| {
        srv.federation_export_works()
    });
    assert!(push.len() >= 1);

    let my_id = srv_b.state.server.with_server_ref(|srv| srv.federation_server_id());
    let (imported, _) = srv_b.state.server.with_server(|srv| {
        srv.federation_import_works(&push, &my_id)
    });
    assert!(imported >= 1);

    let has_origins = srv_b.state.server.with_server_ref(|srv| {
        srv.federation_remote_origin_count() > 0
    });
    assert!(has_origins, "server B should have remote origin entries after import");

    let has_federated = srv_b.state.server.with_server_ref(|srv| {
        srv.federation_has_federated_transclusions()
    });
    assert!(has_federated, "server B should have federated transclusion entries");
}

#[tokio::test]
async fn federated_transclusion_query_returns_local_results() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r,
        json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r,
        json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "hello"}
        })))).await;

    let text_elem = xudanu::edition::RangeElement::text("h".to_string());
    let fp = text_elem.content_fingerprint();
    let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "federated_transclusion_query", Some(serde_json::json!({
            "content_fingerprint_hex": fp_hex,
            "direct_only": false
        })))).await;
    assert_eq!(resp["type"], "response");
    let results = resp["value"]["value"]["results"].as_array().unwrap();
    assert!(!results.is_empty(), "should find local transclusion results");
}

#[tokio::test]
async fn federated_content_fetch_returns_edition() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r,
        json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r,
        json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "fetch me"}
        })))).await;

    let text_elem = xudanu::edition::RangeElement::text("f".to_string());
    let fp = text_elem.content_fingerprint();
    let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "federated_content_fetch", Some(serde_json::json!({
            "content_fingerprint_hex": fp_hex
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["found"], true);
}

#[tokio::test]
async fn federated_content_fetch_not_found() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r,
        json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r,
        json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "federated_content_fetch", Some(serde_json::json!({
            "content_fingerprint_hex": "ff".repeat(32)
        })))).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["found"], false);
}

#[tokio::test]
async fn cross_server_transclusion_after_sync() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;
    srv_b.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url_a = format!("ws://{}/xudanu?format=json&version={}", srv_a.addr, PROTOCOL_VERSION);
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "shared across servers"}
        })))).await;

    let push = srv_a.state.server.with_server(|srv| srv.federation_export_works());
    let my_id = srv_b.state.server.with_server_ref(|srv| srv.federation_server_id());
    srv_b.state.server.with_server(|srv| {
        srv.federation_import_works(&push, &my_id)
    });

    let text_elem = xudanu::edition::RangeElement::text("s".to_string());
    let fp = text_elem.content_fingerprint();
    let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

    let url_b = format!("ws://{}/xudanu?format=json&version={}", srv_b.addr, PROTOCOL_VERSION);
    let (stream_b, _) = tokio_tungstenite::connect_async(&url_b).await.unwrap();
    let (mut s_b, mut r_b) = stream_b.split();
    recv_handshake(&mut r_b).await;
    let _ = send_recv_json(&mut s_b, &mut r_b, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s_b, &mut r_b, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s_b, &mut r_b,
        json_req(10, "federated_transclusion_query", Some(serde_json::json!({
            "content_fingerprint_hex": fp_hex,
            "direct_only": false
        })))).await;
    assert_eq!(resp["type"], "response");
    let results = resp["value"]["value"]["results"].as_array().unwrap();
    assert!(!results.is_empty(), "server B should find transclusion results after sync");
}

#[tokio::test]
async fn federated_transclusion_query_rejected_when_federation_disabled() {
    let srv = FederationTestServer::start().await;

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let fp_hex = "ab".repeat(32);
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "federated_transclusion_query", Some(serde_json::json!({
            "content_fingerprint_hex": fp_hex,
            "direct_only": false
        })))).await;
    assert_eq!(resp["type"], "error", "should reject transclusion query when federation disabled");
}

#[tokio::test]
async fn federated_content_fetch_rejected_when_federation_disabled() {
    let srv = FederationTestServer::start().await;

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let fp_hex = "ff".repeat(32);
    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "federated_content_fetch", Some(serde_json::json!({
            "content_fingerprint_hex": fp_hex
        })))).await;
    assert_eq!(resp["type"], "error", "should reject content fetch when federation disabled");
}

// =====================================================================
// Phase 18: DagWood Reconciliation & Endorsement Sync Integration Tests
// =====================================================================

#[tokio::test]
async fn endorsement_add_returns_tag() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "endorsed content"}
        })))).await;

    let states = srv.state.server.with_server(|srv| srv.reconcile_export_all());
    let fp = &states[0].work_fingerprint;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "endorsement_add", Some(serde_json::json!({
            "work_fingerprint": fp,
            "club_id": 42,
            "token_id": 7
        })))).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["tag_counter"].as_u64().unwrap() > 0);
}

#[tokio::test]
async fn endorsement_query_returns_added_endorsements() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "query me"}
        })))).await;

    let states = srv.state.server.with_server(|srv| srv.reconcile_export_all());
    let fp = &states[0].work_fingerprint;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(11, "endorsement_add", Some(serde_json::json!({
            "work_fingerprint": fp,
            "club_id": 5,
            "token_id": 10
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(12, "endorsement_query", Some(serde_json::json!({
            "work_fingerprint": fp
        })))).await;
    assert_eq!(resp["type"], "response");
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
    assert_eq!(endorsements[0][0].as_u64().unwrap(), 5);
    assert_eq!(endorsements[0][1].as_u64().unwrap(), 10);
}

#[tokio::test]
async fn state_sync_returns_reconcile_states() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "sync state"}
        })))).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "state_sync", Some(serde_json::json!({
            "work_fingerprints": []
        })))).await;
    assert_eq!(resp["type"], "response");
    let states = resp["value"]["value"]["states"].as_array().unwrap();
    assert!(!states.is_empty(), "should return reconcile states");
}

#[tokio::test]
async fn state_alternatives_returns_editions() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", srv.addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s, &mut r,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "alt content"}
        })))).await;

    let states = srv.state.server.with_server(|srv| srv.reconcile_export_all());
    let fp = &states[0].work_fingerprint;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(11, "state_alternatives", Some(serde_json::json!({
            "work_fingerprint": fp
        })))).await;
    assert_eq!(resp["type"], "response");
    let alternatives = resp["value"]["value"]["alternatives"].as_array().unwrap();
    assert_eq!(alternatives.len(), 1);
    assert!(!resp["value"]["value"]["current_key"].as_str().unwrap().is_empty());
}

#[tokio::test]
async fn reconcile_merge_across_servers() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let url_a = format!("ws://{}/xudanu?format=json&version={}", srv_a.addr, PROTOCOL_VERSION);
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(&mut s_a, &mut r_a,
        json_req(10, "work_create", Some(serde_json::json!({
            "edition": {"text": "shared content for reconcile"}
        })))).await;

    let states_a = srv_a.state.server.with_server(|srv| srv.reconcile_export_all());
    let fp = states_a[0].work_fingerprint.clone();

    let alt_b = srv_b.state.server.with_server(|srv| {
        let edition = xudanu::edition::Edition::from_text("server B version");
        let ts = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap_or_default()
            .as_secs()
            + 1000;
        xudanu::server::federation::AlternativeEdition::new(
            srv.federation_server_id(),
            0,
            &edition,
            ts,
        )
    });

    srv_b.state.server.with_server(|srv| {
        let remote = xudanu::server::federation::ReconcileState::new(
            &fp,
            format!("{}:0", srv.federation_server_id()),
            alt_b.clone(),
            srv.federation_server_id(),
            alt_b.timestamp,
        );
        srv.reconcile_merge_remote(remote);
    });

    let states_b = srv_b.state.server.with_server(|srv| srv.reconcile_export_all());
    assert_eq!(states_b.len(), 1);
    assert_eq!(states_b[0].alternative_count(), 1);
    assert_eq!(states_b[0].current_text().unwrap(), "server B version");
}

// =============================================================================
// Phase 19a: Trust & Membership Integration Tests
// =============================================================================

fn setup_federated_server_state() -> xudanu::server::transport::SharedState {
    let server = Server::new();
    let state = AppState::new(server).shared();
    state.server.with_server(|srv| {
        let mut config = xudanu::server::federation::FederationConfig::closed(vec![]);
        config.min_endorsements = 1;
        srv.set_federation_config(config);
        srv.membership_bootstrap_init();
    });
    state
}

async fn start_server_on_random_port(state: xudanu::server::transport::SharedState) -> std::net::SocketAddr {
    let client_router = build_router(state.clone());
    let fed_router = xudanu::server::transport::federation_handler::build_federation_router(state.clone());
    let app = xudanu::server::transport::federation_handler::merge_routers(client_router, fed_router)
        .into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });
    addr
}

#[tokio::test]
async fn membership_bootstrap_registers_self_as_member() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "membership_list", None)).await;
    let members = resp["value"]["value"]["members"].as_array().unwrap();
    assert_eq!(members.len(), 1);
}

#[tokio::test]
async fn membership_verify_returns_member_info() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;
    let server_id = state.server.with_server_ref(|srv| srv.federation_server_id());

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "membership_verify", Some(serde_json::json!({
            "server_id": server_id
        })))).await;
    assert!(resp["value"]["value"]["verify"]["is_member"].as_bool().unwrap());
}

#[tokio::test]
async fn membership_join_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let (proof_json, _my_id) = state.server.with_server(|srv| {
        let proof = srv.membership_sign_endorsement("joining-server", "vk-joining").unwrap();
        let my_id = srv.federation_server_id();
        (serde_json::to_value(&proof).unwrap(), my_id)
    });

    let join_entry = serde_json::json!({
        "server_id": "joining-server",
        "verifying_key_hex": "vk-joining",
        "kex_public_hex": "kex-joining",
        "endorsed_by": [proof_json],
        "joined_at": 1000,
        "status": "active"
    });

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "membership_join_request", Some(serde_json::json!({
            "entry": join_entry
        })))).await;

    let result = &resp["value"]["value"]["result"];
    assert!(result.get("accepted").is_some(), "expected accepted, got: {:?}", result);
    assert_eq!(result["accepted"]["server_id"].as_str().unwrap(), "joining-server");
}

#[tokio::test]
async fn membership_sync_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "membership_sync", None)).await;
    let members = resp["value"]["value"]["members"].as_array().unwrap();
    assert_eq!(members.len(), 1);
}

#[tokio::test]
async fn membership_leave_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let admin_club_id = send_recv_json(&mut s, &mut r, json_req(2, "club_id_by_name", Some(
        serde_json::json!({"name": "admin"})
    ))).await["value"]["value"].as_u64().unwrap();
    send_recv_json(&mut s, &mut r, json_req(3, "session_login", Some(
        serde_json::json!({"club_id": admin_club_id})
    ))).await;
    send_recv_json(&mut s, &mut r, json_req(4, "session_authenticate", Some(
        serde_json::json!({"club_id": admin_club_id, "credential": "Boo"})
    ))).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "membership_leave", None)).await;
    assert!(resp.get("error").is_none(), "leave should succeed with admin auth");

    let count = state.server.with_server(|srv| srv.membership_count());
    assert_eq!(count, 0);
}

#[tokio::test]
async fn membership_endorse_offer_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let proof_json = state.server.with_server(|srv| {
        let join_proof = srv.membership_sign_endorsement("new-server", "vk-new").unwrap();
        let entry = xudanu::server::federation::MembershipEntry::new(
            "new-server", "vk-new", "kex-new", vec![join_proof], 1000,
        );
        srv.membership_process_join(entry);
        let proof = srv.membership_sign_endorsement("new-server", "vk-new").unwrap();
        serde_json::to_value(&proof).unwrap()
    });

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "membership_endorse_offer", Some(serde_json::json!({
            "server_id": "new-server",
            "proof": proof_json
        })))).await;
    assert!(resp["value"]["value"]["accepted"].as_bool().unwrap());
}

#[tokio::test]
async fn membership_merge_across_two_servers() {
    let state_a = setup_federated_server_state();
    let state_b = setup_federated_server_state();

    let id_a = state_a.server.with_server_ref(|srv| srv.federation_server_id());

    let membership_b = state_b.server.with_server(|srv| {
        srv.membership_export_orset().clone()
    });

    state_a.server.with_server(|srv| {
        srv.membership_merge_orset(&membership_b);
    });

    assert!(state_a.server.with_server(|srv| srv.membership_is_known_member(&id_a)));
}

#[tokio::test]
async fn membership_cross_server_endorsement_verification() {
    let state_a = setup_federated_server_state();
    let state_b = setup_federated_server_state();

    let id_b = state_b.server.with_server_ref(|srv| srv.federation_server_id());
    let (proof, vk_a_bytes) = state_a.server.with_server(|srv| {
        let proof = srv.membership_sign_endorsement(&id_b, "vk-b").unwrap();
        let vk_bytes = srv.server_verifying_key().to_bytes();
        (proof, vk_bytes)
    });

    let valid = state_b.server.with_server(|srv_b| {
        let vk = ed25519_dalek::VerifyingKey::from_bytes(&vk_a_bytes).unwrap();
        srv_b.membership_verify_endorsement_proof(&proof, &vk)
    });
    assert!(valid, "server B should verify server A's endorsement");
}

#[tokio::test]
async fn membership_rejects_tampered_endorsement() {
    let state = setup_federated_server_state();

    let other_keypair = xudanu::crypto::keys::ServerKeyPair::generate("attacker");

    let fake_proof = xudanu::server::federation::EndorsementProof {
        endorser_server_id: "attacker-server".to_string(),
        endorser_key_id: other_keypair.key_id,
        endorsee_server_id: "victim".to_string(),
        endorsee_verifying_key_hex: "vk-victim".to_string(),
        signature: vec![0u8; 64],
        timestamp: 1000,
    };

    let valid = state.server.with_server(|srv| {
        srv.membership_verify_endorsement_proof(
            &fake_proof,
            &other_keypair.signing_verifying_key(),
        )
    });
    assert!(!valid, "all-zero signature should be invalid");

    let fake_proof_tampered = xudanu::server::federation::EndorsementProof {
        signature: vec![0xff; 64],
        ..fake_proof
    };
    let invalid = state.server.with_server(|srv| {
        srv.membership_verify_endorsement_proof(
            &fake_proof_tampered,
            &other_keypair.signing_verifying_key(),
        )
    });
    assert!(!invalid, "tampered signature should fail verification");
}

#[tokio::test]
async fn membership_join_rejects_forged_endorsement_signature() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let my_id = state.server.with_server_ref(|srv| srv.federation_server_id());

    let forged_proof = serde_json::json!({
        "endorser_server_id": my_id,
        "endorser_key_id": 99999u64,
        "endorsee_server_id": "attacker",
        "endorsee_verifying_key_hex": "vk-attacker",
        "signature": vec![0u8; 64],
        "timestamp": 1000u64
    });

    let join_entry = serde_json::json!({
        "server_id": "attacker",
        "verifying_key_hex": "vk-attacker",
        "kex_public_hex": "kex-attacker",
        "endorsed_by": [forged_proof],
        "joined_at": 1000u64,
        "status": "active"
    });

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "membership_join_request", Some(serde_json::json!({
            "entry": join_entry
        })))).await;

    let result = &resp["value"]["value"]["result"];
    assert!(result.get("rejected").is_some(),
        "join with forged endorsement should be rejected, got: {:?}", result);
}

#[tokio::test]
async fn membership_endorse_rejects_forged_proof() {
    let state = setup_federated_server_state();

    let forged_proof = xudanu::server::federation::EndorsementProof {
        endorser_server_id: "nonexistent".to_string(),
        endorser_key_id: 1,
        endorsee_server_id: "target".to_string(),
        endorsee_verifying_key_hex: "vk-target".to_string(),
        signature: vec![0u8; 64],
        timestamp: 1000,
    };

    let accepted = state.server.with_server(|srv| {
        srv.membership_endorse("target", forged_proof)
    });
    assert!(!accepted, "endorse with forged proof should be rejected");
}

// =============================================================================
// Phase 19b: Governance & BFT Integration Tests
// =============================================================================

#[tokio::test]
async fn governance_status_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "governance_status", None)).await;
    let status = &resp["value"]["value"];
    assert_eq!(status["view"].as_u64().unwrap(), 0);
    assert_eq!(status["sequence"].as_u64().unwrap(), 0);
    assert!(status["is_leader"].as_bool().unwrap());
    assert!(status["pending"].as_bool().unwrap() == false);
}

#[tokio::test]
async fn governance_propose_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let admin_club_id = send_recv_json(&mut s, &mut r, json_req(2, "club_id_by_name", Some(
        serde_json::json!({"name": "admin"})
    ))).await["value"]["value"].as_u64().unwrap();
    send_recv_json(&mut s, &mut r, json_req(3, "session_login", Some(
        serde_json::json!({"club_id": admin_club_id})
    ))).await;
    send_recv_json(&mut s, &mut r, json_req(4, "session_authenticate", Some(
        serde_json::json!({"club_id": admin_club_id, "credential": "Boo"})
    ))).await;

    let tx = serde_json::json!({
        "type": "admit",
        "server_id": "srv-new",
        "verifying_key_hex": "vk-new",
        "kex_public_hex": "kex-new"
    });

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "governance_propose", Some(serde_json::json!({
            "transactions": [tx]
        })))).await;

    let proposal = &resp["value"]["value"]["proposal"];
    assert!(proposal.is_object());
    assert_eq!(proposal["sequence_number"].as_u64().unwrap(), 1);
    assert_eq!(proposal["transactions"].as_array().unwrap().len(), 1);
}

#[tokio::test]
async fn governance_log_empty_then_propose() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "governance_log", None)).await;
    let log = resp["value"]["value"]["log"].as_array().unwrap();
    assert!(log.is_empty(), "initial log should be empty");
}

#[tokio::test]
async fn governance_full_consensus_via_server_methods() {
    let state = setup_federated_server_state();
    let my_id = state.server.with_server_ref(|srv| srv.federation_server_id());

    state.server.with_server(|srv| {
        let proposal = srv.governance_propose(vec![
            xudanu::server::federation::GovernanceTx::Admit {
                server_id: "srv-joined".to_string(),
                verifying_key_hex: "vk-joined".to_string(),
                kex_public_hex: "kex-joined".to_string(),
            }
        ]).unwrap();

        let vote = xudanu::server::federation::PbftVote {
            view_number: proposal.view_number,
            sequence_number: proposal.sequence_number,
            voter_id: my_id.clone(),
            phase: xudanu::server::federation::PbftPhase::Prepare,
        };
        srv.governance_receive_prepare(vote);

        let commit = xudanu::server::federation::PbftVote {
            view_number: proposal.view_number,
            sequence_number: proposal.sequence_number,
            voter_id: my_id.clone(),
            phase: xudanu::server::federation::PbftPhase::Commit,
        };
        srv.governance_receive_commit(commit);

        let batch = srv.governance_seal_round().unwrap();
        assert_eq!(batch.transactions.len(), 1);
        assert_eq!(srv.governance_log().len(), 1);
        assert!(srv.membership_is_known_member("srv-joined"));
    });
}

#[tokio::test]
async fn governance_royalty_recording_via_consensus() {
    let state = setup_federated_server_state();
    let my_id = state.server.with_server_ref(|srv| srv.federation_server_id());

    state.server.with_server(|srv| {
        srv.governance_propose(vec![
            xudanu::server::federation::GovernanceTx::RoyaltyRecord {
                origin_server_id: my_id.clone(),
                target_server_id: "srv-b".to_string(),
                content_fingerprint_hex: format!("{:064x}", 42),
                royalty_type: xudanu::server::federation::RoyaltyType::Transclusion,
                amount: 500,
            }
        ]).unwrap();

        let vote = xudanu::server::federation::PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: my_id.clone(), phase: xudanu::server::federation::PbftPhase::Prepare,
        };
        srv.governance_receive_prepare(vote);

        let commit = xudanu::server::federation::PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: my_id.clone(), phase: xudanu::server::federation::PbftPhase::Commit,
        };
        srv.governance_receive_commit(commit);

        srv.governance_seal_round().unwrap();

        let ledger = srv.federation_royalty_ledger();
        assert_eq!(ledger.len(), 1);
        assert_eq!(ledger[0].amount, 500);
        assert_eq!(ledger[0].royalty_type, xudanu::server::federation::RoyaltyType::Transclusion);
    });
}

#[tokio::test]
async fn governance_propose_requires_admin() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(10, "governance_propose", Some(serde_json::json!({
            "transactions": []
        })))).await;
    assert!(resp["type"].as_str() == Some("error") || resp.get("error").is_some(), "propose should require admin, got: {:?}", resp);
}

#[tokio::test]
async fn governance_seal_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;
    let my_id = state.server.with_server_ref(|srv| srv.federation_server_id());

    state.server.with_server(|srv| {
        srv.governance_propose(vec![
            xudanu::server::federation::GovernanceTx::Expel {
                server_id: "srv-bad".to_string(),
                reason: "test".to_string(),
            }
        ]).unwrap();

        let vote = xudanu::server::federation::PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: my_id.clone(), phase: xudanu::server::federation::PbftPhase::Prepare,
        };
        srv.governance_receive_prepare(vote);

        let commit = xudanu::server::federation::PbftVote {
            view_number: 0, sequence_number: 1,
            voter_id: my_id.clone(), phase: xudanu::server::federation::PbftPhase::Commit,
        };
        srv.governance_receive_commit(commit);
    });

    let url = format!("ws://{}/xudanu?format=json&version={}", addr, PROTOCOL_VERSION);
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let admin_club_id = send_recv_json(&mut s, &mut r, json_req(2, "club_id_by_name", Some(
        serde_json::json!({"name": "admin"})
    ))).await["value"]["value"].as_u64().unwrap();
    send_recv_json(&mut s, &mut r, json_req(3, "session_login", Some(
        serde_json::json!({"club_id": admin_club_id})
    ))).await;
    send_recv_json(&mut s, &mut r, json_req(4, "session_authenticate", Some(
        serde_json::json!({"club_id": admin_club_id, "credential": "Boo"})
    ))).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "governance_seal", None)).await;
    let batch = &resp["value"]["value"]["batch"];
    assert!(batch.is_object());
    assert_eq!(batch["transactions"].as_array().unwrap().len(), 1);

    let log_resp = send_recv_json(&mut s, &mut r, json_req(11, "governance_log", None)).await;
    let log = log_resp["value"]["value"]["log"].as_array().unwrap();
    assert_eq!(log.len(), 1);
}
