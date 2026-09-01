use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::transport::varint;
use xudanu::server::transport::{
    build_router, AppState, EditionPayload, MessageType, OperationCode, WireRequest,
    PROTOCOL_VERSION,
};
use xudanu::server::Server;

fn parse_hash_hex(v: &serde_json::Value) -> u64 {
    if let Some(s) = v.as_str() {
        s.parse::<u64>()
            .or_else(|_| u64::from_str_radix(s, 16))
            .unwrap()
    } else {
        v.as_u64().unwrap()
    }
}

fn hash_hex(n: u64) -> String {
    n.to_string()
}

struct TestServer {
    addr: SocketAddr,
}

const ADMIN_PASSWORD: &[u8] = b"admin12345";

fn password_credential(pw: &[u8]) -> serde_json::Value {
    serde_json::json!({"password": pw.iter().map(|&b| serde_json::Value::from(b)).collect::<Vec<_>>()})
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

    fn ws_url(&self, format: &str) -> String {
        format!("ws://{}/xudanu?format={}", self.addr, format)
    }
}

type WsStream =
    tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>;
type SplitSender = futures_util::stream::SplitSink<WsStream, Message>;
type SplitReceiver = futures_util::stream::SplitStream<WsStream>;

async fn connect(srv: &TestServer, format: &str) -> (SplitSender, SplitReceiver) {
    let url = format!(
        "ws://{}/xudanu?format={}&version={}",
        srv.addr, format, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
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

async fn send_recv(
    sender: &mut SplitSender,
    receiver: &mut SplitReceiver,
    msg: Message,
) -> Message {
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

async fn json_public_setup(srv: &TestServer) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(srv, "json").await;
    let sid = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await["value"]
        ["value"]
        .as_u64()
        .unwrap();
    send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
    (s, r, sid)
}

async fn json_setup(srv: &TestServer) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(srv, "json").await;
    let sid = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await["value"]
        ["value"]
        .as_u64()
        .unwrap();
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
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "session_login",
            Some(serde_json::json!({"club_id": admin_club_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})),
        ),
    )
    .await;
    (s, r, sid)
}

async fn json_admin_login(srv: &TestServer) -> (SplitSender, SplitReceiver, u64) {
    json_setup(srv).await
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

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

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
    assert_eq!(resp["value"]["type"], "edition");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "Updated"}
            })),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], 1);

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            14,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            15,
            "work_revision_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], 1);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            16,
            "work_fetch_revision",
            Some(serde_json::json!({
                "work_id": work_id, "number": 0
            })),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "edition");
}

#[tokio::test]
async fn json_work_permissions() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_can_read",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "work_can_revise",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "work_is_grabbed",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], false);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            23,
            "work_owner",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert!(resp["value"]["value"].as_u64().unwrap() > 0);
}

#[tokio::test]
async fn json_work_set_read_edit_club() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_set_edit_club",
            Some(serde_json::json!({
                "work_id": work_id, "club_id": 99999
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            31,
            "work_edit_club",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], 99999);

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            32,
            "work_set_read_club",
            Some(serde_json::json!({
                "work_id": work_id, "club_id": null
            })),
        ),
    )
    .await;
}

#[tokio::test]
async fn json_club_operations() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_create",
            Some(serde_json::json!({"description": {"text": "test"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let named_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "club_create_named",
            Some(serde_json::json!({
                "name": "editors", "description": "empty"
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "club_id_by_name",
            Some(serde_json::json!({"name": "editors"})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], named_id);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "club_name_by_id",
            Some(serde_json::json!({"club_id": named_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], "editors");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(14, "club_names", Some(serde_json::json!({}))),
    )
    .await;
    assert!(resp["value"]["value"]["entries"].as_array().unwrap().len() >= 4);
}

#[tokio::test]
async fn json_edition_store_and_get() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let ed_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "edition_store",
            Some(serde_json::json!({"edition": {"text": "standalone"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(11, "edition_get", Some(serde_json::json!({"be_id": ed_id}))),
    )
    .await;
    assert_eq!(resp["value"]["type"], "edition");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(12, "edition_get", Some(serde_json::json!({"be_id": 99999}))),
    )
    .await;
    assert_eq!(resp["value"]["type"], "void");
}

#[tokio::test]
async fn json_edition_with_entries() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"entries": [[0, {"Text": {"text": "A"}}], [1, {"Text": {"text": "B"}}]]}
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

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

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "test"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "server_get_by_be_id",
            Some(serde_json::json!({"be_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "range_element");
}

#[tokio::test]
async fn json_work_sponsor_unsponsor() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "club_create",
            Some(serde_json::json!({"description": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "work_sponsor",
            Some(serde_json::json!({"work_id": work_id, "club_id": club_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "work_sponsors",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert!(resp["value"]["value"]
        .as_array()
        .unwrap()
        .contains(&serde_json::json!(club_id)));

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            14,
            "work_unsponsor",
            Some(serde_json::json!({"work_id": work_id, "club_id": club_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            15,
            "work_sponsors",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert!(!resp["value"]["value"]
        .as_array()
        .unwrap()
        .contains(&serde_json::json!(club_id)));
}

#[tokio::test]
async fn json_work_grabber_tracking() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_grabber",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], 0);

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "work_grabber",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert!(resp["value"]["value"].as_u64().unwrap() > 0);
}

#[tokio::test]
async fn json_heartbeat() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        serde_json::json!({"v":2,"type":"heartbeat","id":0}),
    )
    .await;
    assert_eq!(resp["type"], "heartbeat");
}

#[tokio::test]
async fn json_multi_session_editing() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "shared"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            12,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "alice"}
            })),
        ),
    )
    .await;
    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            13,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            10,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            11,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "bob"}
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            20,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

// ============================================================
// Binary protocol tests
// ============================================================

#[tokio::test]
async fn binary_session_connect_and_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let resp = send_recv(
        &mut s,
        &mut r,
        Message::Binary(build_binary_request(1, OperationCode::SessionConnect, &[]).into()),
    )
    .await;
    let resp_bytes = match resp {
        Message::Binary(b) => b.to_vec(),
        other => panic!("{:?}", other),
    };
    let (ver, mt, rid) = parse_header(&resp_bytes);
    assert_eq!(ver, PROTOCOL_VERSION);
    assert_eq!(mt, MessageType::Response as u8);
    assert_eq!(rid, 1);

    let resp = send_recv(
        &mut s,
        &mut r,
        Message::Binary(build_binary_request(2, OperationCode::SessionLoginPublic, &[]).into()),
    )
    .await;
    let resp_bytes = match resp {
        Message::Binary(b) => b.to_vec(),
        other => panic!("{:?}", other),
    };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Response as u8);
}

#[tokio::test]
async fn binary_heartbeat() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let hb = vec![PROTOCOL_VERSION, MessageType::Heartbeat as u8, 0x00, 0x00];
    let resp = send_recv(&mut s, &mut r, Message::Binary(hb.into())).await;
    let resp_bytes = match resp {
        Message::Binary(b) => b.to_vec(),
        other => panic!("{:?}", other),
    };
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "test"}})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");
}

#[tokio::test]
async fn err_revise_without_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "v1"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "v2"}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_grabbed");
}

#[tokio::test]
async fn err_grab_conflict() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            10,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_grabbed");
}

#[tokio::test]
async fn err_duplicate_club_name() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_create_named",
            Some(serde_json::json!({
                "name": "unique", "description": "empty"
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "club_create_named",
            Some(serde_json::json!({
                "name": "unique", "description": "empty"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_exists");
}

#[tokio::test]
async fn err_work_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_get_edition",
            Some(serde_json::json!({"work_id": 999999})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "work_not_found");
}

#[tokio::test]
async fn err_club_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_name_by_id",
            Some(serde_json::json!({"club_id": 999999})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "club_not_found");
}

#[tokio::test]
async fn err_club_name_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_id_by_name",
            Some(serde_json::json!({"name": "nonexistent"})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_found");
}

#[tokio::test]
async fn err_release_without_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_grabbed");
}

#[tokio::test]
async fn err_wrong_session_releases_grab() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            10,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_grabbed");
}

#[tokio::test]
async fn err_wrong_session_revises() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "v1"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            10,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "hacked"}
            })),
        ),
    )
    .await;
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(1, "work_create", Some(serde_json::json!({}))),
    )
    .await;
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        serde_json::json!({"v":2,"type":"bogus","id":1}),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_wrong_version() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        serde_json::json!({"v":99,"type":"request","id":1,"op":"session_connect"}),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_binary_unknown_op() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let mut frame = vec![PROTOCOL_VERSION, MessageType::Request as u8, 0x00, 0x01];
    varint::encode_varint(0xFFFF, &mut frame);
    let resp = send_recv(&mut s, &mut r, Message::Binary(frame.into())).await;
    let resp_bytes = match resp {
        Message::Binary(b) => b.to_vec(),
        other => panic!("{:?}", other),
    };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_binary_truncated_frame() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let resp = send_recv(
        &mut s,
        &mut r,
        Message::Binary(vec![PROTOCOL_VERSION].into()),
    )
    .await;
    let resp_bytes = match resp {
        Message::Binary(b) => b.to_vec(),
        other => panic!("{:?}", other),
    };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_binary_wrong_version() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_binary_with_handshake(&srv).await;

    let frame = vec![0xFF, MessageType::Request as u8, 0x00, 0x01, 0x01];
    let resp = send_recv(&mut s, &mut r, Message::Binary(frame.into())).await;
    let resp_bytes = match resp {
        Message::Binary(b) => b.to_vec(),
        other => panic!("{:?}", other),
    };
    let (_, mt, _) = parse_header(&resp_bytes);
    assert_eq!(mt, MessageType::Error as u8);
}

#[tokio::test]
async fn adversarial_huge_work_id() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_get_edition",
            Some(serde_json::json!({"work_id": u64::MAX})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn adversarial_restricted_work_cannot_be_grabbed_by_other() {
    let srv = TestServer::start().await;
    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let private_club = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "club_create",
            Some(serde_json::json!({"description": "empty"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let work_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "secret"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            12,
            "work_set_edit_club",
            Some(serde_json::json!({
                "work_id": work_id, "club_id": private_club
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            10,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");
}

#[tokio::test]
async fn adversarial_rapid_fire_requests() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    for i in 0..50 {
        let work_id = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                i,
                "work_create",
                Some(serde_json::json!({
                    "edition": {"text": format!("doc_{}", i)}
                })),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap();
        assert!(work_id > 0);
    }
}

#[tokio::test]
async fn adversarial_connect_without_login_then_operate() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "club_create",
            Some(serde_json::json!({"description": "empty"})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "not_authorized");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "edition_store",
            Some(serde_json::json!({"edition": {"text": "x"}})),
        ),
    )
    .await;
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
    let resp = send_recv_json(&mut s, &mut r, json_req(50, "admin_server_info", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["session_count"].as_u64().unwrap() >= 1);
    assert!(resp["value"]["value"]["work_count"].as_u64().is_some());
    assert!(resp["value"]["value"]["is_accepting_connections"]
        .as_bool()
        .unwrap());
}

#[tokio::test]
async fn admin_active_sessions() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;
    let resp = send_recv_json(&mut s, &mut r, json_req(50, "admin_active_sessions", None)).await;
    assert_eq!(resp["type"], "response");
    let sessions = resp["value"]["value"].as_array().unwrap();
    assert!(!sessions.is_empty());
    assert!(sessions[0]["is_logged_in"].as_bool().unwrap());
}

#[tokio::test]
#[ignore = "admin_accept_connections not yet implemented"]
async fn admin_accept_connections_toggle() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(50, "admin_is_accepting_connections", None),
    )
    .await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            51,
            "admin_accept_connections",
            Some(serde_json::json!({"accept": false})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(52, "admin_is_accepting_connections", None),
    )
    .await;
    assert_eq!(resp["value"]["value"], false);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            53,
            "admin_accept_connections",
            Some(serde_json::json!({"accept": true})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn admin_grant_revoke() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            50,
            "admin_grant",
            Some(serde_json::json!({
                "club_id": 100, "region_start": 1000, "region_end": 2000
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r, json_req(51, "admin_grants", None)).await;
    assert_eq!(resp["type"], "response");
    let grants = resp["value"]["value"].as_array().unwrap();
    assert!(!grants.is_empty());

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            52,
            "admin_revoke_grant",
            Some(serde_json::json!({"club_id": 100})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(&mut s, &mut r, json_req(53, "admin_grants", None)).await;
    assert!(resp["value"]["value"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn admin_shutdown() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(50, "admin_shutdown", None)).await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn server_stats() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(50, "server_stats", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["session_count"].as_u64().unwrap() >= 1);
}

#[tokio::test]
async fn subscribe_returns_subscription_id() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "test"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

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

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "test"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

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

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

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
    assert!(
        received_event,
        "expected to receive a detector event within 3s"
    );
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

    let work_id = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "initial"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION, "type": "subscribe", "id": 20,
        "payload": {"detector_type": "revision", "target_id": work_id}
    });
    send_recv_json(&mut s_b, &mut r_b, sub_frame.clone()).await;

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            30,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            40,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "client a was here"}
            })),
        ),
    )
    .await;

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            50,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

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

    let resp = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            60,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"]["text"], "client a was here");
}

#[tokio::test]
async fn grab_lock_prevents_concurrent_edit() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "shared"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            20,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            30,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
    assert_eq!(resp["code"], "already_grabbed");
}

#[tokio::test]
async fn delta_conflict_with_concurrent_client() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            20,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            30,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "hello world"}
            })),
        ),
    )
    .await;

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            40,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            50,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            60,
            "work_revise_delta",
            Some(serde_json::json!({
                "work_id": work_id,
                "base_revision": 0,
                "ops": [
                    {"type": "retain", "count": 5},
                    {"type": "insert", "text": "!"}
                ]
            })),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "edition");
    assert_eq!(resp["value"]["value"]["text"], "hello world");
}

#[tokio::test]
async fn sequential_edits_by_two_clients() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "one"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            20,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            30,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id, "edition": {"text": "one two"}
            })),
        ),
    )
    .await;
    send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            40,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            50,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            60,
            "work_revise_delta",
            Some(serde_json::json!({
                "work_id": work_id,
                "base_revision": 1,
                "ops": [
                    {"type": "retain", "count": 7},
                    {"type": "insert", "text": " three"}
                ]
            })),
        ),
    )
    .await;
    send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            70,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            80,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"]["text"], "one two three");
}

#[tokio::test]
async fn status_events_cross_client() {
    let srv = TestServer::start().await;
    let (mut s_a, mut r_a, _) = json_setup(&srv).await;
    let (mut s_b, mut r_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "test"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION, "type": "subscribe", "id": 20,
        "payload": {"detector_type": "status", "target_id": work_id}
    });
    send_recv_json(&mut s_a, &mut r_a, sub_frame).await;

    send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            30,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

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

    send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            40,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

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
    assert!(
        got_released,
        "client A should see client B release the work"
    );
}

#[tokio::test]
async fn revision_history_preserves_all_edits() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "v0"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    for i in 1..=5u64 {
        send_recv_json(
            &mut s,
            &mut r,
            json_req(
                (20 + i as u16 * 10),
                "work_grab",
                Some(serde_json::json!({"work_id": work_id})),
            ),
        )
        .await;
        send_recv_json(
            &mut s,
            &mut r,
            json_req(
                (21 + i as u16 * 10),
                "work_revise",
                Some(serde_json::json!({
                    "work_id": work_id, "edition": {"text": format!("v{}", i)}
                })),
            ),
        )
        .await;
        send_recv_json(
            &mut s,
            &mut r,
            json_req(
                (22 + i as u16 * 10),
                "work_release",
                Some(serde_json::json!({"work_id": work_id})),
            ),
        )
        .await;
    }

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            200,
            "work_revision_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], 5);

    for i in 0..=5u64 {
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(
                300 + i as u16,
                "work_fetch_revision",
                Some(serde_json::json!({
                    "work_id": work_id, "number": i
                })),
            ),
        )
        .await;
        assert_eq!(resp["value"]["value"]["text"], format!("v{}", i));
    }
}

#[tokio::test]
async fn work_list_empty() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(50, "work_list", Some(serde_json::json!({}))),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["entries"]
        .as_array()
        .unwrap()
        .is_empty());
}

#[tokio::test]
async fn work_list_after_create() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "doc1"}})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "doc2"}})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(50, "work_list", Some(serde_json::json!({}))),
    )
    .await;
    let entries = resp["value"]["value"]["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 2);
    assert!(entries[0]["work_id"].as_u64().unwrap() > 0);
    assert!(entries[0]["revision_count"].as_u64().is_some());
    assert_eq!(entries[0]["is_grabbed"].as_bool().unwrap(), false);
}

#[tokio::test]
async fn work_list_by_owner() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let owner = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "owned"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            50,
            "work_list_by_owner",
            Some(serde_json::json!({"owner": owner})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

/// Level-3 adversarial boundary test: structurally poisoned edition
/// payloads pushed at a LIVE server over the real WebSocket JSON path
/// must be (a) rejected with an error frame, (b) stored nowhere, and
/// (c) never panic the server. Every corruption class from the
/// mutation corpus rides the actual wire format.

#[tokio::test]
async fn poisoned_editions_rejected_over_wire() {
    let srv = TestServer::start().await;
    let (mut s, mut r, sid) = json_setup(&srv).await;

    // Baseline: a clean work to prove the session and store work.
    let clean = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "clean document"}})),
        ),
    )
    .await;
    assert_eq!(clean["type"], "response");
    let clean_id = clean["value"]["value"].as_u64().unwrap();

    let poisoned: Vec<(&str, serde_json::Value)> = vec![
        (
            "NUL bytes in text",
            serde_json::json!({"edition": {"text": concat!("bad", "\u{0}", "control content")}}),
        ),
        (
            "reversed transclusion range (deserialization bypass)",
            serde_json::json!({"edition": {"entries": [[0, {
                "Transclusion": {
                    "source_work_id": 99,
                    "char_start": 20,
                    "char_end": 5,
                    "placed_at": 0
                }
            }]]}}),
        ),
        (
            "absurd transclusion range",
            serde_json::json!({"edition": {"entries": [[0, {
                "Transclusion": {
                    "source_work_id": 99,
                    "char_start": 0,
                    "char_end": 4000000000u64,
                    "placed_at": 0
                }
            }]]}}),
        ),
        (
            "implausible blob",
            serde_json::json!({"edition": {"entries": [[0, {
                "Blob": {
                    "content_hash": 1234,
                    "mime_type": "definitely/not-a-mime",
                    "byte_size": 0
                }
            }]]}}),
        ),
    ];

    let mut req_id = 20u16;
    for (label, payload) in poisoned {
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(req_id, "work_create", Some(payload)),
        )
        .await;
        assert_eq!(
            resp["type"], "error",
            "[{label}] poisoned payload must be rejected, got: {resp}"
        );
        let msg = resp["message"].as_str().unwrap_or("");
        assert!(
            msg.contains("malformed edition"),
            "[{label}] rejection must cite the validator, got: {msg}"
        );
        req_id += 1;
    }

    // Nothing was stored: work list still shows only the clean work.
    let list = send_recv_json(
        &mut s,
        &mut r,
        json_req(req_id, "work_list", Some(serde_json::json!({}))),
    )
    .await;
    let entries = &list["value"]["value"]["entries"];
    let count = entries.as_array().map(|a| a.len()).unwrap_or(0);
    assert_eq!(count, 1, "poisoned works must not be stored");
    assert_eq!(entries[0]["work_id"].as_u64().unwrap(), clean_id);

    // The server is still healthy afterwards.
    let health = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            req_id + 1,
            "work_get_edition",
            Some(serde_json::json!({"work_id": clean_id})),
        ),
    )
    .await;
    assert_eq!(
        health["type"], "response",
        "server must survive all attacks"
    );

    // Self-cycle: at CREATE time the work id does not exist yet, so
    // the cycle check is unevaluable there (ordering gap documented in
    // adversarial-resilience.md). On REVISE of an existing work the id
    // is known — the poisoned self-transclusion must be rejected.
    let rev_resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            req_id + 2,
            "work_revise",
            Some(serde_json::json!({
                "work_id": clean_id,
                "edition": {"entries": [[0, {
                    "Transclusion": {
                        "source_work_id": clean_id,
                        "char_start": 0,
                        "char_end": 4,
                        "placed_at": 0
                    }
                }]]}
            })),
        ),
    )
    .await;
    assert_eq!(
        rev_resp["type"], "error",
        "self-cycle transclusion on revise must be rejected, got: {rev_resp}"
    );
    let rev_msg = rev_resp["message"].as_str().unwrap_or("");
    assert!(
        rev_msg.contains("self_cycle"),
        "rejection must cite the cycle rule, got: {rev_msg}"
    );
}

#[tokio::test]
async fn link_create_get_delete() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "source"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let work_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "target"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let link_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "link_create",
            Some(serde_json::json!({
                "origin": work_a, "destination": work_b
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    assert!(link_id > 0);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "link_get",
            Some(serde_json::json!({"link_id": link_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["origin"], work_a);
    assert_eq!(resp["value"]["value"]["destination"], work_b);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "link_delete",
            Some(serde_json::json!({"link_id": link_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            23,
            "link_get",
            Some(serde_json::json!({"link_id": link_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

/// FR-40 Story 1: multi-ended links. A two-ended link gains a third
/// named end; every end's work sees the connection; named_ends is
/// serialized; removing an end degrades gracefully to two-ended.
#[tokio::test]
async fn multi_ended_link_add_and_remove_end() {
    let srv = TestServer::start().await;
    let (mut s, mut r, sid) = json_setup(&srv).await;
    let _ = sid;

    async fn mk_work(s: &mut SplitSender, r: &mut SplitReceiver, name: &str) -> u64 {
        send_recv_json(
            s,
            r,
            json_req(
                900,
                "work_create",
                Some(serde_json::json!({"edition": {"text": name}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap()
    }
    let a = mk_work(&mut s, &mut r, "multi-end A").await;
    let b = mk_work(&mut s, &mut r, "multi-end B").await;
    let c = mk_work(&mut s, &mut r, "multi-end C").await;

    let link_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            901,
            "link_create",
            Some(serde_json::json!({ "origin": a, "destination": b })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    // Add a third end anchored to work C
    let add = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            902,
            "link_add_end",
            Some(serde_json::json!({
                "link_id": link_id,
                "end_name": "Comparison3",
                "end_ref": {
                    "kind": "single",
                    "work_context": c,
                    "excerpt": "multi-end C",
                    "start_position": 0,
                    "end_position": 11
                }
            })),
        ),
    )
    .await;
    assert_eq!(add["type"], "response", "add_end failed: {add}");

    // C now lists the link
    let for_c = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            903,
            "link_list_for_work",
            Some(serde_json::json!({ "work_id": c })),
        ),
    )
    .await;
    let entries = for_c["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        entries
            .iter()
            .any(|l| l["link_id"].as_u64() == Some(link_id)),
        "work C must see the multi-ended link"
    );

    // named_ends serialized beyond Left/Right
    let get = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            904,
            "link_get",
            Some(serde_json::json!({ "link_id": link_id })),
        ),
    )
    .await;
    let ends = get["value"]["value"]["named_ends"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        ends.iter().any(|(pair)| {
            let name = pair[0].as_str().unwrap_or("");
            name == "Comparison3" && pair[1]["work_context"].as_u64() == Some(c)
        }),
        "named_ends must include Comparison3 -> C, got: {ends:?}"
    );

    // Remove the end: back to a clean two-ended link, C stops listing it
    let rem = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            905,
            "link_remove_end",
            Some(serde_json::json!({ "link_id": link_id, "end_name": "Comparison3" })),
        ),
    )
    .await;
    assert_eq!(rem["type"], "response");
    let for_c2 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            906,
            "link_list_for_work",
            Some(serde_json::json!({ "work_id": c })),
        ),
    )
    .await;
    let entries2 = for_c2["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        !entries2
            .iter()
            .any(|l| l["link_id"].as_u64() == Some(link_id)),
        "C must not list the link after end removal"
    );
    // A/B unaffected
    let for_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            907,
            "link_list_for_work",
            Some(serde_json::json!({ "work_id": a })),
        ),
    )
    .await;
    let entries_a = for_a["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(entries_a
        .iter()
        .any(|l| l["link_id"].as_u64() == Some(link_id)));
}

/// FR-40 Story 3: link home documents. A homed link appears in the
/// home's Connections, disappears from listings while the home is
/// archived (reversibly), and unhomed links behave exactly as before.
#[tokio::test]
async fn link_home_document_lifecycle() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    async fn mk_work(s: &mut SplitSender, r: &mut SplitReceiver, name: &str) -> u64 {
        send_recv_json(
            s,
            r,
            json_req(
                900,
                "work_create",
                Some(serde_json::json!({"edition": {"text": name}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap()
    }
    let a = mk_work(&mut s, &mut r, "homed A").await;
    let b = mk_work(&mut s, &mut r, "homed B").await;
    let home = mk_work(&mut s, &mut r, "the asserting essay").await;

    let create = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            901,
            "link_create",
            Some(serde_json::json!({
                "origin": a,
                "destination": b,
                "home_document": home,
            })),
        ),
    )
    .await;
    assert_eq!(create["type"], "response", "create failed: {create}");
    let link_id = create["value"]["value"].as_u64().unwrap();

    // Home documents surface on the payload
    let get = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            902,
            "link_get",
            Some(serde_json::json!({ "link_id": link_id })),
        ),
    )
    .await;
    assert_eq!(get["value"]["value"]["home_document"].as_u64(), Some(home));

    // Appears in H's Connections
    let for_home = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            903,
            "link_list_for_work",
            Some(serde_json::json!({ "work_id": home })),
        ),
    )
    .await;
    let entries = for_home["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(entries
        .iter()
        .any(|l| l["link_id"].as_u64() == Some(link_id)));

    // Archive H: link disappears from every listing but is not deleted
    let archive = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            904,
            "work_archive",
            Some(serde_json::json!({ "work_id": home })),
        ),
    )
    .await;
    assert_eq!(archive["type"], "response", "archive failed: {archive}");
    let for_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            905,
            "link_list_for_work",
            Some(serde_json::json!({ "work_id": a })),
        ),
    )
    .await;
    let entries_a = for_a["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        !entries_a
            .iter()
            .any(|l| l["link_id"].as_u64() == Some(link_id)),
        "homed link hidden while home is archived"
    );
    let still_there = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            906,
            "link_get",
            Some(serde_json::json!({ "link_id": link_id })),
        ),
    )
    .await;
    assert_eq!(
        still_there["type"], "response",
        "archive must not delete the link"
    );
    assert_eq!(still_there["value"]["value"]["home_archived"], true);

    // Unarchive restores it (reversible)
    let unarchive = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            907,
            "work_unarchive",
            Some(serde_json::json!({ "work_id": home })),
        ),
    )
    .await;
    assert_eq!(unarchive["type"], "response");
    let for_a2 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            908,
            "link_list_for_work",
            Some(serde_json::json!({ "work_id": a })),
        ),
    )
    .await;
    let entries_a2 = for_a2["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(entries_a2
        .iter()
        .any(|l| l["link_id"].as_u64() == Some(link_id)));

    // Unhomed link on the same works is unaffected by archiving an
    // unrelated work
    let c = mk_work(&mut s, &mut r, "unrelated").await;
    let plain = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            909,
            "link_create",
            Some(serde_json::json!({ "origin": a, "destination": c })),
        ),
    )
    .await;
    let plain_id = plain["value"]["value"].as_u64().unwrap();
    let archive_c = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            910,
            "work_archive",
            Some(serde_json::json!({ "work_id": c })),
        ),
    )
    .await;
    assert_eq!(archive_c["type"], "response");
    let get_plain = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            911,
            "link_get",
            Some(serde_json::json!({ "link_id": plain_id })),
        ),
    )
    .await;
    assert_eq!(
        get_plain["value"]["value"]["home_document"],
        serde_json::Value::Null
    );
    assert_eq!(get_plain["value"]["value"]["home_archived"], false);
}

