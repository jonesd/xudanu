use std::net::SocketAddr;
use std::sync::Arc;
use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::tungstenite::Message;
use xudanu::server::Server;
use xudanu::server::transport::{AppState, build_router, PROTOCOL_VERSION};

type SplitSender = futures_util::stream::SplitSink<
    tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
    Message,
>;
type SplitReceiver = futures_util::stream::SplitStream<
    tokio_tungstenite::WebSocketStream<
        tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
    >,
>;

struct TlsTestServer {
    addr: SocketAddr,
    cert_der: Vec<u8>,
}

impl TlsTestServer {
    async fn start() -> Self {
        let rcgen::CertifiedKey { cert, key_pair } =
            rcgen::generate_simple_self_signed(vec![
                "localhost".to_string(),
                "127.0.0.1".to_string(),
            ])
            .expect("failed to generate cert");

        let cert_der_bytes = cert.der().as_ref().to_vec();
        let cert_der = cert.der().clone();
        let key_der = key_pair.serialize_der();
        let key =
            rustls::pki_types::PrivateKeyDer::from(rustls::pki_types::PrivatePkcs8KeyDer::from(
                key_der,
            ));

        rustls::crypto::ring::default_provider().install_default().ok();

        let mut server_config = rustls::ServerConfig::builder()
            .with_no_client_auth()
            .with_single_cert(vec![cert_der], key)
            .expect("failed to build server tls config");
        server_config.alpn_protocols = vec![b"http/1.1".to_vec()];

        let tls_config =
            axum_server::tls_rustls::RustlsConfig::from_config(Arc::new(server_config));

        let server = Server::new();
        let state = AppState::new(server).shared();
        let app = build_router(state).into_make_service_with_connect_info::<SocketAddr>();

        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();
        let handle = axum_server::Handle::new();

        let h = handle.clone();
        let tcp = listener.into_std().unwrap();
        tokio::spawn(async move {
            axum_server::from_tcp_rustls(tcp, tls_config)
                .handle(h)
                .serve(app)
                .await
                .unwrap();
        });

        for _ in 0..50 {
            tokio::time::sleep(std::time::Duration::from_millis(20)).await;
            if tokio::net::TcpStream::connect(addr).await.is_ok() {
                break;
            }
        }

        TlsTestServer {
            addr,
            cert_der: cert_der_bytes,
        }
    }

    fn base(&self) -> String {
        format!("{}:{}", self.addr.ip(), self.addr.port())
    }

    fn https_url(&self, path: &str) -> String {
        format!("https://{}{}", self.base(), path)
    }

    fn wss_url(&self, path: &str) -> String {
        format!("wss://{}{}", self.base(), path)
    }

    fn http_client(&self) -> reqwest::Client {
        reqwest::Client::builder()
            .danger_accept_invalid_certs(true)
            .build()
            .unwrap()
    }

    async fn connect_wss(&self, path: &str) -> (SplitSender, SplitReceiver) {
        let mut root_store = rustls::RootCertStore::empty();
        root_store
            .add(rustls::pki_types::CertificateDer::from(self.cert_der.clone()))
            .unwrap();
        let client_config = rustls::ClientConfig::builder()
            .with_root_certificates(root_store)
            .with_no_client_auth();
        let connector = tokio_tungstenite::Connector::Rustls(Arc::new(client_config));

        let url = self.wss_url(path);
        let (stream, _) = tokio_tungstenite::connect_async_tls_with_config(
            &url,
            None,
            false,
            Some(connector),
        )
        .await
        .expect("failed wss connect");
        stream.split()
    }
}

async fn recv_json(rx: &mut SplitReceiver) -> serde_json::Value {
    let msg = rx.next().await.unwrap().unwrap();
    match msg {
        Message::Text(t) => serde_json::from_str(&t).unwrap(),
        Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
        other => panic!("expected json message, got: {:?}", other),
    }
}

fn json_req(id: u16, op: &str, payload: Option<serde_json::Value>) -> serde_json::Value {
    let mut f = serde_json::json!({"v": PROTOCOL_VERSION, "type": "request", "id": id, "op": op});
    if let Some(p) = payload {
        f["payload"] = p;
    }
    f
}

async fn send_recv_json(
    tx: &mut SplitSender,
    rx: &mut SplitReceiver,
    frame: serde_json::Value,
) -> serde_json::Value {
    tx.send(Message::Text(serde_json::to_string(&frame).unwrap().into()))
        .await
        .unwrap();
    recv_json(rx).await
}

async fn json_setup(srv: &TlsTestServer) -> (SplitSender, SplitReceiver, u64) {
    let (mut tx, mut rx) = srv
        .connect_wss(&format!("/xudanu?format=json&version={}", PROTOCOL_VERSION))
        .await;
    let _hs = recv_json(&mut rx).await;
    let sid = send_recv_json(&mut tx, &mut rx, json_req(1, "session_connect", None)).await
        ["value"]["value"]
        .as_u64()
        .unwrap();
    send_recv_json(&mut tx, &mut rx, json_req(2, "session_login_public", None)).await;
    (tx, rx, sid)
}

