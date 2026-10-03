//! FR-141 live-server transport tests: MCP tools driven over a real
//! Axum server + WebSocket, through the same handle_message path the
//! xudanu-mcp binary uses.

use xudanu::server::mcp::{handle_message, Docuverse};
use xudanu::server::mcp_ws::WsDocuverse;
use xudanu::server::transport::{build_router, AppState};
use xudanu::server::Server;

struct LiveServer {
    addr: std::net::SocketAddr,
    _keepalive: std::thread::JoinHandle<()>,
}

fn start_live_server() -> LiveServer {
    let (tx, rx) = std::sync::mpsc::channel();
    let handle = std::thread::spawn(move || {
        let rt = tokio::runtime::Runtime::new().unwrap();
        let addr = rt.block_on(async {
            let mut server = Server::new();
            let setup_sid = server.connect();
            server.login_public(setup_sid).unwrap();
            server
                .create_work(
                    setup_sid,
                    xudanu::edition::Edition::from_text("alpha beta gamma"),
                )
                .unwrap();
            server
                .create_work(
                    setup_sid,
                    xudanu::edition::Edition::from_text("beta refutes alpha's claim"),
                )
                .unwrap();
            let state = AppState::new(server).shared();
            let app =
                build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();
            let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
            let addr = listener.local_addr().unwrap();
            tokio::spawn(async move {
                axum::serve(listener, app).await.unwrap();
            });
            addr
        });
        let _ = tx.send(addr);
        loop {
            std::thread::park();
        }
    });
    let addr = rx.recv().expect("server boot");
    LiveServer {
        addr,
        _keepalive: handle,
    }
}

fn remote_target(addr: &std::net::SocketAddr, writes: bool) -> Docuverse {
    let mut ws = WsDocuverse::connect(&format!("ws://{}/xudanu", addr)).expect("ws connect");
    ws.login_public().expect("login");
    if writes {
        ws.set_author_type("test-agent").expect("author type");
    }
    Docuverse::Remote {
        ws,
        writes_enabled: writes,
    }
}

fn call(target: &mut Docuverse, tool: &str, args: serde_json::Value) -> serde_json::Value {
    let frame = serde_json::json!({
        "jsonrpc": "2.0", "id": 1, "method": "tools/call",
        "params": {"name": tool, "arguments": args}
    });
    let resp = handle_message(target, &frame.to_string()).expect("response");
    let v: serde_json::Value = serde_json::from_str(&resp).unwrap();
    assert!(
        !v["result"]["isError"].as_bool().unwrap_or(true),
        "tool {} errored: {}",
        tool,
        v["result"]["content"][0]["text"]
    );
    serde_json::from_str(v["result"]["content"][0]["text"].as_str().unwrap()).unwrap()
}

#[test]
fn remote_read_tools_roundtrip() {
    let live = start_live_server();
    let mut target = remote_target(&live.addr, false);

    let frame = r#"{"jsonrpc":"2.0","id":0,"method":"tools/list"}"#;
    let resp = handle_message(&mut target, frame).unwrap();
    let v: serde_json::Value = serde_json::from_str(&resp).unwrap();
    let names: Vec<&str> = v["result"]["tools"]
        .as_array()
        .unwrap()
        .iter()
        .map(|t| t["name"].as_str().unwrap())
        .collect();
    assert!(names.contains(&"read_span"));
    assert!(!names.contains(&"revise"), "read-only target");

    let search = call(
        &mut target,
        "search_works",
        serde_json::json!({"query": "beta", "max_results": 5}),
    );
    assert!(search["total"].as_u64().unwrap() >= 1);

    let first = search["results"][0]["work_id"].as_u64().unwrap();
    let span = call(
        &mut target,
        "read_span",
        serde_json::json!({"work": first, "start": 0, "end": 5}),
    );
    assert_eq!(span["text"], "alpha");
    assert!(span["uri"].as_str().unwrap().starts_with("xudanu://work/"));
    assert!(!span["content_hash"].as_str().unwrap().is_empty());

    let read = call(&mut target, "read_work", serde_json::json!({"work": first}));
    assert!(read["total_chars"].as_u64().unwrap() >= 10);
}

#[test]
fn remote_write_tools_roundtrip() {
    let live = start_live_server();
    let mut target = remote_target(&live.addr, true);

    let created = call(
        &mut target,
        "create_work",
        serde_json::json!({"text": "agent brief via live server"}),
    );
    let brief = created["work_id"].as_u64().unwrap();
    let read_back = call(&mut target, "read_work", serde_json::json!({"work": brief}));
    assert_eq!(read_back["text"], "agent brief via live server");

    let search = call(
        &mut target,
        "search_works",
        serde_json::json!({"query": "gamma", "max_results": 5}),
    );
    let source = search["results"][0]["work_id"].as_u64().unwrap();

    let watch = call(
        &mut target,
        "watch_work",
        serde_json::json!({"work": source, "kind": "links"}),
    );
    assert!(watch["detector_id"].is_number());

    let link = call(
        &mut target,
        "create_link",
        serde_json::json!({"origin": brief, "destination": source, "link_type": "comment"}),
    );
    assert!(link["link_id"].is_number());

    let events = call(&mut target, "detector_events", serde_json::json!({}));
    assert!(
        events["detectors"]
            .as_array()
            .unwrap()
            .iter()
            .any(|d| d["unread"].as_u64().unwrap_or(0) >= 1),
        "detector should fire over live server: {}",
        events
    );

    let revised = call(
        &mut target,
        "revise",
        serde_json::json!({"work": brief, "text": "agent brief v2"}),
    );
    assert!(revised["revision"].is_number());
    let after = call(&mut target, "read_work", serde_json::json!({"work": brief}));
    assert_eq!(after["text"], "agent brief v2");
}