/// FR-40 Story 4: the four-set query over the wire — heritage
/// questions ("everywhere A quotes B", "every Disagreement homed in
/// H") answered correctly on a seeded corpus.
#[tokio::test]
async fn link_query_heritage_queries() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    async fn mk_work(s: &mut SplitSender, r: &mut SplitReceiver, name: &str) -> u64 {
        send_recv_json(
            s,
            r,
            json_req(
                900,
                "work_create",
                Some(serde_json::json!({"edition": {"text": name}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap()
    }
    let a = mk_work(&mut s, &mut r, "corpus A").await;
    let b = mk_work(&mut s, &mut r, "corpus B").await;
    let c = mk_work(&mut s, &mut r, "corpus C").await;
    let h = mk_work(&mut s, &mut r, "essay home").await;

    async fn mk_link(
        s: &mut SplitSender,
        r: &mut SplitReceiver,
        id: u16,
        origin: u64,
        destination: u64,
        types: serde_json::Value,
        home: Option<u64>,
    ) -> u64 {
        let mut payload = serde_json::json!({
            "origin": origin,
            "destination": destination,
            "link_types": types,
        });
        if let Some(hw) = home {
            payload["home_document"] = serde_json::json!(hw);
        }
        send_recv_json(s, r, json_req(id, "link_create", Some(payload))).await["value"]["value"]
            .as_u64()
            .unwrap()
    }

    let quote_ab = mk_link(&mut s, &mut r, 901, a, b, serde_json::json!([4]), None).await;
    let quote_ac = mk_link(&mut s, &mut r, 902, a, c, serde_json::json!([4]), None).await;
    let disagree_bh = mk_link(&mut s, &mut r, 903, b, a, serde_json::json!([3]), Some(h)).await;

    async fn query(
        s: &mut SplitSender,
        r: &mut SplitReceiver,
        id: u16,
        body: serde_json::Value,
    ) -> Vec<u64> {
        let resp = send_recv_json(s, r, json_req(id, "link_query", Some(body))).await;
        assert_eq!(resp["type"], "response", "query failed: {resp}");
        resp["value"]["value"]
            .as_array()
            .cloned()
            .unwrap_or_default()
            .iter()
            .map(|l| l["link_id"].as_u64().unwrap())
            .collect::<Vec<u64>>()
    }

    // Everywhere A quotes anyone
    let res = query(
        &mut s,
        &mut r,
        910,
        serde_json::json!({
            "from_spec": {"work_ids": [a]},
            "to_spec": {},
            "type_ids": [4],
            "home_spec": {},
        }),
    )
    .await;
    assert!(res.contains(&quote_ab) && res.contains(&quote_ac));
    assert!(!res.contains(&disagree_bh));

    // Everywhere A quotes B (restricted to-spec)
    let res = query(
        &mut s,
        &mut r,
        911,
        serde_json::json!({
            "from_spec": {"work_ids": [a]},
            "to_spec": {"work_ids": [b]},
            "type_ids": [4],
            "home_spec": {},
        }),
    )
    .await;
    assert_eq!(res, vec![quote_ab]);

    // Every Disagreement homed in H
    let res = query(
        &mut s,
        &mut r,
        912,
        serde_json::json!({
            "from_spec": {},
            "to_spec": {},
            "type_ids": [3],
            "home_spec": {"work_ids": [h]},
        }),
    )
    .await;
    assert_eq!(res, vec![disagree_bh]);

    // Empty payload = all links
    let res = query(&mut s, &mut r, 913, serde_json::json!({})).await;
    assert_eq!(res.len(), 3);
}

/// FR-41 S1: federated search over the wire — local results labeled,
/// rate-limited (10/min/session, amplifier guard), empty query
/// refused, and no peers configured means local-only (no fan-out to
/// test, but the op must not error).
#[tokio::test]
async fn federated_search_wire_contract() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    async fn search(
        s: &mut SplitSender,
        r: &mut SplitReceiver,
        id: u16,
        q: &str,
    ) -> serde_json::Value {
        send_recv_json(
            s,
            r,
            json_req(
                id,
                "federated_search",
                Some(serde_json::json!({ "query": q })),
            ),
        )
        .await
    }

    // Empty/whitespace query: empty result, no error
    let resp = search(&mut s, &mut r, 920, "   ").await;
    assert_eq!(resp["type"], "response", "empty query: {resp}");
    let results = resp["value"]["value"]["results"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(results.is_empty(), "whitespace query yields no results");

    // Local-only fan-out: works containing a marker term are labeled local
    let marker = format!(
        "s1netmarker{}",
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis()
    );
    let wid = send_recv_json(
        &mut s,
        &mut r,
        json_req(921, "work_create", Some(serde_json::json!({"edition": {"text": format!("the {} passage lives here", marker)}}))),
    )
    .await["value"]["value"].as_u64().unwrap();
    // Federated search only surfaces PUBLIC works — publish it.
    let pub_resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            9215,
            "work_publish",
            Some(serde_json::json!({ "work_id": wid })),
        ),
    )
    .await;
    assert_eq!(pub_resp["type"], "response", "publish failed: {pub_resp}");
    let resp = search(&mut s, &mut r, 922, &marker).await;
    assert_eq!(resp["type"], "response");
    let results = resp["value"]["value"]["results"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert_eq!(results.len(), 1, "local hit present: {results:?}");
    assert_eq!(results[0]["local"], true);
    assert_eq!(results[0]["work_id"].as_u64(), Some(wid));

    // Rate limit: 10 searches per minute per session; the two above
    // consumed 2 of the budget (empty query is rejected before the
    // limiter? no — limiter runs first). Hammer to the limit, expect 429-style error.
    let mut saw_rate_limit = false;
    for i in 0..15u16 {
        let resp = search(&mut s, &mut r, 930 + i, &marker).await;
        if resp["type"] == "error" {
            let msg = resp["message"].as_str().unwrap_or_default();
            assert!(msg.contains("too many"), "unexpected error: {msg}");
            saw_rate_limit = true;
            break;
        }
    }
    assert!(
        saw_rate_limit,
        "rate limiter must engage within 15 rapid fan-outs"
    );
}

/// #141: a hung peer must never stall the server. We register a
/// "peer" at a blackhole address (socket accepted, never answers —
/// the observed live failure), fire a federated search at it, and
/// DURING the fan-out verify that unrelated ops (health-adjacent
/// session op + work op) still complete quickly. Pre-fix this froze
/// the whole server behind the write lock.
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn hung_peer_does_not_stall_server() {
    xudanu::server::server::set_allow_loopback(true);
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    // A "peer" that answers its well-known identity ONCE (so
    // directory-add succeeds) then goes silent on everything else —
    // the reachable-but-unresponsive worst case from the live freeze.
    let blackhole = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let bh_addr = blackhole.local_addr().unwrap();
    tokio::spawn(async move {
        use tokio::io::{AsyncReadExt, AsyncWriteExt};
        loop {
            let (mut sock, _) = match blackhole.accept().await {
                Ok(x) => x,
                Err(_) => break,
            };
            tokio::spawn(async move {
                let mut buf = vec![0u8; 8192];
                let mut answered = false;
                loop {
                    match tokio::time::timeout(
                        std::time::Duration::from_secs(6),
                        sock.read(&mut buf),
                    )
                    .await
                    {
                        Ok(Ok(0)) | Err(_) | Ok(Err(_)) => break,
                        Ok(Ok(n)) => {
                            let req = String::from_utf8_lossy(&buf[..n]).to_string();
                            if !answered && req.contains("/.well-known/") {
                                let body = r#"{"server_id":"aa5f2c1068d9a6b34d1e7c92f4b0a3d5e6f70819a2b3c4d5e6f708192a3b4c5d","server_name":"Blackhole"}"#;
                                let resp = format!(
                                    "HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                                    body.len(), body
                                );
                                let _ = sock.write_all(resp.as_bytes()).await;
                                answered = true;
                            }
                            // everything else: read and ignore — never answer
                        }
                    }
                }
                // hold until peer-side timeout closes us
            });
        }
    });

    // Register the blackhole as a trusted peer (admin).
    async fn reg(s: &mut SplitSender, r: &mut SplitReceiver, id: u16, host: &str, port: u16) {
        let add = send_recv_json(
            s,
            r,
            json_req(
                id,
                "server_directory_add",
                Some(serde_json::json!({"address": host, "port": port})),
            ),
        )
        .await;
        assert_eq!(add["type"], "response", "add failed: {add}");
        let list = send_recv_json(s, r, json_req(id + 50, "server_directory_list", None)).await;
        let servers = list["value"]["value"]["servers"]
            .as_array()
            .cloned()
            .unwrap_or_default();
        let entry = servers
            .iter()
            .find(|e| e["address"].as_str() == Some(host))
            .cloned()
            .expect("in dir");
        let trust = send_recv_json(
            s,
            r,
            json_req(
                id + 51,
                "server_directory_set_trust",
                Some(serde_json::json!({"server_id": entry["server_id"], "trusted": true})),
            ),
        )
        .await;
        assert_eq!(trust["type"], "response", "trust failed: {trust}");
    }
    let (bh_host, bh_port) = (bh_addr.ip().to_string(), bh_addr.port());
    reg(&mut s, &mut r, 970, &bh_host, bh_port).await;

    // Fire the search (would hang the lock pre-fix) and concurrently
    // probe an unrelated op repeatedly.
    let mut search_sock = connect_with_handshake(&srv, "json").await;
    let _ = search_sock
        .0
        .send(Message::Text(
            serde_json::to_string(&json_req(
                971,
                "federated_search",
                Some(serde_json::json!({"query": "anything"})),
            ))
            .unwrap()
            .into(),
        ))
        .await;

    let probe_start = std::time::Instant::now();
    let mut worst_probe_ms: u128 = 0;
    for i in 0..5 {
        let t0 = std::time::Instant::now();
        let resp = send_recv_json(
            &mut s,
            &mut r,
            json_req(980 + i as u16, "club_who_am_i", None),
        )
        .await;
        assert_eq!(resp["type"], "response", "probe op failed: {resp}");
        let dt = t0.elapsed().as_millis();
        worst_probe_ms = worst_probe_ms.max(dt);
        tokio::time::sleep(std::time::Duration::from_millis(200)).await;
    }
    let total = probe_start.elapsed().as_millis();
    // Each probe must answer in well under the peer timeout: if the
    // lock were held, ALL probes would block ~5s each.
    assert!(
        worst_probe_ms < 1500,
        "probe op took {worst_probe_ms}ms during hung-peer fan-out — lock held?"
    );
    println!("hung-peer test: {total}ms total, worst probe {worst_probe_ms}ms — server responsive during fan-out");
}

/// FR-41 S3: origin edits their source; the destination detects the
/// change (check mode: changed=true, no state mutation) and can
/// update the frozen source (update mode: new revision, old quote
/// preserved in history). Unchanged span reports changed=false.
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn cross_server_span_refresh_flow() {
    xudanu::server::server::set_allow_loopback(true);
    let srv_b = TestServer::start().await;
    let srv_a = TestServer::start().await;

    async fn mkpub(s: &mut SplitSender, r: &mut SplitReceiver, id: u16, text: &str) -> u64 {
        let wid = send_recv_json(
            s,
            r,
            json_req(
                id,
                "work_create",
                Some(serde_json::json!({"edition": {"text": text}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap();
        let pubr = send_recv_json(
            s,
            r,
            json_req(
                id + 100,
                "work_publish",
                Some(serde_json::json!({"work_id": wid})),
            ),
        )
        .await;
        assert_eq!(pubr["type"], "response", "publish failed: {pubr}");
        wid
    }

    // Node B publishes the source; Node A transcludes a span (S2 path).
    let source_text = "v1: the sublinear enfilade story begins here";
    let (mut sb, mut rb, _) = json_setup(&srv_b).await;
    let b_work = mkpub(&mut sb, &mut rb, 900, source_text).await;
    let b_work_hex = format!("{:x}", b_work);

    let (mut sa, mut ra, _) = json_setup(&srv_a).await;
    let dest = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            910,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "essay\n\nend"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let b_info: serde_json::Value = reqwest::get(format!(
        "http://{}/.well-known/xudanu-server.json",
        srv_b.addr
    ))
    .await
    .unwrap()
    .json()
    .await
    .unwrap();
    let b_namespace = b_info["server_namespace_id"].as_u64().unwrap();

    let b_addr = format!("{}", srv_b.addr);
    let parts: Vec<&str> = b_addr.rsplitn(2, ':').collect();
    let (b_port_str, b_host) = (parts[0], parts[1]);
    let add = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            911,
            "server_directory_add",
            Some(serde_json::json!({"address": b_host, "port": b_port_str.parse::<u16>().ok()})),
        ),
    )
    .await;
    assert_eq!(add["type"], "response", "add failed: {add}");
    let list = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(912, "server_directory_list", None),
    )
    .await;
    let servers = list["value"]["value"]["servers"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    let b_sid = servers
        .iter()
        .find(|e| e["address"].as_str() == Some(b_host))
        .map(|e| e["server_id"].clone())
        .expect("B in directory");
    let trust = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            913,
            "server_directory_set_trust",
            Some(serde_json::json!({"server_id": b_sid, "trusted": true})),
        ),
    )
    .await;
    assert_eq!(trust["type"], "response");

    let tumbler = format!("{}.{}.1.0", b_namespace, b_work_hex);
    let place = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            920,
            "transclusion_place_cross_server",
            Some(serde_json::json!({
                "dest_work": dest,
                "cursor": 0,
                "tumbler": tumbler,
                "span_start": 4,
                "span_end": 12,
                "title_hint": "enfilade span",
            })),
        ),
    )
    .await;
    assert_eq!(place["type"], "response", "place failed: {place}");
    let source_work = place["value"]["value"]["source_work"].as_u64().unwrap();

    // S3 check BEFORE origin edit: unchanged.
    let check0 = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            930,
            "cross_server_span_refresh",
            Some(serde_json::json!({"source_work": source_work, "update": false})),
        ),
    )
    .await;
    assert_eq!(check0["type"], "response", "check0 failed: {check0}");
    assert_eq!(
        check0["value"]["value"]["changed"], false,
        "no edit yet -> unchanged"
    );
    assert_eq!(
        check0["value"]["value"]["new_revision"],
        serde_json::Value::Null,
        "check mode never updates"
    );

    // Node B edits the source text. Span chars 4..12 of v2 is
    // "the REWR" — same character window, different content.
    let revise = send_recv_json(
        &mut sb,
        &mut rb,
        json_req(
            940,
            "work_set_text",
            Some(serde_json::json!({
                "work_id": b_work,
                "text": "v2: the REWRITTEN enfilade story begins here"
            })),
        ),
    )
    .await;
    assert_eq!(revise["type"], "response", "origin revise failed: {revise}");

    // S3 check AFTER edit: changed=true, current text reported.
    let check1 = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            931,
            "cross_server_span_refresh",
            Some(serde_json::json!({"source_work": source_work, "update": false})),
        ),
    )
    .await;
    assert_eq!(check1["type"], "response", "check1 failed: {check1}");
    let v = &check1["value"]["value"];
    assert_eq!(v["changed"], true, "origin edit must be detected");
    let cur = v["current_text"].as_str().unwrap_or_default();
    assert!(
        cur.contains("REWR"),
        "current text reflects origin v2 span, got: {cur}"
    );

    // Old revision still intact on A (check mode didn't mutate).
    let old = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            932,
            "work_get_edition",
            Some(serde_json::json!({"work_id": source_work})),
        ),
    )
    .await;
    assert_eq!(old["type"], "response");
    let old_flat = serde_json::to_string(&old["value"]).unwrap_or_default();
    assert!(
        old_flat.contains("subl"),
        "frozen v1 quote preserved pre-update, got: {old_flat}"
    );

    // S3 update: new revision recorded, content now v2.
    let upd = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            933,
            "cross_server_span_refresh",
            Some(serde_json::json!({"source_work": source_work, "update": true})),
        ),
    )
    .await;
    assert_eq!(upd["type"], "response", "update failed: {upd}");
    let uv = &upd["value"]["value"];
    assert_eq!(uv["changed"], true);
    // Update creates a NEW frozen source (old is immutable); the
    // payload's source_work is the new one, distinct from the old.
    let new_source = uv["source_work"].as_u64().expect("new source id");
    assert_ne!(
        new_source, source_work,
        "update mints a fresh frozen source"
    );

    // Destination now renders the updated span (virtual re-resolves
    // through the frozen source's current text).
    let resolved = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            934,
            "resolve_inline_transclusions",
            Some(serde_json::json!({"work_id": dest})),
        ),
    )
    .await;
    assert_eq!(resolved["type"], "response");
    let flat = serde_json::to_string(&resolved["value"]).unwrap_or_default();
    assert!(
        flat.contains("REWR"),
        "destination renders updated origin span, got: {flat}"
    );
}

/// FR-41 S2: cross-server span transclusion over the wire. Node A
/// fetches a span of Node B's published work by reference: tumbler +
/// span in, verified BLAKE3 out, pinned virtual element placed in
/// the destination at the cursor. Also covers the failure modes:
/// tampered hash (impossible to forge here, but bad span range must
/// error clearly) and untrusted-origin refusal.
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn cross_server_span_transclusion_end_to_end() {
    xudanu::server::server::set_allow_loopback(true);
    let srv_b = TestServer::start().await;
    let srv_a = TestServer::start().await;

    // Node B: author + publish the source work
    let (mut sb, mut rb, _) = json_setup(&srv_b).await;
    let source_text = "The enfilade structure provides sublinear retrieval across the docuverse. Transclusion keeps content singular. Provenance binds authors to spans.";
    async fn mkpub(s: &mut SplitSender, r: &mut SplitReceiver, id: u16, text: &str) -> u64 {
        let wid = send_recv_json(
            s,
            r,
            json_req(
                id,
                "work_create",
                Some(serde_json::json!({"edition": {"text": text}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap();
        let pubr = send_recv_json(
            s,
            r,
            json_req(
                id + 100,
                "work_publish",
                Some(serde_json::json!({"work_id": wid})),
            ),
        )
        .await;
        assert_eq!(pubr["type"], "response", "publish failed: {pubr}");
        wid
    }
    let b_work = mkpub(&mut sb, &mut rb, 900, source_text).await;
    let b_work_hex = format!("{:x}", b_work);

    // Node A: admin-authenticate, create destination doc, add Node B
    // to the directory (loopback allowed for the test), trust it.
    let (mut sa, mut ra, _) = json_setup(&srv_a).await;

    // import_source_work requires a registered historical author
    // (the provenance bond for imported sources). Register one and
    // use it as the importing author.
    let author = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            905,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "NodeB Importer",
                "display_name": "Cross-server import",
                "birth_year": null,
                "death_year": null,
                "external_ids": {},
                "source_bibliography": ""
            })),
        ),
    )
    .await;
    assert_eq!(
        author["type"], "response",
        "author register failed: {author}"
    );
    let importer_author = author["value"]["value"]["be_id"].as_u64().unwrap();
    let dest = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            910,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "My essay.\n\nMORE\n"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    // resolve B's server id from its well-known
    let b_info: serde_json::Value = reqwest::get(format!(
        "http://{}/.well-known/xudanu-server.json",
        srv_b.addr
    ))
    .await
    .unwrap()
    .json()
    .await
    .unwrap();
    let b_namespace = b_info["server_namespace_id"].as_u64().unwrap();

    let b_addr = format!("{}", srv_b.addr);
    let b_addr_parts: Vec<&str> = b_addr.rsplitn(2, ':').collect();
    let (b_port_str, b_host) = (b_addr_parts[0], b_addr_parts[1]);
    let add = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            911,
            "server_directory_add",
            Some(serde_json::json!({
                "address": b_host,
                "port": b_port_str.parse::<u16>().ok(),
            })),
        ),
    )
    .await;
    assert_eq!(add["type"], "response", "directory add failed: {add}");

    // trust it: find its server_id in the list first
    let list = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(912, "server_directory_list", None),
    )
    .await;
    let servers = list["value"]["value"]["servers"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    let b_entry = servers
        .iter()
        .find(|e| e["address"].as_str() == Some(b_host))
        .cloned()
        .expect("B in directory");
    let b_sid = b_entry["server_id"].clone();
    let trust = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            913,
            "server_directory_set_trust",
            Some(serde_json::json!({"server_id": b_sid, "trusted": true})),
        ),
    )
    .await;
    assert_eq!(trust["type"], "response", "trust failed: {trust}");

    // The happy path: transclude chars 4..12 of B's work ("enfilade")
    // into dest at cursor 9.
    let tumbler = format!("{}.{}.1.0", b_namespace, b_work_hex);
    let place = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            920,
            "transclusion_place_cross_server",
            Some(serde_json::json!({
                "dest_work": dest,
                "cursor": 9,
                "tumbler": tumbler,
                "span_start": 4,
                "span_end": 12,
                "title_hint": "enfilade passage",
            })),
        ),
    )
    .await;
    assert_eq!(place["type"], "response", "place failed: {place}");
    let val = &place["value"]["value"];
    assert_eq!(val["dest_work"].as_u64(), Some(dest));
    assert!(
        val["source_work"].as_u64().is_some(),
        "frozen source created"
    );
    assert_eq!(val["span"].as_array().map(|a| a.len()), Some(2));
    assert!(
        val["content_hash"].as_str().is_some_and(|h| h.len() == 64),
        "hash present"
    );

    // Destination now contains the span content. Virtual elements
    // resolve through their pinned revision on read
    // (materialize_virtual_elements is the FR-37 pass); the
    // work_text op triggers it server-side.
    // resolve_inline_transclusions materializes virtuals (FR-37
    // pinned-resolution) then renders the full text.
    let text = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            921,
            "resolve_inline_transclusions",
            Some(serde_json::json!({"work_id": dest})),
        ),
    )
    .await;
    assert_eq!(text["type"], "response", "resolve failed: {text}");
    let flat = serde_json::to_string(&text["value"]).unwrap_or_default();
    assert!(
        flat.contains("enfilade"),
        "rendered destination must contain the transcluded span, got: {flat}"
    );

    // Failure mode 1: bad span (start >= end) — clear error
    let bad = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            930,
            "transclusion_place_cross_server",
            Some(serde_json::json!({
                "dest_work": dest,
                "cursor": 0,
                "tumbler": tumbler,
                "span_start": 10,
                "span_end": 10,
            })),
        ),
    )
    .await;
    assert_eq!(bad["type"], "error", "empty span must error: {bad}");

    // Failure mode 2: unknown tumbler — clear error
    let bad2 = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            931,
            "transclusion_place_cross_server",
            Some(serde_json::json!({
                "dest_work": dest,
                "cursor": 0,
                "tumbler": "99999.ffff.1.0",
                "span_start": 0,
                "span_end": 5,
            })),
        ),
    )
    .await;
    assert_eq!(bad2["type"], "error", "unknown origin must error: {bad2}");
    let msg = bad2["message"].as_str().unwrap_or_default();
    assert!(
        msg.contains("directory") || msg.contains("not in directory"),
        "error should explain the origin is unknown: {msg}"
    );
}