#[tokio::test]
async fn tls_https_health_endpoint() {
    let srv = TlsTestServer::start().await;
    let client = srv.http_client();

    let resp = client
        .get(&srv.https_url("/health"))
        .send()
        .await
        .expect("https request failed");
    assert_eq!(resp.status(), 200);
    let body: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(body["status"], "ok");
}

#[tokio::test]
async fn tls_https_index_page() {
    let srv = TlsTestServer::start().await;
    let client = srv.http_client();

    let resp = client
        .get(&srv.https_url("/"))
        .send()
        .await
        .expect("https index request failed");
    assert_eq!(resp.status(), 200);
    let body = resp.text().await.unwrap();
    assert!(!body.is_empty());
}

#[tokio::test]
async fn tls_wss_handshake() {
    let srv = TlsTestServer::start().await;

    let (mut tx, mut rx) = srv
        .connect_wss(&format!("/xudanu?format=json&version={}", PROTOCOL_VERSION))
        .await;

    let hs = recv_json(&mut rx).await;
    assert_eq!(hs["type"], "handshake");
    tx.close().await.ok();
}

#[tokio::test]
async fn tls_wss_create_and_open_edition() {
    let srv = TlsTestServer::start().await;
    let (mut tx, mut rx, _sid) = json_setup(&srv).await;

    let resp = send_recv_json(
        &mut tx,
        &mut rx,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "hello tls"}}))),
    )
    .await;
    assert_eq!(resp["type"], "response");
    let work_id = resp["value"]["value"].as_u64().unwrap();
    assert!(work_id > 0);

    let resp = send_recv_json(
        &mut tx,
        &mut rx,
        json_req(20, "work_get_edition", Some(serde_json::json!({"work_id": work_id}))),
    )
    .await;
    assert_eq!(resp["type"], "response");

    tx.close().await.ok();
}

#[tokio::test]
async fn tls_wss_two_clients_sync() {
    let srv = TlsTestServer::start().await;
    let (mut tx_a, mut rx_a, _) = json_setup(&srv).await;
    let (mut tx_b, mut rx_b, _) = json_setup(&srv).await;

    let work_id = send_recv_json(
        &mut tx_a,
        &mut rx_a,
        json_req(10, "work_create", Some(serde_json::json!({"edition": {"text": "initial"}}))),
    )
    .await["value"]["value"]
        .as_u64()
        .unwrap();

    let sub_resp = send_recv_json(
        &mut tx_b,
        &mut rx_b,
        serde_json::json!({
            "v": PROTOCOL_VERSION, "type": "subscribe", "id": 20,
            "payload": {"detector_type": "revision", "target_id": work_id}
        }),
    )
    .await;
    assert_eq!(sub_resp["type"], "response");

    let grab_resp = send_recv_json(
        &mut tx_a,
        &mut rx_a,
        json_req(30, "work_grab", Some(serde_json::json!({"work_id": work_id}))),
    )
    .await;
    assert_eq!(grab_resp["type"], "response");

    let revise_resp = send_recv_json(
        &mut tx_a,
        &mut rx_a,
        json_req(40, "work_revise", Some(serde_json::json!({
            "work_id": work_id,
            "edition": {"text": "hello from client a over tls"}
        }))),
    )
    .await;
    assert_eq!(revise_resp["type"], "response");

    let mut got_event = false;
    let deadline = std::time::Duration::from_secs(3);
    let start = std::time::Instant::now();
    while start.elapsed() < deadline {
        match tokio::time::timeout(std::time::Duration::from_millis(100), rx_b.next()).await {
            Ok(Some(Ok(msg))) => {
                let v: serde_json::Value = match msg {
                    Message::Text(t) => serde_json::from_str(&t).unwrap(),
                    _ => continue,
                };
                if v["type"] == "event" && v["event"]["type"] == "work_revised" {
                    got_event = true;
                    break;
                }
            }
            _ => continue,
        }
    }
    assert!(got_event, "client B should receive work_revised over TLS");

    tx_a.close().await.ok();
    tx_b.close().await.ok();
}

#[tokio::test]
async fn tls_https_blob_not_found() {
    let srv = TlsTestServer::start().await;
    let client = srv.http_client();

    let resp = client
        .get(&srv.https_url(&format!("/blobs/{:016x}", 99999u64)))
        .send()
        .await
        .expect("https blob request failed");
    assert_eq!(resp.status(), 404);
}

#[tokio::test]
async fn tls_server_refuses_plain_http() {
    let srv = TlsTestServer::start().await;

    let plain_client = reqwest::Client::builder().build().unwrap();

    let result = plain_client
        .get(format!("http://{}/health", srv.base()))
        .send()
        .await;

    match result {
        Ok(resp) => {
            assert_ne!(
                resp.status(),
                200,
                "plain HTTP should not serve content on TLS port"
            );
        }
        Err(_) => {}
    }
}
