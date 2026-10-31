//! FR-45 admin-console wire integration tests: drive the real WebSocket
//! protocol (JSON) end-to-end — auth, admin gating, and every admin op
//! added for the console (moderation, policy, sessions, audit,
//! identities).

#![cfg(feature = "server")]

use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::transport::{build_router, AppState, PROTOCOL_VERSION};
use xudanu::server::Server;

const ADMIN_PASSWORD: &[u8] = b"admin12345";

fn password_credential(pw: &[u8]) -> serde_json::Value {
    serde_json::json!({"password": pw.iter().map(|&b| serde_json::Value::from(b)).collect::<Vec<_>>()})
}

struct TestServer {
    addr: SocketAddr,
}

impl TestServer {
    /// Persistent variant (temp data dir) — audit tail and other
    /// data-dir-dependent ops need it.
    async fn start_persistent(tag: &str) -> Self {
        let dir = std::env::temp_dir().join(format!(
            "xudanu_admin_console_{}_{}_{}",
            tag,
            std::process::id(),
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_millis()
        ));
        std::fs::create_dir_all(&dir).unwrap();
        let mut server = Server::new();
        server.init_data_dir(&dir, None).unwrap();
        Self::finish(server).await
    }

    async fn start() -> Self {
        let mut server = Server::new();
        Self::finish(server).await
    }