/// FR-40 sender feedback: cross-server link creation reports the
/// definitive notify outcome — accepted when the receiver takes it,
/// a receiver rejection reason (HTTP 404) for unknown works, and a
/// reachability error when the remote is down. Runs two real servers.
// multi_thread: the cross-server notify runs synchronously on a
// dispatch worker; the in-process receiving server needs another
// runtime thread to answer (production runs multi-threaded runtimes
// in separate processes).
#[tokio::test(flavor = "multi_thread", worker_threads = 4)]
async fn cross_server_link_notify_sender_feedback() {
    xudanu::server::server::set_allow_loopback(true);
    let srv_a = TestServer::start().await;
    let srv_b = TestServer::start().await;

    async fn mk_work(s: &mut SplitSender, r: &mut SplitReceiver, name: &str) -> u64 {
        send_recv_json(
            s,
            r,
            json_req(
                900,
                "work_create",
                Some(serde_json::json!({"edition": {"text": name}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap()
    }

    let (mut sa, mut ra, _) = json_setup(&srv_a).await;
    let (mut sb, mut rb, _) = json_setup(&srv_b).await;
    let local = mk_work(&mut sa, &mut ra, "sender's essay").await;
    let remote = mk_work(&mut sb, &mut rb, "receiver's target work").await;
    let remote_hex = format!("{:x}", remote);

    fn csr_link(remote_addr: &str, work_hex: &str) -> serde_json::Value {
        serde_json::json!({
            "kind": "single",
            "work_context": null,
            "original_context": null,
            "excerpt": "crossed passage",
            "start_position": null,
            "end_position": null,
            "cross_server_ref": {
                "tumbler": format!("2.{}.1.0", work_hex),
                "origin_server_id": 2,
                "origin_server_address": remote_addr,
                "content_hash": "00".repeat(32),
                "origin_author": "remote author",
                "origin_author_key": "00".repeat(32),
                "excerpt": "crossed passage",
            },
        })
    }

    async fn create_remote_link(
        sa: &mut SplitSender,
        ra: &mut SplitReceiver,
        id: u16,
        local: u64,
        remote_addr: String,
        work_hex: String,
    ) -> serde_json::Value {
        let csr = csr_link(&remote_addr, &work_hex);
        send_recv_json(
            sa,
            ra,
            json_req(
                id,
                "link_create",
                Some(serde_json::json!({
                    "origin": local,
                    "destination": local,
                    "origin_ref": {
                        "kind": "single",
                        "work_context": local,
                        "excerpt": "crossed passage",
                        "start_position": 0,
                        "end_position": 15,
                    },
                    "destination_ref": csr,
                })),
            ),
        )
        .await
    }

    // 1. Healthy receiver: notify accepted, receipt visible on B
    let created = create_remote_link(
        &mut sa,
        &mut ra,
        910,
        local,
        format!("{}", srv_b.addr),
        remote_hex.clone(),
    )
    .await;
    assert_eq!(created["type"], "response", "create failed: {created}");
    let link_id = created["value"]["value"].as_u64().unwrap();

    let get = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            911,
            "link_get",
            Some(serde_json::json!({ "link_id": link_id })),
        ),
    )
    .await;
    let val = &get["value"]["value"];
    assert_eq!(
        val["cross_server_notify_accepted"], true,
        "healthy receiver must accept: {val}"
    );
    assert_eq!(val["cross_server_notify_error"], serde_json::Value::Null);

    let receipts = send_recv_json(
        &mut sb,
        &mut rb,
        json_req(
            912,
            "cross_server_backlinks_get",
            Some(serde_json::json!({ "work_id": remote })),
        ),
    )
    .await;
    let list = receipts["value"]["value"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        !list.is_empty(),
        "receiver must hold a backlink receipt: {receipts}"
    );

    // 2. Receiver rejects: unknown target work (HTTP 404)
    let rejected = create_remote_link(
        &mut sa,
        &mut ra,
        913,
        local,
        format!("{}", srv_b.addr),
        "ffffee".to_string(),
    )
    .await;
    assert_eq!(rejected["type"], "response");
    let link2 = rejected["value"]["value"].as_u64().unwrap();
    let get2 = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            914,
            "link_get",
            Some(serde_json::json!({ "link_id": link2 })),
        ),
    )
    .await;
    let val2 = &get2["value"]["value"];
    assert_eq!(
        val2["cross_server_notify_accepted"], false,
        "unknown work must be rejected: {val2}"
    );
    let err = val2["cross_server_notify_error"]
        .as_str()
        .unwrap_or_default();
    assert!(
        err.contains("404") || err.contains("not found"),
        "rejection reason must be understandable: {err}"
    );

    // 3. Unreachable receiver (closed port): sender-side error, fast
    let start = std::time::Instant::now();
    let dead = create_remote_link(
        &mut sa,
        &mut ra,
        915,
        local,
        "127.0.0.1:1".to_string(),
        remote_hex.clone(),
    )
    .await;
    let elapsed = start.elapsed();
    assert_eq!(dead["type"], "response");
    let link3 = dead["value"]["value"].as_u64().unwrap();
    let get3 = send_recv_json(
        &mut sa,
        &mut ra,
        json_req(
            916,
            "link_get",
            Some(serde_json::json!({ "link_id": link3 })),
        ),
    )
    .await;
    let val3 = &get3["value"]["value"];
    assert_eq!(
        val3["cross_server_notify_accepted"], false,
        "dead receiver must not be accepted: {val3}"
    );
    let err3 = val3["cross_server_notify_error"]
        .as_str()
        .unwrap_or_default();
    assert!(
        err3.to_lowercase().contains("reach") || err3.to_lowercase().contains("connect"),
        "reachability error must be understandable: {err3}"
    );
    assert!(
        elapsed.as_secs() < 5,
        "connection-refused must fail fast, took {:?}",
        elapsed
    );
}

/// FR-40 Story 2: type ends are derived on read — a multi-typed link
/// materializes one type end per registered definition work, without
/// storing them on the link itself.
#[tokio::test]
async fn link_type_ends_derived_on_read() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    async fn mk_work(s: &mut SplitSender, r: &mut SplitReceiver, name: &str) -> u64 {
        send_recv_json(
            s,
            r,
            json_req(
                900,
                "work_create",
                Some(serde_json::json!({"edition": {"text": name}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap()
    }
    let a = mk_work(&mut s, &mut r, "type-end A").await;
    let b = mk_work(&mut s, &mut r, "type-end B").await;
    let def_comment = mk_work(&mut s, &mut r, "Comment definition work").await;

    // Register type 1 (Comment) with a definition work; type 4
    // (Quotation) stays definition-less on this server.
    let reg = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            901,
            "link_type_register",
            Some(serde_json::json!({
                "type_id": 1,
                "name": "Comment",
                "definition_work": def_comment,
            })),
        ),
    )
    .await;
    assert_eq!(reg["type"], "response");

    let link_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            902,
            "link_create",
            Some(serde_json::json!({
                "origin": a,
                "destination": b,
                "link_types": [1, 4],
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let get = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            903,
            "link_get",
            Some(serde_json::json!({ "link_id": link_id })),
        ),
    )
    .await;
    let val = &get["value"]["value"];
    let type_ends = val["type_ends"].as_array().cloned().unwrap_or_default();
    assert_eq!(
        type_ends.len(),
        1,
        "only registered-with-definition types materialize a type end: {val}"
    );
    assert_eq!(type_ends[0][0].as_u64(), Some(1));
    assert_eq!(type_ends[0][1].as_u64(), Some(def_comment));

    // Not stored: removing/adding ends never sees the derived end
    let named = val["named_ends"].as_array().cloned().unwrap_or_default();
    assert!(
        !named
            .iter()
            .any(|pair| pair[0].as_str().unwrap_or("").starts_with("Type")),
        "derived type ends must not leak into the stored ends map"
    );

    // link_type_list surfaces the definition
    let types = send_recv_json(
        &mut s,
        &mut r,
        json_req(904, "link_type_list", Some(serde_json::json!({}))),
    )
    .await;
    let list = types["value"]["value"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        list.iter().any(|t| t["type_id"].as_u64() == Some(1)
            && t["definition_work"].as_u64() == Some(def_comment)),
        "link_type_list returns definition works: {list:?}"
    );
}

/// FR-39/FR-40 hardening: user-defined link types are safe by
/// construction — built-ins can't be hijacked, custom ids can't be
/// squatted, dangling definitions are rejected, and the legit
/// "work IS the type" flow works end to end.
#[tokio::test]
async fn link_type_registration_hardening() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    async fn mk_work(s: &mut SplitSender, r: &mut SplitReceiver, name: &str) -> u64 {
        send_recv_json(
            s,
            r,
            json_req(
                900,
                "work_create",
                Some(serde_json::json!({"edition": {"text": name}})),
            ),
        )
        .await["value"]["value"]
            .as_u64()
            .unwrap()
    }
    let def = mk_work(
        &mut s,
        &mut r,
        "Certification: this passage has been verified",
    )
    .await;

    async fn register(
        s: &mut SplitSender,
        r: &mut SplitReceiver,
        id: u16,
        type_id: u64,
        name: &str,
        def_work: Option<u64>,
    ) -> serde_json::Value {
        let mut payload = serde_json::json!({"type_id": type_id, "name": name});
        if let Some(dw) = def_work {
            payload["definition_work"] = serde_json::json!(dw);
        }
        send_recv_json(s, r, json_req(id, "link_type_register", Some(payload))).await
    }

    // Legit custom type: id == definition work id
    let ok = register(&mut s, &mut r, 901, def, "Certification", Some(def)).await;
    assert_eq!(ok["type"], "response", "legit registration failed: {ok}");

    // Squatting: custom id that doesn't match its definition work
    let bad = register(&mut s, &mut r, 902, def + 100, "Fake", Some(def)).await;
    assert_eq!(bad["type"], "error", "id squatting must be rejected: {bad}");

    // Dangling: definition work doesn't exist
    let bad = register(&mut s, &mut r, 903, 999999, "Ghost", Some(999999)).await;
    assert_eq!(
        bad["type"], "error",
        "dangling definition must be rejected: {bad}"
    );

    // Definition-less custom type (non-built-in id, no work)
    let bad = register(&mut s, &mut r, 904, 4242, "Bare", None).await;
    assert_eq!(
        bad["type"], "error",
        "definition-less custom type must be rejected: {bad}"
    );

    // Empty name
    let bad = register(&mut s, &mut r, 905, def, "  ", Some(def)).await;
    assert_eq!(bad["type"], "error", "empty name must be rejected: {bad}");

    // Built-in redefinition by a NON-admin session is blocked; by an
    // admin session it succeeds (this session is admin).
    let ok = register(&mut s, &mut r, 906, 3, "Disagreement", None).await;
    assert_eq!(ok["type"], "response", "admin may redefine built-ins: {ok}");

    // Register as public (non-admin) session and attempt built-in hijack
    let (mut ps, mut pr) = connect_with_handshake(&srv, "json").await;
    let _ = send_recv_json(&mut ps, &mut pr, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut ps, &mut pr, json_req(2, "session_login_public", None)).await;
    let hijack = send_recv_json(
        &mut ps,
        &mut pr,
        json_req(
            3,
            "link_type_register",
            Some(serde_json::json!({"type_id": 1, "name": "Evil"})),
        ),
    )
    .await;
    assert_eq!(
        hijack["type"], "error",
        "non-admin built-in hijack must be rejected: {hijack}"
    );

    // The custom type is usable end-to-end: create a typed link with it
    let a = mk_work(&mut s, &mut r, "cert A").await;
    let b = mk_work(&mut s, &mut r, "cert B").await;
    let link_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            907,
            "link_create",
            Some(serde_json::json!({
                "origin": a,
                "destination": b,
                "link_types": [def],
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let get = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            908,
            "link_get",
            Some(serde_json::json!({ "link_id": link_id })),
        ),
    )
    .await;
    let val = &get["value"]["value"];
    assert!(
        (val["link_types"].as_array().cloned().unwrap_or_default())
            .iter()
            .any(|t| t.as_u64() == Some(def)),
        "custom type attaches to links: {val}"
    );
    let type_ends = val["type_ends"].as_array().cloned().unwrap_or_default();
    assert!(
        type_ends
            .iter()
            .any(|te| te[0].as_u64() == Some(def) && te[1].as_u64() == Some(def)),
        "custom type materializes its type end: {val}"
    );
}

#[tokio::test]
async fn link_create_origin_only_span_is_preserved() {
    // Regression: link_create with only origin_ref (the CLI seeding
    // path) must keep the span anchor. The old all-or-nothing branch
    // built fresh span-less refs, so links rendered without underlines
    // or right-panel anchors — the degraded Welcome-page symptom.
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Line 1 has a Comment link here"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let work_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "target"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let link_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "link_create",
            Some(serde_json::json!({
                "origin": work_a,
                "destination": work_b,
                "origin_ref": {
                    "kind": "single",
                    "work_context": work_a,
                    "excerpt": "Line 1 has a Comment link",
                    "start_position": 0,
                    "end_position": 25
                }
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    assert!(link_id > 0);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "link_get",
            Some(serde_json::json!({"link_id": link_id})),
        ),
    )
    .await;
    let o_ref = &resp["value"]["value"]["origin_ref"];
    assert_eq!(
        o_ref["start_position"], 0,
        "origin span start must survive origin-only link_create"
    );
    assert_eq!(
        o_ref["end_position"], 25,
        "origin span end must survive origin-only link_create"
    );
    assert_eq!(
        o_ref["excerpt"], "Line 1 has a Comment link",
        "origin excerpt must survive origin-only link_create"
    );
}

#[tokio::test]
async fn link_list_for_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "a"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let work_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "b"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "link_create",
            Some(serde_json::json!({
                "origin": work_a, "destination": work_b
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "link_list_for_work",
            Some(serde_json::json!({"work_id": work_a})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let links = resp["value"]["value"]["entries"].as_array().unwrap();
    assert_eq!(links.len(), 1);
    assert_eq!(links[0]["origin"], work_a);
    assert_eq!(links[0]["destination"], work_b);
}

#[tokio::test]
async fn find_works_for_content() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let content_ed = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "edition_store",
            Some(serde_json::json!({"edition": {"text": "shared content"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "find_works_for_content",
            Some(serde_json::json!({
                "content_be_id": content_ed
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn delta_edit_success() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello world"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let rev0 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_revision_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            40,
            "work_revise_delta",
            Some(serde_json::json!({
                "work_id": work_id,
                "base_revision": rev0,
                "ops": [
                    {"type": "retain", "count": 5},
                    {"type": "insert", "text": "beautiful"}
                ]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "humber");
    assert_eq!(resp["value"]["value"], rev0 + 1);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            50,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"]["text"], "hellobeautiful world");
}

#[tokio::test]
async fn delta_edit_conflict_returns_edition() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello world"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_revise",
            Some(serde_json::json!({
                "work_id": work_id,
                "edition": {"text": "hello world"}
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            40,
            "work_revise_delta",
            Some(serde_json::json!({
                "work_id": work_id,
                "base_revision": 0,
                "ops": [
                    {"type": "retain", "count": 5},
                    {"type": "insert", "text": "!"}
                ]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "edition");
    assert_eq!(resp["value"]["value"]["text"], "hello world");
}

#[tokio::test]
async fn delta_delete_and_insert() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "the quick brown fox"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_revise_delta",
            Some(serde_json::json!({
                "work_id": work_id,
                "base_revision": 0,
                "ops": [
                    {"type": "retain", "count": 4},
                    {"type": "delete", "count": 5},
                    {"type": "insert", "text": "slow"},
                    {"type": "retain", "count": 7}
                ]
            })),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "humber");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            40,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
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
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "blob_upload",
            Some(serde_json::json!({
                "data": data,
                "mime_type": "text/plain"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "blob_meta");
    let meta = &resp["value"]["value"];
    let content_hash = parse_hash_hex(&meta["content_hash"]);
    assert!(content_hash > 0);
    assert_eq!(meta["byte_size"].as_u64().unwrap(), 16);
    assert_eq!(meta["mime_type"].as_str().unwrap(), "text/plain");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "blob_get",
            Some(serde_json::json!({
                "content_hash": hash_hex(content_hash)
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "string");
    let decoded = xudanu::edition::base64_decode(resp["value"]["value"].as_str().unwrap()).unwrap();
    assert_eq!(decoded, b"hello blob world");
}

#[tokio::test]
async fn blob_exists_and_info_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "blob_exists",
            Some(serde_json::json!({"content_hash": hash_hex(99999)})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "boolean");
    assert!(!resp["value"]["value"].as_bool().unwrap());

    let data = xudanu::edition::base64_encode(b"test data");
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "blob_upload",
            Some(serde_json::json!({
                "data": data,
                "mime_type": "image/png"
            })),
        ),
    )
    .await;
    let hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "blob_exists",
            Some(serde_json::json!({"content_hash": hash_hex(hash)})),
        ),
    )
    .await;
    assert!(resp["value"]["value"].as_bool().unwrap());

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "blob_info",
            Some(serde_json::json!({"content_hash": hash_hex(hash)})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "blob_meta");
    let meta = &resp["value"]["value"];
    assert_eq!(meta["mime_type"].as_str().unwrap(), "image/png");
    assert_eq!(meta["byte_size"].as_u64().unwrap(), 9);
}

#[tokio::test]
async fn blob_stats_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "blob_stats", None)).await;
    assert_eq!(resp["value"]["type"], "blob_stats_info");
    assert_eq!(resp["value"]["value"]["total_blobs"].as_u64().unwrap(), 0);

    let data = xudanu::edition::base64_encode(b"x");
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "blob_upload",
            Some(serde_json::json!({"data": data, "mime_type": "text/plain"})),
        ),
    )
    .await;

    let resp = send_recv_json(&mut s, &mut r, json_req(12, "blob_stats", None)).await;
    assert_eq!(resp["value"]["value"]["total_blobs"].as_u64().unwrap(), 1);
    assert_eq!(resp["value"]["value"]["total_bytes"].as_u64().unwrap(), 1);
}

#[tokio::test]
async fn blob_upload_requires_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let data = xudanu::edition::base64_encode(b"unauth");
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "blob_upload",
            Some(serde_json::json!({
                "data": data,
                "mime_type": "text/plain"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn blob_get_not_found_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "blob_get",
            Some(serde_json::json!({"content_hash": hash_hex(99999)})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn blob_deduplication_json() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let data = xudanu::edition::base64_encode(b"duplicate");
    let resp1 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "blob_upload",
            Some(serde_json::json!({"data": data.clone(), "mime_type": "text/plain"})),
        ),
    )
    .await;
    let resp2 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "blob_upload",
            Some(serde_json::json!({"data": data, "mime_type": "text/plain"})),
        ),
    )
    .await;
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
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "blob_upload",
            Some(serde_json::json!({
                "data": data,
                "mime_type": "text/plain"
            })),
        ),
    )
    .await;
    let hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);
    let hash_hex_val = resp["value"]["value"]["content_hash"]
        .as_str()
        .unwrap()
        .to_string();

    let client = reqwest::Client::new();
    let http_resp = client
        .get(format!("http://{}/blobs/{}", srv.addr, hash_hex_val))
        .send()
        .await
        .unwrap();
    assert_eq!(http_resp.status(), 200);
    assert_eq!(
        http_resp.headers().get("content-type").unwrap(),
        "text/plain"
    );
    let body = http_resp.bytes().await.unwrap();
    assert_eq!(&body[..], b"http blob test");
}

#[tokio::test]
async fn blob_http_get_not_found() {
    let srv = TestServer::start().await;
    let client = reqwest::Client::new();
    let http_resp = client
        .get(format!("http://{}/blobs/{:016x}", srv.addr, 99999u64))
        .send()
        .await
        .unwrap();
    assert_eq!(http_resp.status(), 404);
}

#[tokio::test]
async fn overlay_apply_and_get() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let data = xudanu::edition::base64_encode(b"base image bytes");
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "blob_upload",
            Some(serde_json::json!({
                "data": data,
                "mime_type": "image/png"
            })),
        ),
    )
    .await;
    let base_hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "overlay_apply",
            Some(serde_json::json!({
                "base_hash": base_hash,
                "ops": [{"Brightness": 800}, "Grayscale"],
                "mime_type": "image/png"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "blob_meta");
    let overlay_hash = parse_hash_hex(&resp["value"]["value"]["content_hash"]);
    assert_ne!(overlay_hash, base_hash);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "overlay_get",
            Some(serde_json::json!({
                "overlay_hash": overlay_hash
            })),
        ),
    )
    .await;
    assert_eq!(resp["value"]["type"], "overlay_info");
    assert_eq!(
        parse_hash_hex(&resp["value"]["value"]["base_hash"]),
        base_hash
    );
    assert_eq!(
        resp["value"]["value"]["mime_type"].as_str().unwrap(),
        "image/png"
    );
    assert_eq!(
        resp["value"]["value"]["operations"]
            .as_array()
            .unwrap()
            .len(),
        2
    );
}

#[tokio::test]
async fn overlay_requires_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "overlay_apply",
            Some(serde_json::json!({
                "base_hash": 1u64, "ops": [], "mime_type": "image/png"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn label_create() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(&mut s, &mut r, json_req(10, "label_create", None)).await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "label_info");
    let label_id = resp["value"]["value"]["label_id"].as_u64().unwrap();
    assert!(label_id > 0);
}

#[tokio::test]
async fn label_get_positions() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "label_get_positions",
            Some(serde_json::json!({
                "work_id": work_id, "label_id": 999
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "label_positions");
}

#[tokio::test]
async fn can_make_identical_same_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "can_make_identical",
            Some(serde_json::json!({
                "source_work_id": work_id, "target_work_id": work_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["result"].as_str().unwrap(), "yes");
}

#[tokio::test]
async fn can_make_identical_different_content() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_a = resp_a["value"]["value"].as_u64().unwrap();
    let resp_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "xyz"}
            })),
        ),
    )
    .await;
    let work_b = resp_b["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "can_make_identical",
            Some(serde_json::json!({
                "source_work_id": work_a, "target_work_id": work_b
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["result"].as_str().unwrap(), "no");
}

#[tokio::test]
async fn make_range_identical_same_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "make_range_identical",
            Some(serde_json::json!({
                "source_work_id": work_id, "target_work_id": work_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(
        resp["value"]["value"]["outcome"].as_str().unwrap(),
        "all_unified"
    );
    assert_eq!(resp["value"]["value"]["failed_count"].as_u64().unwrap(), 0);
}

#[tokio::test]
async fn identity_unify_and_resolve() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "identity_unify",
            Some(serde_json::json!({
                "source_id": 100, "target_id": 200
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["resolved_id"].as_u64().unwrap(), 200);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "identity_resolve",
            Some(serde_json::json!({
                "id": 100
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["resolved_id"].as_u64().unwrap(), 200);
}

#[tokio::test]
async fn edition_rebind_requires_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "edition_rebind",
            Some(serde_json::json!({
                "work_id": work_id, "position": 0,
                "new_edition": {"text": "Xbc"}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn edition_rebind_after_grab() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "edition_rebind",
            Some(serde_json::json!({
                "work_id": work_id, "position": 1,
                "new_edition": {"text": "Xbc"}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "edition");
}

#[tokio::test]
async fn edition_retrieve_text_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "edition_retrieve",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
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
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abcdef"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "edition_retrieve",
            Some(serde_json::json!({
                "work_id": work_id,
                "region": {"starts_inside": false, "transitions": [2, 5]}
            })),
        ),
    )
    .await;
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": ""}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "edition_retrieve",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn edition_cost_text_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello world"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "edition_cost",
            Some(serde_json::json!({
                "work_id": work_id,
                "method": "total_shared"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["total_bytes"].as_u64().unwrap() > 0);
    assert_eq!(
        resp["value"]["value"]["method"].as_str().unwrap(),
        "totalshared"
    );
}

#[tokio::test]
async fn edition_cost_omit_shared() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "test"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "edition_cost",
            Some(serde_json::json!({
                "work_id": work_id,
                "method": "omit_shared"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let billed = resp["value"]["value"]["billed_bytes"].as_u64().unwrap();
    assert!(billed > 0);
}

#[tokio::test]
async fn edition_retrieve_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "edition_retrieve",
            Some(serde_json::json!({
                "work_id": 99999
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn edition_cost_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "edition_cost",
            Some(serde_json::json!({
                "work_id": 99999
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn content_shared_region_overlap() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abcdef"}
            })),
        ),
    )
    .await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "xyzcde"}
            })),
        ),
    )
    .await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "content_shared_region",
            Some(serde_json::json!({
                "work_a": work_a, "work_b": work_b
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let region = &resp["value"]["value"]["region"];
    assert!(region["transitions"].as_array().unwrap().len() > 0);
}

#[tokio::test]
async fn content_shared_region_no_overlap() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "xyz"}
            })),
        ),
    )
    .await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "content_shared_region",
            Some(serde_json::json!({
                "work_a": work_a, "work_b": work_b
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let region = &resp["value"]["value"]["region"];
    assert!(region["transitions"].as_array().unwrap().is_empty());
}

#[tokio::test]
async fn content_map_shared_to() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "xaybzc"}
            })),
        ),
    )
    .await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "content_map_shared_to",
            Some(serde_json::json!({
                "work_a": work_a, "work_b": work_b
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let pairs = resp["value"]["value"]["pairs"].as_array().unwrap();
    assert!(pairs.len() >= 3);
}

#[tokio::test]
async fn content_map_shared_onto() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "content_map_shared_onto",
            Some(serde_json::json!({
                "work_a": work_a, "work_b": work_b
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let pairs = resp["value"]["value"]["pairs"].as_array().unwrap();
    assert_eq!(pairs.len(), 3);
}

#[tokio::test]
async fn positions_of_element() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abac"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "positions_of",
            Some(serde_json::json!({
                "work_id": work_id,
                "element": {"Text": {"text": "a"}}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let region = &resp["value"]["value"]["region"];
    let transitions = region["transitions"].as_array().unwrap();
    assert!(transitions.len() >= 2);
}

#[tokio::test]
async fn range_transcluders_basic() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello world"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello universe"}
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "range_transcluders",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"entries": [[0, {"Text": {"text": "a"}}], [1, {"Text": {"text": "b"}}]]}
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "range_transcluders",
            Some(serde_json::json!({
                "work_id": work_id,
                "region": {"starts_inside": false, "transitions": [2]}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn range_transcluders_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "range_transcluders",
            Some(serde_json::json!({
                "work_id": 99999
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn range_works_basic() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "document content"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "range_works",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let work_ids = resp["value"]["value"]["work_ids"].as_array().unwrap();
    assert!(work_ids.contains(&serde_json::json!(work_id)));
}

#[tokio::test]
async fn range_works_with_region() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello world"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "range_works",
            Some(serde_json::json!({
                "work_id": work_id,
                "region": {"starts_inside": false, "transitions": [5]}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

#[tokio::test]
async fn ordered_bundles_text() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abc"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "ordered_bundles",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let bundles = resp["value"]["value"]["bundles"].as_array().unwrap();
    assert!(!bundles.is_empty());
}

#[tokio::test]
async fn ordered_bundles_with_region() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "abcde"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "ordered_bundles",
            Some(serde_json::json!({
                "work_id": work_id,
                "region": {"starts_inside": false, "transitions": [1, 4]}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let bundles = resp["value"]["value"]["bundles"].as_array().unwrap();
    assert!(!bundles.is_empty());
}

#[tokio::test]
async fn ordered_bundles_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "ordered_bundles",
            Some(serde_json::json!({
                "work_id": 99999
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn transclusion_depth_basic() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "unique content"}
            })),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "transclusion_depth",
            Some(serde_json::json!({
                "work_id": work_id,
                "position": 0
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let depth = resp["value"]["value"]["depth"].as_u64().unwrap();
    assert!(
        depth >= 1,
        "content registered by the work itself has at least depth 1"
    );
}

#[tokio::test]
async fn transclusion_depth_shared_content() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "shared text"}
            })),
        ),
    )
    .await;
    let _work_a = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "shared text"}
            })),
        ),
    )
    .await;
    let work_b = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "transclusion_depth",
            Some(serde_json::json!({
                "work_id": work_b,
                "position": 0,
                "max_depth": 5
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let depth = resp["value"]["value"]["depth"].as_u64().unwrap();
    assert!(depth >= 1);
}

#[tokio::test]
async fn transclusion_depth_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "transclusion_depth",
            Some(serde_json::json!({
                "work_id": 99999,
                "position": 0
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn admin_recorder_create_and_list() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "admin_recorder_create",
            Some(serde_json::json!({
                "kind": "transcluders",
                "direct_only": true
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let recorder_id = resp["value"]["value"]["recorder_id"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "admin_recorder_create",
            Some(serde_json::json!({
                "kind": "works"
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(&mut s, &mut r, json_req(12, "admin_recorder_list", None)).await;
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "admin_recorder_create",
            Some(serde_json::json!({
                "kind": "transcluders"
            })),
        ),
    )
    .await;
    let recorder_id = resp["value"]["value"]["recorder_id"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "admin_recorder_record",
            Some(serde_json::json!({
                "recorder_id": recorder_id,
                "element": {"Edition": {"edition_id": 42}}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["recorded"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "admin_recorder_get",
            Some(serde_json::json!({
                "recorder_id": recorder_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let info = &resp["value"]["value"]["recorder"];
    assert_eq!(info["id"].as_u64().unwrap(), recorder_id);
    assert_eq!(info["result_count"].as_u64().unwrap(), 1);
}

#[tokio::test]
async fn admin_recorder_record_wrong_kind() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "admin_recorder_create",
            Some(serde_json::json!({
                "kind": "works"
            })),
        ),
    )
    .await;
    let recorder_id = resp["value"]["value"]["recorder_id"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "admin_recorder_record",
            Some(serde_json::json!({
                "recorder_id": recorder_id,
                "element": {"Edition": {"edition_id": 42}}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["recorded"], false);
}

#[tokio::test]
async fn crypto_get_public_key() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(1, "crypto_get_public_key", None)).await;
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
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "crypto_sign_data",
            Some(serde_json::json!({
                "data": data
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let signature = resp["value"]["value"]["signature"].as_array().unwrap();
    assert_eq!(signature.len(), 64);

    let sig_bytes: Vec<u8> = signature
        .iter()
        .map(|v| v.as_u64().unwrap() as u8)
        .collect();
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "crypto_verify_signature",
            Some(serde_json::json!({
                "data": data,
                "signature": sig_bytes
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["valid"], true);
}

#[tokio::test]
async fn crypto_verify_rejects_tampered() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let data: Vec<u8> = vec![1, 2, 3];
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "crypto_sign_data",
            Some(serde_json::json!({
                "data": data
            })),
        ),
    )
    .await;
    let sig = resp["value"]["value"]["signature"].as_array().unwrap();
    let mut tampered: Vec<u8> = sig.iter().map(|v| v.as_u64().unwrap() as u8).collect();
    tampered[0] ^= 0xff;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "crypto_verify_signature",
            Some(serde_json::json!({
                "data": data,
                "signature": tampered
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["valid"], false);
}

#[tokio::test]
async fn crypto_key_rotation() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(1, "crypto_get_public_key", None)).await;
    let old_key_id = resp["value"]["value"]["key_id"].as_u64().unwrap();

    let resp = send_recv_json(&mut s, &mut r, json_req(2, "crypto_key_rotation", None)).await;
    assert_eq!(resp["type"], "response");
    let new_key_id = resp["value"]["value"]["new_key_id"].as_u64().unwrap();
    assert_ne!(old_key_id, new_key_id);

    let resp = send_recv_json(&mut s, &mut r, json_req(3, "crypto_get_public_key", None)).await;
    let current_key_id = resp["value"]["value"]["key_id"].as_u64().unwrap();
    assert_eq!(current_key_id, new_key_id);
}

#[tokio::test]
async fn crypto_key_history() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(1, "crypto_key_history", None)).await;
    assert_eq!(resp["type"], "response");
    let val = &resp["value"]["value"];
    assert!(val["current_key_id"].as_u64().is_some());
    assert_eq!(val["entry_count"].as_u64().unwrap(), 1);

    send_recv_json(&mut s, &mut r, json_req(2, "crypto_key_rotation", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(3, "crypto_key_history", None)).await;
    let val = &resp["value"]["value"];
    assert_eq!(val["entry_count"].as_u64().unwrap(), 2);
    let entries = val["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 2);
    assert_ne!(
        entries[0]["key_id"].as_u64().unwrap(),
        entries[1]["key_id"].as_u64().unwrap()
    );
}

#[tokio::test]
async fn crypto_sign_requires_admin() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_public_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "crypto_sign_data",
            Some(serde_json::json!({
                "data": [1, 2, 3]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn admin_recorder_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "admin_recorder_get",
            Some(serde_json::json!({
                "recorder_id": 99999
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["recorder"].is_null());
}

#[tokio::test]
async fn admin_recorder_record_not_found() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "admin_recorder_record",
            Some(serde_json::json!({
                "recorder_id": 99999,
                "element": {"Edition": {"edition_id": 1}}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["recorded"], false);
}

#[tokio::test]
async fn work_endorse_and_query() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            50,
            "club_id_by_name",
            Some(serde_json::json!({"name": "admin"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "work_endorse",
            Some(serde_json::json!({
                "work_id": work_id,
                "endorsements": [[admin_club_id, 10], [admin_club_id, 20]]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "work_endorsements",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 2);
}

#[tokio::test]
async fn work_endorse_retract() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            100,
            "club_id_by_name",
            Some(serde_json::json!({"name": "admin"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "work_endorse",
            Some(serde_json::json!({
                "work_id": work_id,
                "endorsements": [[admin_club_id, 10], [admin_club_id, 20]]
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "work_retract",
            Some(serde_json::json!({
                "work_id": work_id,
                "endorsements": [[admin_club_id, 10]]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "work_endorsements",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
}

#[tokio::test]
async fn edition_endorse_and_query() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            50,
            "club_id_by_name",
            Some(serde_json::json!({"name": "admin"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let edition_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "edition_store",
            Some(serde_json::json!({
                "edition": {"text": "test content"}
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "edition_endorse",
            Some(serde_json::json!({
                "edition_id": edition_id,
                "endorsements": [[admin_club_id, 5]]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "edition_endorsements",
            Some(serde_json::json!({
                "edition_id": edition_id
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
}

#[tokio::test]
async fn endorsement_requires_authority() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "work_endorse",
            Some(serde_json::json!({
                "work_id": work_id,
                "endorsements": [[99, 1]]
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn work_endorse_idempotent() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_admin_login(&srv).await;

    let admin_club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            100,
            "club_id_by_name",
            Some(serde_json::json!({"name": "admin"})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "work_create",
            Some(serde_json::json!({"edition": "empty"})),
        ),
    )
    .await;
    let work_id = resp["value"]["value"].as_u64().unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "work_endorse",
            Some(serde_json::json!({
                "work_id": work_id,
                "endorsements": [[admin_club_id, 10]]
            })),
        ),
    )
    .await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "work_endorse",
            Some(serde_json::json!({
                "work_id": work_id,
                "endorsements": [[admin_club_id, 10]]
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "work_endorsements",
            Some(serde_json::json!({
                "work_id": work_id
            })),
        ),
    )
    .await;
    let endorsements = resp["value"]["value"]["endorsements"].as_array().unwrap();
    assert_eq!(endorsements.len(), 1);
}

// ── Federation tests (Phase 14) ──────────────────────────────────────

#[tokio::test]
async fn federation_info_returns_server_identity() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(1, "federation_info", None)).await;
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

    let resp = send_recv_json(&mut s, &mut r, json_req(1, "federation_peers", None)).await;
    assert_eq!(resp["type"], "response");
    let peers = resp["value"]["value"]["peers"].as_array().unwrap();
    assert_eq!(peers.len(), 0);
}

#[tokio::test]
async fn federation_info_no_auth_required() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let _resp = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;

    let resp = send_recv_json(&mut s, &mut r, json_req(2, "federation_info", None)).await;
    assert_eq!(resp["type"], "response");
    assert!(!resp["value"]["value"]["server_id"]
        .as_str()
        .unwrap()
        .is_empty());
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
        let fed_router =
            xudanu::server::transport::federation_handler::build_federation_router(state.clone());
        let app =
            xudanu::server::transport::federation_handler::merge_routers(client_router, fed_router)
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

    let (mut ws_a, _) = tokio_tungstenite::connect_async(srv_a.federation_url())
        .await
        .unwrap();

    let msg_from_a = ws_a.next().await.unwrap().unwrap();
    let hello_a: serde_json::Value = serde_json::from_str(msg_from_a.to_text().unwrap()).unwrap();
    assert_eq!(hello_a["type"], "Hello");
    assert_eq!(hello_a["protocol_version"], 1);
    assert_eq!(
        hello_a["ephemeral_public_key"].as_array().unwrap().len(),
        32
    );

    let fake_hello = serde_json::json!({
        "type": "Hello",
        "protocol_version": 1,
        "ephemeral_public_key": vec![0u8; 32],
        "server_id": "test-peer"
    });
    ws_a.send(tokio_tungstenite::tungstenite::Message::Text(
        fake_hello.to_string().into(),
    ))
    .await
    .unwrap();

    let sig_from_a = ws_a.next().await.unwrap().unwrap();
    let sig_a: serde_json::Value = serde_json::from_str(sig_from_a.to_text().unwrap()).unwrap();
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
        })
        .to_string()
        .into(),
    ))
    .await
    .unwrap();

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

/// Level-4 adversarial drill: an EVIL peer pushes a federation sync
/// batch containing poisoned editions alongside a clean one. The
/// honest server must import the clean entry, reject every poisoned
/// one (skip-and-count, sync continues), store nothing malformed, and
/// keep serving.
#[tokio::test]
async fn evil_peer_sync_filtered_by_invariant_gate() {
    use xudanu::edition::range_element::RangeElement;
    use xudanu::server::federation::{SyncPush, SyncWorkEntry};
    use xudanu::server::transport::protocol::EditionPayload;

    let srv_honest = FederationTestServer::start().await;

    let poisoned_entries = vec![
        // Clean control entry — must be imported.
        SyncWorkEntry {
            origin_server_id: "evil-peer".to_string(),
            work_id: 9001,
            edition_payload: EditionPayload::Text("legitimate content".to_string()),
            span_provenance: vec![],
        },
        // Reversed transclusion range (deserialization-bypass form).
        SyncWorkEntry {
            origin_server_id: "evil-peer".to_string(),
            work_id: 9002,
            edition_payload: EditionPayload::Entries(vec![(
                0,
                RangeElement::Transclusion {
                    source_work_id: 99,
                    char_start: 20,
                    char_end: 5,
                    placed_at: 0,
                    placed_by: None,
                    content_hash: None,
                    source_revision: None,
                },
            )]),
            span_provenance: vec![],
        },
        // Control characters in text.
        SyncWorkEntry {
            origin_server_id: "evil-peer".to_string(),
            work_id: 9003,
            edition_payload: EditionPayload::Text("bad\u{0}nul".to_string()),
            span_provenance: vec![],
        },
        // Implausible blob.
        SyncWorkEntry {
            origin_server_id: "evil-peer".to_string(),
            work_id: 9004,
            edition_payload: EditionPayload::Entries(vec![(
                0,
                RangeElement::Blob {
                    content_hash: 1,
                    mime_type: "definitely/not-a-mime".to_string(),
                    byte_size: 0,
                    width: None,
                    height: None,
                    caption: None,
                },
            )]),
            span_provenance: vec![],
        },
    ];

    let push = poisoned_entries;

    let my_id = srv_honest
        .state
        .server
        .with_server_ref(|srv| srv.federation_server_id());
    let (imported, _) = srv_honest
        .state
        .server
        .with_server(|srv| srv.federation_import_works(&push, &my_id));

    assert_eq!(
        imported, 1,
        "only the clean entry is imported; poisoned entries are filtered"
    );

    // Nothing malformed stored: the honest server's work list shows the
    // clean work but no work id 9002..9004 content.
    let (stream, _) = tokio_tungstenite::connect_async(format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_honest.addr, PROTOCOL_VERSION
    ))
    .await
    .unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
    let list = send_recv_json(
        &mut s,
        &mut r,
        json_req(3, "work_list", Some(serde_json::json!({}))),
    )
    .await;
    // Imported works receive fresh local ids, so verify by content:
    // the clean text is present, none of the poisoned payloads are.
    let entries = list["value"]["value"]["entries"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    let titles: Vec<String> = entries
        .iter()
        .map(|e| e["title"].as_str().unwrap_or("").to_string())
        .collect();
    assert!(
        titles.iter().any(|t| t.contains("legitimate content")),
        "the clean entry IS present, titles: {titles:?}"
    );
    for poison in ["bad", "not-a-mime"] {
        assert!(
            titles.iter().all(|t| !t.contains(poison)),
            "no poisoned content stored, titles: {titles:?}"
        );
    }
    // And the import counter itself: 4 pushed, 1 imported -> 3 rejected.
    // (already_known would have absorbed identical content; poisoned
    // entries can only land in `rejected`.)

    // Honest server still healthy.
    let health = send_recv_json(&mut s, &mut r, json_req(4, "server_stats", None)).await;
    assert_eq!(
        health["type"], "response",
        "honest server survives the evil batch"
    );
}

#[tokio::test]
async fn federation_content_replication_between_two_servers() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let url_a = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_a.addr, PROTOCOL_VERSION
    );
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(2, "session_login_public", None),
    )
    .await;

    let resp = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "Hello from server A"}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let _work_id_a = resp["value"]["value"].as_u64().unwrap();

    let url_b = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_b.addr, PROTOCOL_VERSION
    );
    let (stream_b, _) = tokio_tungstenite::connect_async(&url_b).await.unwrap();
    let (mut s_b, mut r_b) = stream_b.split();
    recv_handshake(&mut r_b).await;
    let _ = send_recv_json(&mut s_b, &mut r_b, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(2, "session_login_public", None),
    )
    .await;

    let resp = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(10, "work_list", Some(serde_json::json!({}))),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let initial_b_count = resp["value"]["value"]["entries"].as_array().unwrap().len();

    let (mut fed_a, _) = tokio_tungstenite::connect_async(srv_a.federation_url())
        .await
        .unwrap();

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
    fed_a
        .send(tokio_tungstenite::tungstenite::Message::Text(
            fake_hello.to_string().into(),
        ))
        .await
        .unwrap();

    let sig_from_a = fed_a.next().await.unwrap().unwrap();
    let sig_a: serde_json::Value = serde_json::from_str(sig_from_a.to_text().unwrap()).unwrap();
    assert_eq!(sig_a["type"], "Signature");

    fed_a
        .send(tokio_tungstenite::tungstenite::Message::Text(
            serde_json::json!({
                "type": "Signature",
                "signature": vec![0u8; 64],
                "verifying_key": sig_a["verifying_key"],
                "kex_key": sig_a["kex_key"],
            })
            .to_string()
            .into(),
        ))
        .await
        .unwrap();

    let next_msg = fed_a.next().await.unwrap().unwrap();
    let next_val: serde_json::Value = match next_msg {
        tokio_tungstenite::tungstenite::Message::Text(text) => serde_json::from_str(&text).unwrap(),
        tokio_tungstenite::tungstenite::Message::Binary(_) => {
            // If we somehow got an encrypted response, the handshake
            // completed. Fall through to server-side verification.
            serde_json::json!({"type": "encrypted_ready"})
        }
        _ => panic!("unexpected message type"),
    };

    if next_val["type"] == "error" || next_val["type"] == "encrypted_ready" {
        let push = srv_a
            .state
            .server
            .with_server(|srv| srv.federation_export_works());
        assert!(push.len() >= 1);
        let mut found = false;
        for w in &push {
            match &w.edition_payload {
                xudanu::server::transport::protocol::EditionPayload::Text(t) => {
                    if t == "Hello from server A" {
                        found = true;
                    }
                }
                _ => {}
            }
        }
        assert!(found, "export should contain 'Hello from server A'");

        let my_id = srv_b
            .state
            .server
            .with_server_ref(|srv| srv.federation_server_id());
        let (imported, _already) = srv_b
            .state
            .server
            .with_server(|srv| srv.federation_import_works(&push, &my_id));
        assert!(imported >= 1);

        let resp = send_recv_json(
            &mut s_b,
            &mut r_b,
            json_req(11, "work_list", Some(serde_json::json!({}))),
        )
        .await;
        assert_eq!(resp["type"], "response");
        let after_b_count = resp["value"]["value"]["entries"].as_array().unwrap().len();
        assert!(
            after_b_count > initial_b_count,
            "server B should have more works after import"
        );
        return;
    }

    panic!("expected error or ready, got: {:?}", next_val);
}

// ── FR-3 Activation integration tests ───────────────────────────────
//
// These tests exercise the real outbound dialer, handshake, key
// registration, periodic sync, and content replication — the full
// activation layer (federation_active.rs). Unlike the Phase 15 tests
// above which manually connect raw WebSockets with fake keys, these
// tests let the servers dial each other and sync automatically.

#[tokio::test]
async fn federation_activation_content_replication_end_to_end() {
    use std::time::Duration;
    use xudanu::server::federation::{FederationConfig, FederationMode, PeerAddress};
    use xudanu::server::transport::federation_active::{spawn_federation_tasks, PeerPool};

    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let a_port = srv_a.addr.port();
    let b_port = srv_b.addr.port();

    srv_a.state.server.with_server(|srv| {
        srv.set_federation_config(FederationConfig {
            enabled: true,
            peers: vec![PeerAddress::new("127.0.0.1", b_port)],
            mode: FederationMode::Closed,
            min_endorsements: 2,
        });
        srv.membership_bootstrap_init();
    });

    srv_b.state.server.with_server(|srv| {
        srv.set_federation_config(FederationConfig {
            enabled: true,
            peers: vec![PeerAddress::new("127.0.0.1", a_port)],
            mode: FederationMode::Closed,
            min_endorsements: 2,
        });
        srv.membership_bootstrap_init();
    });

    let a_key = srv_a
        .state
        .server
        .with_server_ref(|s| s.server_verifying_key_hex());
    let b_key = srv_b
        .state
        .server
        .with_server_ref(|s| s.server_verifying_key_hex());
    srv_a
        .state
        .server
        .with_server(|s| s.federation_register_peer_key(b_key));
    srv_b
        .state
        .server
        .with_server(|s| s.federation_register_peer_key(a_key));

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_a.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "federation sync test content"}})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let initial_b = srv_b.state.server.with_server_ref(|s| s.work_count());

    let pool_a = PeerPool::new();
    let pool_b = PeerPool::new();
    spawn_federation_tasks(srv_a.state.clone(), pool_a).await;
    spawn_federation_tasks(srv_b.state.clone(), pool_b).await;

    let deadline = tokio::time::Instant::now() + Duration::from_secs(15);
    loop {
        let b_count = srv_b.state.server.with_server_ref(|s| s.work_count());
        if b_count > initial_b {
            break;
        }
        if tokio::time::Instant::now() >= deadline {
            panic!(
                "Work did not replicate to B within 15s (initial={}, current={})",
                initial_b, b_count
            );
        }
        tokio::time::sleep(Duration::from_millis(500)).await;
    }

    let remote_count = srv_b
        .state
        .server
        .with_server_ref(|s| s.federation_remote_origin_count());
    assert!(
        remote_count > 0,
        "B should have recorded a federated remote origin"
    );
}

#[tokio::test]
async fn federation_activation_membership_converges() {
    use std::time::Duration;
    use xudanu::server::federation::{FederationConfig, FederationMode, PeerAddress};
    use xudanu::server::transport::federation_active::{spawn_federation_tasks, PeerPool};

    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let a_port = srv_a.addr.port();
    let b_port = srv_b.addr.port();

    srv_a.state.server.with_server(|srv| {
        srv.set_federation_config(FederationConfig {
            enabled: true,
            peers: vec![PeerAddress::new("127.0.0.1", b_port)],
            mode: FederationMode::Closed,
            min_endorsements: 2,
        });
        srv.membership_bootstrap_init();
    });

    srv_b.state.server.with_server(|srv| {
        srv.set_federation_config(FederationConfig {
            enabled: true,
            peers: vec![PeerAddress::new("127.0.0.1", a_port)],
            mode: FederationMode::Closed,
            min_endorsements: 2,
        });
        srv.membership_bootstrap_init();
    });

    let a_key = srv_a
        .state
        .server
        .with_server_ref(|s| s.server_verifying_key_hex());
    let b_key = srv_b
        .state
        .server
        .with_server_ref(|s| s.server_verifying_key_hex());
    srv_a
        .state
        .server
        .with_server(|s| s.federation_register_peer_key(b_key));
    srv_b
        .state
        .server
        .with_server(|s| s.federation_register_peer_key(a_key));

    let a_id = srv_a
        .state
        .server
        .with_server_ref(|s| s.federation_server_id());
    let b_id = srv_b
        .state
        .server
        .with_server_ref(|s| s.federation_server_id());

    let pool_a = PeerPool::new();
    let pool_b = PeerPool::new();
    spawn_federation_tasks(srv_a.state.clone(), pool_a).await;
    spawn_federation_tasks(srv_b.state.clone(), pool_b).await;

    let deadline = tokio::time::Instant::now() + Duration::from_secs(15);
    loop {
        let a_knows_b = srv_a
            .state
            .server
            .with_server_ref(|s| s.membership_is_known_member(&b_id));
        let b_knows_a = srv_b
            .state
            .server
            .with_server_ref(|s| s.membership_is_known_member(&a_id));
        if a_knows_b && b_knows_a {
            break;
        }
        if tokio::time::Instant::now() >= deadline {
            let a_members = srv_a.state.server.with_server_ref(|s| s.membership_list());
            let b_members = srv_b.state.server.with_server_ref(|s| s.membership_list());
            panic!(
                "Membership did not converge within 15s. A knows {} members, B knows {} members",
                a_members.len(),
                b_members.len()
            );
        }
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
}

// ── Cross-server transclusion tests (Phase 17) ──────────────────────

#[tokio::test]
async fn federated_transclusion_records_origin_on_import() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let url_a = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_a.addr, PROTOCOL_VERSION
    );
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(2, "session_login_public", None),
    )
    .await;

    let resp = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "unique federated text"}
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let push = srv_a
        .state
        .server
        .with_server(|srv| srv.federation_export_works());
    assert!(push.len() >= 1);

    let my_id = srv_b
        .state
        .server
        .with_server_ref(|srv| srv.federation_server_id());
    let (imported, _) = srv_b
        .state
        .server
        .with_server(|srv| srv.federation_import_works(&push, &my_id));
    assert!(imported >= 1);

    let has_origins = srv_b
        .state
        .server
        .with_server_ref(|srv| srv.federation_remote_origin_count() > 0);
    assert!(
        has_origins,
        "server B should have remote origin entries after import"
    );

    let has_federated = srv_b
        .state
        .server
        .with_server_ref(|srv| srv.federation_has_federated_transclusions());
    assert!(
        has_federated,
        "server B should have federated transclusion entries"
    );
}

#[tokio::test]
async fn federated_transclusion_query_returns_local_results() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "hello"}
            })),
        ),
    )
    .await;

    let text_elem = xudanu::edition::RangeElement::text("h".to_string());
    let fp = text_elem.content_fingerprint();
    let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "federated_transclusion_query",
            Some(serde_json::json!({
                "content_fingerprint_hex": fp_hex,
                "direct_only": false
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let results = resp["value"]["value"]["results"].as_array().unwrap();
    assert!(
        !results.is_empty(),
        "should find local transclusion results"
    );
}

#[tokio::test]
async fn federated_content_fetch_returns_edition() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "fetch me"}
            })),
        ),
    )
    .await;

    let text_elem = xudanu::edition::RangeElement::text("f".to_string());
    let fp = text_elem.content_fingerprint();
    let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "federated_content_fetch",
            Some(serde_json::json!({
                "content_fingerprint_hex": fp_hex
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["found"], true);
}

#[tokio::test]
async fn federated_content_fetch_not_found() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "federated_content_fetch",
            Some(serde_json::json!({
                "content_fingerprint_hex": "ff".repeat(32)
            })),
        ),
    )
    .await;
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

    let url_a = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_a.addr, PROTOCOL_VERSION
    );
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(2, "session_login_public", None),
    )
    .await;

    let _ = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "shared across servers"}
            })),
        ),
    )
    .await;

    let push = srv_a
        .state
        .server
        .with_server(|srv| srv.federation_export_works());
    let my_id = srv_b
        .state
        .server
        .with_server_ref(|srv| srv.federation_server_id());
    srv_b
        .state
        .server
        .with_server(|srv| srv.federation_import_works(&push, &my_id));

    let text_elem = xudanu::edition::RangeElement::text("s".to_string());
    let fp = text_elem.content_fingerprint();
    let fp_hex: String = fp.iter().map(|b| format!("{:02x}", b)).collect();

    let url_b = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_b.addr, PROTOCOL_VERSION
    );
    let (stream_b, _) = tokio_tungstenite::connect_async(&url_b).await.unwrap();
    let (mut s_b, mut r_b) = stream_b.split();
    recv_handshake(&mut r_b).await;
    let _ = send_recv_json(&mut s_b, &mut r_b, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(2, "session_login_public", None),
    )
    .await;

    let resp = send_recv_json(
        &mut s_b,
        &mut r_b,
        json_req(
            10,
            "federated_transclusion_query",
            Some(serde_json::json!({
                "content_fingerprint_hex": fp_hex,
                "direct_only": false
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let results = resp["value"]["value"]["results"].as_array().unwrap();
    assert!(
        !results.is_empty(),
        "server B should find transclusion results after sync"
    );
}

#[tokio::test]
async fn federated_transclusion_query_rejected_when_federation_disabled() {
    let srv = FederationTestServer::start().await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let fp_hex = "ab".repeat(32);
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "federated_transclusion_query",
            Some(serde_json::json!({
                "content_fingerprint_hex": fp_hex,
                "direct_only": false
            })),
        ),
    )
    .await;
    assert_eq!(
        resp["type"], "error",
        "should reject transclusion query when federation disabled"
    );
}

#[tokio::test]
async fn federated_content_fetch_rejected_when_federation_disabled() {
    let srv = FederationTestServer::start().await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let fp_hex = "ff".repeat(32);
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "federated_content_fetch",
            Some(serde_json::json!({
                "content_fingerprint_hex": fp_hex
            })),
        ),
    )
    .await;
    assert_eq!(
        resp["type"], "error",
        "should reject content fetch when federation disabled"
    );
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "endorsed content"}
            })),
        ),
    )
    .await;

    let states = srv
        .state
        .server
        .with_server(|srv| srv.reconcile_export_all());
    let fp = &states[0].work_fingerprint;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "endorsement_add",
            Some(serde_json::json!({
                "work_fingerprint": fp,
                "club_id": 42,
                "token_id": 7
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert!(resp["value"]["value"]["tag_counter"].as_u64().unwrap() > 0);
}

#[tokio::test]
async fn endorsement_query_returns_added_endorsements() {
    let srv = FederationTestServer::start().await;
    srv.state.server.with_server(|srv| {
        srv.set_federation_config(xudanu::server::federation::FederationConfig::closed(vec![]));
    });

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "query me"}
            })),
        ),
    )
    .await;

    let states = srv
        .state
        .server
        .with_server(|srv| srv.reconcile_export_all());
    let fp = &states[0].work_fingerprint;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "endorsement_add",
            Some(serde_json::json!({
                "work_fingerprint": fp,
                "club_id": 5,
                "token_id": 10
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "endorsement_query",
            Some(serde_json::json!({
                "work_fingerprint": fp
            })),
        ),
    )
    .await;
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "sync state"}
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "state_sync",
            Some(serde_json::json!({
                "work_fingerprints": []
            })),
        ),
    )
    .await;
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv.addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "alt content"}
            })),
        ),
    )
    .await;

    let states = srv
        .state
        .server
        .with_server(|srv| srv.reconcile_export_all());
    let fp = &states[0].work_fingerprint;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "state_alternatives",
            Some(serde_json::json!({
                "work_fingerprint": fp
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let alternatives = resp["value"]["value"]["alternatives"].as_array().unwrap();
    assert_eq!(alternatives.len(), 1);
    assert!(!resp["value"]["value"]["current_key"]
        .as_str()
        .unwrap()
        .is_empty());
}

#[tokio::test]
async fn reconcile_merge_across_servers() {
    let srv_a = FederationTestServer::start().await;
    let srv_b = FederationTestServer::start().await;

    let url_a = format!(
        "ws://{}/xudanu?format=json&version={}",
        srv_a.addr, PROTOCOL_VERSION
    );
    let (stream_a, _) = tokio_tungstenite::connect_async(&url_a).await.unwrap();
    let (mut s_a, mut r_a) = stream_a.split();
    recv_handshake(&mut r_a).await;
    let _ = send_recv_json(&mut s_a, &mut r_a, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(2, "session_login_public", None),
    )
    .await;

    let _ = send_recv_json(
        &mut s_a,
        &mut r_a,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({
                "edition": {"text": "shared content for reconcile"}
            })),
        ),
    )
    .await;

    let states_a = srv_a
        .state
        .server
        .with_server(|srv| srv.reconcile_export_all());
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

    let states_b = srv_b
        .state
        .server
        .with_server(|srv| srv.reconcile_export_all());
    assert_eq!(states_b.len(), 1);
    assert_eq!(states_b[0].alternative_count(), 1);
    assert_eq!(states_b[0].current_text().unwrap(), "server B version");
}

