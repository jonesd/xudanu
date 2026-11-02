//! FR-157 trust-lab v0: the synthetic-population harness over both
//! endorsement domains — FR-155 human renditions and FR-158 skills
//! claims. Seeded personas with behavioral profiles (a careful
//! human, an AI agent, a sloppy liberal endorser, and a
//! three-identity colluding ring) play both ladders end to end on
//! one server. The test asserts the shared rules in each store —
//! two-person rule, one endorsement per identity, retraction,
//! derived grades, best-first ordering — and pins the v0 inflation
//! semantics: endorsements are unweighted, so the ring out-votes
//! honest work in both domains. That pin is the baseline FR-157's
//! work-weighting must invert; when weighting lands, the ring
//! assertions here flip from "records the inflation" to "suppresses
//! it" on the same scenario.

#![cfg(feature = "server")]

use futures_util::{SinkExt, StreamExt};
use std::net::SocketAddr;
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::transport::{build_router, AppState, PROTOCOL_VERSION};
use xudanu::server::Server;

fn password_credential(pw: &[u8]) -> serde_json::Value {
    serde_json::json!({"password": pw.iter().map(|&b| serde_json::Value::from(b)).collect::<Vec<_>>()})
}

struct TestServer {
    addr: SocketAddr,
}

impl TestServer {
    async fn start_persistent(tag: &str) -> Self {
        let dir = std::env::temp_dir().join(format!(
            "xudanu_trust_lab_{}_{}_{}",
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
        let admin_club = server.admin_club_id();
        let setup_sid = server.connect();
        server.login_public(setup_sid).unwrap();
        server.grant_admin_authority(setup_sid).unwrap();
        server
            .club_set_password(setup_sid, admin_club, b"lab-admin-pass")
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

/// One synthetic identity: a password-holding personal club, logged
/// in and authenticated on its own WebSocket — the population unit
/// for every behavioral profile.
async fn persona_session(
    addr: &SocketAddr,
    display_name: &str,
    password: &str,
) -> (SplitSender, SplitReceiver, u64) {
    let (mut s, mut r) = connect_with_handshake(addr).await;
    req(&mut s, &mut r, 1, "session_connect", None).await;
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
    assert!(resp["type"] == "response", "authenticate");
    (s, r, club)
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

fn claim_index(claims: &[serde_json::Value], subject: u64) -> usize {
    claims
        .iter()
        .position(|c| c["subject"].as_u64() == Some(subject))
        .unwrap_or_else(|| panic!("no claim for club {subject} in list"))
}

fn sub_index(subs: &[serde_json::Value], submitter: u64) -> usize {
    subs.iter()
        .position(|s| s["submitter"].as_u64() == Some(submitter))
        .unwrap_or_else(|| panic!("no submission by club {submitter} in list"))
}

macro_rules! call {
    ($s:expr, $r:expr, $id:ident, $op:expr, $payload:expr) => {{
        $id += 1;
        req(&mut $s, &mut $r, $id, $op, $payload).await
    }};
}

/// The population plays both endorsement domains on one server: the
/// ladder rules hold identically in each store, and the unweighted
/// v0 semantics are pinned so work-weighting (FR-157) has a baseline
/// to invert.
#[tokio::test]
async fn trust_lab_population_over_wire() {
    let srv = TestServer::start_persistent("fr157-v0").await;

    // The population: honest human, AI agent, sloppy endorser, and a
    // three-identity colluding ring.
    let (mut hs, mut hr, honest) =
        persona_session(&srv.addr, "lab-honest", "lab-honest-pass").await;
    let (mut ags, mut agr, agent) = persona_session(&srv.addr, "lab-agent", "lab-agent-pass").await;
    let (mut sls, mut slr, sloppy) =
        persona_session(&srv.addr, "lab-sloppy", "lab-sloppy-pass").await;
    let (mut ras, mut rar, ring_a) =
        persona_session(&srv.addr, "lab-ring-a", "lab-ring-a-pass").await;
    let (mut rbs, mut rbr, ring_b) =
        persona_session(&srv.addr, "lab-ring-b", "lab-ring-b-pass").await;
    let (mut rcs, mut rcr, ring_c) =
        persona_session(&srv.addr, "lab-ring-c", "lab-ring-c-pass").await;
    let ring = [ring_a, ring_b, ring_c];
    for (i, x) in ring.iter().enumerate() {
        for y in ring.iter().skip(i + 1) {
            assert_ne!(x, y, "ring identities must be distinct");
        }
    }

    let mut id = 10u16;

    // ─── The corpus: one public-domain German work ────────────────
    // (Goethe, Wanderers Nachtlied — public domain), published and
    // publicly readable so renditions can attach to it.
    let text = "Über allen Gipfeln ist Ruh";
    let pub_wid = create_work(&mut hs, &mut hr, &mut id, text).await;
    let pub_hex = format!("{:x}", pub_wid);
    assert!(
        is_ok(&call!(
            hs,
            hr,
            id,
            "work_publish",
            Some(serde_json::json!({"work_id": pub_wid}))
        )),
        "publish"
    );
    let pub_club = call!(
        hs,
        hr,
        id,
        "club_id_by_name",
        Some(serde_json::json!({"name": "public"}))
    )["value"]["value"]
        .as_u64()
        .unwrap();
    assert!(
        is_ok(&call!(
            hs,
            hr,
            id,
            "work_set_read_club",
            Some(serde_json::json!({"work_id": pub_wid, "club_id": pub_club}))
        )),
        "public read"
    );
    assert!(
        is_ok(&call!(
            hs,
            hr,
            id,
            "annotation_create",
            Some(serde_json::json!({
                "work_id": pub_wid,
                "annotation_id": 1,
                "kind": "language",
                "payload": serde_json::json!({"lang": "de"}).to_string(),
                "char_start": 0,
                "char_end": 0,
                "is_private": false,
            }))
        )),
        "language annotation"
    );

    // Each persona authors one evidence work — skills claims anchor
    // to works, and renditions are not content, so the portfolio is
    // the claimable evidence.
    let ev_honest = create_work(&mut hs, &mut hr, &mut id, "Nachtlied translation journal").await;
    let ev_agent = create_work(&mut ags, &mut agr, &mut id, "Engine-assisted drafting log").await;
    let ev_sloppy = create_work(&mut sls, &mut slr, &mut id, "Quick reading notes").await;
    let ev_a = create_work(&mut ras, &mut rar, &mut id, "Ring study notes A").await;
    let ev_b = create_work(&mut rbs, &mut rbr, &mut id, "Ring study notes B").await;
    let ev_c = create_work(&mut rcs, &mut rcr, &mut id, "Ring study notes C").await;

    // ─── Domain 1: human renditions (FR-155) ──────────────────────
    let source_hash = blake3::hash(text.as_bytes()).to_hex().to_string();
    let span_payload = |model: Option<&str>, rendition: &str| {
        serde_json::json!({
            "work_id": pub_hex,
            "target_lang": "en",
            "license": "cc-by",
            "derived_from_model": model,
            "spans": [{
                "char_start": 0,
                "char_end": text.chars().count(),
                "source_hash": source_hash,
                "rendition": rendition,
            }],
        })
    };

    // Profile behavior, in character: honest submits a careful
    // rendition; the agent submits an engine-assisted draft (PROV
    // wasRevisionOf rides the wire); sloppy submits a loose one.
    let r1 = call!(
        hs,
        hr,
        id,
        "translation_submit",
        Some(span_payload(None, "Above all the summits it is calm"))
    );
    assert!(is_ok(&r1), "honest submit: {}", err_msg(&r1));
    let r1_id = r1["value"]["value"]["submission"]
        .as_str()
        .unwrap()
        .to_string();
    assert_eq!(r1["value"]["value"]["grade"], "human-draft");

    let r2 = call!(
        ags,
        agr,
        id,
        "translation_submit",
        Some(span_payload(
            Some("lab-engine-1"),
            "Over all the peaks there is rest"
        ))
    );
    assert!(is_ok(&r2), "agent submit: {}", err_msg(&r2));
    let r2_id = r2["value"]["value"]["submission"]
        .as_str()
        .unwrap()
        .to_string();
    assert_eq!(r2["value"]["value"]["derived_from_model"], "lab-engine-1");

    let r3 = call!(
        sls,
        slr,
        id,
        "translation_submit",
        Some(span_payload(None, "peaceful tops everywhere"))
    );
    assert!(is_ok(&r3), "sloppy submit: {}", err_msg(&r3));
    let r3_id = r3["value"]["value"]["submission"]
        .as_str()
        .unwrap()
        .to_string();

    // Two-person rule, both directions.
    let resp = call!(
        hs,
        hr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r1_id}))
    );
    assert!(resp["type"] == "error", "honest cannot self-endorse");
    assert!(
        err_msg(&resp).contains("two-person rule"),
        "{}",
        err_msg(&resp)
    );
    let resp = call!(
        ags,
        agr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r2_id}))
    );
    assert!(resp["type"] == "error", "agent cannot self-endorse");

    // Honest work earns outside vouches: the agent endorses the
    // human's accurate rendition; sloppy endorses liberally.
    let resp = call!(
        ags,
        agr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r1_id}))
    );
    assert!(is_ok(&resp), "agent endorses R1: {}", err_msg(&resp));
    assert_eq!(resp["value"]["value"]["grade"], "human-reviewed");
    let resp = call!(
        sls,
        slr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r1_id}))
    );
    assert!(is_ok(&resp), "sloppy endorses R1: {}", err_msg(&resp));
    assert_eq!(resp["value"]["value"]["endorsements"], 2);

    // The human reviews the agent's draft, then withdraws —
    // retraction as review-withdrawal, the ladder falling back.
    let resp = call!(
        hs,
        hr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r2_id}))
    );
    assert!(is_ok(&resp), "honest endorses R2: {}", err_msg(&resp));
    let resp = call!(
        hs,
        hr,
        id,
        "translation_unendorse",
        Some(serde_json::json!({"submission": r2_id}))
    );
    assert!(is_ok(&resp), "honest retracts R2: {}", err_msg(&resp));
    assert_eq!(resp["value"]["value"]["grade"], "human-draft");
    assert_eq!(resp["value"]["value"]["endorsements"], 0);

    // The ring pumps sloppy's rendition: three vouches, none earned.
    let resp = call!(
        ras,
        rar,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r3_id}))
    );
    assert!(is_ok(&resp), "ring_a endorses R3: {}", err_msg(&resp));
    let resp = call!(
        rbs,
        rbr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r3_id}))
    );
    assert!(is_ok(&resp), "ring_b endorses R3: {}", err_msg(&resp));
    let resp = call!(
        rcs,
        rcr,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r3_id}))
    );
    assert!(is_ok(&resp), "ring_c endorses R3: {}", err_msg(&resp));
    // One endorsement per identity.
    let resp = call!(
        ras,
        rar,
        id,
        "translation_endorse",
        Some(serde_json::json!({"submission": r3_id}))
    );
    assert!(resp["type"] == "error", "ring member cannot endorse twice");
    assert!(
        err_msg(&resp).contains("already endorsed"),
        "{}",
        err_msg(&resp)
    );

    // THE V0 INFLATION PIN: with unweighted endorsements the ring's
    // pick tops the list — three colluding vouches beat the honest
    // pair's two. When work-weighting lands (FR-157), this ordering
    // assertion is the one that must invert on the same scenario.
    let resp = call!(
        sls,
        slr,
        id,
        "translation_list",
        Some(serde_json::json!({"work_id": pub_hex, "lang": "en"}))
    );
    assert!(is_ok(&resp), "list: {}", err_msg(&resp));
    let subs = resp["value"]["value"]["submissions"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert_eq!(subs.len(), 3, "three submissions recorded");
    let (i1, i2, i3) = (
        sub_index(&subs, honest),
        sub_index(&subs, agent),
        sub_index(&subs, sloppy),
    );
    assert!(
        i3 < i1 && i1 < i2,
        "order is ring(3) > honest(2) > agent(0): got {i3} < {i1} < {i2}"
    );
    assert_eq!(subs[i3]["grade"], "human-reviewed");
    assert_eq!(subs[i3]["endorsements"], 3);
    let mut r3_endorsers = subs[i3]["endorsers"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    r3_endorsers.sort_by_key(|v| v.as_u64().unwrap());
    let mut expected = ring.to_vec();
    expected.sort();
    let expected: Vec<serde_json::Value> =
        expected.into_iter().map(serde_json::Value::from).collect();
    assert_eq!(r3_endorsers, expected, "R3's vouches are exactly the ring");
    assert_eq!(subs[i1]["grade"], "human-reviewed");
    assert_eq!(subs[i2]["grade"], "human-draft");

    // ─── Domain 2: skills claims (FR-158) ─────────────────────────
    let claim_payload = |subject: u64, skill: &str, evidence_hex: &str, note: &str| {
        serde_json::json!({
            "subject": subject,
            "skill": skill,
            "summary": "translation practice",
            "evidence": [{"work_id": evidence_hex, "note": note}],
        })
    };

    // Everyone claims translation — honest in mixed case, which
    // normalizes onto the same tag as the rest of the population.
    let c_h = call!(
        hs,
        hr,
        id,
        "skill_claim_submit",
        Some(claim_payload(
            honest,
            "Translation",
            &format!("{:x}", ev_honest),
            "kept the journal"
        ))
    );
    assert!(is_ok(&c_h), "honest claim: {}", err_msg(&c_h));
    assert_eq!(c_h["value"]["value"]["skill"], "translation");
    let c_h_id = c_h["value"]["value"]["claim"].as_str().unwrap().to_string();

    let c_ag = call!(
        ags,
        agr,
        id,
        "skill_claim_submit",
        Some(claim_payload(
            agent,
            "translation",
            &format!("{:x}", ev_agent),
            "drafted with engine assist"
        ))
    );
    assert!(is_ok(&c_ag), "agent claim: {}", err_msg(&c_ag));

    let c_sl = call!(
        sls,
        slr,
        id,
        "skill_claim_submit",
        Some(claim_payload(
            sloppy,
            "translation",
            &format!("{:x}", ev_sloppy),
            "read a lot"
        ))
    );
    assert!(is_ok(&c_sl), "sloppy claim: {}", err_msg(&c_sl));

    let c_a = call!(
        ras,
        rar,
        id,
        "skill_claim_submit",
        Some(claim_payload(
            ring_a,
            "translation",
            &format!("{:x}", ev_a),
            "studied together"
        ))
    );
    assert!(is_ok(&c_a), "ring_a claim: {}", err_msg(&c_a));
    let c_b = call!(
        rbs,
        rbr,
        id,
        "skill_claim_submit",
        Some(claim_payload(
            ring_b,
            "translation",
            &format!("{:x}", ev_b),
            "studied together"
        ))
    );
    assert!(is_ok(&c_b), "ring_b claim: {}", err_msg(&c_b));
    let c_c = call!(
        rcs,
        rcr,
        id,
        "skill_claim_submit",
        Some(claim_payload(
            ring_c,
            "translation",
            &format!("{:x}", ev_c),
            "studied together"
        ))
    );
    assert!(is_ok(&c_c), "ring_c claim: {}", err_msg(&c_c));
    let (c_a_id, c_b_id, c_c_id) = (
        c_a["value"]["value"]["claim"].as_str().unwrap().to_string(),
        c_b["value"]["value"]["claim"].as_str().unwrap().to_string(),
        c_c["value"]["value"]["claim"].as_str().unwrap().to_string(),
    );

    // Two-person rule again, same shape in the second store.
    let resp = call!(
        hs,
        hr,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_h_id}))
    );
    assert!(
        resp["type"] == "error",
        "honest cannot self-endorse the claim"
    );
    assert!(
        err_msg(&resp).contains("two-person rule"),
        "{}",
        err_msg(&resp)
    );

    // Honest's claim earns outside vouches (the agent's, and
    // sloppy's liberal one); the agent's own claim earns none — an
    // AI agent's standing must be vouched in, not assumed.
    let resp = call!(
        ags,
        agr,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_h_id}))
    );
    assert!(
        is_ok(&resp),
        "agent endorses honest's claim: {}",
        err_msg(&resp)
    );
    let resp = call!(
        sls,
        slr,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_h_id}))
    );
    assert!(
        is_ok(&resp),
        "sloppy endorses honest's claim: {}",
        err_msg(&resp)
    );
    assert_eq!(resp["value"]["value"]["endorsements"], 2);

    // The ring closes on itself: ring_b and ring_c vouch ring_a's
    // claim, and ring_a vouches both of theirs. Every ring claim
    // reaches verified with zero endorsements from outside the ring.
    let resp = call!(
        rbs,
        rbr,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_a_id}))
    );
    assert!(is_ok(&resp), "ring_b vouches ring_a: {}", err_msg(&resp));
    let resp = call!(
        rcs,
        rcr,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_a_id}))
    );
    assert!(is_ok(&resp), "ring_c vouches ring_a: {}", err_msg(&resp));
    let resp = call!(
        ras,
        rar,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_b_id}))
    );
    assert!(is_ok(&resp), "ring_a vouches ring_b: {}", err_msg(&resp));
    let resp = call!(
        ras,
        rar,
        id,
        "skill_endorse",
        Some(serde_json::json!({"claim": c_c_id}))
    );
    assert!(is_ok(&resp), "ring_a vouches ring_c: {}", err_msg(&resp));

    // The expertise-location query, best first.
    let resp = call!(
        sls,
        slr,
        id,
        "skill_list",
        Some(serde_json::json!({"skill": "Translation"}))
    );
    assert!(is_ok(&resp), "list by skill: {}", err_msg(&resp));
    assert_eq!(
        resp["value"]["value"]["skill"], "translation",
        "query normalizes"
    );
    let claims = resp["value"]["value"]["claims"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert_eq!(claims.len(), 6, "the whole population claims translation");
    let (ih, iag, isl, ia, ib, ic) = (
        claim_index(&claims, honest),
        claim_index(&claims, agent),
        claim_index(&claims, sloppy),
        claim_index(&claims, ring_a),
        claim_index(&claims, ring_b),
        claim_index(&claims, ring_c),
    );
    // Verified before claimed, robustly: the four endorsed claims
    // precede the two unendorsed ones whatever the timestamp ties.
    assert!(
        ia < iag && ib < iag && ic < iag && ih < iag,
        "verified precedes claimed"
    );
    assert!(
        ia < isl && ib < isl && ic < isl && ih < isl,
        "verified precedes claimed"
    );
    // More endorsements first within verified: the 2-vouch claims
    // (honest's, ring_a's) outrank the 1-vouch ones.
    assert!(
        ih < ib && ih < ic && ia < ib && ia < ic,
        "2 vouches outrank 1"
    );
    // The measured sybil baseline: ring_b's and ring_c's claims are
    // verified by exactly {ring_a} — zero outside vouches. FR-157's
    // work-weighting must price these near zero.
    for (idx, who) in [(ib, ring_b), (ic, ring_c)] {
        assert_eq!(claims[idx]["grade"], "verified");
        assert_eq!(claims[idx]["endorsements"], 1);
        assert_eq!(
            claims[idx]["endorsers"]
                .as_array()
                .cloned()
                .unwrap_or_default(),
            vec![serde_json::Value::from(ring_a)],
            "{who}'s claim is verified by the ring alone"
        );
    }
    assert_eq!(claims[ih]["grade"], "verified");
    assert_eq!(claims[ih]["endorsements"], 2);
    assert_eq!(
        claims[iag]["grade"], "claimed",
        "the agent's claim stays claimed until vouched"
    );
    assert_eq!(claims[isl]["grade"], "claimed");

    // Retraction is live here too: ring_c withdraws, ring_a's claim
    // keeps its derived grade on the remaining vouch.
    let resp = call!(
        rcs,
        rcr,
        id,
        "skill_unendorse",
        Some(serde_json::json!({"claim": c_a_id}))
    );
    assert!(is_ok(&resp), "ring_c retracts: {}", err_msg(&resp));
    assert_eq!(resp["value"]["value"]["grade"], "verified");
    assert_eq!(resp["value"]["value"]["endorsements"], 1);

    // ─── One identity, two trust structures ───────────────────────
    // The same club id is the rendition submitter in the translate
    // store and the claim subject in the skills store: the fabric's
    // join key. Per-club reads confirm each persona's records.
    let resp = call!(
        ags,
        agr,
        id,
        "skill_list",
        Some(serde_json::json!({"club": honest}))
    );
    let claims = resp["value"]["value"]["claims"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert_eq!(claims.len(), 1);
    assert_eq!(claims[0]["claim"].as_str(), Some(c_h_id.as_str()));
    assert_eq!(claims[0]["grade"], "verified");
    let resp = call!(
        sls,
        slr,
        id,
        "skill_list",
        Some(serde_json::json!({"club": agent}))
    );
    let claims = resp["value"]["value"]["claims"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert_eq!(claims.len(), 1);
    assert_eq!(claims[0]["grade"], "claimed");
    let resp = call!(
        ags,
        agr,
        id,
        "translation_list",
        Some(serde_json::json!({"work_id": pub_hex, "lang": "en"}))
    );
    let subs = resp["value"]["value"]["submissions"]
        .as_array()
        .cloned()
        .unwrap_or_default();
    assert_eq!(
        subs[sub_index(&subs, honest)]["submitter"].as_u64(),
        Some(honest)
    );
    assert_eq!(subs[sub_index(&subs, honest)]["grade"], "human-reviewed");
}