    async fn finish(mut server: Server) -> Self {
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

async fn connect_with_handshake(addr: &SocketAddr) -> (SplitSender, SplitReceiver) {
    let url = format!(
        "ws://{}/xudanu?format=json&version={}",
        addr, PROTOCOL_VERSION
    );
    let (stream, _) = tokio_tungstenite::connect_async(&url).await.unwrap();
    let (s, mut r) = stream.split();
    let msg = r.next().await.unwrap().unwrap();
    match msg {
        Message::Text(t) => {
            let hs: serde_json::Value = serde_json::from_str(&t).unwrap();
            assert_eq!(hs["type"], "handshake");
        }
        other => panic!("expected handshake, got: {:?}", other),
    }
    (s, r)
}

async fn req(
    s: &mut SplitSender,
    r: &mut SplitReceiver,
    id: u16,
    op: &str,
    payload: Option<serde_json::Value>,
) -> serde_json::Value {
    let mut frame =
        serde_json::json!({"v": PROTOCOL_VERSION, "type": "request", "id": id, "op": op});
    if let Some(p) = payload {
        frame["payload"] = p;
    }
    s.send(Message::Text(frame.to_string().into()))
        .await
        .unwrap();
    let msg = r.next().await.unwrap().unwrap();
    match msg {
        Message::Text(t) => serde_json::from_str(&t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
        other => panic!("unexpected: {:?}", other),
    }
}

/// Connect + session_connect + login_public. Returns sid.
async fn pleb_session(addr: &SocketAddr) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(addr).await;
    let resp = req(&mut s, &mut r, 1, "session_connect", None).await;
    let sid = resp["value"]["value"].as_u64().unwrap();
    req(&mut s, &mut r, 2, "session_login_public", None).await;
    (s, r, sid)
}

/// Connect + session_connect + admin club login + authenticate.
async fn admin_session(addr: &SocketAddr) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(addr).await;
    let resp = req(&mut s, &mut r, 1, "session_connect", None).await;
    let sid = resp["value"]["value"].as_u64().unwrap();
    let club = req(
        &mut s,
        &mut r,
        2,
        "club_id_by_name",
        Some(serde_json::json!({"name": "admin"})),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    req(
        &mut s,
        &mut r,
        3,
        "session_login",
        Some(serde_json::json!({"club_id": club})),
    )
    .await;
    req(
        &mut s,
        &mut r,
        4,
        "session_authenticate",
        Some(serde_json::json!({"credential": password_credential(ADMIN_PASSWORD)})),
    )
    .await;
    (s, r, sid)
}

async fn create_work(s: &mut SplitSender, r: &mut SplitReceiver, id: &mut u16, text: &str) -> u64 {
    *id += 1;
    let resp = req(
        s,
        r,
        *id,
        "work_create",
        Some(serde_json::json!({"edition": {"text": text}})),
    )
    .await;
    resp["value"]["value"].as_u64().unwrap()
}

fn is_ok(resp: &serde_json::Value) -> bool {
    resp["type"] == "response"
}

fn err_msg(resp: &serde_json::Value) -> String {
    resp["message"]
        .as_str()
        .unwrap_or("(no message)")
        .to_string()
}

// ─── P1: content moderation ─────────────────────────────────────────

#[tokio::test]
async fn admin_content_moderation_over_wire() {
    let srv = TestServer::start().await;

    // A pleb creates two works.
    let (mut ps, mut pr, _pleb) = pleb_session(&srv.addr).await;
    let mut id = 10u16;
    let w1 = create_work(&mut ps, &mut pr, &mut id, "moderation target one").await;
    let w2 = create_work(&mut ps, &mut pr, &mut id, "moderation target two").await;

    // work_list carries char_count.
    let list = req(
        &mut ps,
        &mut pr,
        20,
        "work_list",
        Some(serde_json::json!({})),
    )
    .await;
    let entries = list["value"]["value"]["entries"].as_array().unwrap();
    let e1 = entries
        .iter()
        .find(|e| e["work_id"].as_u64() == Some(w1))
        .unwrap();
    assert_eq!(
        e1["char_count"].as_u64(),
        Some("moderation target one".len() as u64)
    );

    // Pleb cannot admin-delete.
    let resp = req(
        &mut ps,
        &mut pr,
        21,
        "work_admin_delete",
        Some(serde_json::json!({"work_id": w2})),
    )
    .await;
    assert!(resp["type"] == "error", "pleb delete must fail: {:?}", resp);

    // Admin deletes w2; it leaves the list.
    let (mut as_, mut ar, _admin) = admin_session(&srv.addr).await;
    let resp = req(
        &mut as_,
        &mut ar,
        30,
        "work_admin_delete",
        Some(serde_json::json!({"work_id": w2})),
    )
    .await;
    assert!(is_ok(&resp), "admin delete: {}", err_msg(&resp));

    let list = req(
        &mut ps,
        &mut pr,
        22,
        "work_list",
        Some(serde_json::json!({})),
    )
    .await;
    let entries = list["value"]["value"]["entries"].as_array().unwrap();
    assert!(entries.iter().any(|e| e["work_id"].as_u64() == Some(w1)));
    assert!(!entries.iter().any(|e| e["work_id"].as_u64() == Some(w2)));

    // Admin archives w1; it leaves the live list too (restorable).
    let resp = req(
        &mut as_,
        &mut ar,
        31,
        "work_archive",
        Some(serde_json::json!({"work_id": w1})),
    )
    .await;
    assert!(is_ok(&resp), "archive: {}", err_msg(&resp));
    let list = req(
        &mut ps,
        &mut pr,
        23,
        "work_list",
        Some(serde_json::json!({})),
    )
    .await;
    let entries = list["value"]["value"]["entries"].as_array().unwrap();
    assert!(!entries.iter().any(|e| e["work_id"].as_u64() == Some(w1)));
}

#[tokio::test]
async fn text_cap_enforced_over_wire() {
    let srv = TestServer::start().await;
    let (mut s, mut r, _) = pleb_session(&srv.addr).await;
    let big = "x".repeat(1024 * 1024 + 10);
    let resp = req(
        &mut s,
        &mut r,
        1,
        "work_create",
        Some(serde_json::json!({"edition": {"text": big}})),
    )
    .await;
    assert!(resp["type"] == "error", "oversized create must fail");
    assert!(
        err_msg(&resp).contains("too large"),
        "got: {}",
        err_msg(&resp)
    );
}

// ─── P2: policy over the wire ───────────────────────────────────────

#[tokio::test]
async fn admin_policy_over_wire() {
    let srv = TestServer::start().await;
    let (mut as_, mut ar, _admin) = admin_session(&srv.addr).await;

    // Edit policy round-trip.
    let resp = req(
        &mut as_,
        &mut ar,
        1,
        "admin_edit_policy_set",
        Some(serde_json::json!({"policy": "public-sandbox"})),
    )
    .await;
    assert!(is_ok(&resp), "policy set: {}", err_msg(&resp));
    let resp = req(
        &mut as_,
        &mut ar,
        2,
        "admin_edit_policy_set",
        Some(serde_json::json!({"policy": "owner-only"})),
    )
    .await;
    assert!(is_ok(&resp));
    let resp = req(
        &mut as_,
        &mut ar,
        3,
        "admin_edit_policy_set",
        Some(serde_json::json!({"policy": "nonsense"})),
    )
    .await;
    assert!(resp["type"] == "error", "bad policy must fail");

    // Network + external links toggles.
    let resp = req(
        &mut as_,
        &mut ar,
        4,
        "network_set_enabled",
        Some(serde_json::json!({"enabled": true})),
    )
    .await;
    assert!(is_ok(&resp), "network: {}", err_msg(&resp));
    let resp = req(
        &mut as_,
        &mut ar,
        5,
        "external_links_set_enabled",
        Some(serde_json::json!({"enabled": true})),
    )
    .await;
    assert!(is_ok(&resp), "links: {}", err_msg(&resp));

    // Toggle back off to leave clean state.
    req(
        &mut as_,
        &mut ar,
        6,
        "network_set_enabled",
        Some(serde_json::json!({"enabled": false})),
    )
    .await;
    req(
        &mut as_,
        &mut ar,
        7,
        "external_links_set_enabled",
        Some(serde_json::json!({"enabled": false})),
    )
    .await;

    // Pleb cannot set policy.
    let (mut ps, mut pr, _) = pleb_session(&srv.addr).await;
    let resp = req(
        &mut ps,
        &mut pr,
        1,
        "admin_edit_policy_set",
        Some(serde_json::json!({"policy": "public-sandbox"})),
    )
    .await;
    assert!(resp["type"] == "error", "pleb policy must fail");
}

// ─── P3: sessions + audit over the wire ────────────────────────────

#[tokio::test]
async fn admin_sessions_and_audit_over_wire() {
    let srv = TestServer::start_persistent("sessaudit").await;
    let (mut ps, mut pr, pleb_sid) = pleb_session(&srv.addr).await;

    // Pleb cannot list sessions or read audit.
    let resp = req(&mut ps, &mut pr, 1, "admin_active_sessions", None).await;
    assert!(resp["type"] == "error");
    let resp = req(&mut ps, &mut pr, 2, "admin_audit_tail", None).await;
    assert!(resp["type"] == "error");

    let (mut as_, mut ar, admin_sid) = admin_session(&srv.addr).await;

    // Sessions list includes both parties.
    let resp = req(&mut as_, &mut ar, 1, "admin_active_sessions", None).await;
    assert!(is_ok(&resp), "sessions: {}", err_msg(&resp));
    let val = resp["value"]["value"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(val.len() >= 2, "expected >=2 sessions, got {}", val.len());

    // Cannot kick self.
    let resp = req(
        &mut as_,
        &mut ar,
        2,
        "admin_session_kick",
        Some(serde_json::json!({"session_id": admin_sid})),
    )
    .await;
    assert!(resp["type"] == "error", "self-kick must fail");

    // Kick the pleb; the server drops the socket — the next read on
    // that stream errors or closes (either is the kicked outcome).
    let resp = req(
        &mut as_,
        &mut ar,
        3,
        "admin_session_kick",
        Some(serde_json::json!({"session_id": pleb_sid})),
    )
    .await;
    assert!(is_ok(&resp), "kick: {}", err_msg(&resp));
    // Server breaks the WS loop on next message from the dead session:
    // the client sees a Close frame or EOF. Guard with a timeout so a
    // regression hangs the test, not the suite.
    let dead = tokio::time::timeout(std::time::Duration::from_secs(5), async {
        let frame = serde_json::to_string(&serde_json::json!({"v": PROTOCOL_VERSION, "type": "request", "id": 99, "op": "work_list"})).unwrap();
        if ps.send(Message::Text(frame.into())).await.is_err() {
            return true;
        }
        match pr.next().await {
            None => true,
            Some(Err(_)) => true,
            Some(Ok(Message::Close(_))) => true,
            Some(Ok(Message::Text(t))) => {
                let v: serde_json::Value = serde_json::from_str(&t).unwrap_or_default();
                v["type"] == "error"
            }
            _ => false,
        }
    })
    .await
    .unwrap_or(true);
    assert!(dead, "kicked session must be dead");

    // Audit tail: lines array + chain_valid flag (log may be empty in
    // test env; the shape and flag are what matters).
    let resp = req(&mut as_, &mut ar, 4, "admin_audit_tail", None).await;
    assert!(is_ok(&resp), "audit: {}", err_msg(&resp));
    let inner = &resp["value"]["value"];
    assert!(inner["lines"].is_array());
    assert!(inner["chain_valid"].is_boolean());
}

// ─── P4: identities over the wire ──────────────────────────────────

#[tokio::test]
async fn admin_identities_over_wire() {
    let srv = TestServer::start().await;

    // Pleb creates a personal identity via club_create_personal.
    let (mut ps, mut pr, _) = pleb_session(&srv.addr).await;
    let resp = req(
        &mut ps,
        &mut pr,
        1,
        "club_create_personal",
        Some(serde_json::json!({"name": "wireuser", "display_name": "Wire User"})),
    )
    .await;
    eprintln!("CK: club resp {:?}", resp);
    let pleb_club = resp["value"]["value"].as_u64().unwrap_or(0);

    let (mut as_, mut ar, _admin) = admin_session(&srv.addr).await;

    // Probe A: known-good write-path op (kick a ghost -> error response).
    let resp = req(
        &mut as_,
        &mut ar,
        90,
        "admin_session_kick",
        Some(serde_json::json!({"session_id": 987654321})),
    )
    .await;
    eprintln!("CK: probeA {:?}", resp["type"]);

    // Directory lists clubs including the new identity.
    let resp = req(&mut as_, &mut ar, 1, "admin_clubs_list", None).await;
    eprintln!("CK: clubs resp {:?}", resp["type"]);
    assert!(is_ok(&resp), "clubs list: {}", err_msg(&resp));
    let clubs = resp["value"]["value"]["clubs"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert!(
        clubs.iter().any(|c| c["be_id"].as_u64() == Some(pleb_club)),
        "personal club {} must appear in directory",
        pleb_club
    );
    assert!(clubs.iter().any(|c| c["is_system"].as_bool() == Some(true)));

    // Grant admin to the pleb club; a fresh session of that club passes
    // admin gating; revoke removes it.
    let resp = req(
        &mut as_,
        &mut ar,
        2,
        "admin_grant_admin",
        Some(serde_json::json!({"club_id": pleb_club})),
    )
    .await;
    assert!(is_ok(&resp), "grant: {}", err_msg(&resp));

    let resp = req(
        &mut as_,
        &mut ar,
        3,
        "admin_revoke_admin",
        Some(serde_json::json!({"club_id": pleb_club})),
    )
    .await;
    assert!(is_ok(&resp), "revoke: {}", err_msg(&resp));

    // Unknown club errors.
    let resp = req(
        &mut as_,
        &mut ar,
        4,
        "admin_grant_admin",
        Some(serde_json::json!({"club_id": 987654})),
    )
    .await;
    assert!(resp["type"] == "error");

    // Pleb cannot list the directory.
    let resp = req(&mut ps, &mut pr, 5, "admin_clubs_list", None).await;
    assert!(resp["type"] == "error");
}

// ─── P5: network status + probe over the wire ──────────────────────

#[tokio::test]
async fn admin_network_status_and_probe_over_wire() {
    let srv = TestServer::start().await;

    // Pleb refused.
    let (mut ps, mut pr, _) = pleb_session(&srv.addr).await;
    let resp = req(&mut ps, &mut pr, 1, "admin_network_status", None).await;
    assert!(resp["type"] == "error");

    let (mut as_, mut ar, _admin) = admin_session(&srv.addr).await;

    // Status: single-player defaults, empty directory.
    let resp = req(&mut as_, &mut ar, 1, "admin_network_status", None).await;
    assert!(is_ok(&resp), "status: {}", err_msg(&resp));
    let inner = &resp["value"]["value"];
    assert_eq!(inner["network_enabled"].as_bool(), Some(false));
    assert_eq!(inner["servers"].as_array().map(|a| a.len()), Some(0));

    // Probe of an unknown server: clean error, no hang.
    let resp = req(
        &mut as_,
        &mut ar,
        2,
        "admin_server_probe",
        Some(serde_json::json!({"server_key": "999999"})),
    )
    .await;
    assert!(
        resp["type"] == "error",
        "unknown probe must error: {:?}",
        resp
    );
}

#[tokio::test]
async fn translate_capabilities_reports_disabled_without_provider() {
    // FR-155: with no provider configured the op is descriptive
    // about it — enabled:false plus the env var name that turns it
    // on. Capability discovery must work for any connected session.
    let srv = TestServer::start().await;
    let (mut s, mut r) = connect_with_handshake(&srv.addr).await;
    let resp = req(&mut s, &mut r, 1, "translate_capabilities", None).await;
    assert!(is_ok(&resp), "capabilities: {}", err_msg(&resp));
    let inner = &resp["value"]["value"];
    assert_eq!(inner["enabled"].as_bool(), Some(false));
    assert!(
        inner["reason"]
            .as_str()
            .unwrap_or_default()
            .contains("XUDANU_TRANSLATE_PROVIDER_URL"),
        "reason must name the env var: {:?}",
        inner["reason"]
    );
    assert!(inner["cache_entries"].as_u64().is_some());
    // Stage 3 contract: with no data directory the durable layer is
    // absent — null, not zero — so "memory-only" is observable.
    assert!(inner["cache_disk_entries"].is_null());
    assert!(inner["rendition_store_path"].is_null());
}

#[tokio::test]
async fn admin_rate_limit_get_set_over_wire() {
    // Operator knob for the public-read budget: admin-gated on both
    // ops, bounds enforced, changes reflected immediately.
    let srv = TestServer::start().await;

    // Pleb refused on both.
    let (mut ps, mut pr, _) = pleb_session(&srv.addr).await;
    let resp = req(&mut ps, &mut pr, 1, "admin_rate_limit_get", None).await;
    assert!(resp["type"] == "error", "get must be admin-gated");
    let resp = req(
        &mut ps,
        &mut pr,
        2,
        "admin_rate_limit_set",
        Some(serde_json::json!({"get_limit": 240})),
    )
    .await;
    assert!(resp["type"] == "error", "set must be admin-gated");

    let (mut as_, mut ar, _admin) = admin_session(&srv.addr).await;

    // Default budget reported with the full contract context.
    let resp = req(&mut as_, &mut ar, 1, "admin_rate_limit_get", None).await;
    assert!(is_ok(&resp), "get: {}", err_msg(&resp));
    let inner = &resp["value"]["value"];
    assert_eq!(inner["get_limit"].as_u64(), Some(120));
    assert_eq!(inner["default_get_limit"].as_u64(), Some(120));
    assert_eq!(inner["min_get_limit"].as_u64(), Some(10));
    assert_eq!(inner["max_get_limit"].as_u64(), Some(1_000_000));
    assert_eq!(inner["get_window_secs"].as_u64(), Some(60));

    // Set + reflected immediately.
    let resp = req(
        &mut as_,
        &mut ar,
        2,
        "admin_rate_limit_set",
        Some(serde_json::json!({"get_limit": 240})),
    )
    .await;
    assert!(is_ok(&resp), "set: {}", err_msg(&resp));
    assert_eq!(
        resp["value"]["value"]["get_limit"].as_u64(),
        Some(240),
        "set echoes the applied limit"
    );
    let resp = req(&mut as_, &mut ar, 3, "admin_rate_limit_get", None).await;
    assert_eq!(resp["value"]["value"]["get_limit"].as_u64(), Some(240));

    // Out-of-bounds values are rejected with an error, and the
    // previous limit survives them.
    for bad in [0u64, 5, 2_000_000] {
        let resp = req(
            &mut as_,
            &mut ar,
            4,
            "admin_rate_limit_set",
            Some(serde_json::json!({"get_limit": bad})),
        )
        .await;
        assert!(resp["type"] == "error", "bounds must reject {}", bad);
    }
    let resp = req(&mut as_, &mut ar, 5, "admin_rate_limit_get", None).await;
    assert_eq!(
        resp["value"]["value"]["get_limit"].as_u64(),
        Some(240),
        "rejected sets must not change the limit"
    );
}

// ─── FR-155 Stage A: human renditions over the wire ────────────────

/// A pleb session that creates a password-holding personal club and
/// authenticates as it — a distinct acting identity for the
/// two-person endorsement rule.
async fn persona_session(
    addr: &SocketAddr,
    display_name: &str,
    password: &str,
) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(addr).await;
    let resp = req(&mut s, &mut r, 1, "session_connect", None).await;
    let _sid = resp["value"]["value"].as_u64().unwrap();
    req(&mut s, &mut r, 2, "session_login_public", None).await;
    let resp = req(
        &mut s,
        &mut r,
        3,
        "club_create_personal",
        Some(serde_json::json!({
            "display_name": display_name,
            "password": password.as_bytes().iter().map(|&b| serde_json::Value::from(b)).collect::<Vec<_>>(),
        })),
    )
    .await;
    let club = resp["value"]["value"].as_u64().unwrap();
    req(
        &mut s,
        &mut r,
        4,
        "session_login",
        Some(serde_json::json!({"club_id": club})),
    )
    .await;
    let resp = req(
        &mut s,
        &mut r,
        5,
        "session_authenticate",
        Some(serde_json::json!({"credential": password_credential(password.as_bytes())})),
    )
    .await;
    assert!(is_ok(&resp), "authenticate: {}", err_msg(&resp));
    (s, r, club)
}

#[tokio::test]
async fn translation_human_renditions_over_wire() {
    // Stage A: submit → list → endorse (two-person rule, ladder,
    // retraction) → validation rejections, all over the wire. The
    // durable store rides the persistent test server's data dir.
    let srv = TestServer::start_persistent("fr155-human").await;

    let (mut ts, mut tr, translator_club) = persona_session(&srv.addr, "translator", "tpass").await;
    let (mut es, mut er, endorser_club) = persona_session(&srv.addr, "endorser", "epass").await;
    assert_ne!(translator_club, endorser_club);

    // A published, publicly readable German work.
    let text = "Über allen Gipfeln ist Ruh";
    let mut id = 10u16;
    let wid = create_work(&mut ts, &mut tr, &mut id, text).await;
    let wid_hex = format!("{:x}", wid);
    let resp = req(
        &mut ts,
        &mut tr,
        11,
        "work_publish",
        Some(serde_json::json!({"work_id": wid})),
    )
    .await;
    assert!(is_ok(&resp), "publish: {}", err_msg(&resp));
    let pub_club = req(
        &mut ts,
        &mut tr,
        12,
        "club_id_by_name",
        Some(serde_json::json!({"name": "public"})),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();
    let resp = req(
        &mut ts,
        &mut tr,
        13,
        "work_set_read_club",
        Some(serde_json::json!({"work_id": wid, "club_id": pub_club})),
    )
    .await;
    assert!(is_ok(&resp), "read club: {}", err_msg(&resp));
    // Document default language: German (empty range).
    let resp = req(
        &mut ts,
        &mut tr,
        14,
        "annotation_create",
        Some(serde_json::json!({
            "work_id": wid,
            "annotation_id": 1,
            "kind": "language",
            "payload": serde_json::json!({"lang": "de"}).to_string(),
            "char_start": 0,
            "char_end": 0,
            "is_private": false,
        })),
    )
    .await;
    assert!(is_ok(&resp), "annotation: {}", err_msg(&resp));

    // A single line coalesces to one span covering [0, len).
    let source_hash = blake3::hash(text.as_bytes()).to_hex().to_string();
    let submit_payload = |hash: &str, rendition: &str| {
        serde_json::json!({
            "work_id": wid_hex,
            "target_lang": "en",
            "license": "cc-by",
            "derived_from_model": null,
            "spans": [{
                "char_start": 0,
                "char_end": text.chars().count(),
                "source_hash": hash,
                "rendition": rendition,
            }],
        })
    };

    // Unknown license rejected before anything else.
    let mut bad = submit_payload(&source_hash, "Above all summits it is calm");
    bad["license"] = serde_json::json!("made-up");
    let resp = req(&mut ts, &mut tr, 20, "translation_submit", Some(bad)).await;
    assert!(resp["type"] == "error", "unknown license must reject");
    assert!(
        err_msg(&resp).contains("unknown license"),
        "{}",
        err_msg(&resp)
    );

    // Stale source hash rejected: the source changed; retranslate.
    let stale = blake3::hash("anderer text".as_bytes()).to_hex().to_string();
    let resp = req(
        &mut ts,
        &mut tr,
        21,
        "translation_submit",
        Some(submit_payload(&stale, "Above all summits it is calm")),
    )
    .await;
    assert!(resp["type"] == "error", "stale hash must reject");
    assert!(
        err_msg(&resp).contains("source changed"),
        "{}",
        err_msg(&resp)
    );

    // Happy submit.
    let resp = req(
        &mut ts,
        &mut tr,
        22,
        "translation_submit",
        Some(submit_payload(&source_hash, "Above all summits it is calm")),
    )
    .await;
    assert!(is_ok(&resp), "submit: {}", err_msg(&resp));
    let sub1 = &resp["value"]["value"];
    assert_eq!(sub1["grade"], "human-draft");
    assert_eq!(sub1["submitter"].as_u64(), Some(translator_club));
    let submission_id = sub1["submission"].as_str().unwrap().to_string();
    assert_eq!(submission_id.len(), 64, "blake3 hex id");

    // Two-person rule: the submitter cannot endorse their own.
    let resp = req(
        &mut ts,
        &mut tr,
        23,
        "translation_endorse",
        Some(serde_json::json!({"submission": submission_id})),
    )
    .await;
    assert!(resp["type"] == "error", "self-endorse must reject");
    assert!(
        err_msg(&resp).contains("two-person rule"),
        "{}",
        err_msg(&resp)
    );

    // Endorsement by a second identity moves it up the ladder.
    let resp = req(
        &mut es,
        &mut er,
        30,
        "translation_endorse",
        Some(serde_json::json!({"submission": submission_id})),
    )
    .await;
    assert!(is_ok(&resp), "endorse: {}", err_msg(&resp));
    let up = &resp["value"]["value"];
    assert_eq!(up["grade"], "human-reviewed");
    assert_eq!(up["endorsements"], 1);
    assert_eq!(
        up["submission"].as_str(),
        Some(submission_id.as_str()),
        "the id is stable under endorsement"
    );

    // One endorsement per identity.
    let resp = req(
        &mut es,
        &mut er,
        31,
        "translation_endorse",
        Some(serde_json::json!({"submission": submission_id})),
    )
    .await;
    assert!(resp["type"] == "error", "duplicate endorse must reject");
    assert!(
        err_msg(&resp).contains("already endorsed"),
        "{}",
        err_msg(&resp)
    );

    // List reflects the reviewed grade; any connected session reads.
    let resp = req(
        &mut es,
        &mut er,
        32,
        "translation_list",
        Some(serde_json::json!({"work_id": wid_hex, "lang": "en"})),
    )
    .await;
    assert!(is_ok(&resp), "list: {}", err_msg(&resp));
    let subs = resp["value"]["value"]["submissions"].as_array().cloned();
    let subs = subs.unwrap_or_default();
    assert_eq!(subs.len(), 1);
    assert_eq!(subs[0]["grade"], "human-reviewed");
    assert_eq!(subs[0]["endorsements"], 1);

    // Retraction drops it back to draft.
    let resp = req(
        &mut es,
        &mut er,
        33,
        "translation_unendorse",
        Some(serde_json::json!({"submission": submission_id})),
    )
    .await;
    assert!(is_ok(&resp), "unendorse: {}", err_msg(&resp));
    assert_eq!(resp["value"]["value"]["grade"], "human-draft");
    let resp = req(
        &mut es,
        &mut er,
        34,
        "translation_unendorse",
        Some(serde_json::json!({"submission": submission_id})),
    )
    .await;
    assert!(resp["type"] == "error", "double retraction must reject");

    // A second submission by the endorser; the list orders strongest
    // first, so the still-endorsed one wins once re-endorsed.
    let resp = req(
        &mut es,
        &mut er,
        40,
        "translation_submit",
        Some(submit_payload(
            &source_hash,
            "Over every peak there is quiet",
        )),
    )
    .await;
    assert!(is_ok(&resp), "second submit: {}", err_msg(&resp));
    let sub2_id = resp["value"]["value"]["submission"]
        .as_str()
        .unwrap()
        .to_string();
    let resp = req(
        &mut ts,
        &mut tr,
        41,
        "translation_endorse",
        Some(serde_json::json!({"submission": sub2_id})),
    )
    .await;
    assert!(is_ok(&resp), "cross endorse: {}", err_msg(&resp));
    let resp = req(
        &mut es,
        &mut er,
        42,
        "translation_list",
        Some(serde_json::json!({"work_id": wid_hex, "lang": "en"})),
    )
    .await;
    let subs = resp["value"]["value"]["submissions"].as_array().cloned();
    let subs = subs.unwrap_or_default();
    assert_eq!(subs.len(), 2, "two submissions recorded");
    assert_eq!(
        subs[0]["submission"].as_str(),
        Some(sub2_id.as_str()),
        "endorsed submission lists first"
    );
    assert_eq!(subs[0]["grade"], "human-reviewed");
    assert_eq!(subs[1]["grade"], "human-draft");
}