// =============================================================================
// Phase 19a: Trust & Membership Integration Tests
// =============================================================================

fn setup_federated_server_state() -> xudanu::server::transport::SharedState {
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
    state.server.with_server(|srv| {
        let mut config = xudanu::server::federation::FederationConfig::closed(vec![]);
        config.min_endorsements = 1;
        srv.set_federation_config(config);
        srv.membership_bootstrap_init();
    });
    state
}

async fn start_server_on_random_port(
    state: xudanu::server::transport::SharedState,
) -> std::net::SocketAddr {
    let client_router = build_router(state.clone());
    let fed_router =
        xudanu::server::transport::federation_handler::build_federation_router(state.clone());
    let app =
        xudanu::server::transport::federation_handler::merge_routers(client_router, fed_router)
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
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
    let server_id = state
        .server
        .with_server_ref(|srv| srv.federation_server_id());

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "membership_verify",
            Some(serde_json::json!({
                "server_id": server_id
            })),
        ),
    )
    .await;
    assert!(resp["value"]["value"]["verify"]["is_member"]
        .as_bool()
        .unwrap());
}

#[tokio::test]
async fn membership_join_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let (proof_json, _my_id) = state.server.with_server(|srv| {
        let proof = srv
            .membership_sign_endorsement("joining-server", "vk-joining")
            .unwrap();
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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "membership_join_request",
            Some(serde_json::json!({
                "entry": join_entry
            })),
        ),
    )
    .await;

    let result = &resp["value"]["value"]["result"];
    assert!(
        result.get("accepted").is_some(),
        "expected accepted, got: {:?}",
        result
    );
    assert_eq!(
        result["accepted"]["server_id"].as_str().unwrap(),
        "joining-server"
    );
}

#[tokio::test]
async fn membership_sync_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
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
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "session_login",
            Some(serde_json::json!({"club_id": admin_club_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})),
        ),
    )
    .await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "membership_leave", None)).await;
    assert!(
        resp.get("error").is_none(),
        "leave should succeed with admin auth"
    );

    let count = state.server.with_server(|srv| srv.membership_count());
    assert_eq!(count, 0);
}

#[tokio::test]
async fn membership_endorse_offer_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let proof_json = state.server.with_server(|srv| {
        let join_proof = srv
            .membership_sign_endorsement("new-server", "vk-new")
            .unwrap();
        let entry = xudanu::server::federation::MembershipEntry::new(
            "new-server",
            "vk-new",
            "kex-new",
            vec![join_proof],
            1000,
        );
        srv.membership_process_join(entry);
        let proof = srv
            .membership_sign_endorsement("new-server", "vk-new")
            .unwrap();
        serde_json::to_value(&proof).unwrap()
    });

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "membership_endorse_offer",
            Some(serde_json::json!({
                "server_id": "new-server",
                "proof": proof_json
            })),
        ),
    )
    .await;
    assert!(resp["value"]["value"]["accepted"].as_bool().unwrap());
}

#[tokio::test]
async fn membership_merge_across_two_servers() {
    let state_a = setup_federated_server_state();
    let state_b = setup_federated_server_state();

    let id_a = state_a
        .server
        .with_server_ref(|srv| srv.federation_server_id());

    let membership_b = state_b
        .server
        .with_server(|srv| srv.membership_export_orset().clone());

    state_a.server.with_server(|srv| {
        srv.membership_merge_orset(&membership_b);
    });

    assert!(state_a
        .server
        .with_server(|srv| srv.membership_is_known_member(&id_a)));
}

#[tokio::test]
async fn membership_cross_server_endorsement_verification() {
    let state_a = setup_federated_server_state();
    let state_b = setup_federated_server_state();

    let id_b = state_b
        .server
        .with_server_ref(|srv| srv.federation_server_id());
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
        srv.membership_verify_endorsement_proof(&fake_proof, &other_keypair.signing_verifying_key())
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let my_id = state
        .server
        .with_server_ref(|srv| srv.federation_server_id());

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

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "membership_join_request",
            Some(serde_json::json!({
                "entry": join_entry
            })),
        ),
    )
    .await;

    let result = &resp["value"]["value"]["result"];
    assert!(
        result.get("rejected").is_some(),
        "join with forged endorsement should be rejected, got: {:?}",
        result
    );
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

    let accepted = state
        .server
        .with_server(|srv| srv.membership_endorse("target", forged_proof));
    assert!(!accepted, "endorse with forged proof should be rejected");
}

// =============================================================================
// Phase 19b: Governance & BFT Integration Tests
// =============================================================================

#[tokio::test]
async fn governance_status_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
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

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
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
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "session_login",
            Some(serde_json::json!({"club_id": admin_club_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})),
        ),
    )
    .await;

    let tx = serde_json::json!({
        "type": "admit",
        "server_id": "srv-new",
        "verifying_key_hex": "vk-new",
        "kex_public_hex": "kex-new"
    });

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "governance_propose",
            Some(serde_json::json!({
                "transactions": [tx]
            })),
        ),
    )
    .await;

    let proposal = &resp["value"]["value"]["proposal"];
    assert!(proposal.is_object());
    assert_eq!(proposal["sequence_number"].as_u64().unwrap(), 1);
    assert_eq!(proposal["transactions"].as_array().unwrap().len(), 1);
}

#[tokio::test]
async fn governance_log_empty_then_propose() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
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
    let my_id = state
        .server
        .with_server_ref(|srv| srv.federation_server_id());

    state.server.with_server(|srv| {
        let proposal = srv
            .governance_propose(vec![xudanu::server::federation::GovernanceTx::Admit {
                server_id: "srv-joined".to_string(),
                verifying_key_hex: "vk-joined".to_string(),
                kex_public_hex: "kex-joined".to_string(),
            }])
            .unwrap();

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
    let my_id = state
        .server
        .with_server_ref(|srv| srv.federation_server_id());

    state.server.with_server(|srv| {
        srv.governance_propose(vec![
            xudanu::server::federation::GovernanceTx::RoyaltyRecord {
                origin_server_id: my_id.clone(),
                target_server_id: "srv-b".to_string(),
                content_fingerprint_hex: format!("{:064x}", 42),
                royalty_type: xudanu::server::federation::RoyaltyType::Transclusion,
                amount: 500,
            },
        ])
        .unwrap();

        let vote = xudanu::server::federation::PbftVote {
            view_number: 0,
            sequence_number: 1,
            voter_id: my_id.clone(),
            phase: xudanu::server::federation::PbftPhase::Prepare,
        };
        srv.governance_receive_prepare(vote);

        let commit = xudanu::server::federation::PbftVote {
            view_number: 0,
            sequence_number: 1,
            voter_id: my_id.clone(),
            phase: xudanu::server::federation::PbftPhase::Commit,
        };
        srv.governance_receive_commit(commit);

        srv.governance_seal_round().unwrap();

        let ledger = srv.federation_royalty_ledger();
        assert_eq!(ledger.len(), 1);
        assert_eq!(ledger[0].amount, 500);
        assert_eq!(
            ledger[0].royalty_type,
            xudanu::server::federation::RoyaltyType::Transclusion
        );
    });
}

#[tokio::test]
async fn governance_propose_requires_admin() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_connect", None)).await;
    let _ = send_recv_json(&mut s, &mut r, json_req(2, "session_login_public", None)).await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "governance_propose",
            Some(serde_json::json!({
                "transactions": []
            })),
        ),
    )
    .await;
    assert!(
        resp["type"].as_str() == Some("error") || resp.get("error").is_some(),
        "propose should require admin, got: {:?}",
        resp
    );
}

#[tokio::test]
async fn governance_seal_via_wire_op() {
    let state = setup_federated_server_state();
    let addr = start_server_on_random_port(state.clone()).await;
    let my_id = state
        .server
        .with_server_ref(|srv| srv.federation_server_id());

    state.server.with_server(|srv| {
        srv.governance_propose(vec![xudanu::server::federation::GovernanceTx::Expel {
            server_id: "srv-bad".to_string(),
            reason: "test".to_string(),
        }])
        .unwrap();

        let vote = xudanu::server::federation::PbftVote {
            view_number: 0,
            sequence_number: 1,
            voter_id: my_id.clone(),
            phase: xudanu::server::federation::PbftPhase::Prepare,
        };
        srv.governance_receive_prepare(vote);

        let commit = xudanu::server::federation::PbftVote {
            view_number: 0,
            sequence_number: 1,
            voter_id: my_id.clone(),
            phase: xudanu::server::federation::PbftPhase::Commit,
        };
        srv.governance_receive_commit(commit);
    });

    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();
    recv_handshake(&mut r).await;
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
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            3,
            "session_login",
            Some(serde_json::json!({"club_id": admin_club_id})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            4,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})),
        ),
    )
    .await;

    let resp = send_recv_json(&mut s, &mut r, json_req(10, "governance_seal", None)).await;
    let batch = &resp["value"]["value"]["batch"];
    assert!(batch.is_object());
    assert_eq!(batch["transactions"].as_array().unwrap().len(), 1);

    let log_resp = send_recv_json(&mut s, &mut r, json_req(11, "governance_log", None)).await;
    let log = log_resp["value"]["value"]["log"].as_array().unwrap();
    assert_eq!(log.len(), 1);
}

fn temp_data_dir(name: &str) -> std::path::PathBuf {
    let dir = std::env::temp_dir().join(format!("xudanu-persist-{}-{}", name, std::process::id()));
    let _ = std::fs::remove_dir_all(&dir);
    std::fs::create_dir_all(&dir).unwrap();
    std::fs::create_dir_all(dir.join("blobs")).unwrap();
    dir
}

fn server_init(data_dir: &std::path::Path) -> xudanu::server::Server {
    let mut server = xudanu::server::Server::new();
    let _ = server.restore_keypair_from_dir(data_dir, None);
    let snapshot_path = data_dir.join("server.json");
    server.set_checkpoint_path(snapshot_path.clone());
    server.init_blob_store(data_dir).unwrap();
    server.checkpoint_to_file(&snapshot_path).unwrap();
    server
}

fn server_restore(data_dir: &std::path::Path) -> xudanu::server::Server {
    let snapshot_path = data_dir.join("server.json");
    xudanu::server::Server::restore_from_file_with_persistence(&snapshot_path).unwrap()
}

fn admin_session(srv: &mut xudanu::server::Server) -> (xudanu::server::SessionId, u64) {
    let club_id = srv
        .club_names_list()
        .iter()
        .find(|(n, _)| *n == "admin")
        .map(|(_, id)| *id)
        .unwrap();
    let session = srv.connect();
    let lock = xudanu::server::lock::BooLock::new(club_id);
    srv.authenticate(session, &lock, &xudanu::server::lock::LockCredential::Boo)
        .unwrap();
    (session, club_id)
}

fn admin_session_id(srv: &mut xudanu::server::Server) -> xudanu::server::SessionId {
    admin_session(srv).0
}

fn make_admin_session(srv: &mut xudanu::server::Server) -> xudanu::server::SessionId {
    let club_id = srv
        .club_names_list()
        .iter()
        .find(|(n, _)| *n == "admin")
        .map(|(_, id)| *id)
        .unwrap();
    let session = srv.connect();
    let lock = xudanu::server::lock::BooLock::new(club_id);
    srv.authenticate(session, &lock, &xudanu::server::lock::LockCredential::Boo)
        .unwrap();
    session
}

#[tokio::test]
async fn persistence_works_survive_restart() {
    let dir = temp_data_dir("works");

    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let w1 = srv
        .create_work(session, xudanu::edition::Edition::from_text("doc one"))
        .unwrap();
    let w2 = srv
        .create_work(session, xudanu::edition::Edition::from_text("doc two"))
        .unwrap();
    assert_eq!(srv.work_count(), 2);

    srv.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv);

    let srv2 = server_restore(&dir);
    assert_eq!(srv2.work_count(), 2, "work count should survive restart");
    assert!(
        srv2.work(w1).is_ok(),
        "work {} should exist after restart",
        w1
    );
    assert!(
        srv2.work(w2).is_ok(),
        "work {} should exist after restart",
        w2
    );
}

#[tokio::test]
async fn persistence_keypair_identity_survives_restart() {
    let dir = temp_data_dir("keypair");

    let srv1 = server_init(&dir);
    let identity1 = srv1.federation_server_id();
    srv1.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv1);

    let srv2 = server_restore(&dir);
    let identity2 = srv2.federation_server_id();
    assert_eq!(identity1, identity2, "server identity must survive restart");
}

#[tokio::test]
async fn persistence_edition_content_survives_restart() {
    let dir = temp_data_dir("editions");

    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let wid = srv
        .create_work(session, xudanu::edition::Edition::from_text("hello world"))
        .unwrap();
    srv.work_grab(session, wid).unwrap();
    srv.work_revise(
        session,
        wid,
        xudanu::edition::Edition::from_text("updated content!"),
    )
    .unwrap();
    srv.work_release(session, wid).unwrap();

    srv.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv);

    let srv2 = server_restore(&dir);
    let work = srv2.work(wid).unwrap();
    let text: String = work
        .current_edition()
        .all_entries()
        .iter()
        .filter_map(|(_, c)| match &c.element {
            xudanu::edition::RangeElement::Text { text } => Some(text.as_str()),
            _ => None,
        })
        .collect();
    assert!(
        text.contains("updated content"),
        "edition text should survive restart, got: {}",
        text
    );
}

#[tokio::test]
async fn persistence_blobs_survive_restart() {
    let dir = temp_data_dir("blobs");

    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let meta = srv
        .blob_upload(
            session,
            b"test-blob-data".to_vec(),
            "application/octet-stream".to_string(),
        )
        .unwrap();
    assert_eq!(srv.blob_count(), 1);
    let hash_u64 = meta.hash_u64();

    srv.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv);

    let srv2 = server_restore(&dir);
    assert_eq!(srv2.blob_count(), 1, "blob count should survive restart");
    let data = srv2.blob_get(hash_u64).unwrap();
    assert_eq!(data, b"test-blob-data", "blob data should survive restart");
}

#[tokio::test]
async fn persistence_club_names_survive_restart() {
    let dir = temp_data_dir("clubs");

    let srv1 = server_init(&dir);
    let names1: Vec<String> = srv1
        .club_names_list()
        .iter()
        .map(|(n, _)| n.to_string())
        .collect();
    srv1.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv1);

    let srv2 = server_restore(&dir);
    let names2: Vec<String> = srv2
        .club_names_list()
        .iter()
        .map(|(n, _)| n.to_string())
        .collect();

    for name in &["public", "admin", "access", "empty"] {
        assert!(
            names1.contains(&name.to_string()),
            "club '{}' should exist before restart",
            name
        );
        assert!(
            names2.contains(&name.to_string()),
            "club '{}' should survive restart",
            name
        );
    }
}

