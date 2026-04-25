use std::net::SocketAddr;
use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::Server;
use xudanu::server::transport::{
    AppState, build_router, OperationCode, MessageType, PROTOCOL_VERSION,
    EditionPayload, WireRequest,
};
use xudanu::server::transport::varint;

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
    let (stream, _) = tokio_tungstenite::connect_async(&srv.ws_url(format))
        .await
        .unwrap();
    stream.split()
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
    let mut f = serde_json::json!({"v": 1, "type": "request", "id": id, "op": op});
    if let Some(p) = payload {
        f["payload"] = p;
    }
    f
}

async fn json_setup(srv: &TestServer) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect(srv, "json").await;
    let sid = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None))
        .await["value"]["value"]
        .as_u64()
        .unwrap();
    send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
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
    let (mut s, mut r) = connect(&srv, "json").await;

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
    assert_eq!(resp["value"]["value"]["entries"].as_array().unwrap().len(), 2);
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
    let (mut s, mut r) = connect(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r, serde_json::json!({"v":1,"type":"heartbeat","id":0})).await;
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
    let (mut s, mut r) = connect(&srv, "binary").await;

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
    let (mut s, mut r) = connect(&srv, "binary").await;

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
    let (mut s, mut r) = connect(&srv, "json").await;

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
    let (mut s, mut r) = connect(&srv, "json").await;

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
    let (mut s, mut r) = connect(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        json_req(1, "work_create", Some(serde_json::json!({})))).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_unknown_operation() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        serde_json::json!({"v":1,"type":"request","id":1,"op":"nonexistent_operation","payload":{}}))
        .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_unknown_message_type() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        serde_json::json!({"v":1,"type":"bogus","id":1})).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_wrong_version() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect(&srv, "json").await;

    let resp = send_recv_json(&mut s, &mut r,
        serde_json::json!({"v":99,"type":"request","id":1,"op":"session_connect"})).await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_binary_unknown_op() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect(&srv, "binary").await;

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
    let (mut s, mut r) = connect(&srv, "binary").await;

    let resp = send_recv(&mut s, &mut r, Message::Binary(vec![PROTOCOL_VERSION].into())).await;
    let resp_bytes = match resp { Message::Binary(b) => b.to_vec(), other => panic!("{:?}", other) };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_binary_wrong_version() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect(&srv, "binary").await;

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
    let (mut s, mut r) = connect(&srv, "json").await;

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
    let (mut s, mut r) = connect(&srv, "json").await;

    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(3, "session_login_public", None)).await;
    assert_eq!(resp["type"], "response");
}