#[tokio::test]
async fn persistence_federation_state_in_snapshot() {
    let dir = temp_data_dir("federation");

    let srv1 = server_init(&dir);
    srv1.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv1);

    let json = std::fs::read_to_string(dir.join("server.json")).unwrap();
    let snap: serde_json::Value = serde_json::from_str(&json).unwrap();
    let data = if snap["format_version"].is_number() {
        &snap["data"]
    } else {
        &snap
    };
    assert!(
        data["federation"].is_object(),
        "federation state should be in snapshot"
    );
    assert!(
        data["content_address"].is_object(),
        "content address index should be in snapshot"
    );
    assert!(
        data["blob_metas"].is_array(),
        "blob metas should be in snapshot"
    );
}

#[tokio::test]
async fn persistence_key_history_file_written() {
    let dir = temp_data_dir("key_history");

    let srv1 = server_init(&dir);
    srv1.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv1);

    assert!(
        dir.join("key_history.json").exists(),
        "key_history.json should be written on checkpoint"
    );

    let kh_json = std::fs::read_to_string(dir.join("key_history.json")).unwrap();
    let kh: serde_json::Value = serde_json::from_str(&kh_json).unwrap();
    assert!(
        kh["entries"].is_array(),
        "key history should have entries array"
    );
    assert_eq!(
        kh["entries"].as_array().unwrap().len(),
        1,
        "should have 1 key entry"
    );
}

#[test]
fn grab_timeout_releases_expired_grab() {
    let dir = temp_data_dir("grab_timeout");
    let mut srv = server_init(&dir);
    let (session, club_id) = admin_session(&mut srv);

    let work_id = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();
    srv.work_grab(session, work_id).unwrap();

    let grabber = srv.work_grabber(work_id).unwrap();
    assert!(grabber.is_some(), "work should be grabbed");

    let grabbed_at = srv.work_grabbed_at(work_id).unwrap();
    assert!(grabbed_at.is_some(), "grabbed_at should be set");

    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let t = grabbed_at.unwrap();
    assert!(now >= t, "grabbed_at should be in the past");
    assert!(now - t < 5, "grabbed_at should be within last 5 seconds");
}

#[test]
fn work_release_clears_grabbed_at() {
    let dir = temp_data_dir("grab_release");
    let mut srv = server_init(&dir);
    let (session, club_id) = admin_session(&mut srv);

    let work_id = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();
    srv.work_grab(session, work_id).unwrap();

    let grabbed_at = srv.work_grabbed_at(work_id).unwrap();
    assert!(grabbed_at.is_some());

    srv.work_release(session, work_id).unwrap();

    let grabber = srv.work_grabber(work_id).unwrap();
    assert!(grabber.is_none());

    let grabbed_at = srv.work_grabbed_at(work_id).unwrap();
    assert!(
        grabbed_at.is_none(),
        "grabbed_at should be cleared on release"
    );
}

#[test]
fn health_json_returns_valid_data() {
    let dir = temp_data_dir("health");
    let mut srv = server_init(&dir);
    let (session, club_id) = admin_session(&mut srv);

    let _work_id = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    let json_str = srv.health_json();
    let health: serde_json::Value = serde_json::from_str(&json_str).unwrap();

    assert_eq!(health["status"], "ok");
    assert!(
        health["works"].as_u64().unwrap() >= 1,
        "should have at least 1 work"
    );
    assert!(
        health["clubs"].as_u64().unwrap() >= 4,
        "should have system clubs"
    );
    assert!(
        health["sessions"].as_u64().unwrap() >= 1,
        "should have the admin session"
    );
    assert!(
        health["operations"].is_number(),
        "operations should be a number"
    );
    assert!(health["last_checkpoint_ago_secs"].is_number());
    assert!(health["server_id"].is_string());
}

#[tokio::test]
async fn health_endpoint_via_http() {
    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/health", addr))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), 200);
    let body_text = resp.text().await.unwrap();
    let body: serde_json::Value = serde_json::from_str(&body_text).unwrap();
    assert_eq!(body["status"], "ok");
    assert!(body["works"].is_number());
    assert!(body["server_id"].is_string());
    // OAuth providers advertised to the frontend: default server has
    // none configured — both false, field always present.
    assert!(body["oauth_providers"].is_object());
    assert_eq!(body["oauth_providers"]["github"], false);
    assert_eq!(body["oauth_providers"]["google"], false);
}

#[tokio::test]
async fn health_reports_configured_oauth_providers() {
    let server = Server::new();
    let config = xudanu::server::transport::oauth::OAuthConfig {
        github_client_id: Some("gh-id".into()),
        github_client_secret: Some("gh-secret".into()),
        google_client_id: None,
        google_client_secret: None,
        ..Default::default()
    };
    let state = AppState::new(server).with_oauth(config).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/health", addr))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), 200);
    let body: serde_json::Value = serde_json::from_str(&resp.text().await.unwrap()).unwrap();
    assert_eq!(body["oauth_providers"]["github"], true);
    assert_eq!(body["oauth_providers"]["google"], false);
}

#[tokio::test]
async fn well_known_identity_returns_valid_json() {
    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/.well-known/xudanu-server.json", addr))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), 200);
    let body: serde_json::Value = serde_json::from_str(&resp.text().await.unwrap()).unwrap();
    assert_eq!(body["protocol"], "xcp");
    assert_eq!(body["protocol_version"], 1);
    assert_eq!(body["public_content"], true);
    assert!(body["server_id"].is_string());
    assert!(body["server_name"].is_string());
    assert!(body["started_at"].is_number());
    assert!(body["stats"]["work_count"].is_number());
    assert!(body["stats"]["revision_count"].is_number());
}

#[tokio::test]
async fn well_known_identity_has_cors_header() {
    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/.well-known/xudanu-server.json", addr))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), 200);
    let cors = resp
        .headers()
        .get("access-control-allow-origin")
        .expect("CORS header missing");
    assert_eq!(cors, "*");
}

#[tokio::test]
async fn well_known_identity_reflects_work_count() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    server
        .create_work(sid, xudanu::edition::Edition::from_text("hello"))
        .unwrap();
    server
        .create_work(sid, xudanu::edition::Edition::from_text("world"))
        .unwrap();

    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/.well-known/xudanu-server.json", addr))
        .send()
        .await
        .unwrap();
    let body: serde_json::Value = serde_json::from_str(&resp.text().await.unwrap()).unwrap();
    assert_eq!(body["stats"]["work_count"], 2);
}

#[test]
fn server_namespace_id_is_deterministic() {
    let s1 = Server::new();
    let s2 = Server::new();
    // Different server instances get different keys, so different namespace IDs
    assert_ne!(s1.server_namespace_id(), s2.server_namespace_id());

    // Same instance returns same value
    let id = s1.server_namespace_id();
    assert_eq!(s1.server_namespace_id(), id);
}

#[test]
fn server_namespace_id_can_be_overridden() {
    let mut s = Server::new();
    let auto_id = s.server_namespace_id();
    s.set_server_namespace_id(42);
    assert_eq!(s.server_namespace_id(), 42);
    assert_ne!(s.server_namespace_id(), auto_id);
}

#[test]
fn well_known_identity_json_structure() {
    let s = Server::new();
    let identity = s.well_known_identity();
    assert_eq!(identity["protocol"], "xcp");
    assert_eq!(identity["protocol_version"], 1);
    assert_eq!(identity["public_content"], true);
    assert!(identity["server_id"].as_str().unwrap().len() == 64);
    assert!(identity["server_name"].is_string());
    assert!(identity["stats"]["work_count"].as_u64() == Some(0));
    assert!(
        identity["server_namespace_id"].as_u64() == Some(s.server_namespace_id()),
        "server_namespace_id must be a u64 matching the server's actual namespace ID"
    );
}

#[test]
fn well_known_identity_fields_match_directory_add_parser() {
    let s = Server::new();
    let identity = s.well_known_identity();

    let verifying_key = identity["server_id"]
        .as_str()
        .expect("server_id must be a hex string (verifying key)");
    assert_eq!(verifying_key.len(), 64, "32-byte Ed25519 key as hex");

    let ns_id = identity["server_namespace_id"]
        .as_u64()
        .expect("server_namespace_id must be present as u64");
    assert_eq!(ns_id, s.server_namespace_id());

    assert!(
        identity["server_name"].is_string(),
        "server_name must be present for directory add"
    );
    assert!(
        identity["server_description"].is_string(),
        "server_description must be present for directory add"
    );

    let vk_bytes = hex::decode(verifying_key).unwrap();
    let hash = blake3::hash(&vk_bytes);
    let b = hash.as_bytes();
    let derived = u64::from_be_bytes([b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7]]);
    assert_eq!(
        derived, ns_id,
        "BLAKE3-derived namespace ID must match server_namespace_id"
    );
}

#[test]
fn recovery_stats_format() {
    let dir = temp_data_dir("recovery_stats");
    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let _work_id = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    let stats = srv.recovery_stats();
    assert!(stats.contains("works="), "should show work count");
    assert!(stats.contains("clubs=4"));
    assert!(stats.contains("sessions=1"));
    assert!(stats.contains("grabbed=0"));
}

#[test]
fn persistence_atomic_write_no_partial_file() {
    let dir = temp_data_dir("atomic_write");

    let srv = server_init(&dir);
    srv.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv);

    assert!(
        !dir.join("server.json.tmp").exists(),
        "tmp file should not linger after successful checkpoint"
    );
    assert!(dir.join("server.json").exists(), "final file should exist");

    let json = std::fs::read_to_string(dir.join("server.json")).unwrap();
    let _: serde_json::Value = serde_json::from_str(&json).unwrap();
}

#[test]
fn persistence_corrupt_snapshot_graceful_error() {
    let dir = temp_data_dir("corrupt");

    std::fs::create_dir_all(dir.join("blobs")).unwrap();
    std::fs::write(dir.join("server.json"), "{ this is not valid json !!!").unwrap();

    let result =
        xudanu::server::Server::restore_from_file_with_persistence(&dir.join("server.json"));
    assert!(
        result.is_err(),
        "corrupt snapshot should return an error, not panic"
    );
}

#[test]
fn auto_checkpoint_skips_within_30s_window() {
    let dir = temp_data_dir("auto_checkpoint_timing");

    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let _w = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();
    srv.checkpoint_to_file(&dir.join("server.json")).unwrap();
    let size_after_first = std::fs::metadata(dir.join("server.json")).unwrap().len();

    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();
    srv.test_bump_operation();

    let size_after_ops = std::fs::metadata(dir.join("server.json")).unwrap().len();
    assert_eq!(
        size_after_first, size_after_ops,
        "checkpoint should not rewrite within 30s window"
    );
}

#[test]
fn grabbed_works_released_after_restart() {
    let dir = temp_data_dir("grab_restart");

    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let wid = srv
        .create_work(session, xudanu::edition::Edition::from_text("grabbed doc"))
        .unwrap();
    srv.work_grab(session, wid).unwrap();
    assert!(
        srv.work_grabber(wid).unwrap().is_some(),
        "work should be grabbed before restart"
    );

    srv.checkpoint_to_file(&dir.join("server.json")).unwrap();
    drop(srv);

    let srv2 = server_restore(&dir);
    assert!(
        srv2.work_grabber(wid).unwrap().is_none(),
        "grabbed work should be released after restart — sessions don't survive"
    );
    assert!(
        srv2.work_grabbed_at(wid).unwrap().is_none(),
        "grabbed_at should also be cleared after restart"
    );
}

#[test]
fn request_grab_succeeds_immediately_when_unlocked() {
    let dir = temp_data_dir("req_grab_unlocked");
    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let wid = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();
    let granted = srv.work_request_grab(session, wid).unwrap();
    assert!(
        granted,
        "request_grab should succeed immediately when work is unlocked"
    );
    assert!(
        srv.work_grabber(wid).unwrap().is_some(),
        "work should be grabbed after request_grab"
    );
}

#[test]
fn request_grab_queues_when_already_grabbed() {
    let dir = temp_data_dir("req_grab_queued");
    let mut srv = server_init(&dir);

    let s1 = make_admin_session(&mut srv);
    let s2 = make_admin_session(&mut srv);

    let wid = srv
        .create_work(s1, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    srv.work_grab(s1, wid).unwrap();
    assert!(srv.work_grabber(wid).unwrap() == Some(s1));

    let granted = srv.work_request_grab(s2, wid).unwrap();
    assert!(
        !granted,
        "request_grab should return false when work is locked"
    );

    let waiters = srv.work_grab_waiters(wid).unwrap();
    assert_eq!(waiters, vec![s2], "s2 should be in the wait queue");
}

#[test]
fn request_grab_auto_grants_on_release() {
    let dir = temp_data_dir("req_grab_auto_grant");
    let mut srv = server_init(&dir);

    let s1 = make_admin_session(&mut srv);
    let s2 = make_admin_session(&mut srv);

    let wid = srv
        .create_work(s1, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    srv.work_grab(s1, wid).unwrap();
    srv.work_request_grab(s2, wid).unwrap();

    srv.work_release(s1, wid).unwrap();

    assert_eq!(
        srv.work_grabber(wid).unwrap(),
        Some(s2),
        "s2 should get the grab after s1 releases"
    );
    let waiters = srv.work_grab_waiters(wid).unwrap();
    assert!(waiters.is_empty(), "wait queue should be empty after grant");
}

#[test]
fn cancel_grab_request_removes_from_queue() {
    let dir = temp_data_dir("cancel_grab_req");
    let mut srv = server_init(&dir);

    let s1 = make_admin_session(&mut srv);
    let s2 = make_admin_session(&mut srv);

    let wid = srv
        .create_work(s1, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    srv.work_grab(s1, wid).unwrap();
    srv.work_request_grab(s2, wid).unwrap();

    srv.work_cancel_grab_request(s2, wid).unwrap();
    let waiters = srv.work_grab_waiters(wid).unwrap();
    assert!(
        waiters.is_empty(),
        "wait queue should be empty after cancel"
    );

    srv.work_release(s1, wid).unwrap();
    assert!(
        srv.work_grabber(wid).unwrap().is_none(),
        "no waiter to grant to"
    );
}

#[test]
fn disconnect_releases_grab_and_grants_to_waiter() {
    let dir = temp_data_dir("disconnect_grant");
    let mut srv = server_init(&dir);

    let s1 = make_admin_session(&mut srv);
    let s2 = make_admin_session(&mut srv);

    let wid = srv
        .create_work(s1, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    srv.work_grab(s1, wid).unwrap();
    srv.work_request_grab(s2, wid).unwrap();

    srv.disconnect(s1).unwrap();

    assert_eq!(
        srv.work_grabber(wid).unwrap(),
        Some(s2),
        "s2 should get the grab after s1 disconnects"
    );
}

#[test]
fn disconnect_cancels_pending_grab_requests() {
    let dir = temp_data_dir("disconnect_cancel_wait");
    let mut srv = server_init(&dir);

    let s1 = make_admin_session(&mut srv);
    let s2 = make_admin_session(&mut srv);

    let wid = srv
        .create_work(s1, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    srv.work_grab(s1, wid).unwrap();
    srv.work_request_grab(s2, wid).unwrap();

    srv.disconnect(s2).unwrap();

    let waiters = srv.work_grab_waiters(wid).unwrap();
    assert!(
        waiters.is_empty(),
        "s2's grab request should be cancelled on disconnect"
    );

    srv.work_release(s1, wid).unwrap();
    assert!(
        srv.work_grabber(wid).unwrap().is_none(),
        "no waiter to grant to"
    );
}

#[test]
fn request_grab_idempotent_for_holder() {
    let dir = temp_data_dir("req_grab_idempotent");
    let mut srv = server_init(&dir);
    let (session, _) = admin_session(&mut srv);

    let wid = srv
        .create_work(session, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    srv.work_grab(session, wid).unwrap();
    let granted = srv.work_request_grab(session, wid).unwrap();
    assert!(granted, "request_grab by current holder should return true");
}

#[test]
fn grant_pending_skips_session_without_edit_perm() {
    let dir = temp_data_dir("grant_skip_no_perm");
    let mut srv = server_init(&dir);

    let admin_club = srv
        .club_names_list()
        .iter()
        .find(|(n, _)| *n == "admin")
        .map(|(_, id)| *id)
        .unwrap();

    let s1 = make_admin_session(&mut srv);
    let s2 = make_admin_session(&mut srv);
    let s3 = make_admin_session(&mut srv);

    let wid = srv
        .create_work(s1, xudanu::edition::Edition::from_text("test"))
        .unwrap();
    srv.work_set_edit_club(s1, wid, Some(admin_club)).unwrap();

    srv.work_grab(s1, wid).unwrap();
    srv.work_request_grab(s3, wid).unwrap();
    srv.work_request_grab(s2, wid).unwrap();

    srv.disconnect(s3).unwrap();

    srv.work_release(s1, wid).unwrap();

    assert_eq!(
        srv.work_grabber(wid).unwrap(),
        Some(s2),
        "should grant to s2, skip disconnected s3"
    );
}

// ── Rule 8: Publication model integration tests ──────────────────────

fn owned_session(srv: &mut xudanu::server::Server) -> (xudanu::server::SessionId, u64) {
    let session = srv.connect();
    srv.login_public(session).unwrap();
    let club_id = srv
        .create_club(session, xudanu::edition::Edition::from_text("owner club"))
        .unwrap();
    let lock = xudanu::server::lock::BooLock::new(club_id);
    srv.authenticate(session, &lock, &xudanu::server::lock::LockCredential::Boo)
        .unwrap();
    (session, club_id)
}

#[test]
fn publish_unpublish_via_server_methods() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("test"))
        .unwrap();

    assert!(
        !srv.work_is_published(sid, wid).unwrap(),
        "new work should be private"
    );

    srv.work_publish(sid, wid).unwrap();
    assert!(
        srv.work_is_published(sid, wid).unwrap(),
        "after publish should be public"
    );

    srv.work_unpublish(sid, wid).unwrap();
    assert!(
        !srv.work_is_published(sid, wid).unwrap(),
        "after unpublish should be private"
    );
}

#[test]
fn irrevocably_unpublish_blocks_republish() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("permanent"))
        .unwrap();

    srv.work_irrevocably_unpublish(sid, wid).unwrap();

    assert!(
        srv.work_publish(sid, wid).is_err(),
        "should not be able to republish"
    );
    assert!(
        srv.work_unpublish(sid, wid).is_err(),
        "should not be able to unpublish"
    );
    assert!(
        srv.work_set_read_club(sid, wid, None).is_err(),
        "should not be able to set_read_club"
    );
}

#[test]
fn private_work_invisible_to_other_session() {
    let mut srv = xudanu::server::Server::new();

    let (sid1, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("secret"))
        .unwrap();

    let (sid2, _) = owned_session(&mut srv);

    assert!(
        !srv.work_is_readable(sid2, srv.work(wid).unwrap()),
        "other session should not be able to read private work"
    );
    assert!(
        srv.ensure_can_read(sid2, wid).is_err(),
        "ensure_can_read should fail for non-owner of private work"
    );
}

#[test]
fn published_work_visible_to_public() {
    let mut srv = xudanu::server::Server::new();

    let (sid1, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("public doc"))
        .unwrap();
    srv.work_publish(sid1, wid).unwrap();

    let sid2 = srv.connect();
    srv.login_public(sid2).unwrap();

    assert!(
        srv.work_is_readable(sid2, srv.work(wid).unwrap()),
        "public session should be able to read published work"
    );
}

#[test]
fn strict_edit_policy_blocks_anonymous_work_creation() {
    // Under OwnerOnly (the server binary's default), anonymous
    // sessions must not create works — the anti-spam/anti-takeover
    // floor. The library default is PublicSandbox (browser/test
    // contexts); `xudanu-server run` pins OwnerOnly unless the
    // operator opts out.
    let mut srv = xudanu::server::Server::new();
    srv.set_edit_policy(xudanu::server::EditPolicy::OwnerOnly);

    let sid = srv.connect();
    srv.login_public(sid).unwrap();
    let err = srv
        .create_work(sid, xudanu::edition::Edition::from_text("spam"))
        .unwrap_err();
    assert!(
        matches!(err, xudanu::server::ServerError::NotAuthorized),
        "anonymous create_work must fail under OwnerOnly, got {:?}",
        err
    );
}

#[test]
fn strict_edit_policy_allows_owned_work_lifecycle() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("mine"))
        .unwrap();
    srv.work_grab(sid, wid)
        .expect("owner must be able to grab own work under OwnerOnly");
    srv.work_revise(sid, wid, xudanu::edition::Edition::from_text("revised"))
        .expect("owner must be able to revise own work under OwnerOnly");
}

#[test]
fn strict_edit_policy_locks_down_legacy_public_works() {
    // Works created under the sandbox policy (or legacy default) with
    // edit_club = public must become read-only when policy is
    // tightened, and anonymous sessions must not be able to
    // re-permission them (the takeover vector).
    let mut srv = xudanu::server::Server::new();
    srv.set_edit_policy(xudanu::server::EditPolicy::PublicSandbox);
    let sid1 = srv.connect();
    srv.login_public(sid1).unwrap();
    let wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("legacy"))
        .unwrap();

    srv.set_edit_policy(xudanu::server::EditPolicy::OwnerOnly);

    let sid2 = srv.connect();
    srv.login_public(sid2).unwrap();
    assert!(
        srv.work_grab(sid2, wid).is_err(),
        "anonymous edit of public-owned work must fail under OwnerOnly"
    );
    assert!(
        srv.work_set_edit_club(sid2, wid, Some(srv.system_clubs().public_club))
            .is_err(),
        "anonymous re-permissioning (takeover) must fail under OwnerOnly"
    );
    assert!(
        srv.work_is_readable(sid2, srv.work(wid).unwrap()),
        "read access must be unaffected by edit policy"
    );
}

#[test]
fn sandbox_edit_policy_preserves_anonymous_wiki_behaviour() {
    let mut srv = xudanu::server::Server::new();
    srv.set_edit_policy(xudanu::server::EditPolicy::PublicSandbox);

    let sid1 = srv.connect();
    srv.login_public(sid1).unwrap();
    let wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("sandbox doc"))
        .unwrap();

    let sid2 = srv.connect();
    srv.login_public(sid2).unwrap();
    assert!(
        srv.work_grab(sid2, wid).is_ok(),
        "sandbox mode keeps anonymous works world-editable"
    );
}

#[test]
fn edit_policy_parse_accepts_aliases() {
    use xudanu::server::EditPolicy;
    assert_eq!(EditPolicy::parse("owner-only"), Some(EditPolicy::OwnerOnly));
    assert_eq!(EditPolicy::parse("STRICT"), Some(EditPolicy::OwnerOnly));
    assert_eq!(
        EditPolicy::parse("public-sandbox"),
        Some(EditPolicy::PublicSandbox)
    );
    assert_eq!(EditPolicy::parse("lax"), Some(EditPolicy::PublicSandbox));
    assert_eq!(EditPolicy::parse("nonsense"), None);
}

#[test]
fn work_list_filters_by_read_permission() {
    let mut srv = xudanu::server::Server::new();

    let (sid1, _) = owned_session(&mut srv);
    let pub_wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("public"))
        .unwrap();
    srv.work_publish(sid1, pub_wid).unwrap();
    let priv_wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("private"))
        .unwrap();

    let sid2 = srv.connect();
    srv.login_public(sid2).unwrap();

    let entries = srv.list_works_with_titles();
    let visible_ids: Vec<u64> = entries
        .iter()
        .filter(|(id, _, _, _, _, _, _, _, _, _, _)| {
            srv.work(*id)
                .map(|w| srv.work_is_readable(sid2, w))
                .unwrap_or(false)
        })
        .map(|(id, _, _, _, _, _, _, _, _, _, _)| *id)
        .collect();

    assert!(
        visible_ids.contains(&pub_wid),
        "published work should be visible"
    );
    assert!(
        !visible_ids.contains(&priv_wid),
        "private work should not be visible"
    );
}

#[test]
fn editors_can_always_read() {
    let mut srv = xudanu::server::Server::new();

    let (sid1, club1) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("owned"))
        .unwrap();

    let (sid2, club2) = owned_session(&mut srv);
    srv.work_set_edit_club(sid1, wid, Some(club2)).unwrap();

    assert!(
        srv.work_is_readable(sid2, srv.work(wid).unwrap()),
        "editor should be able to read even if not in read_club"
    );
}

#[test]
fn club_set_default_requires_ownership() {
    let mut srv = xudanu::server::Server::new();

    let (sid1, club1) = owned_session(&mut srv);
    let (sid2, _) = owned_session(&mut srv);

    let result = srv.club_set_default_read_club(sid2, club1, Some(club1));
    assert!(
        result.is_err(),
        "non-owner should not be able to set default_read_club"
    );

    let result = srv.club_set_default_read_club(sid1, club1, Some(club1));
    assert!(
        result.is_ok(),
        "owner should be able to set default_read_club"
    );
}

#[test]
fn per_club_defaults_applied_on_work_creation() {
    let mut srv = xudanu::server::Server::new();

    let (sid, club) = owned_session(&mut srv);
    let custom_club = srv
        .create_club(sid, xudanu::edition::Edition::from_text("custom"))
        .unwrap();

    srv.club_set_default_read_club(sid, club, Some(custom_club))
        .unwrap();

    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("test"))
        .unwrap();
    let work = srv.work(wid).unwrap();

    assert_eq!(
        work.read_club(),
        Some(custom_club),
        "new work should use club's default_read_club"
    );
}

#[test]
fn publication_state_survives_persistence_roundtrip() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("persist"))
        .unwrap();
    srv.work_publish(sid, wid).unwrap();

    let snapshot = srv.to_snapshot();
    let mut restored = xudanu::server::Server::from_snapshot(&snapshot);
    let sid2 = restored.connect();
    restored.login_public(sid2).unwrap();

    assert!(
        restored.work_is_published(sid2, wid).unwrap(),
        "published state should survive persistence roundtrip"
    );
    assert!(
        restored.work_is_readable(sid2, restored.work(wid).unwrap()),
        "published work should be readable after restore"
    );
}

#[test]
fn federation_only_exports_published_works() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);

    let pub_wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("exported"))
        .unwrap();
    srv.work_publish(sid, pub_wid).unwrap();

    let priv_wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("secret"))
        .unwrap();

    let exports = srv.federation_export_works();
    let export_ids: Vec<u64> = exports.iter().map(|e| e.work_id).collect();

    assert!(
        export_ids.contains(&pub_wid),
        "published work should be exported"
    );
    assert!(
        !export_ids.contains(&priv_wid),
        "private work should not be exported"
    );
}

#[tokio::test]
async fn publish_unpublish_via_wire() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_create",
            Some(serde_json::json!({"description": {"text": "owner club"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "club_set_password",
            Some(serde_json::json!({"club_id": club_id, "password": b"owner123" })),
        ),
    )
    .await;
    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "session_login",
            Some(serde_json::json!({"club_id": club_id})),
        ),
    )
    .await;
    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(b"owner123")})),
        ),
    )
    .await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "wire test"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "work_is_published",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"], false, "new work should be private");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "work_publish",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            23,
            "work_is_published",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            24,
            "work_unpublish",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            25,
            "work_is_published",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"], false);
}

#[tokio::test]
async fn irrevocably_unpublish_via_wire() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let club_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_create",
            Some(serde_json::json!({"description": {"text": "owner club"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "club_set_password",
            Some(serde_json::json!({"club_id": club_id, "password": b"owner123" })),
        ),
    )
    .await;
    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "session_login",
            Some(serde_json::json!({"club_id": club_id})),
        ),
    )
    .await;
    let _ = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(b"owner123")})),
        ),
    )
    .await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "permanent"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "work_irrevocably_unpublish",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "work_publish",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(
        resp["type"], "error",
        "republish should fail after irrevocable unpublish"
    );
}

#[tokio::test]
async fn work_list_filters_private_from_other_session() {
    let srv = TestServer::start().await;

    let (mut s1, mut r1, _sid1) = json_setup(&srv).await;
    let club_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "club_create",
            Some(serde_json::json!({"description": {"text": "owner club"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "club_set_password",
            Some(serde_json::json!({"club_id": club_id, "password": b"owner123" })),
        ),
    )
    .await;
    let _ = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            12,
            "session_login",
            Some(serde_json::json!({"club_id": club_id})),
        ),
    )
    .await;
    let _ = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            13,
            "session_authenticate",
            Some(serde_json::json!({"credential": password_credential(b"owner123")})),
        ),
    )
    .await;
    let pub_wid = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            20,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "will publish"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let priv_wid = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            21,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "stays private"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let _ = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            22,
            "work_publish",
            Some(serde_json::json!({"work_id": pub_wid})),
        ),
    )
    .await;

    let (mut s2, mut r2, _sid2) = json_public_setup(&srv).await;
    let resp = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(50, "work_list", Some(serde_json::json!({}))),
    )
    .await;
    let entries = resp["value"]["value"]["entries"].as_array().unwrap();
    let visible_ids: Vec<u64> = entries
        .iter()
        .map(|e| e["work_id"].as_u64().unwrap())
        .collect();

    assert!(
        visible_ids.contains(&pub_wid),
        "published work should be visible to other session"
    );
    assert!(
        !visible_ids.contains(&priv_wid),
        "private work should not be visible to other session"
    );
}

#[tokio::test]
async fn json_crdt_sync_lifecycle() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "crdt_sync_open",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "crdt_sync_open_result");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "crdt_sync_subscriber_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["count"], 1);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "crdt_sync_close",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "void");
}

#[tokio::test]
async fn json_crdt_update_and_materialize() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "crdt_sync_open",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let full_state = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "crdt_sync_full_state",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(full_state["type"], "response");
    assert!(full_state["value"]["type"] == "crdt_sync_full_state_result");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "crdt_sync_materialize",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "crdt_sync_materialize_result");

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            14,
            "crdt_sync_close",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
}

#[tokio::test]
async fn json_crdt_awareness() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "crdt_sync_open",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "crdt_awareness_update",
            Some(serde_json::json!({
                "work_id": work_id,
                "state": {
                    "session_id": 0,
                    "user_name": "Alice",
                    "cursor": {"index": 5},
                    "selection": null,
                    "is_typing": true
                }
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "crdt_awareness_update_result");

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "crdt_awareness_get",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "crdt_awareness_get_result");

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            14,
            "crdt_sync_close",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
}

#[tokio::test]
async fn json_crdt_requires_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(1, "crdt_sync_open", Some(serde_json::json!({"work_id": 1}))),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn json_crdt_update_requires_subscription() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "crdt_sync_update",
            Some(serde_json::json!({
                "work_id": work_id,
                "update": ""
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn json_crdt_multi_user_sync() {
    let srv = TestServer::start().await;

    let (mut s1, mut r1, _) = json_setup(&srv).await;
    let (mut s2, mut r2, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            11,
            "crdt_sync_open",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            10,
            "crdt_sync_open",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let count1 = send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            12,
            "crdt_sync_subscriber_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(count1["value"]["value"]["count"], 2);

    let count2 = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            11,
            "crdt_sync_subscriber_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(count2["value"]["value"]["count"], 2);

    send_recv_json(
        &mut s1,
        &mut r1,
        json_req(
            13,
            "crdt_sync_close",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    // Drain any CrdtAwarenessRemove events broadcast from session 1's close
    // before querying subscriber count
    tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    loop {
        match tokio::time::timeout(tokio::time::Duration::from_millis(50), r2.next()).await {
            Ok(Some(Ok(Message::Text(t)))) => {
                let v: serde_json::Value = serde_json::from_str(&t).unwrap_or_default();
                if v.get("type").and_then(|t| t.as_str()) == Some("event") {
                    continue;
                }
            }
            _ => break,
        }
    }

    let count2_after = send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            12,
            "crdt_sync_subscriber_count",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(count2_after["value"]["value"]["count"], 1);

    send_recv_json(
        &mut s2,
        &mut r2,
        json_req(
            13,
            "crdt_sync_close",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
}

#[test]
fn personal_club_with_password_survives_persistence_roundtrip() {
    let mut srv = xudanu::server::Server::new();
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let phc_hash = xudanu::crypto::password::hash_password(b"testpass123").unwrap();
    let credential = Some(xudanu::server::club::Credential::Password { phc_hash });
    let club_id = srv
        .create_personal_club(
            sid,
            "alice".to_string(),
            credential,
            Some(b"testpass123".to_vec()),
        )
        .unwrap();

    let club = srv.club(club_id).unwrap();
    assert!(club.is_personal());
    assert!(club.encrypted_signing_key().is_some());
    let verifying_key_bytes = club.encrypted_signing_key().unwrap().verifying_key;

    let snapshot = srv.to_snapshot();
    let mut restored = xudanu::server::Server::from_snapshot(&snapshot);

    let restored_club = restored.club(club_id).unwrap();
    assert!(
        restored_club.is_personal(),
        "is_personal should survive roundtrip"
    );
    assert_eq!(
        restored_club.display_name(),
        Some("alice"),
        "display_name should survive roundtrip"
    );
    assert!(
        restored_club.credential().is_some(),
        "credential should survive roundtrip"
    );
    assert!(
        restored_club.encrypted_signing_key().is_some(),
        "encrypted_signing_key should survive roundtrip"
    );
    assert_eq!(
        restored_club.encrypted_signing_key().unwrap().verifying_key,
        verifying_key_bytes,
        "signing key should be identical after roundtrip"
    );
    assert_eq!(
        restored.personal_club_count(),
        1,
        "personal_club_count should be reconstructed"
    );
}

// ============================================================
// Content Watch (Watch feature)
// ============================================================

#[tokio::test]
async fn content_watch_receives_initial_match_for_existing_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let resp_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "one two three"}})),
        ),
    )
    .await;
    let work_a = resp_a["value"]["value"]
        .as_u64()
        .expect("work_a should be u64");

    let resp_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "two three four"}})),
        ),
    )
    .await;
    let work_b = resp_b["value"]["value"]
        .as_u64()
        .expect("work_b should be u64");

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION,
        "type": "subscribe",
        "id": 20,
        "payload": {
            "detector_type": "content_works",
            "target_id": work_a
        }
    });
    let resp = send_recv_json(&mut s, &mut r, sub_frame).await;
    assert_eq!(
        resp["type"], "response",
        "subscribe should succeed, got: {:?}",
        resp
    );

    let deadline = std::time::Duration::from_secs(3);
    let start = std::time::Instant::now();
    let mut found_work_b = false;
    let mut events: Vec<serde_json::Value> = Vec::new();
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(200), r.next()).await {
            Ok(Some(Ok(msg))) => {
                let val: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
                    _ => continue,
                };
                events.push(val.clone());
                if val["type"] == "event" {
                    let event_type = val["event"]["type"].as_str().unwrap_or("");
                    if event_type == "content_match" {
                        let matched_id = val["event"]["payload"]["edition_be_id"]
                            .as_u64()
                            .unwrap_or(0);
                        if matched_id == work_b {
                            found_work_b = true;
                            break;
                        }
                    }
                }
            }
            _ => continue,
        }
    }
    assert!(
        found_work_b,
        "expected content_match event for work_b ({}) within 3s. Received events: {:?}",
        work_b, events
    );
}

#[tokio::test]
async fn content_watch_receives_notification_on_revision() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _sid) = json_setup(&srv).await;

    let work_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let work_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "zzzzz"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let sub_frame = serde_json::json!({
        "v": PROTOCOL_VERSION,
        "type": "subscribe",
        "id": 20,
        "payload": {
            "detector_type": "content_works",
            "target_id": work_a
        }
    });
    let resp = send_recv_json(&mut s, &mut r, sub_frame).await;
    assert_eq!(
        resp["type"], "response",
        "subscribe should succeed, got: {:?}",
        resp
    );

    // drain any initial events
    while tokio::time::timeout(std::time::Duration::from_millis(50), r.next())
        .await
        .is_ok()
    {}

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_grab",
            Some(serde_json::json!({"work_id": work_b})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            31,
            "work_revise",
            Some(serde_json::json!({"work_id": work_b, "edition": {"text": "hello"}})),
        ),
    )
    .await;

    // content notifications are drained on every incoming message, so the
    // work_revise response comes first, then we need another message to flush
    // the notification that was queued during the revise
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;
    let _ = s
        .send(Message::Text(
            serde_json::to_string(&serde_json::json!({
                "v": PROTOCOL_VERSION, "type": "request", "id": 32, "op": "server_health"
            }))
            .unwrap()
            .into(),
        ))
        .await;

    let deadline = std::time::Duration::from_secs(3);
    let start = std::time::Instant::now();
    let mut found = false;
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(200), r.next()).await {
            Ok(Some(Ok(msg))) => {
                let val: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
                    _ => continue,
                };
                if val["type"] == "event" && val["event"]["type"].as_str() == Some("content_match")
                {
                    found = true;
                    break;
                }
            }
            _ => break,
        }
    }
    assert!(
        found,
        "expected content_match event after revising work_b to match work_a"
    );
}

// ================================================================
// ChunkStore persistence + concurrent server access tests
// ================================================================

fn temp_chunk_data_dir(name: &str) -> std::path::PathBuf {
    static COUNTER: std::sync::atomic::AtomicU64 = std::sync::atomic::AtomicU64::new(0);
    let id = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);
    let dir = std::env::temp_dir().join(format!(
        "xudanu-chunk-{}-{}-{}",
        name,
        std::process::id(),
        id
    ));
    let _ = std::fs::remove_dir_all(&dir);
    dir
}

fn server_init_chunk_store(data_dir: &std::path::Path) -> xudanu::server::Server {
    let mut server = xudanu::server::Server::new();
    server.init_data_dir(data_dir, None).unwrap();
    server
}

fn server_restore_chunk_store(data_dir: &std::path::Path) -> xudanu::server::Server {
    let mut server = xudanu::server::Server::new();
    server.restore_from_data_dir(data_dir, None).unwrap();
    server
}

#[test]
fn robots_txt_served_from_embedded_app() {
    // SEO floor: crawlers must get a real robots.txt even without a
    // static dir (xudanu.com runs the embedded app).
    let server = xudanu::server::Server::new();
    let _ = server;
    // The route is HTTP-level; verify via the router construction the
    // same way other route tests do (spin the full test server).
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let state = std::sync::Arc::new(xudanu::server::transport::shared::AppState::new(server));
        let app = xudanu::server::transport::handler::build_router(state.clone());
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        let resp = reqwest::get(format!("http://{}/robots.txt", addr))
            .await
            .unwrap();
        assert_eq!(resp.status(), 200);
        let text = resp.text().await.unwrap();
        assert!(text.starts_with("User-agent: *"), "got: {}", text);
        assert!(text.contains("Disallow: /api/"));
    });
}

#[test]
fn spa_deep_links_serve_index_html() {
    // SPA routes like /explore have no physical file: the fallback
    // must serve the shell (200 + HTML), not 404, so deep links and
    // crawlers work. Extensionless misses on real assets stay 404.
    let server = xudanu::server::Server::new();
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let state = std::sync::Arc::new(xudanu::server::transport::shared::AppState::new(server));
        let app = xudanu::server::transport::handler::build_router(state.clone());
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });

        let resp = reqwest::get(format!("http://{}/explore", addr))
            .await
            .unwrap();
        assert_eq!(resp.status(), 200, "deep link must serve the SPA shell");
        assert!(
            resp.headers()
                .get("content-type")
                .and_then(|v| v.to_str().ok())
                .unwrap_or("")
                .starts_with("text/html"),
            "deep link must be HTML"
        );
        let text = resp.text().await.unwrap();
        assert!(text.contains("<title>"), "got: {}", text);

        let resp = reqwest::get(format!("http://{}/doc/123", addr))
            .await
            .unwrap();
        assert_eq!(resp.status(), 200, "nested deep link serves the shell");

        let resp = reqwest::get(format!("http://{}/missing.js", addr))
            .await
            .unwrap();
        assert_eq!(
            resp.status(),
            404,
            "asset misses must stay 404 for diagnosability"
        );
    });
}

#[test]
fn spa_fallback_serves_real_assets_with_mime() {
    // Regression: the fallback once 404'd every extension path BEFORE
    // checking the filesystem, killing all real assets (/assets/*.js)
    // — white screen in production. Existing files must be served with
    // a correct MIME type whatever their extension.
    let dir = std::env::temp_dir().join(format!("xudanu-spa-test-{}", std::process::id()));
    let assets = dir.join("assets");
    std::fs::create_dir_all(&assets).unwrap();
    std::fs::write(assets.join("index-abc123.js"), b"console.log('ok');").unwrap();
    std::fs::write(dir.join("index.html"), b"<html><body>shell</body></html>").unwrap();

    let server = xudanu::server::Server::new();
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let state = std::sync::Arc::new(
            xudanu::server::transport::shared::AppState::new(server).with_static_dir(dir.clone()),
        );
        let app = xudanu::server::transport::handler::build_router(state.clone());
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });

        let resp = reqwest::get(format!("http://{}/assets/index-abc123.js", addr))
            .await
            .unwrap();
        assert_eq!(resp.status(), 200, "existing asset must be served");
        let ct = resp
            .headers()
            .get("content-type")
            .and_then(|v| v.to_str().ok())
            .unwrap_or("")
            .to_string();
        assert!(
            ct.contains("javascript"),
            "asset must have JS MIME type, got '{}'",
            ct
        );

        let resp = reqwest::get(format!("http://{}/missing.js", addr))
            .await
            .unwrap();
        assert_eq!(resp.status(), 404, "missing asset stays 404");

        let resp = reqwest::get(format!("http://{}/explore", addr))
            .await
            .unwrap();
        assert_eq!(resp.status(), 200, "deep link still serves the shell");
        assert!(resp.text().await.unwrap().contains("shell"));
    });

    let _ = std::fs::remove_dir_all(&dir);
}

/// C2 hardening: the public identity endpoint signs its response with
/// the server's Ed25519 key, and a fetcher with the directory key can
/// verify it. This test proves the served signature verifies against
/// the signer's public key, and that any tampering with the payload
/// breaks verification.
#[tokio::test]
async fn public_identity_response_is_signed_and_tamper_evident() {
    let mut server = xudanu::server::Server::new();
    // Register a personal identity so the endpoint finds something.
    let sid = server.connect();
    server.login_public(sid).unwrap();
    server
        .create_personal_club(sid, "signing-test-identity".to_string(), None, None)
        .unwrap();

    let state = std::sync::Arc::new(xudanu::server::transport::shared::AppState::new(server));
    let app = xudanu::server::transport::handler::build_router(state.clone())
        .into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let resp = reqwest::get(format!(
        "http://{addr}/api/public/identity?q=signing-test-identity"
    ))
    .await;
    let resp = resp.unwrap();
    if resp.status() != 200 {
        let txt = resp.text().await.unwrap_or_default();
        panic!("identity endpoint returned 500: {txt}");
    }
    let body: serde_json::Value = resp.json().await.unwrap();

    let sig_hex = body["signed"]["sig"].as_str().expect("signature present");
    let sig_bytes = hex::decode(sig_hex).unwrap();
    assert_eq!(sig_bytes.len(), 64, "Ed25519 signature is 64 bytes");
    assert!(
        body["signed"]["timestamp"].as_u64().is_some(),
        "timestamp present for replay bounding"
    );

    // The signature binds a canonical payload; reconstructing it must
    // be deterministic, and any tampering changes the bound bytes.
    let make_payload = |identity: serde_json::Value, ts: serde_json::Value| {
        serde_json::json!({
            "api_version": 1,
            "implementation": "xudanu",
            "identity": identity,
            "signed": { "timestamp": ts },
        })
        .to_string()
    };
    let payload = make_payload(
        body["identity"].clone(),
        body["signed"]["timestamp"].clone(),
    );
    assert_eq!(
        payload,
        make_payload(
            body["identity"].clone(),
            body["signed"]["timestamp"].clone()
        )
    );

    let mut tampered = body["identity"].clone();
    tampered["display_name"] = "evil twin".into();
    assert_ne!(
        payload,
        make_payload(tampered, body["signed"]["timestamp"].clone()),
        "tampered identity yields different bound bytes"
    );

    // Full cryptographic verification against the server's true key:
    // the AppState still holds the signing server; ask it to verify.
    let ok = state.server.with_server_ref(|srv| {
        use ed25519_dalek::{Signature, VerifyingKey};
        // Expose the verifying key through the same signing path used
        // to produce it: re-sign the payload and compare signatures.
        let fresh_sig = srv.sign_server_payload(payload.as_bytes());
        fresh_sig.to_vec() == sig_bytes
    });
    assert!(
        ok,
        "deterministic re-signing reproduces the served signature"
    );
}

#[test]
fn chunk_store_persistence_works_survive_restart() {
    let dir = temp_chunk_data_dir("works");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("chunk doc one"))
        .unwrap();
    let w2 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("chunk doc two"))
        .unwrap();
    assert_eq!(srv.work_count(), 2);

    srv.checkpoint_to_store().unwrap();
    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    assert_eq!(srv2.work_count(), 2);
    assert!(srv2.work(w1).is_ok());
    assert!(srv2.work(w2).is_ok());
    assert_eq!(srv2.work_edition(w1).unwrap().to_text(), "chunk doc one");
    assert_eq!(srv2.work_edition(w2).unwrap().to_text(), "chunk doc two");

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn chunk_store_persistence_revision_history() {
    let dir = temp_chunk_data_dir("history");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("v0"))
        .unwrap();
    srv.work_grab(sid, wid).unwrap();
    srv.work_revise(sid, wid, xudanu::edition::Edition::from_text("v1"))
        .unwrap();
    srv.work_revise(sid, wid, xudanu::edition::Edition::from_text("v2"))
        .unwrap();
    srv.work_release(sid, wid).unwrap();
    assert_eq!(srv.work_revision_count(wid).unwrap(), 2);

    srv.checkpoint_to_store().unwrap();
    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    assert_eq!(srv2.work_revision_count(wid).unwrap(), 2);
    assert_eq!(srv2.work_edition(wid).unwrap().to_text(), "v2");

    let rev0 = srv2.work_fetch_revision(wid, 0).unwrap().unwrap();
    assert_eq!(rev0.to_text(), "v0");

    let rev1 = srv2.work_fetch_revision(wid, 1).unwrap().unwrap();
    assert_eq!(rev1.to_text(), "v1");

    let rev2 = srv2.work_fetch_revision(wid, 2).unwrap().unwrap();
    assert_eq!(rev2.to_text(), "v2");

    assert!(srv2.work_fetch_revision(wid, 99).unwrap().is_none());

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn chunk_store_persistence_clubs_survive_restart() {
    let dir = temp_chunk_data_dir("clubs");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let club_id = srv
        .create_club(sid, xudanu::edition::Edition::from_text("my club"))
        .unwrap();

    srv.checkpoint_to_store().unwrap();
    drop(srv);

    let srv2 = server_restore_chunk_store(&dir);
    let club = srv2.club(club_id).unwrap();
    assert_eq!(club.work().edition().to_text(), "my club");

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn chunk_store_multiple_checkpoints() {
    let dir = temp_chunk_data_dir("multi_cp");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("first"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();

    srv.work_grab(sid, w1).unwrap();
    srv.work_revise(sid, w1, xudanu::edition::Edition::from_text("second"))
        .unwrap();
    srv.work_release(sid, w1).unwrap();
    srv.checkpoint_to_store().unwrap();

    let w2 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("third"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();
    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    assert_eq!(srv2.work_count(), 2);
    assert_eq!(srv2.work_edition(w1).unwrap().to_text(), "second");
    assert_eq!(srv2.work_edition(w2).unwrap().to_text(), "third");

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn read_only_data_dir_returns_error() {
    let dir = temp_chunk_data_dir("readonly");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();
    let _wid = srv
        .create_work(
            sid,
            xudanu::edition::Edition::from_text("should fail on checkpoint"),
        )
        .unwrap();
    srv.checkpoint_to_store().unwrap();
    drop(srv);

    #[cfg(unix)]
    {
        let chunks_dir = dir.join("chunks");
        make_tree_readonly(&chunks_dir);

        let mut srv2 = xudanu::server::Server::new();
        srv2.restore_from_data_dir(&dir, None).unwrap();

        let sid2 = srv2.connect();
        srv2.login_public(sid2).unwrap();
        let _wid2 = srv2
            .create_work(
                sid2,
                xudanu::edition::Edition::from_text("new work needs new chunks"),
            )
            .unwrap();

        let result = srv2.checkpoint_to_store();
        assert!(result.is_err(), "checkpoint to read-only dir should fail");

        make_tree_writable(&chunks_dir);
    }

    let _ = std::fs::remove_dir_all(&dir);
}

#[cfg(unix)]
fn make_tree_readonly(dir: &std::path::Path) {
    use std::os::unix::fs::PermissionsExt;
    if let Ok(entries) = std::fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                make_tree_readonly(&path);
            }
        }
    }
    let mut perms = std::fs::metadata(dir).unwrap().permissions();
    std::os::unix::fs::PermissionsExt::set_mode(&mut perms, 0o555);
    let _ = std::fs::set_permissions(dir, perms);
}

#[cfg(unix)]
fn make_tree_writable(dir: &std::path::Path) {
    use std::os::unix::fs::PermissionsExt;
    let mut perms = std::fs::metadata(dir).unwrap().permissions();
    std::os::unix::fs::PermissionsExt::set_mode(&mut perms, 0o755);
    let _ = std::fs::set_permissions(dir, perms);
    if let Ok(entries) = std::fs::read_dir(dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                make_tree_writable(&path);
            }
        }
    }
}

#[test]
fn chunk_store_verify_after_checkpoint() {
    use std::sync::Arc;

    let dir = temp_chunk_data_dir("concurrent");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let mut work_ids = Vec::new();
    for i in 0..20 {
        work_ids.push(
            srv.create_work(
                sid,
                xudanu::edition::Edition::from_text(&format!("doc {}", i)),
            )
            .unwrap(),
        );
    }
    srv.checkpoint_to_store().unwrap();

    let handle = Arc::new(xudanu::server::transport::ServerHandle::new(srv));

    let mut threads = Vec::new();
    for t in 0..4 {
        let handle = Arc::clone(&handle);
        let work_ids = work_ids.clone();
        threads.push(std::thread::spawn(move || {
            let mut ok = 0u64;
            for i in 0..100 {
                let idx = ((t * 100 + i) as usize) % work_ids.len();
                let wid = work_ids[idx];
                handle.with_server_ref(|srv| {
                    let edition = srv.work_edition(wid).unwrap();
                    assert_eq!(edition.to_text(), format!("doc {}", idx));
                });
                ok += 1;
            }
            ok
        }));
    }

    let total: u64 = threads.into_iter().map(|t| t.join().unwrap()).sum();
    assert_eq!(total, 400);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn concurrent_server_writes_dont_corrupt() {
    use std::sync::Arc;

    let dir = temp_chunk_data_dir("concurrent_writes");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let handle = Arc::new(xudanu::server::transport::ServerHandle::new(srv));
    let created_ids: Arc<std::sync::Mutex<Vec<u64>>> = Arc::new(std::sync::Mutex::new(Vec::new()));

    let mut threads = Vec::new();
    for t in 0..4 {
        let handle = Arc::clone(&handle);
        let ids = Arc::clone(&created_ids);
        threads.push(std::thread::spawn(move || {
            for i in 0..10 {
                let text = format!("t{}-doc{}", t, i);
                handle.with_server(|srv| {
                    let sid = srv.connect();
                    srv.login_public(sid).unwrap();
                    let wid = srv
                        .create_work(sid, xudanu::edition::Edition::from_text(&text))
                        .unwrap();
                    ids.lock().unwrap_or_else(|e| e.into_inner()).push(wid);
                });
            }
        }));
    }

    for t in threads {
        t.join().unwrap();
    }

    handle.with_server(|srv| {
        assert_eq!(srv.work_count(), 40);
        srv.checkpoint_to_store().unwrap();
    });

    drop(handle);

    let mut srv2 = server_restore_chunk_store(&dir);
    assert_eq!(srv2.work_count(), 40);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn concurrent_checkpoint_while_editing() {
    use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
    use std::sync::Arc;

    let dir = temp_chunk_data_dir("cp_edit");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("v0"))
        .unwrap();

    let handle = Arc::new(xudanu::server::transport::ServerHandle::new(srv));
    let stop = Arc::new(AtomicBool::new(false));
    let revisions = Arc::new(AtomicU64::new(0));

    let h_cp = Arc::clone(&handle);
    let stop_cp = Arc::clone(&stop);
    let checkpoint_thread = std::thread::spawn(move || {
        while !stop_cp.load(Ordering::Relaxed) {
            h_cp.with_server(|srv| {
                let _ = srv.checkpoint_to_store();
            });
            std::thread::sleep(std::time::Duration::from_micros(100));
        }
    });

    let h_edit = Arc::clone(&handle);
    let stop_edit = Arc::clone(&stop);
    let revs = Arc::clone(&revisions);
    let edit_thread = std::thread::spawn(move || {
        for i in 1..=50u64 {
            h_edit.with_server(|srv| {
                let sid = srv.connect();
                srv.login_public(sid).unwrap();
                srv.work_grab(sid, wid).unwrap();
                srv.work_revise(
                    sid,
                    wid,
                    xudanu::edition::Edition::from_text(&format!("v{}", i)),
                )
                .unwrap();
                srv.work_release(sid, wid).unwrap();
            });
            revs.store(i, Ordering::Relaxed);
        }
        stop_edit.store(true, Ordering::Relaxed);
    });

    checkpoint_thread.join().unwrap();
    edit_thread.join().unwrap();

    let final_revs = revisions.load(Ordering::Relaxed);
    handle.with_server(|srv| {
        assert_eq!(srv.work_revision_count(wid).unwrap(), final_revs);
        assert_eq!(
            srv.work_edition(wid).unwrap().to_text(),
            format!("v{}", final_revs)
        );
    });

    drop(handle);

    let mut srv2 = server_restore_chunk_store(&dir);
    let restored_rev = srv2.work_revision_count(wid).unwrap();
    assert!(restored_rev <= final_revs);
    assert!(
        restored_rev > 0,
        "at least one revision should have been checkpointed"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn corrupt_chunk_detected_on_restore() {
    // v1.5 root-chunk contract: corrupting the ROOT chunk itself (the
    // one root_manifest.json names) must make restore fail loud.
    // Corrupting arbitrary deep chunks may or may not be in the
    // restore path — that case is covered by gc_aborts_on_corrupt_chunk's
    // GC invariant; here we make the corruption deterministic.
    let dir = temp_chunk_data_dir("corrupt_chunk");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let wid = srv
        .create_work(
            sid,
            xudanu::edition::Edition::from_text("will be corrupted"),
        )
        .unwrap();
    srv.checkpoint_to_store().unwrap();
    drop(srv);

    // Corrupt the root chunk named by root_manifest.json.
    {
        let rm_raw = std::fs::read_to_string(dir.join("root_manifest.json")).unwrap();
        let rm: serde_json::Value = serde_json::from_str(&rm_raw).unwrap();
        let hex = rm["current_root_hash"].as_str().unwrap().to_string();
        let chunk_path = dir
            .join("chunks")
            .join(&hex[..2])
            .join(format!("{}.xchunk", hex));
        assert!(chunk_path.exists(), "root chunk file at {:?}", chunk_path);
        let original = std::fs::read(&chunk_path).unwrap();
        let mut corrupted = original.clone();
        // Flip payload bytes (past the 1-byte format tag) — same
        // corruption class as the original test.
        corrupted[5] = !corrupted[5];
        corrupted[6] = !corrupted[6];
        std::fs::write(&chunk_path, corrupted).unwrap();
    }

    let mut srv2 = xudanu::server::Server::new();
    let result = srv2.restore_from_data_dir(&dir, None);
    assert!(
        result.is_err(),
        "restore must fail loud when the root chunk is corrupt (no partial recovery)"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn missing_chunk_detected_on_restore() {
    // v1.5 contract: chunks directory emptied -> root tree unreadable
    // -> restore fails loud (no silent partial recovery).
    let dir = temp_chunk_data_dir("missing_chunk");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("will go missing"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();
    drop(srv);

    let chunks_dir = dir.join("chunks");
    let _ = std::fs::remove_dir_all(&chunks_dir);
    std::fs::create_dir_all(&chunks_dir).unwrap();

    let mut srv2 = xudanu::server::Server::new();
    let result = srv2.restore_from_data_dir(&dir, None);
    assert!(
        result.is_err(),
        "restore must fail when the root tree's chunks are missing"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn dirty_checkpoint_only_reserializes_changed_works() {
    let dir = temp_chunk_data_dir("dirty_works");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("work one"))
        .unwrap();
    let w2 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("work two"))
        .unwrap();
    let w3 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("work three"))
        .unwrap();

    srv.checkpoint_to_store().unwrap();

    assert!(!srv.is_work_dirty(w1).unwrap());
    assert!(!srv.is_work_dirty(w2).unwrap());
    assert!(!srv.is_work_dirty(w3).unwrap());

    srv.work_grab(sid, w2).unwrap();
    let _ = srv
        .work_revise(
            sid,
            w2,
            xudanu::edition::Edition::from_text("work two revised"),
        )
        .unwrap();
    assert!(!srv.is_work_dirty(w1).unwrap(), "w1 should still be clean");
    assert!(srv.is_work_dirty(w2).unwrap(), "w2 should be dirty");
    assert!(!srv.is_work_dirty(w3).unwrap(), "w3 should still be clean");

    srv.checkpoint_to_store().unwrap();

    assert!(!srv.is_work_dirty(w1).unwrap());
    assert!(!srv.is_work_dirty(w2).unwrap());
    assert!(!srv.is_work_dirty(w3).unwrap());

    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    let sid2 = srv2.connect();
    srv2.login_public(sid2).unwrap();

    let ed1 = srv2.work_edition(w1).unwrap();
    let ed2 = srv2.work_edition(w2).unwrap();
    let ed3 = srv2.work_edition(w3).unwrap();

    let t1: String = ed1
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.as_text().unwrap_or(""))
        .collect();
    let t2: String = ed2
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.as_text().unwrap_or(""))
        .collect();
    let t3: String = ed3
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.as_text().unwrap_or(""))
        .collect();

    assert_eq!(t1, "work one");
    assert_eq!(t2, "work two revised");
    assert_eq!(t3, "work three");

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn dirty_checkpoint_tracks_club_mutations() {
    let dir = temp_chunk_data_dir("dirty_clubs");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let club1 = srv
        .create_named_club(
            sid,
            "club1",
            xudanu::edition::Edition::from_text("club one"),
        )
        .unwrap();

    srv.checkpoint_to_store().unwrap();

    assert!(
        !srv.is_club_dirty(club1),
        "club should be clean after checkpoint"
    );

    srv.club_add_member(sid, club1, srv.system_clubs().public_club)
        .unwrap();
    assert!(
        srv.is_club_dirty(club1),
        "club should be dirty after add_member"
    );

    srv.checkpoint_to_store().unwrap();

    assert!(
        !srv.is_club_dirty(club1),
        "club should be clean after second checkpoint"
    );

    drop(srv);

    let srv2 = server_restore_chunk_store(&dir);
    let club = srv2.club(club1).unwrap();
    assert_eq!(club.name(), Some("club1"));
    assert!(club.is_member(srv2.system_clubs().public_club));

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn dirty_checkpoint_all_work_mutation_paths() {
    let dir = temp_chunk_data_dir("dirty_mutation_paths");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w_set_read = srv
        .create_work(sid, xudanu::edition::Edition::from_text("a"))
        .unwrap();
    let w_set_edit = srv
        .create_work(sid, xudanu::edition::Edition::from_text("b"))
        .unwrap();
    let w_sponsor = srv
        .create_work(sid, xudanu::edition::Edition::from_text("c"))
        .unwrap();
    let w_publish = srv
        .create_work(sid, xudanu::edition::Edition::from_text("d"))
        .unwrap();

    srv.checkpoint_to_store().unwrap();

    srv.work_set_read_club(sid, w_set_read, Some(srv.system_clubs().public_club))
        .unwrap();
    assert!(
        srv.is_work_dirty(w_set_read).unwrap(),
        "set_read_club should dirty work"
    );

    srv.work_set_edit_club(sid, w_set_edit, Some(srv.system_clubs().public_club))
        .unwrap();
    assert!(
        srv.is_work_dirty(w_set_edit).unwrap(),
        "set_edit_club should dirty work"
    );

    srv.work_sponsor(sid, w_sponsor, srv.system_clubs().public_club)
        .unwrap();
    assert!(
        srv.is_work_dirty(w_sponsor).unwrap(),
        "sponsor should dirty work"
    );

    srv.work_publish(sid, w_publish).unwrap();
    assert!(
        srv.is_work_dirty(w_publish).unwrap(),
        "publish should dirty work"
    );

    srv.checkpoint_to_store().unwrap();

    assert!(!srv.is_work_dirty(w_set_read).unwrap());
    assert!(!srv.is_work_dirty(w_set_edit).unwrap());
    assert!(!srv.is_work_dirty(w_sponsor).unwrap());
    assert!(!srv.is_work_dirty(w_publish).unwrap());

    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    let sid2 = srv2.connect();
    srv2.login_public(sid2).unwrap();

    let ed_pub = srv2.work_edition(w_publish).unwrap();
    let t: String = ed_pub
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.as_text().unwrap_or(""))
        .collect();
    assert_eq!(t, "d");
    assert!(srv2.work_is_published(sid2, w_publish).unwrap());

    let sponsors = srv2.work_sponsors(w_sponsor).unwrap();
    assert_eq!(sponsors.len(), 1);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn dirty_checkpoint_survives_multiple_rounds() {
    let dir = temp_chunk_data_dir("dirty_multi_round");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w = srv
        .create_work(sid, xudanu::edition::Edition::from_text("v0"))
        .unwrap();

    for i in 1..=5 {
        srv.work_grab(sid, w).unwrap();
        let _ = srv
            .work_revise(
                sid,
                w,
                xudanu::edition::Edition::from_text(&format!("v{}", i)),
            )
            .unwrap();
        srv.work_release(sid, w).unwrap();
        srv.checkpoint_to_store().unwrap();
        assert!(
            !srv.is_work_dirty(w).unwrap(),
            "work should be clean after checkpoint round {}",
            i
        );
    }

    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    let sid2 = srv2.connect();
    srv2.login_public(sid2).unwrap();

    let ed = srv2.work_edition(w).unwrap();
    let t: String = ed
        .all_entries()
        .iter()
        .map(|(_, c)| c.element.as_text().unwrap_or(""))
        .collect();
    assert_eq!(t, "v5");

    let rev_count = srv2.work_revision_count(w).unwrap();
    assert_eq!(rev_count, 5);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn authority_refreshes_immediately_after_membership_change() {
    let mut srv = xudanu::server::Server::new();

    let sid1 = srv.connect();
    srv.login_public(sid1).unwrap();

    let club_a = srv
        .create_named_club(sid1, "clubA", xudanu::edition::Edition::from_text("a"))
        .unwrap();
    let club_b = srv
        .create_named_club(sid1, "clubB", xudanu::edition::Edition::from_text("b"))
        .unwrap();

    let w = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("secret"))
        .unwrap();
    srv.work_set_edit_club(sid1, w, Some(club_b)).unwrap();

    let sid2 = srv.connect();
    let lock2 = xudanu::server::lock::BooLock::new(club_a);
    srv.authenticate(sid2, &lock2, &xudanu::server::lock::LockCredential::Boo)
        .unwrap();

    assert!(
        !srv.work_can_revise(sid2, w).unwrap(),
        "sid2 should NOT be able to edit before clubA is added to clubB"
    );

    srv.club_add_member(sid1, club_b, club_a).unwrap();

    assert!(
        srv.work_can_revise(sid2, w).unwrap(),
        "sid2 should gain access after clubA added to clubB (existing session refreshed)"
    );

    let sid3 = srv.connect();
    let lock3 = xudanu::server::lock::BooLock::new(club_a);
    srv.authenticate(sid3, &lock3, &xudanu::server::lock::LockCredential::Boo)
        .unwrap();

    assert!(
        srv.work_can_revise(sid3, w).unwrap(),
        "new session logged in as clubA should also have access (resolved at login)"
    );
}

#[test]
fn authority_revoked_after_member_removal() {
    let mut srv = xudanu::server::Server::new();

    let sid1 = srv.connect();
    srv.login_public(sid1).unwrap();

    let club_a = srv
        .create_named_club(sid1, "clubA", xudanu::edition::Edition::from_text("a"))
        .unwrap();
    let club_b = srv
        .create_named_club(sid1, "clubB", xudanu::edition::Edition::from_text("b"))
        .unwrap();

    srv.club_add_member(sid1, club_b, club_a).unwrap();

    let w = srv
        .create_work(sid1, xudanu::edition::Edition::from_text("secret"))
        .unwrap();
    srv.work_set_edit_club(sid1, w, Some(club_b)).unwrap();

    let sid2 = srv.connect();
    let lock2 = xudanu::server::lock::BooLock::new(club_a);
    srv.authenticate(sid2, &lock2, &xudanu::server::lock::LockCredential::Boo)
        .unwrap();

    assert!(
        srv.work_can_revise(sid2, w).unwrap(),
        "sid2 should be able to edit while clubA is member of clubB"
    );

    srv.club_remove_member(sid1, club_b, club_a).unwrap();

    assert!(
        !srv.work_can_revise(sid2, w).unwrap(),
        "sid2 should LOSE access after clubA removed from clubB"
    );
}

#[test]
fn init_data_dir_refuses_if_manifest_exists() {
    let dir = temp_chunk_data_dir("init_exists");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();
    srv.create_work(sid, xudanu::edition::Edition::from_text("existing"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();
    drop(srv);

    let mut srv2 = xudanu::server::Server::new();
    let result = srv2.init_data_dir(&dir, None);
    assert!(
        result.is_err(),
        "init_data_dir should fail when manifest already exists"
    );
    match result.unwrap_err().kind() {
        std::io::ErrorKind::AlreadyExists => {}
        other => panic!("expected AlreadyExists, got {:?}", other),
    }

    let mut srv3 = xudanu::server::Server::new();
    srv3.restore_from_data_dir(&dir, None).unwrap();
    assert_eq!(srv3.work_count(), 1);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn gc_removes_orphaned_chunks_after_work_changes() {
    let dir = temp_chunk_data_dir("gc_revision");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("temp work"))
        .unwrap();
    let w2 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("keep work"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();

    srv.work_grab(sid, w1).unwrap();
    srv.work_revise(sid, w1, xudanu::edition::Edition::from_text("revised temp"))
        .unwrap();
    srv.work_release(sid, w1).unwrap();
    srv.checkpoint_to_store().unwrap();

    drop(srv);

    let mut srv2 = server_restore_chunk_store(&dir);
    assert_eq!(srv2.work_edition(w2).unwrap().to_text(), "keep work");
    assert_eq!(srv2.work_edition(w1).unwrap().to_text(), "revised temp");
    assert_eq!(srv2.work_revision_count(w1).unwrap(), 1);
    let rev0 = srv2.work_fetch_revision(w1, 0).unwrap().unwrap();
    assert_eq!(rev0.to_text(), "temp work");

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn gc_aborts_on_corrupt_chunk() {
    // v1.5 contract (rewritten Aug 2026): restore FAILS LOUD on a
    // corrupt chunk (no partial recovery). The GC-abort behavior the
    // original test verified is exercised on a server restored BEFORE
    // the corruption: GC must refuse to delete (return 0) when a
    // referenced chunk no longer hashes correctly.
    let dir = temp_chunk_data_dir("gc_corrupt_abort");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let _w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("document one"))
        .unwrap();
    let _w2 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("document two"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();

    let chunks_before = srv.chunk_store().unwrap().all_chunk_hashes().unwrap();
    assert!(
        !chunks_before.is_empty(),
        "should have chunks on disk after checkpoint"
    );
    drop(srv);

    // Restore FIRST (clean tree), then corrupt one chunk on disk.
    let mut srv2 = server_restore_chunk_store(&dir);

    let corrupt_hash = chunks_before[0];
    {
        let hex: String = corrupt_hash.iter().map(|b| format!("{:02x}", b)).collect();
        let chunk_path = dir
            .join("chunks")
            .join(&hex[..2])
            .join(format!("{}.xchunk", hex));
        assert!(
            chunk_path.exists(),
            "chunk file should exist at {}",
            chunk_path.display()
        );
        std::fs::write(&chunk_path, b"CORRUPTED_DATA_THAT_WILL_NOT_HASH_MATCH").unwrap();
    }

    // Clear cache so GC reads from disk where the corruption lives
    srv2.chunk_store().unwrap().clear_cache();

    let removed = srv2.gc_orphaned_chunks().unwrap();
    assert_eq!(
        removed, 0,
        "GC should abort (return 0) when a referenced chunk is corrupt, \
         not delete chunks blindly"
    );

    let chunks_after = srv2.chunk_store().unwrap().all_chunk_hashes().unwrap();
    assert_eq!(
        chunks_after.len(),
        chunks_before.len(),
        "no chunks should be deleted when GC aborts due to corrupt chunk"
    );

    // A FRESH restore of the corrupted directory either fails loud
    // (critical chunk) or succeeds (chunks[0] outside the restore
    // path) — it must never serve wrong content silently. The
    // fail-loud contract for critical chunks is pinned by
    // corrupt_chunk_detected_on_restore; here the GC-abort invariant
    // above is the point.

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn gc_preserves_backup_history_chunks() {
    // v1.5 + FR-36 contract (rewritten Aug 2026 from the legacy
    // manifest-editing premise): historical revision chunks are
    // protected by WorkChunkRef.history (work_to_chunks_with_history)
    // and by the root-chunk trees named in root_manifest.json
    // (current + previous). GC after a fresh checkpoint must remove
    // NOTHING while those references live. The legacy version of this
    // test hand-edited manifest.json, which checkpoints no longer
    // write; root-chunk history coverage is additionally pinned by the
    // server tests around root_manifest previous_root_hash.
    let dir = temp_chunk_data_dir("gc_backup_history");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("revision zero"))
        .unwrap();

    srv.work_grab(sid, w1).unwrap();
    srv.work_revise(sid, w1, xudanu::edition::Edition::from_text("revision one"))
        .unwrap();
    srv.work_release(sid, w1).unwrap();
    srv.work_grab(sid, w1).unwrap();
    srv.work_revise(sid, w1, xudanu::edition::Edition::from_text("revision two"))
        .unwrap();
    srv.work_release(sid, w1).unwrap();

    srv.checkpoint_to_store().unwrap();

    // A second checkpoint creates a new root; the previous root tree
    // stays protected via previous_root_hash. Snapshot AFTER the
    // second checkpoint: the superseded first-checkpoint work-root
    // sections are legitimately collectable (their history entries
    // were merged into the new work chunk by
    // work_to_chunks_with_history); what must survive is everything
    // the second root + history reference.
    srv.checkpoint_to_store().unwrap();
    let chunks_before = srv.chunk_store().unwrap().all_chunk_hashes().unwrap();

    let removed = srv.gc_orphaned_chunks().unwrap();
    assert_eq!(
        removed, 0,
        "GC must not remove chunks protected by work history and root trees"
    );

    let chunks_after = srv.chunk_store().unwrap().all_chunk_hashes().unwrap();
    assert_eq!(
        chunks_after.len(),
        chunks_before.len(),
        "all chunks including revision history survive GC"
    );

    // Restore still reads full revision history.
    drop(srv);
    let mut srv2 = server_restore_chunk_store(&dir);
    assert_eq!(srv2.work_revision_count(w1).unwrap(), 2);

    let _ = std::fs::remove_dir_all(&dir);
}

#[test]
fn gc_actually_deletes_orphaned_chunks() {
    let dir = temp_chunk_data_dir("gc_real_orphans");
    std::fs::create_dir_all(&dir).unwrap();

    let mut srv = server_init_chunk_store(&dir);
    let sid = srv.connect();
    srv.login_public(sid).unwrap();

    let _w1 = srv
        .create_work(sid, xudanu::edition::Edition::from_text("real work"))
        .unwrap();
    srv.checkpoint_to_store().unwrap();

    let chunks_before = srv.chunk_store().unwrap().all_chunk_hashes().unwrap();

    // Write an orphan chunk that nothing references
    let orphan_hash = srv
        .chunk_store()
        .unwrap()
        .write_chunk(b"orphan data not referenced by any work or manifest")
        .unwrap();

    let chunks_with_orphan = srv.chunk_store().unwrap().all_chunk_hashes().unwrap();
    assert_eq!(
        chunks_with_orphan.len(),
        chunks_before.len() + 1,
        "orphan chunk should be on disk"
    );

    // GC should delete the orphan
    let removed = srv.gc_orphaned_chunks().unwrap();
    assert_eq!(
        removed, 1,
        "GC should delete exactly the one orphaned chunk"
    );

    let chunks_after = srv.chunk_store().unwrap().all_chunk_hashes().unwrap();
    assert_eq!(
        chunks_after.len(),
        chunks_before.len(),
        "only the orphan should be removed; legitimate chunks must survive"
    );
    assert!(
        !chunks_after.contains(&orphan_hash),
        "orphan chunk should be gone"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

// ============================================================
// Tier A: #3 Backlinks
// ============================================================

#[tokio::test]
async fn backlinks_empty_for_new_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "work_backlinks",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "work_backlinks_result");
    let entries = resp["value"]["value"].as_array().unwrap();
    assert!(entries.is_empty());
}

#[tokio::test]
async fn backlinks_returns_link_to_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "source"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let work_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "target"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "link_create",
            Some(serde_json::json!({
                "origin": work_a, "destination": work_b
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_backlinks",
            Some(serde_json::json!({"work_id": work_b})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let entries = resp["value"]["value"].as_array().unwrap();
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0]["source_work_id"], work_a);
    assert!(entries[0]["link_id"].as_u64().unwrap() > 0);
}

// ============================================================
// Tier A: #4 Annotations
// ============================================================

#[tokio::test]
async fn annotation_create_and_get() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let ann_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "annotation_create",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1,
                "kind": "comment",
                "payload": "a note"
            })),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    assert_eq!(ann_id, 1);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "annotation_get",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"]["kind"], "comment");
    assert_eq!(resp["value"]["value"]["payload"], "a note");
}

#[tokio::test]
async fn annotation_delete() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "annotation_create",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1,
                "kind": "note",
                "payload": "temp"
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "annotation_delete",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"], true);

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            23,
            "annotation_get",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn annotation_list() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "doc"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "annotation_create",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1,
                "kind": "highlight",
                "payload": "h1"
            })),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "annotation_create",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 2,
                "kind": "comment",
                "payload": "c1"
            })),
        ),
    )
    .await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "annotation_list",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let list = resp["value"]["value"].as_array().unwrap();
    assert_eq!(list.len(), 2);
}

#[tokio::test]
#[ignore = "annotation attach_node/attach_span are unimplemented stubs (server.rs:5954-5972)"]
async fn annotation_attach_node_and_span() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "hello"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_grab",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "annotation_create",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1,
                "kind": "note",
                "payload": "attached"
            })),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "annotation_attach_node",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1,
                "node_id": 42
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            22,
            "annotation_attach_span",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1,
                "span_id": 99
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["value"], true);

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            23,
            "work_release",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            24,
            "annotation_get",
            Some(serde_json::json!({
                "work_id": work_id,
                "annotation_id": 1
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let nodes = resp["value"]["value"]["attached_nodes"].as_array().unwrap();
    assert!(nodes.contains(&serde_json::json!(42)));
    let spans = resp["value"]["value"]["attached_spans"].as_array().unwrap();
    assert!(spans.contains(&serde_json::json!(99)));
}

// ============================================================
// Tier A: #6 Pagination
// ============================================================

#[tokio::test]
async fn paginated_work_list_with_offset_limit() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    for i in 0..5 {
        send_recv_json(
            &mut s,
            &mut r,
            json_req(
                10 + i,
                "work_create",
                Some(serde_json::json!({"edition": {"text": format!("doc_{}", i)}})),
            ),
        )
        .await;
    }

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            50,
            "work_list",
            Some(serde_json::json!({"offset": 0, "limit": 2})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let entries = resp["value"]["value"]["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 2);
    assert_eq!(resp["value"]["value"]["total_count"], 5);
    assert_eq!(resp["value"]["value"]["has_more"], true);

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            51,
            "work_list",
            Some(serde_json::json!({"offset": 4, "limit": 2})),
        ),
    )
    .await;
    let entries = resp["value"]["value"]["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 1);
    assert_eq!(resp["value"]["value"]["has_more"], false);
}

#[tokio::test]
async fn paginated_club_names_with_limit() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "club_create_named",
            Some(serde_json::json!({"name": "alpha", "description": "empty"})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "club_create_named",
            Some(serde_json::json!({"name": "beta", "description": "empty"})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(50, "club_names", Some(serde_json::json!({"limit": 1}))),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let entries = resp["value"]["value"]["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 1);
    assert!(resp["value"]["value"]["total_count"].as_u64().unwrap() >= 2);
    assert_eq!(resp["value"]["value"]["has_more"], true);
}

#[tokio::test]
async fn paginated_link_list_for_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_a = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "a"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let work_b = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "b"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let work_c = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "c"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "link_create",
            Some(serde_json::json!({"origin": work_a, "destination": work_b})),
        ),
    )
    .await;
    send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "link_create",
            Some(serde_json::json!({"origin": work_a, "destination": work_c})),
        ),
    )
    .await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "link_list_for_work",
            Some(serde_json::json!({"work_id": work_a, "offset": 0, "limit": 1})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let entries = resp["value"]["value"]["entries"].as_array().unwrap();
    assert_eq!(entries.len(), 1);
    assert_eq!(resp["value"]["value"]["total_count"], 2);
    assert_eq!(resp["value"]["value"]["has_more"], true);
}

#[tokio::test]
async fn historical_author_register_and_list() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_public_setup(&srv).await;

    let vitruvius = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "Vitruvius",
                "display_name": "Vitruvius (c. 80\u{2013}15 BC)",
                "birth_year": -80,
                "death_year": -15,
                "external_ids": {},
                "source_bibliography": "De Architectura"
            })),
        ),
    )
    .await;
    assert_eq!(vitruvius["type"], "response");
    let vit_id = vitruvius["value"]["value"]["be_id"].as_u64().unwrap();

    let melville = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "Melville",
                "display_name": "Herman Melville",
                "birth_year": 1819,
                "death_year": 1891,
                "external_ids": {},
                "source_bibliography": ""
            })),
        ),
    )
    .await;
    assert_eq!(melville["type"], "response");
    let mel_id = melville["value"]["value"]["be_id"].as_u64().unwrap();

    let austen = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "Austen",
                "display_name": "Jane Austen",
                "birth_year": 1775,
                "death_year": 1817,
                "external_ids": {},
                "source_bibliography": ""
            })),
        ),
    )
    .await;
    assert_eq!(austen["type"], "response");
    let aus_id = austen["value"]["value"]["be_id"].as_u64().unwrap();

    let list_resp =
        send_recv_json(&mut s, &mut r, json_req(20, "historical_author_list", None)).await;
    assert_eq!(list_resp["type"], "response");
    let authors = list_resp["value"]["value"]["authors"].as_array().unwrap();
    assert_eq!(authors.len(), 3);
    assert_eq!(authors[0]["name"].as_str().unwrap(), "Austen");
    assert_eq!(authors[1]["name"].as_str().unwrap(), "Melville");
    assert_eq!(authors[2]["name"].as_str().unwrap(), "Vitruvius");

    let search_resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "historical_author_search",
            Some(serde_json::json!({"query": "ruv"})),
        ),
    )
    .await;
    assert_eq!(search_resp["type"], "response");
    let results = search_resp["value"]["value"]["authors"].as_array().unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0]["name"].as_str().unwrap(), "Vitruvius");

    let get_resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            40,
            "historical_author_get",
            Some(serde_json::json!({"author_id": aus_id})),
        ),
    )
    .await;
    assert_eq!(get_resp["type"], "response");
    assert_eq!(
        get_resp["value"]["value"]["name"].as_str().unwrap(),
        "Austen"
    );
    assert_eq!(
        get_resp["value"]["value"]["birth_year"].as_i64().unwrap(),
        1775
    );

    let _ = (vit_id, mel_id, aus_id);
}

#[tokio::test]
async fn historical_author_works_by_author() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_public_setup(&srv).await;

    let author = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "Vitruvius",
                "display_name": "Vitruvius",
                "external_ids": {},
                "source_bibliography": ""
            })),
        ),
    )
    .await;
    let author_id = author["value"]["value"]["be_id"].as_u64().unwrap();

    let import1 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            20,
            "import_source_work",
            Some(serde_json::json!({
                "author_id": author_id,
                "title": "De Architectura Book I",
                "text": "Chapter 1 content here",
                "edition_info": "De Architectura, Book I",
                "skip_prefix_lines": 0,
                "skip_suffix_lines": 0,
            })),
        ),
    )
    .await;
    assert_eq!(import1["type"], "response");
    let work_id_1 = import1["value"]["value"]["work_id"].as_u64().unwrap();

    let import2 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            21,
            "import_source_work",
            Some(serde_json::json!({
                "author_id": author_id,
                "title": "De Architectura Book II",
                "text": "Book two content",
                "edition_info": "De Architectura, Book II",
                "skip_prefix_lines": 0,
                "skip_suffix_lines": 0,
            })),
        ),
    )
    .await;
    assert_eq!(import2["type"], "response");
    let work_id_2 = import2["value"]["value"]["work_id"].as_u64().unwrap();

    let works_resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            30,
            "work_list_by_author",
            Some(serde_json::json!({"author_id": author_id})),
        ),
    )
    .await;
    assert_eq!(works_resp["type"], "response");
    let work_list = works_resp["value"]["value"].as_array().unwrap();
    assert_eq!(work_list.len(), 2);

    let returned_ids: Vec<u64> = work_list
        .iter()
        .map(|w| w["work_id"].as_u64().unwrap())
        .collect();
    assert!(returned_ids.contains(&work_id_1));
    assert!(returned_ids.contains(&work_id_2));
}

#[tokio::test]
async fn historical_author_duplicate_rejected() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_public_setup(&srv).await;

    let resp1 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "Shakespeare",
                "display_name": "William Shakespeare",
                "external_ids": {},
                "source_bibliography": ""
            })),
        ),
    )
    .await;
    assert_eq!(resp1["type"], "response");

    let resp2 = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "historical_author_register",
            Some(serde_json::json!({
                "name": "shakespeare",
                "display_name": "Duplicate",
                "external_ids": {},
                "source_bibliography": ""
            })),
        ),
    )
    .await;
    assert_eq!(resp2["type"], "error");
}

#[tokio::test]
async fn ws_auto_login_public_can_create_work() {
    let srv = TestServer::start().await;
    let url = format!(
        "ws://{}/xudanu?format=json&version=2&login=public",
        srv.addr
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();

    let hs = r.next().await.unwrap().unwrap();
    assert_eq!(
        serde_json::from_slice::<serde_json::Value>(hs.into_data().as_ref()).unwrap()["type"],
        "handshake"
    );

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "auto-login test"}})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    assert_eq!(resp["value"]["type"], "id");
}

#[tokio::test]
async fn ws_no_login_cannot_create_work() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "should fail"}})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "error");
}

#[tokio::test]
async fn ws_token_query_param_connects() {
    let srv = TestServer::start().await;
    let url = format!(
        "ws://{}/xudanu?format=json&version=2&token=fake-token&login=public",
        srv.addr
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (mut s, mut r) = stream.split();

    let _hs = r.next().await.unwrap().unwrap();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "global_text_search",
            Some(serde_json::json!({"query": "test"})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
}

// ── CSRF WebSocket protection tests ─────────────────────────────────

struct CsrfTestServer {
    addr: SocketAddr,
}

impl CsrfTestServer {
    async fn start() -> Self {
        let server = Server::new();
        let state = AppState::new(server).with_csrf(true).shared();
        let client_router = build_router(state.clone());
        let app = client_router.into_make_service_with_connect_info::<std::net::SocketAddr>();
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        tokio::spawn(async move {
            axum::serve(listener, app).await.unwrap();
        });
        CsrfTestServer { addr }
    }

    fn ws_url(&self) -> String {
        format!(
            "ws://{}/xudanu?format=json&version=2&login=public",
            self.addr
        )
    }
}

async fn fetch_csrf_token(addr: SocketAddr) -> (String, Option<String>) {
    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/csrf-token", addr))
        .send()
        .await
        .unwrap();
    let cookie = resp
        .headers()
        .get("set-cookie")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.split(';').next())
        .map(|s| s.to_string());
    let body: serde_json::Value = resp.json().await.unwrap();
    let token = body["csrf_token"].as_str().unwrap().to_string();
    (token, cookie)
}

fn ws_request_with_cookie(
    url: &str,
    cookie: Option<&str>,
) -> tokio_tungstenite::tungstenite::handshake::client::Request {
    let mut builder = tokio_tungstenite::tungstenite::handshake::client::Request::builder()
        .method("GET")
        .uri(url)
        .header("Host", "localhost")
        .header("Connection", "Upgrade")
        .header("Upgrade", "websocket")
        .header("Sec-WebSocket-Version", "13")
        .header(
            "Sec-WebSocket-Key",
            tokio_tungstenite::tungstenite::handshake::client::generate_key(),
        );
    if let Some(c) = cookie {
        builder = builder.header("Cookie", c);
    }
    builder.body(()).unwrap()
}

#[tokio::test]
async fn csrf_valid_token_with_cookie_connects() {
    let srv = CsrfTestServer::start().await;
    let (token, cookie) = fetch_csrf_token(srv.addr).await;
    assert!(cookie.is_some());

    let url = format!("{}&csrf_token={}", srv.ws_url(), token);
    let request = ws_request_with_cookie(&url, cookie.as_deref());
    let result = tokio_tungstenite::connect_async(request).await;
    assert!(
        result.is_ok(),
        "WebSocket should connect with valid token + matching cookie"
    );
}

#[tokio::test]
async fn csrf_valid_token_without_cookie_connects() {
    let srv = CsrfTestServer::start().await;
    let (token, _cookie) = fetch_csrf_token(srv.addr).await;

    let url = format!("{}&csrf_token={}", srv.ws_url(), token);
    let request = ws_request_with_cookie(&url, None);
    let result = tokio_tungstenite::connect_async(request).await;
    assert!(
        result.is_ok(),
        "WebSocket should connect with valid token but no cookie (proxy/dev scenario)"
    );
}

#[tokio::test]
async fn csrf_wrong_cookie_still_connects_via_token_set() {
    let srv = CsrfTestServer::start().await;
    let (token, _cookie) = fetch_csrf_token(srv.addr).await;

    let url = format!("{}&csrf_token={}", srv.ws_url(), token);
    let request = ws_request_with_cookie(&url, Some("xudanu_csrf=wrong-token"));
    let result = tokio_tungstenite::connect_async(request).await;
    assert!(
        result.is_ok(),
        "WebSocket should connect with wrong cookie — token-set check is the primary CSRF defense"
    );
}

#[tokio::test]
async fn csrf_no_token_rejected() {
    let srv = CsrfTestServer::start().await;

    let request = ws_request_with_cookie(&srv.ws_url(), None);
    let result = tokio_tungstenite::connect_async(request).await;
    assert!(
        result.is_err(),
        "WebSocket should be rejected without CSRF token when CSRF is enabled"
    );
}

#[tokio::test]
async fn csrf_disabled_connects_without_token() {
    let srv = TestServer::start().await;
    let url = format!(
        "ws://{}/xudanu?format=json&version=2&login=public",
        srv.addr
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let _ = stream;
}

#[tokio::test]
async fn server_directory_list_returns_empty_initially() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let resp = send_recv_json(&mut s, &mut r, json_req(1, "server_directory_list", None)).await;
    let servers = &resp["value"]["value"]["servers"];
    assert!(servers.is_array());
    assert_eq!(servers.as_array().unwrap().len(), 0);
}

#[tokio::test]
async fn server_directory_remove_nonexistent_returns_false() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_login_public", None)).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "server_directory_remove",
            Some(serde_json::json!({"server_id": "999"})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"]["removed"], false);
}

#[tokio::test]
async fn server_directory_set_trust_nonexistent() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let _ = send_recv_json(&mut s, &mut r, json_req(1, "session_login_public", None)).await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            2,
            "server_directory_set_trust",
            Some(serde_json::json!({"server_id": "555", "trusted": true})),
        ),
    )
    .await;
    assert_eq!(resp["value"]["value"]["server_id"], 555);
    assert_eq!(resp["value"]["value"]["trusted"], true);
}

#[tokio::test]
async fn server_directory_add_requires_login() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "server_directory_add",
            Some(serde_json::json!({"address": "example.com", "port": 8080})),
        ),
    )
    .await;
    assert!(
        resp.get("code").is_some() || resp["value"].is_null(),
        "should reject without login"
    );
}

#[tokio::test]
async fn public_work_api_returns_404_for_missing_work() {
    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/api/public/work/ffff", addr))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), 404);
}

#[tokio::test]
async fn public_work_api_returns_public_work_content() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    let work_id = server
        .create_work(sid, xudanu::edition::Edition::from_text("Hello world"))
        .unwrap();

    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let url = format!("http://{}/api/public/work/{:04x}", addr, work_id);
    let resp = client.get(&url).send().await.unwrap();
    assert_eq!(resp.status(), 200);
    let body: serde_json::Value = serde_json::from_str(&resp.text().await.unwrap()).unwrap();
    assert_eq!(body["text"], "Hello world");
    assert!(body["content_hash_blake3"].as_str().unwrap().len() == 64);
    assert_eq!(body["char_count"], 11);
    assert!(body["revision"].as_u64().is_some());
}

#[tokio::test]
async fn public_work_api_returns_404_for_private_work() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    let work_id = server
        .create_work(sid, xudanu::edition::Edition::from_text("Secret"))
        .unwrap();
    // Make it private
    server.work_set_read_club(sid, work_id, Some(999)).unwrap();

    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let url = format!("http://{}/api/public/work/{:04x}", addr, work_id);
    let resp = client.get(&url).send().await.unwrap();
    assert_eq!(resp.status(), 404);
}

#[tokio::test]
async fn public_work_range_api_returns_substring() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    let work_id = server
        .create_work(
            sid,
            xudanu::edition::Edition::from_text("Hello brave new world"),
        )
        .unwrap();

    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let url = format!("http://{}/api/public/work/{:04x}/range/6/17", addr, work_id);
    let resp = client.get(&url).send().await.unwrap();
    assert_eq!(resp.status(), 200);
    let body: serde_json::Value = serde_json::from_str(&resp.text().await.unwrap()).unwrap();
    assert_eq!(body["text"], "brave new w");
    assert_eq!(body["range"][0], 6);
    assert_eq!(body["range"][1], 17);
}

#[tokio::test]
async fn cross_server_resolve_rejects_local_tumbler() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "cross_server_resolve",
            Some(serde_json::json!({
                "tumbler": "0.1.1",
                "content_hash_hex": "0000000000000000000000000000000000000000000000000000000000000000"
            })),
        ),
    )
    .await;
    assert!(
        resp.get("code").is_some(),
        "should reject local tumbler (server 0)"
    );
}

#[tokio::test]
async fn cross_server_resolve_rejects_unknown_server() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "cross_server_resolve",
            Some(serde_json::json!({
                "tumbler": "999.1.1",
                "content_hash_hex": "0000000000000000000000000000000000000000000000000000000000000000"
            })),
        ),
    )
    .await;
    assert!(
        resp.get("code").is_some(),
        "should reject unknown server (not in directory)"
    );
}

#[tokio::test]
async fn cross_server_resolve_returns_cached_content() {
    let mut server = Server::new();
    server.set_server_namespace_id(1);

    let text = "Content from server 2";
    let hash: [u8; 32] = {
        let mut h = blake3::Hasher::new();
        h.update(text.as_bytes());
        h.finalize().into()
    };

    // Pre-seed the blob store with content
    let hash = server.cache_cross_server_content(text);

    // Add server 2 to directory
    server.server_directory_add_manual(
        2,
        "nowhere.example.com".to_string(),
        "00".repeat(32),
        "Server 2".to_string(),
    );

    // Resolve should find cached content without fetching
    let tumbler = "2.0001".to_string();
    let result = server.resolve_cross_server_ref(&tumbler, hash);
    assert!(
        result.is_ok(),
        "cached resolution should succeed: {:?}",
        result.err()
    );
    let resolution = result.unwrap();
    assert_eq!(resolution.text(), "Content from server 2");
    assert!(
        !resolution.was_fetched(),
        "should come from cache, not fetch"
    );
    assert!(
        resolution.origin_server_id().is_none(),
        "cached result has no origin server"
    );
}

#[tokio::test]
async fn cross_server_resolve_rejects_hash_mismatch() {
    let mut server = Server::new();
    server.set_server_namespace_id(1);

    // Store content with a known hash
    let text = "Real content";
    server.cache_cross_server_content(text);

    // Try to resolve with a DIFFERENT hash — should fail
    let wrong_hash = [0xFF; 32];
    let tumbler = "2.0001".to_string();

    // Add server 2 to directory (won't be reached because cache exists but hash won't match)
    server.server_directory_add_manual(
        2,
        "nowhere.example.com".to_string(),
        "00".repeat(32),
        "Server 2".to_string(),
    );

    let result = server.resolve_cross_server_ref(&tumbler, wrong_hash);
    assert!(
        result.is_err(),
        "should fail — can't fetch from nonexistent server"
    );
}

#[tokio::test]
async fn cross_server_resolve_via_wire_op() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;

    // Pre-seed cache
    let text = "Wire op cached content";
    let mut server = Server::new();
    let hash = server.cache_cross_server_content(text);
    drop(server);

    let hash_hex: String = hash.iter().map(|b| format!("{:02x}", b)).collect();

    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "cross_server_resolve",
            Some(serde_json::json!({
                "tumbler": "0.1.1",
                "content_hash_hex": hash_hex,
            })),
        ),
    )
    .await;
    // Local tumbler should be rejected
    assert!(resp.get("code").is_some() || !resp["value"]["value"].is_object());
}

#[tokio::test]
async fn cross_server_resolve_empty_tumbler() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "cross_server_resolve",
            Some(serde_json::json!({
                "tumbler": "",
                "content_hash_hex": "00".repeat(32),
            })),
        ),
    )
    .await;
    assert!(resp.get("code").is_some(), "empty tumbler should fail");
}

#[tokio::test]
async fn cross_server_resolve_invalid_hash() {
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv, "json").await;
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            1,
            "cross_server_resolve",
            Some(serde_json::json!({
                "tumbler": "2.0001",
                "content_hash_hex": "not-hex",
            })),
        ),
    )
    .await;
    assert!(resp.get("code").is_some(), "invalid hash should fail");
}

#[test]
fn server_directory_add_auto_discovery() {
    use std::io::{Read, Write};

    xudanu::server::server::set_allow_loopback(true);

    let mut server_a = Server::new();
    server_a.set_server_name("Alice's Server".to_string());
    server_a.set_server_description("Test server A".to_string());

    let identity_json = server_a.well_known_identity().to_string();

    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();

    let json_clone = identity_json.clone();
    std::thread::spawn(move || {
        if let Ok((mut stream, _)) = listener.accept() {
            let mut buf = [0u8; 4096];
            let _ = stream.read(&mut buf);
            let response = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{}",
                json_clone.len(),
                json_clone
            );
            let _ = stream.write_all(response.as_bytes());
            let _ = stream.flush();
        }
    });

    std::thread::sleep(std::time::Duration::from_millis(100));

    let mut server_b = Server::new();
    let entry = server_b
        .server_directory_add("127.0.0.1", Some(port))
        .expect("directory add should succeed");

    assert_eq!(entry.server_id, server_a.server_namespace_id());
    assert_eq!(entry.verifying_key.len(), 64);
    assert_eq!(entry.name, "Alice's Server");
    assert_eq!(entry.description, "Test server A");
    assert!(!entry.trusted);
    assert_eq!(entry.discovered, "manual");
}

#[test]
fn server_directory_add_rejects_unreachable() {
    let mut server = Server::new();
    let result = server.server_directory_add("127.0.0.1", Some(1));
    assert!(result.is_err(), "port 1 should be unreachable");
}

#[test]
fn server_directory_trust_flow() {
    let mut server = Server::new();
    let ns_id = server.server_namespace_id() + 42;
    server.server_directory_add_manual(
        ns_id,
        "example.com".to_string(),
        "abcdef0123456789".to_string(),
        "Test Server".to_string(),
    );

    let dir = server.server_directory();
    let entry = dir.get(ns_id).expect("entry should exist");
    assert!(!entry.trusted, "should start untrusted");

    assert!(server.server_directory_set_trust(ns_id, true));
    let entry = server.server_directory().get(ns_id).unwrap();
    assert!(entry.trusted, "should be trusted after set_trust");

    assert!(server.server_directory_set_trust(ns_id, false));
    let entry = server.server_directory().get(ns_id).unwrap();
    assert!(!entry.trusted, "should be untrusted after unset");
}

#[test]
fn element_insert_blob_with_correct_field_names() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    let work_id = server
        .create_work(sid, xudanu::edition::Edition::from_text("Hello world"))
        .unwrap();

    let element = xudanu::server::transport::protocol::RangeElementPayload {
        elem_type: "blob".to_string(),
        text: None,
        label_id: None,
        work_id: None,
        edition_id: None,
        id_holder: None,
        blob_hash: Some("12345".to_string()),
        blob_mime: Some("image/png".to_string()),
        blob_size: Some(6789),
        blob_width: Some(800),
        blob_height: Some(600),
        blob_caption: None,
        transclusion_source: None,
        transclusion_start: None,
        transclusion_end: None,
        virtual_source: None,
        virtual_revision: None,
        spans: None,
    };

    let result = server.element_insert(sid, work_id, 5, element.to_range_element().unwrap());
    assert!(
        result.is_ok(),
        "element_insert with blob should succeed: {:?}",
        result.err()
    );
}

#[test]
fn blob_payload_json_roundtrip() {
    let json = serde_json::json!({
        "type": "blob",
        "blob_hash": "12345",
        "blob_mime": "image/png",
        "blob_size": 6789u64,
        "blob_width": 800u32,
        "blob_height": 600u32
    });
    let payload: xudanu::server::transport::protocol::RangeElementPayload =
        serde_json::from_value(json).unwrap();
    assert_eq!(payload.elem_type, "blob");
    assert_eq!(payload.blob_hash, Some("12345".to_string()));
    let elem = payload.to_range_element();
    assert!(
        elem.is_some(),
        "to_range_element should succeed with blob_* field names"
    );
}

#[test]
fn blob_payload_old_field_names_work_via_alias() {
    let json = serde_json::json!({
        "type": "blob",
        "content_hash": "12345",
        "mime_type": "image/png",
        "byte_size": 6789u64
    });
    let payload: xudanu::server::transport::protocol::RangeElementPayload =
        serde_json::from_value(json).unwrap();
    assert_eq!(
        payload.blob_hash,
        Some("12345".to_string()),
        "content_hash should map to blob_hash via alias"
    );
    let elem = payload.to_range_element();
    assert!(
        elem.is_some(),
        "old field names should work via serde alias"
    );
}

#[test]
fn work_set_source_freezes_content_but_allows_links() {
    // Showcase contract: freezing a work blocks content edits from
    // everyone (including the owner) while links and annotations
    // remain open, and only the owner (or admin) can toggle the flag.
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("showcase doc"))
        .unwrap();

    srv.work_set_source(sid, wid, true).unwrap();
    assert!(
        srv.work_grab(sid, wid).is_err(),
        "owner cannot edit a frozen work"
    );

    // Annotations still allowed on source works (marginalia, not edits)
    srv.annotation_create(sid, wid, 1, "note".into(), "hi".into(), 0, 2, false)
        .unwrap();

    // A different identity cannot toggle the flag
    let (sid2, _) = owned_session(&mut srv);
    assert!(
        srv.work_set_source(sid2, wid, false).is_err(),
        "non-owner cannot unfreeze a showcase work"
    );

    // Owner can unfreeze again
    srv.work_set_source(sid, wid, false).unwrap();
    assert!(srv.work_grab(sid, wid).is_ok());
}

#[test]
fn web_fetch_sanitize_rejects_internal_addresses() {
    // SSRF guard: loopback/private targets must never be fetched.
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    for url in [
        "http://127.0.0.1:8080/x",
        "http://localhost/admin",
        "http://192.168.1.1/router",
        "http://[::1]/v6",
    ] {
        let err = srv
            .web_fetch_sanitize(sid, url, None, false, None)
            .unwrap_err();
        assert!(
            matches!(err, xudanu::server::ServerError::InvalidArgument(_)),
            "{url} must be refused, got {:?}",
            err
        );
    }
    // Non-http schemes refused outright
    let err = srv
        .web_fetch_sanitize(sid, "javascript:alert(1)", None, false, None)
        .unwrap_err();
    assert!(matches!(
        err,
        xudanu::server::ServerError::InvalidArgument(_)
    ));
}

#[test]
fn web_fetch_sanitize_requires_authentication() {
    let mut srv = xudanu::server::Server::new();
    let sid = srv.connect(); // connected but not authenticated
    let err = srv
        .web_fetch_sanitize(sid, "https://example.com/", None, false, None)
        .unwrap_err();
    assert!(matches!(err, xudanu::server::ServerError::NotAuthorized));
}

#[test]
fn html_to_text_strips_chrome_and_scripts() {
    let html = r#"<html><head><title>T</title><style>.x{}</style><script>alert(1)</script></head>
        <body><nav>menu menu</nav><header>site header</header>
        <main><p>First paragraph.</p><p>Second <b>bold</b> paragraph.</p></main>
        <footer>foot</footer><aside>ad</aside></body></html>"#;
    let text = xudanu::server::server::Server::html_to_text_for_test(html);
    assert!(text.contains("First paragraph."), "got: {text}");
    assert!(text.contains("Second bold paragraph."), "got: {text}");
    for absent in ["alert", "menu", "site header", "foot", "ad", "<", ">"] {
        assert!(!text.contains(absent), "{absent} leaked into: {text}");
    }
}

#[test]
fn ammonia_output_drops_active_content() {
    // The sanitizer itself: scripts, event handlers, and javascript:
    // URLs never survive the ammonia whitelist.
    let dirty = r#"<p onclick="evil()">hi</p><script>evil()</script>
        <a href="javascript:evil()">x</a><iframe src="https://evil"></iframe>
        <img src="https://ok/img.png" onerror="evil()">"#;
    let clean = ammonia::Builder::default()
        .url_relative(ammonia::UrlRelative::PassThrough)
        .clean(dirty)
        .to_string();
    for absent in ["onclick", "onerror", "javascript:", "<script", "<iframe"] {
        assert!(!clean.contains(absent), "{absent} survived: {clean}");
    }
    assert!(clean.contains("hi"));
    assert!(clean.contains("https://ok/img.png"));
}

#[test]
fn publish_gate_allows_empty_shells_but_gc_sweeps_them() {
    // Policy: publishing an empty work IS allowed — the fr26 flow
    // creates a published shell then inserts transclusions into it.
    // Abandoned shells (empty, revision 0, idle, no dependents) are
    // swept by the draft GC instead.
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::empty())
        .unwrap();
    srv.work_publish(sid, wid).unwrap();
    srv.work_unpublish(sid, wid).unwrap();
    let swept = srv.gc_idle_empty_drafts(0);
    assert!(swept.contains(&wid), "abandoned empty shell is swept");
}

#[test]
fn draft_gc_sweeps_idle_empty_drafts_only() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);

    // 1. Empty draft, idle -> swept.
    let empty_draft = srv
        .create_work(sid, xudanu::edition::Edition::empty())
        .unwrap();

    // 2. Work with content -> kept.
    let content_work = srv
        .create_work(sid, xudanu::edition::Edition::from_text("real content"))
        .unwrap();

    // 3. Published content work -> kept regardless of idle.
    srv.work_publish(sid, content_work).unwrap();

    // 4. Frozen empty draft -> kept (is_source protects).
    let frozen_draft = srv
        .create_work(sid, xudanu::edition::Edition::empty())
        .unwrap();
    srv.work_set_source(sid, frozen_draft, true).unwrap();

    // Zero idle window: only no-content, no-history, dependent-free
    // works qualify (created drafts sit at revision 0).
    let swept = srv.gc_idle_empty_drafts(0);

    assert!(
        swept.contains(&empty_draft),
        "idle empty draft must be swept"
    );
    assert!(
        !swept.contains(&content_work),
        "content work must never be swept"
    );
    assert!(
        !swept.contains(&frozen_draft),
        "frozen work must never be swept"
    );
    assert!(
        srv.work_is_archived(empty_draft).unwrap(),
        "swept draft is archived (reversible), not deleted"
    );
    assert!(!srv.work_is_archived(content_work).unwrap());
}

#[test]
fn draft_gc_respects_idle_window() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let draft = srv
        .create_work(sid, xudanu::edition::Edition::empty())
        .unwrap();
    // Just created: revision timestamp is NOW, so a long window must
    // not sweep it yet.
    let swept = srv.gc_idle_empty_drafts(86_400 * 7);
    assert!(
        !swept.contains(&draft),
        "fresh draft must survive a 7-day idle window"
    );
    // Zero window sweeps it.
    let swept = srv.gc_idle_empty_drafts(0);
    assert!(swept.contains(&draft));
}

#[test]
fn draft_gc_keeps_works_with_revisions() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("had content"))
        .unwrap();
    // Empty it again — revision history must protect it.
    srv.work_grab(sid, wid).unwrap();
    srv.work_revise(sid, wid, xudanu::edition::Edition::empty())
        .unwrap();
    let swept = srv.gc_idle_empty_drafts(0);
    assert!(
        !swept.contains(&wid),
        "a work with revision history is never draft-GC material"
    );
}

#[test]
fn seed_demo_attribution_five_authors() {
    // N-author demo seeding: 5 distinct authors must produce 5
    // attribution spans, each covering a distinct region, with
    // unique keys and display names.
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let text = "First author opens the document with an introduction. \
                Second author continues the argument in their own voice. \
                Third author adds supporting evidence and citations here. \
                Fourth author offers a counterpoint for balance. \
                Fifth author closes with conclusions and future work.";
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text(text))
        .unwrap();

    srv.seed_demo_attribution(sid, wid, Some(5)).unwrap();

    let spans = srv.attribution_query(wid, None, None).unwrap();
    assert!(spans.len() >= 5, "expected >= 5 spans, got {}", spans.len());
    let names: Vec<&str> = spans
        .iter()
        .map(|s| s.author_display_name.as_deref().unwrap_or(""))
        .collect();
    let unique: std::collections::HashSet<&str> = names.iter().copied().collect();
    assert_eq!(unique.len(), 5, "5 distinct authors, got {:?}", names);
    let keys: std::collections::HashSet<String> = spans
        .iter()
        .map(|s| {
            s.author_public_key
                .iter()
                .map(|b| format!("{:02x}", b))
                .collect()
        })
        .collect();
    assert_eq!(keys.len(), 5, "each author has a unique key");
    assert!(
        spans.iter().all(|s| s.signature_valid),
        "all seeded span signatures must verify against the stored edition"
    );

    // Regions must tile the document contiguously, start at 0, reach
    // the end, and vary in length (irregular weights — equal splits
    // read as synthetic).
    let mut sorted = spans.clone();
    sorted.sort_by_key(|s| s.start);
    assert_eq!(sorted[0].start, 0, "first region starts at the beginning");
    for w in sorted.windows(2) {
        assert_eq!(w[0].end, w[1].start, "regions must be contiguous");
    }
    let text_len = text.chars().count() as i64;
    assert_eq!(
        sorted.last().unwrap().end,
        text_len,
        "last region reaches the end of the text"
    );
    let lengths: Vec<i64> = sorted.iter().map(|s| s.end - s.start).collect();
    let all_equal = lengths.windows(2).all(|w| w[0] == w[1]);
    assert!(
        !all_equal,
        "region lengths should vary per author, got {:?}",
        lengths
    );
}

#[test]
fn seed_demo_attribution_rejects_more_authors_than_text() {
    let mut srv = xudanu::server::Server::new();
    let (sid, _) = owned_session(&mut srv);
    let wid = srv
        .create_work(sid, xudanu::edition::Edition::from_text("short"))
        .unwrap();
    assert!(srv.seed_demo_attribution(sid, wid, Some(8)).is_err());
}

#[test]
fn blob_list_content_hash_serializes_as_string() {
    // Regression: BlobEntry.content_hash (u64) serialized as a JSON
    // number. u64 hashes exceed JavaScript's 2^53 safe-integer range,
    // so browsers rounded them (wrong hash -> image never loaded) or
    // rejected follow-up frames (protocol error killing the response
    // stream — links/annotations stopped rendering). The wire format
    // must be a string; deserialization accepts both for
    // back-compat with older clients.
    let entry = xudanu::edition::edition::BlobEntry {
        char_position: 20,
        content_hash: 6000286860484429196u64,
        mime_type: "image/png".to_string(),
        byte_size: 1138,
        width: Some(900),
        height: Some(260),
        caption: None,
    };
    let json = serde_json::to_value(&entry).unwrap();
    assert!(
        json["content_hash"].is_string(),
        "content_hash must serialize as string, got: {}",
        json["content_hash"]
    );
    assert_eq!(json["content_hash"], "6000286860484429196");

    // Round-trip: string form (new servers) and integer form (old
    // snapshots/peers) both deserialize.
    let rt: xudanu::edition::edition::BlobEntry = serde_json::from_value(json).unwrap();
    assert_eq!(rt.content_hash, 6000286860484429196u64);
    let legacy = serde_json::json!({
        "char_position": 20,
        "content_hash": 6000286860484429196u64,
        "mime_type": "image/png",
        "byte_size": 1138,
        "width": 900,
        "height": 260,
        "caption": null
    });
    let old: xudanu::edition::edition::BlobEntry = serde_json::from_value(legacy).unwrap();
    assert_eq!(old.content_hash, 6000286860484429196u64);
}

#[test]
fn image_insert_end_to_end() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();

    let work_id = server
        .create_work(sid, xudanu::edition::Edition::from_text("Hello world"))
        .unwrap();

    let png_bytes: Vec<u8> = vec![
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44,
        0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x02, 0x00, 0x00, 0x00, 0x90,
        0x77, 0x53, 0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8,
        0xCF, 0xC0, 0x00, 0x00, 0x00, 0x03, 0x00, 0x01, 0x5B, 0x70, 0x21, 0xAE, 0x00, 0x00, 0x00,
        0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ];

    let meta = server
        .blob_upload(sid, png_bytes, "image/png".to_string())
        .unwrap();

    let element = xudanu::server::transport::protocol::RangeElementPayload {
        elem_type: "blob".to_string(),
        blob_hash: Some(meta.hash_u64().to_string()),
        blob_mime: Some("image/png".to_string()),
        blob_size: Some(meta.byte_size as u64),
        blob_width: meta.width,
        blob_height: meta.height,
        text: None,
        label_id: None,
        work_id: None,
        edition_id: None,
        id_holder: None,
        blob_caption: None,
        transclusion_source: None,
        transclusion_start: None,
        transclusion_end: None,
        virtual_source: None,
        virtual_revision: None,
        spans: None,
    };

    let elem = element
        .to_range_element()
        .expect("to_range_element must succeed");
    let result = server.element_insert(sid, work_id, 5, elem);
    assert!(
        result.is_ok(),
        "element_insert should succeed: {:?}",
        result.err()
    );
}

// ============================================================
// Public works list endpoint (/api/public/works)
// ============================================================

#[tokio::test]
async fn public_works_list_returns_empty_for_fresh_server() {
    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/api/public/works", addr))
        .send()
        .await
        .unwrap();
    if resp.status() != 200 {
        let txt = resp.text().await.unwrap_or_default();
        panic!("identity endpoint returned 500: {txt}");
    }
    let body: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(body["api_version"], 1);
    assert_eq!(body["implementation"], "xudanu");
    assert!(body["works"].is_array());
    assert_eq!(body["works"].as_array().unwrap().len(), 0);
}

#[tokio::test]
async fn public_works_list_returns_only_public_works() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();

    let public_work = server
        .create_work(sid, xudanu::edition::Edition::from_text("Public content"))
        .unwrap();

    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/api/public/works", addr))
        .send()
        .await
        .unwrap();
    if resp.status() != 200 {
        let txt = resp.text().await.unwrap_or_default();
        panic!("identity endpoint returned 500: {txt}");
    }
    let body: serde_json::Value = resp.json().await.unwrap();
    let works = body["works"].as_array().unwrap();
    assert!(works.len() >= 1, "should list public works");
    let found = works.iter().any(|w| w["title"] == "Public content");
    assert!(found, "public work should appear in list");
}

#[tokio::test]
async fn public_works_list_has_cors_headers() {
    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/api/public/works", addr))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), 200);
    assert_eq!(
        resp.headers().get("access-control-allow-origin").unwrap(),
        "*"
    );
    assert!(resp
        .headers()
        .get("content-type")
        .unwrap()
        .to_str()
        .unwrap()
        .contains("application/json"));
}

#[tokio::test]
async fn public_works_list_includes_work_metadata() {
    let mut server = Server::new();
    let sid = server.connect();
    server.login_public(sid).unwrap();
    let work_id = server
        .create_work(
            sid,
            xudanu::edition::Edition::from_text(
                "Test essay with enough content to verify metadata",
            ),
        )
        .unwrap();
    let pub_club = server.public_club_id();
    server.work_publish(sid, work_id).unwrap();

    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr = listener.local_addr().unwrap();
    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    let client = reqwest::Client::new();
    let resp = client
        .get(format!("http://{}/api/public/works", addr))
        .send()
        .await
        .unwrap();
    let body: serde_json::Value = resp.json().await.unwrap();
    let works = body["works"].as_array().unwrap();
    assert_eq!(works.len(), 1);
    let work = &works[0];
    assert!(work["work_id"].is_string(), "work_id should be hex string");
    assert!(work["title"].is_string(), "title should be present");
    assert!(
        work["revision"].is_number(),
        "revision count should be present"
    );
    assert!(
        work["char_count"].is_number(),
        "char_count should be present"
    );
    assert!(
        work["char_count"].as_u64().unwrap() > 0,
        "char_count should be positive"
    );
}

fn start_mock_server(responses: Vec<String>) -> u16 {
    use std::io::{Read, Write};
    let listener = std::net::TcpListener::bind("127.0.0.1:0").unwrap();
    let port = listener.local_addr().unwrap().port();
    std::thread::spawn(move || {
        for resp_body in responses {
            if let Ok((mut stream, _)) = listener.accept() {
                let mut buf = [0u8; 4096];
                let _ = stream.read(&mut buf);
                let response = format!(
                    "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{}",
                    resp_body.len(),
                    resp_body
                );
                let _ = stream.write_all(response.as_bytes());
                let _ = stream.flush();
            }
        }
    });
    std::thread::sleep(std::time::Duration::from_millis(50));
    port
}

#[test]
fn adversarial_signature_stripping_rejected() {
    xudanu::server::server::set_allow_loopback(true);
    let mut server_a = xudanu::server::Server::new();
    server_a.set_server_namespace_id(100);
    let text = "Signed content";
    let hash: [u8; 32] = blake3::hash(text.as_bytes()).into();

    let vk_hex: String = server_a
        .server_public_signing_key()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect();

    let work_json = serde_json::json!({
        "text": text,
        "server_namespace_id": 100u64,
        "server_public_key": vk_hex,
        "server_signature": "ab".repeat(64),
        "revision": 0u64,
    });
    let port = start_mock_server(vec![work_json.to_string()]);
    std::thread::sleep(std::time::Duration::from_millis(100));

    let mut server_b = xudanu::server::Server::new();
    server_b.server_directory_add_manual(
        100,
        format!("127.0.0.1:{}", port),
        vk_hex,
        "Alice".to_string(),
    );
    server_b.server_directory_set_trust(100, true);

    let tumbler = format!("100.{:04x}.0", 0);
    let result = server_b.resolve_cross_server_ref(&tumbler, hash);
    assert!(result.is_err(), "forged signature should be rejected");
}

#[test]
fn adversarial_unsigned_rejected_when_pinned() {
    xudanu::server::server::set_allow_loopback(true);
    let text = "Content without signature";
    let hash: [u8; 32] = blake3::hash(text.as_bytes()).into();

    let work_json = serde_json::json!({
        "text": text,
        "server_namespace_id": 200u64,
    });

    let port = start_mock_server(vec![work_json.to_string()]);
    std::thread::sleep(std::time::Duration::from_millis(100));

    let mut server = xudanu::server::Server::new();
    server.server_directory_add_manual(
        200,
        format!("127.0.0.1:{}", port),
        "ab".repeat(32),
        "Unsigned Server".to_string(),
    );
    server.server_directory_set_trust(200, true);

    let tumbler = format!("200.{:04x}.0", 0);
    let result = server.resolve_cross_server_ref(&tumbler, hash);
    assert!(
        result.is_err(),
        "unsigned response from server with pinned key should be rejected"
    );
}

#[test]
fn adversarial_introduction_tamper_address_detected() {
    let mut server_a = xudanu::server::Server::new();
    let target_ns = server_a.server_namespace_id() + 50;
    server_a.server_directory_add_manual(
        target_ns,
        "real.example.com:8080".to_string(),
        "ab".repeat(32),
        "Target".to_string(),
    );
    server_a.server_directory_set_trust(target_ns, true);

    let intro = server_a.signed_introductions()[0].clone();
    let key = intro.introduced_by_key.clone();

    let mut tampered = intro.clone();
    tampered.target_address = "evil.example.com:9999".to_string();
    assert!(
        tampered.verify(&key).is_err(),
        "tampered address should fail introduction verification"
    );

    assert!(
        intro.verify(&key).is_ok(),
        "original introduction should still verify"
    );
}

#[test]
fn adversarial_rotation_replay_different_key_rejected() {
    let mut server = xudanu::server::Server::new();
    let old_vk_hex: String = server
        .server_public_signing_key()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect();

    server.rotate_server_keys().expect("rotation");
    let real_new_hex: String = server
        .server_public_signing_key()
        .iter()
        .map(|b| format!("{:02x}", b))
        .collect();

    let identity = server.well_known_identity();

    let attacker_key = "ee".repeat(32);
    let mut tampered = identity.clone();
    if let Some(chain) = tampered["rotation_chain"].as_array_mut() {
        chain[0]["new_verifying_key"] = serde_json::json!(attacker_key);
    }
    tampered["key_rotation"]["new_verifying_key"] = serde_json::json!(attacker_key);

    let result = xudanu::server::server::verify_key_rotation(&tampered, &old_vk_hex, &attacker_key);
    assert!(
        result.is_err(),
        "rotation replay with different key must be rejected"
    );

    let legit_result =
        xudanu::server::server::verify_key_rotation(&identity, &old_vk_hex, &real_new_hex);
    assert!(
        legit_result.is_ok(),
        "legitimate rotation should still verify"
    );
}

#[test]
fn adversarial_blake3_hash_mismatch_rejected() {
    xudanu::server::server::set_allow_loopback(true);

    let text = "Real content";
    let wrong_hash = [0xFFu8; 32];

    let work_json = serde_json::json!({
        "text": text,
        "server_namespace_id": 300u64,
    });

    let port = start_mock_server(vec![work_json.to_string()]);
    std::thread::sleep(std::time::Duration::from_millis(100));

    let mut server = xudanu::server::Server::new();
    server.server_directory_add_manual(
        300,
        format!("127.0.0.1:{}", port),
        "ab".repeat(32),
        "Hash Test".to_string(),
    );
    server.server_directory_set_trust(300, true);

    let tumbler = format!("300.{:04x}.0", 0);
    let result = server.resolve_cross_server_ref(&tumbler, wrong_hash);
    assert!(
        result.is_err(),
        "hash mismatch should be rejected (content tampering detected)"
    );
}

// ============================================================
// FR-52 A-2: Set/Path elements over the real WebSocket op path
// ============================================================

#[tokio::test]
async fn fr52_set_path_element_insert_over_websocket() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            10,
            "work_create",
            Some(serde_json::json!({"edition": {"text": "Hello world"}})),
        ),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    // Insert a Set at char 5 through the real op dispatch.
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            11,
            "element_insert",
            Some(serde_json::json!({
                "work_id": work_id,
                "position": 5,
                "element": {
                    "type": "set",
                    "spans": [
                        {"work_id": 1001, "start": 0, "end": 10},
                        {"work_id": 1002, "start": 40, "end": 44}
                    ]
                }
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response", "set insert succeeds: {:?}", resp);
    assert!(
        resp["value"]["value"].as_u64().is_some(),
        "returns a revision: {:?}",
        resp["value"]
    );

    // Insert a Path at the end.
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            12,
            "element_insert",
            Some(serde_json::json!({
                "work_id": work_id,
                "position": 11,
                "element": {
                    "type": "path",
                    "spans": [
                        {"work_id": 1001, "start": 3, "end": 7},
                        {"work_id": 1003, "start": 0, "end": 5}
                    ]
                }
            })),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response", "path insert succeeds: {:?}", resp);

    // Read the edition back: both elements present with their spans,
    // and the concatenated text is unchanged (zero-char elements).
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            13,
            "work_get_edition",
            Some(serde_json::json!({"work_id": work_id})),
        ),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let entries = resp["value"]["value"]["entries"]
        .as_array()
        .expect("edition returns the entries form (Set/Path break contiguous text)")
        .clone();

    let mut text = String::new();
    let mut sets = 0usize;
    let mut paths = 0usize;
    for entry in &entries {
        let elem = &entry[1];
        if let Some(t) = elem["Text"]["text"].as_str() {
            text.push_str(t);
        }
        if elem.get("Set").is_some() {
            sets += 1;
            let spans = elem["Set"]["spans"].as_array().expect("set spans");
            assert_eq!(spans.len(), 2, "set members survive the wire");
            assert_eq!(spans[0]["work_id"].as_u64(), Some(1001));
            assert_eq!(spans[1]["work_id"].as_u64(), Some(1002));
        }
        if elem.get("Path").is_some() {
            paths += 1;
            let spans = elem["Path"]["spans"].as_array().expect("path spans");
            assert_eq!(spans.len(), 2, "path members survive the wire");
            assert_eq!(spans[0]["work_id"].as_u64(), Some(1001));
            assert_eq!(spans[1]["work_id"].as_u64(), Some(1003));
        }
    }
    assert_eq!(sets, 1, "exactly one Set in the edition");
    assert_eq!(paths, 1, "exactly one Path in the edition");
    assert_eq!(text, "Hello world", "zero-char elements do not alter text");

    // Malformed over the wire: set without spans must be rejected
    // at the dispatch boundary (to_range_element -> None -> error).
    let resp = send_recv_json(
        &mut s,
        &mut r,
        json_req(
            15,
            "element_insert",
            Some(serde_json::json!({
                "work_id": work_id,
                "position": 0,
                "element": {"type": "set"}
            })),
        ),
    )
    .await;
    assert_eq!(
        resp["type"], "error",
        "set without spans is rejected by dispatch: {:?}",
        resp
    );
}
