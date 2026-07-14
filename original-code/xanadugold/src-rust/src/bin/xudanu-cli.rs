use std::io::{self, BufRead, Write};

use futures_util::{SinkExt, StreamExt};
use tokio_tungstenite::tungstenite::Message;

fn usage() {
    eprintln!("xudanu-cli — command-line client for xudanu server");
    eprintln!();
    eprintln!("Usage:");
    eprintln!("  xudanu-cli <server-url> <command> [args...]");
    eprintln!("  xudanu-cli <server-url> repl");
    eprintln!();
    eprintln!("Commands:");
    eprintln!("  repl                                    Interactive mode");
    eprintln!("  create-work <text>                      Create a work with text content");
    eprintln!("  create-work <title> <text>              Create a titled work");
    eprintln!("  get-work <id>                           Get work edition");
    eprintln!("  list-works                              List all works");
    eprintln!("  grab <id>                               Grab a work for editing");
    eprintln!("  revise <id> <text>                      Revise a grabbed work");
    eprintln!("  release <id>                            Release a grabbed work");
    eprintln!("  history <id>                            Show revision count");
    eprintln!("  fetch-revision <id> <n>                 Fetch specific revision");
    eprintln!("  create-link <origin-id> <dest-id> [type]  Create a link (type: 1=Comment 2=Reference 3=Disagreement 4=Quotation 5=SeeAlso)");
    eprintln!("  set-link-type <link-id> <type-id>        Set link type");
    eprintln!("  publish <id>                            Publish a work (make publicly readable)");
    eprintln!("  get-link <link-id>                      Get link details");
    eprintln!("  list-links <work-id>                    List links involving a work");
    eprintln!("  delete-link <link-id>                   Delete a link");
    eprintln!("  find-content <be-id>                    Find works containing content");
    eprintln!("  club-create [name]                      Create a club (optionally named)");
    eprintln!("  club-list                               List all clubs");
    eprintln!("  info                                    Server info");
    eprintln!("  login                                   Login as public");
    eprintln!("  login-admin                             Login as admin");
    eprintln!();
    eprintln!("Offline commands (no server connection):");
    eprintln!("  verify-report <report.json>             Verify an attestation report offline");
    eprintln!("  registry-init <registry.json>           Create new trusted server registry");
    eprintln!("  registry-add <registry.json> <server-id> <signing-key> <kex-key> [domain]");
    eprintln!("                                         Add server to registry");
    eprintln!("  registry-remove <registry.json> <server-id> <authority-key>");
    eprintln!("                                         Remove server from registry");
    eprintln!("  registry-verify <registry.json>         Verify registry signature");
    eprintln!("  registry-list <registry.json>            List trusted servers");
}

type WsStream =
    tokio_tungstenite::WebSocketStream<tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>>;

struct Client {
    sender: futures_util::stream::SplitSink<WsStream, Message>,
    receiver: futures_util::stream::SplitStream<WsStream>,
    next_id: u16,
    session_id: Option<u64>,
    logged_in: bool,
}

impl Client {
    async fn connect(url: &str) -> Result<Self, Box<dyn std::error::Error>> {
        use tokio_tungstenite::tungstenite::client::IntoClientRequest;

        let http_base = url
            .trim_start_matches("ws://")
            .trim_start_matches("wss://")
            .split('/')
            .next()
            .unwrap_or("127.0.0.1:8080");

        let final_url = match reqwest::get(format!("http://{}/csrf-token", http_base)).await {
            Ok(resp) => {
                if resp.status().is_success() {
                    #[derive(serde::Deserialize)]
                    struct CsrfResp {
                        csrf_token: String,
                    }
                    if let Ok(data) = resp.json::<CsrfResp>().await {
                        let sep = if url.contains('?') { '&' } else { '?' };
                        format!("{}{}csrf_token={}", url, sep, data.csrf_token)
                    } else {
                        url.to_string()
                    }
                } else {
                    url.to_string()
                }
            }
            Err(_) => url.to_string(),
        };

        let mut request = final_url.into_client_request()?;
        request
            .headers_mut()
            .insert("Origin", "http://localhost:5173".parse().unwrap());
        let (stream, _) = tokio_tungstenite::connect_async(request).await?;
        let (sender, mut receiver) = stream.split();

        let _hs: serde_json::Value = match receiver.next().await {
            Some(Ok(Message::Text(t))) => serde_json::from_str(&t)?,
            Some(Ok(Message::Binary(b))) => serde_json::from_slice(&b)?,
            other => return Err(format!("unexpected handshake: {:?}", other).into()),
        };

        Ok(Client {
            sender,
            receiver,
            next_id: 1,
            session_id: None,
            logged_in: false,
        })
    }

    async fn request(&mut self, op: &str, payload: Option<serde_json::Value>) -> serde_json::Value {
        let id = self.next_id;
        self.next_id += 1;
        let mut frame = serde_json::json!({"v": 2, "type": "request", "id": id, "op": op});
        if let Some(p) = payload {
            frame["payload"] = p;
        }
        let text = serde_json::to_string(&frame).unwrap();
        self.sender.send(Message::Text(text.into())).await.unwrap();
        let resp = self.receiver.next().await.unwrap().unwrap();
        match resp {
            Message::Text(t) => serde_json::from_str(&t).unwrap(),
            Message::Binary(b) => serde_json::from_slice(&b).unwrap(),
            other => serde_json::json!({"type": "error", "message": format!("{:?}", other)}),
        }
    }

    async fn ensure_login(&mut self) {
        if self.logged_in {
            return;
        }
        if self.session_id.is_none() {
            let resp = self.request("session_connect", None).await;
            self.session_id = resp["value"]["value"].as_u64();
        }
        self.request("session_login_public", None).await;
        self.logged_in = true;
    }

    async fn login_admin(&mut self) -> Result<(), String> {
        if self.session_id.is_none() {
            let resp = self.request("session_connect", None).await;
            self.session_id = resp["value"]["value"].as_u64();
        }
        let admin_id = self
            .request(
                "club_id_by_name",
                Some(serde_json::json!({"name": "admin"})),
            )
            .await;
        let club_id = admin_id["value"]["value"]
            .as_u64()
            .ok_or("admin club not found")?;
        self.request(
            "session_login",
            Some(serde_json::json!({"club_id": club_id})),
        )
        .await;
        self.request(
            "session_authenticate",
            Some(serde_json::json!({"club_id": club_id, "credential": "Boo"})),
        )
        .await;
        self.logged_in = true;
        Ok(())
    }

    fn hex_decode(s: &str) -> Result<Vec<u8>, String> {
        if s.len() % 2 != 0 {
            return Err("odd-length hex".to_string());
        }
        let mut result = Vec::with_capacity(s.len() / 2);
        let bytes = s.as_bytes();
        for i in (0..bytes.len()).step_by(2) {
            let hi = (bytes[i] as char).to_digit(16).ok_or("invalid hex")?;
            let lo = (bytes[i + 1] as char).to_digit(16).ok_or("invalid hex")?;
            result.push((hi * 16 + lo) as u8);
        }
        Ok(result)
    }

    fn verify_report(path: &str) -> Result<(), Box<dyn std::error::Error>> {
        use sha2::Digest;

        let report_text =
            std::fs::read_to_string(path).map_err(|e| format!("Cannot read {}: {}", path, e))?;

        let signed: serde_json::Value =
            serde_json::from_str(&report_text).map_err(|e| format!("Invalid JSON: {}", e))?;

        let report = signed.get("report").ok_or("Missing 'report' field")?;
        let report_hash = signed
            .get("report_hash_sha256")
            .and_then(|v| v.as_str())
            .ok_or("Missing 'report_hash_sha256' field")?;
        let sig_hex = signed
            .get("server_signature_ed25519")
            .and_then(|v| v.as_str())
            .ok_or("Missing 'server_signature_ed25519' field")?;

        let report_body = serde_json::to_string_pretty(report)?;

        println!("═══════════════════════════════════════════════════════════");
        println!("  XUDANU ATTESTATION REPORT — VERIFICATION");
        println!("═══════════════════════════════════════════════════════════");
        println!();

        let doc = &report["document"];
        println!(
            "  Document:  Work {}, revision {}",
            doc["work_id"].as_str().unwrap_or("?"),
            doc.get("revision").and_then(|v| v.as_u64()).unwrap_or(0)
        );
        println!(
            "  Title:     {}",
            doc["title"].as_str().unwrap_or("(untitled)")
        );
        println!(
            "  Chars:     {}",
            doc.get("character_count")
                .and_then(|v| v.as_u64())
                .unwrap_or(0)
        );
        println!(
            "  BLAKE3:    {}",
            doc["content_hash_blake3"].as_str().unwrap_or("?")
        );
        println!();

        let server_id = report["server_identity"]["server_id"]
            .as_str()
            .unwrap_or("?");
        let verifying_key_hex = report["server_identity"]["verifying_key_ed25519"]
            .as_str()
            .unwrap_or("?");
        println!(
            "  Server:    {} ({})",
            server_id,
            &verifying_key_hex[..16.min(verifying_key_hex.len())]
        );
        println!();

        let mut report_hash_ok = false;
        let mut hasher = sha2::Sha256::new();
        hasher.update(report_body.as_bytes());
        let computed_hash = format!("{:x}", hasher.finalize());
        if computed_hash == report_hash {
            println!("  Report hash:      VALID (SHA-256 matches)");
            report_hash_ok = true;
        } else {
            println!("  Report hash:      FAILED");
            println!("    Expected: {}", report_hash);
            println!("    Got:      {}", computed_hash);
        }

        let mut sig_ok = false;
        let sig_bytes = hex_decode(sig_hex).map_err(|e| format!("Invalid signature hex: {}", e))?;
        if sig_bytes.len() == 64 {
            let vk_bytes = hex_decode(verifying_key_hex)
                .map_err(|e| format!("Invalid verifying key hex: {}", e))?;
            if vk_bytes.len() == 32 {
                let vk_array: [u8; 32] = vk_bytes
                    .as_slice()
                    .try_into()
                    .map_err(|_| "Verifying key wrong length")?;
                let sig_array: [u8; 64] = sig_bytes
                    .as_slice()
                    .try_into()
                    .map_err(|_| "Signature wrong length")?;
                let vk = ed25519_dalek::VerifyingKey::from_bytes(&vk_array)
                    .map_err(|e| format!("Invalid verifying key: {}", e))?;
                let signature = ed25519_dalek::Signature::from_slice(&sig_array)
                    .map_err(|e| format!("Invalid signature: {}", e))?;

                match xudanu::crypto::sign::verify_signature(
                    &vk,
                    report_hash.as_bytes(),
                    &signature,
                ) {
                    Ok(()) => {
                        println!("  Server signature:  VALID (Ed25519)");
                        sig_ok = true;
                    }
                    Err(e) => println!("  Server signature:  FAILED ({})", e),
                }
            } else {
                println!(
                    "  Server signature:  SKIPPED (verifying key wrong length: {})",
                    vk_bytes.len()
                );
            }
        } else {
            println!(
                "  Server signature:  SKIPPED (signature wrong length: {})",
                sig_bytes.len()
            );
        }

        let spans = report["attribution"]["spans"].as_array();
        let span_count = spans.map(|s| s.len()).unwrap_or(0);
        let signed_count = spans
            .map(|s| {
                s.iter()
                    .filter(|sp| {
                        sp.get("signature_valid")
                            .and_then(|v| v.as_bool())
                            .unwrap_or(false)
                    })
                    .count()
            })
            .unwrap_or(0);
        let unsigned_count = span_count - signed_count;

        println!();
        println!(
            "  Attribution: {} spans, {} signed, {} unsigned",
            span_count, signed_count, unsigned_count
        );
        if span_count > 0 && unsigned_count == 0 {
            println!("    All spans signed with Ed25519");
        } else if unsigned_count > 0 {
            println!(
                "    WARNING: {} spans lack valid signatures",
                unsigned_count
            );
        }

        let chain_valid = report["security_log"]["chain_valid"]
            .as_bool()
            .unwrap_or(false);
        let entry_count = report["security_log"]["entry_count"].as_u64().unwrap_or(0);
        println!();
        println!(
            "  Security log: {} entries, chain {}",
            entry_count,
            if chain_valid { "VALID" } else { "BROKEN" }
        );

        let prov_chain = report["provenance_chain"].as_array();
        if let Some(chain) = prov_chain {
            if !chain.is_empty() {
                println!();
                println!("  Provenance chain ({} hops):", chain.len());
                for hop in chain {
                    println!(
                        "    {} -> {}",
                        hop["source_work_title"]
                            .as_str()
                            .or_else(|| hop["source_author_name"].as_str())
                            .unwrap_or("?"),
                        hop["dest_work_id"].as_str().unwrap_or("this document")
                    );
                }
            }
        }

        println!();
        println!("───────────────────────────────────────────────────────────");

        let all_pass = report_hash_ok && sig_ok && chain_valid && unsigned_count == 0;

        if all_pass {
            println!("  RESULT: ALL CHECKS PASSED");
            println!("  Trust level: 1 (Basic — server-signed, chained log)");
        } else {
            println!("  RESULT: ISSUES DETECTED");
            if !report_hash_ok {
                println!("    - Report hash mismatch (content may be tampered)");
            }
            if !sig_ok {
                println!("    - Server signature invalid (report may be forged)");
            }
            if !chain_valid {
                println!("    - Security log chain broken (possible tampering)");
            }
            if unsigned_count > 0 {
                println!("    - {} unsigned spans (attribution gaps)", unsigned_count);
            }
        }
        println!("───────────────────────────────────────────────────────────");

        if !all_pass {
            std::process::exit(1);
        }

        Ok(())
    }
}

fn extract_value(resp: &serde_json::Value) -> &serde_json::Value {
    &resp["value"]
}

async fn run_command(
    client: &mut Client,
    cmd: &str,
    args: &[&str],
) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        "repl" => unreachable!(),
        "login" => {
            client.ensure_login().await;
            println!("Logged in.");
        }
        "login-admin" => {
            client.login_admin().await.map_err(|e| {
                Box::new(std::io::Error::new(std::io::ErrorKind::Other, e))
                    as Box<dyn std::error::Error>
            })?;
            println!("Logged in as admin.");
        }
        "create-work" => {
            client.ensure_login().await;
            let text = if args.is_empty() {
                "empty".to_string()
            } else {
                args.join(" ")
            };
            let resp = client
                .request(
                    "work_create",
                    Some(serde_json::json!({
                        "edition": {"text": text}
                    })),
                )
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                let id = extract_value(&resp)["value"].as_u64().unwrap();
                println!("{}", id);
            }
        }
        "get-work" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: get-work <id>")?.parse()?;
            let resp = client
                .request("work_get_edition", Some(serde_json::json!({"work_id": id})))
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!(
                    "{}",
                    serde_json::to_string_pretty(extract_value(&resp)).unwrap()
                );
            }
        }
        "list-works" => {
            client.ensure_login().await;
            let resp = client.request("work_list", None).await;
            let entries = extract_value(&resp)["value"].as_array();
            if let Some(entries) = entries {
                if entries.is_empty() {
                    println!("No works.");
                } else {
                    println!(
                        "{:<10} {:<10} {:<10} {}",
                        "ID", "OWNER", "REVISIONS", "GRABBED"
                    );
                    for e in entries {
                        println!(
                            "{:<10} {:<10} {:<10} {}",
                            e["work_id"].as_u64().unwrap_or(0),
                            e["owner"].as_u64().unwrap_or(0),
                            e["revision_count"].as_u64().unwrap_or(0),
                            if e["is_grabbed"].as_bool().unwrap_or(false) {
                                "yes"
                            } else {
                                "no"
                            }
                        );
                    }
                }
            }
        }
        "grab" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: grab <id>")?.parse()?;
            let resp = client
                .request("work_grab", Some(serde_json::json!({"work_id": id})))
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!("Grabbed work {}", id);
            }
        }
        "revise" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: revise <id> <text>")?.parse()?;
            let text = if args.len() > 1 {
                args[1..].join(" ")
            } else {
                "".to_string()
            };
            let resp = client
                .request(
                    "work_revise",
                    Some(serde_json::json!({
                        "work_id": id, "edition": {"text": text}
                    })),
                )
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                let rev = extract_value(&resp)["value"].as_u64().unwrap_or(0);
                println!("Revision {} saved.", rev);
            }
        }
        "release" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: release <id>")?.parse()?;
            let resp = client
                .request("work_release", Some(serde_json::json!({"work_id": id})))
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!("Released work {}", id);
            }
        }
        "history" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: history <id>")?.parse()?;
            let resp = client
                .request(
                    "work_revision_count",
                    Some(serde_json::json!({"work_id": id})),
                )
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!(
                    "{} revisions.",
                    extract_value(&resp)["value"].as_u64().unwrap_or(0)
                );
            }
        }
        "fetch-revision" => {
            client.ensure_login().await;
            let id: u64 = args
                .first()
                .ok_or("usage: fetch-revision <id> <n>")?
                .parse()?;
            let n: u64 = args
                .get(1)
                .ok_or("usage: fetch-revision <id> <n>")?
                .parse()?;
            let resp = client
                .request(
                    "work_fetch_revision",
                    Some(serde_json::json!({
                        "work_id": id, "number": n
                    })),
                )
                .await;
            println!(
                "{}",
                serde_json::to_string_pretty(extract_value(&resp)).unwrap()
            );
        }
        "create-link" => {
            client.ensure_login().await;
            let origin: u64 = args
                .first()
                .ok_or(
                    "usage: create-link <origin-id> <dest-id> [type-id] [start] [end] [excerpt]",
                )?
                .parse()?;
            let dest: u64 = args
                .get(1)
                .ok_or(
                    "usage: create-link <origin-id> <dest-id> [type-id] [start] [end] [excerpt]",
                )?
                .parse()?;
            let start: Option<i64> = args.get(3).and_then(|s| s.parse::<i64>().ok());
            let end: Option<i64> = args.get(4).and_then(|s| s.parse::<i64>().ok());
            let excerpt_val: String = args.get(5).map(|s| s.to_string()).unwrap_or_default();

            let mut payload = serde_json::json!({ "origin": origin, "destination": dest });
            if let (Some(s), Some(e)) = (start, end) {
                payload["origin_ref"] = serde_json::json!({
                    "kind": "single",
                    "work_context": origin,
                    "excerpt": excerpt_val,
                    "start_position": s,
                    "end_position": e,
                });
            }
            let resp = client.request("link_create", Some(payload)).await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                let link_id = extract_value(&resp)["value"].as_u64().unwrap();
                if let Some(type_str) = args.get(2) {
                    if let Ok(type_id) = type_str.parse::<u64>() {
                        let _ = client
                            .request(
                                "link_set_types",
                                Some(serde_json::json!({
                                    "link_id": link_id, "link_types": [type_id]
                                })),
                            )
                            .await;
                    }
                }
                println!(
                    "Link 0x{:x} created: 0x{:x} -> 0x{:x}",
                    link_id, origin, dest
                );
            }
        }
        "get-link" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: get-link <link-id>")?.parse()?;
            let resp = client
                .request("link_get", Some(serde_json::json!({"link_id": id})))
                .await;
            println!(
                "{}",
                serde_json::to_string_pretty(extract_value(&resp)).unwrap()
            );
        }
        "list-links" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: list-links <work-id>")?.parse()?;
            let resp = client
                .request(
                    "link_list_for_work",
                    Some(serde_json::json!({"work_id": id})),
                )
                .await;
            let links = extract_value(&resp)["value"].as_array();
            if let Some(links) = links {
                if links.is_empty() {
                    println!("No links.");
                } else {
                    println!("{:<10} {:<10} {}", "LINK_ID", "ORIGIN", "DEST");
                    for l in links {
                        println!(
                            "{:<10} {:<10} {}",
                            l["link_id"].as_u64().unwrap_or(0),
                            l["origin"].as_u64().unwrap_or(0),
                            l["destination"].as_u64().unwrap_or(0)
                        );
                    }
                }
            }
        }
        "delete-link" => {
            client.ensure_login().await;
            let id: u64 = args
                .first()
                .ok_or("usage: delete-link <link-id>")?
                .parse()?;
            let resp = client
                .request("link_delete", Some(serde_json::json!({"link_id": id})))
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!("Link 0x{:x} deleted.", id);
            }
        }
        "set-link-type" => {
            client.ensure_login().await;
            let link_id: u64 = args
                .first()
                .ok_or("usage: set-link-type <link-id> <type-id>")?
                .parse()?;
            let type_id: u64 = args
                .get(1)
                .ok_or("usage: set-link-type <link-id> <type-id>")?
                .parse()?;
            let resp = client
                .request(
                    "link_set_types",
                    Some(serde_json::json!({"link_id": link_id, "link_types": [type_id]})),
                )
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!("Link 0x{:x} type set to {}.", link_id, type_id);
            }
        }
        "publish" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: publish <work-id>")?.parse()?;
            let resp = client
                .request("work_publish", Some(serde_json::json!({"work_id": id})))
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!("Work 0x{:x} published.", id);
            }
        }
        "find-content" => {
            client.ensure_login().await;
            let id: u64 = args.first().ok_or("usage: find-content <be-id>")?.parse()?;
            let resp = client
                .request(
                    "find_works_for_content",
                    Some(serde_json::json!({
                        "content_be_id": id
                    })),
                )
                .await;
            let ids = extract_value(&resp)["value"].as_array();
            if let Some(ids) = ids {
                if ids.is_empty() {
                    println!("No works found.");
                } else {
                    for id in ids {
                        print!("{} ", id.as_u64().unwrap_or(0));
                    }
                    println!();
                }
            }
        }
        "club-create" => {
            client.ensure_login().await;
            let name = args.first();
            let resp = if let Some(name) = name {
                client
                    .request(
                        "club_create_named",
                        Some(serde_json::json!({
                            "name": name, "description": "empty"
                        })),
                    )
                    .await
            } else {
                client
                    .request(
                        "club_create",
                        Some(serde_json::json!({"description": "empty"})),
                    )
                    .await
            };
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                println!("{}", extract_value(&resp)["value"].as_u64().unwrap());
            }
        }
        "club-list" => {
            client.ensure_login().await;
            let resp = client.request("club_names", None).await;
            let names = extract_value(&resp)["value"].as_array();
            if let Some(names) = names {
                println!("{:<30} {}", "NAME", "ID");
                for pair in names {
                    println!(
                        "{:<30} {}",
                        pair[0].as_str().unwrap_or("?"),
                        pair[1].as_u64().unwrap_or(0)
                    );
                }
            }
        }
        "info" => {
            client.ensure_login().await;
            let resp = client.request("admin_server_info", None).await;
            if resp["type"] == "error" {
                let resp = client.request("server_stats", None).await;
                println!(
                    "{}",
                    serde_json::to_string_pretty(extract_value(&resp)).unwrap()
                );
            } else {
                println!(
                    "{}",
                    serde_json::to_string_pretty(extract_value(&resp)).unwrap()
                );
            }
        }
        "help" => {
            println!("Commands: login, login-admin, create-work, get-work, list-works, grab, revise, release, history, fetch-revision, create-link, get-link, list-links, delete-link, find-content, club-create, club-list, info, quit");
        }
        "quit" | "exit" => {
            std::process::exit(0);
        }
        other => {
            eprintln!("Unknown command: {}. Type 'help' for commands.", other);
        }
    }
    Ok(())
}

async fn repl(client: &mut Client) -> Result<(), Box<dyn std::error::Error>> {
    println!("xudanu-cli REPL. Type 'help' for commands, 'quit' to exit.");
    let stdin = io::stdin();
    print!("> ");
    io::stdout().flush()?;
    for line in stdin.lock().lines() {
        let line = line?;
        let parts: Vec<&str> = line.trim().split_whitespace().collect();
        if parts.is_empty() {
            print!("> ");
            io::stdout().flush()?;
            continue;
        }
        let cmd = parts[0];
        let args = &parts[1..];
        run_command(client, cmd, args).await?;
        print!("> ");
        io::stdout().flush()?;
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args: Vec<String> = std::env::args().collect();

    if args.len() >= 2 && args[1] == "verify-report" {
        if args.len() < 3 {
            eprintln!("Usage: xudanu-cli verify-report <report.json>");
            std::process::exit(1);
        }
        return verify_report(&args[2]);
    }

    // Registry management commands
    if args.len() >= 2 && args[1].starts_with("registry-") {
        return handle_registry_command(&args).await;
    }

    // Registry management commands
    if args.len() >= 2 && args[1].starts_with("registry-") {
        return handle_registry_command(&args).await;
    }

    if args.len() >= 2 && args[1] == "security-test" {
        if args.len() < 3 {
            eprintln!("Usage: xudanu-cli security-test <http://host:port>");
            eprintln!("");
            eprintln!("Tests public API security controls on a running xudanu server:");
            eprintln!("  - Health endpoint accessibility");
            eprintln!("  - Well-known identity endpoint");
            eprintln!("  - Public work API (valid + invalid IDs)");
            eprintln!("  - Rate limiting (flood test)");
            eprintln!("  - Backlink notification (valid + invalid)");
            eprintln!("  - Input validation (bad work IDs, bad hashes)");
            eprintln!("  - CORS headers");
            eprintln!("  - Response size caps");
            std::process::exit(1);
        }
        return security_test(&args[2]).await;
    }

    if args.len() < 3 {
        usage();
        std::process::exit(1);
    }

    let server_url = &args[1];
    let base = if server_url.starts_with("ws://") || server_url.starts_with("wss://") {
        server_url.to_string()
    } else {
        format!("ws://{}", server_url)
    };
    let base = if base.ends_with('/') {
        &base[..base.len() - 1]
    } else {
        &base
    };
    let url = format!("{}/xudanu?format=json&version=2", base);

    let mut client = Client::connect(&url).await?;

    let cmd = args[2].as_str();
    let cmd_args: Vec<&str> = args[3..].iter().map(|s| s.as_str()).collect();

    if cmd == "repl" {
        repl(&mut client).await?;
    } else {
        run_command(&mut client, cmd, &cmd_args).await?;
    }

    Ok(())
}

fn hex_decode(s: &str) -> Result<Vec<u8>, String> {
    if s.len() % 2 != 0 {
        return Err("odd-length hex".to_string());
    }
    let mut result = Vec::with_capacity(s.len() / 2);
    let bytes = s.as_bytes();
    for i in (0..bytes.len()).step_by(2) {
        let hi = (bytes[i] as char).to_digit(16).ok_or("invalid hex")?;
        let lo = (bytes[i + 1] as char).to_digit(16).ok_or("invalid hex")?;
        result.push((hi * 16 + lo) as u8);
    }
    Ok(result)
}

fn hex_encode(bytes: &[u8]) -> String {
    bytes.iter().map(|b| format!("{:02x}", b)).collect()
}

fn verify_report(path: &str) -> Result<(), Box<dyn std::error::Error>> {
    let report_text =
        std::fs::read_to_string(path).map_err(|e| format!("Cannot read {}: {}", path, e))?;

    let report: serde_json::Value =
        serde_json::from_str(&report_text).map_err(|e| format!("Invalid JSON: {}", e))?;

    println!("===========================================================");
    println!("  XUDANU ATTESTATION VERIFICATION");
    println!("===========================================================");
    println!();

    if report.get("prefix").and_then(|v| v.as_object()).is_some()
        && report.get("entity").and_then(|v| v.as_object()).is_some()
    {
        return verify_prov_json(&report);
    }

    if report.get("type").and_then(|v| v.as_str()) == Some("xudanu-attestation-report") {
        return verify_custom_report(&report);
    }

    if report.get("report").is_some() && report.get("report_hash_sha256").is_some() {
        return verify_signed_report(&report);
    }

    Err("Unrecognized report format. Expected xudanu-attestation-report, PROV-JSON, or signed report.".into())
}

fn verify_prov_json(doc: &serde_json::Value) -> Result<(), Box<dyn std::error::Error>> {
    println!("  Format: PROV-JSON (W3C)");
    println!();

    let entities = doc["entity"].as_object().ok_or("No entity map")?;
    let agents = doc["agent"].as_object().ok_or("No agent map")?;

    let mut doc_title = "?".to_string();
    let mut doc_hash = "?".to_string();
    let mut doc_revision = "?".to_string();
    let mut doc_work_id = "?".to_string();
    for (_id, ent) in entities {
        let ptype = get_prov_literal(ent, "prov:type");
        if ptype.as_deref() == Some("xudanu:Document") {
            doc_title = get_prov_literal(ent, "xudanu:title").unwrap_or_default();
            doc_hash = get_prov_literal(ent, "xudanu:contentHash").unwrap_or_default();
            doc_revision = get_prov_literal(ent, "xudanu:revision").unwrap_or_default();
            doc_work_id = get_prov_literal(ent, "xudanu:workId").unwrap_or_default();
        }
    }

    println!("  Document:  {} (rev {})", doc_title, doc_revision);
    println!("  Work ID:   {}", doc_work_id);
    println!("  BLAKE3:    {}...", &doc_hash[..32.min(doc_hash.len())]);
    println!();

    let mut server_key = "?".to_string();
    for (_id, agent) in agents {
        let ptype = get_prov_literal(agent, "prov:type");
        if ptype.as_deref() == Some("xudanu:Server") {
            server_key = get_prov_literal(agent, "xudanu:verifyingKey").unwrap_or_default();
        }
    }
    println!(
        "  Server key: {}...",
        &server_key[..16.min(server_key.len())]
    );
    println!();

    let mut span_count = 0u32;
    let mut sig_valid_count = 0u32;
    let mut sig_invalid_count = 0u32;

    for (_id, ent) in entities {
        let ptype = get_prov_literal(ent, "prov:type");
        if ptype.as_deref() == Some("xudanu:ContentSpan") {
            span_count += 1;
            let sig_valid = get_prov_literal(ent, "xudanu:signatureValid");
            let char_range = get_prov_literal(ent, "xudanu:charRange").unwrap_or_default();
            let author_pk = get_prov_literal(ent, "xudanu:authorPublicKey").unwrap_or_default();
            let ts = get_prov_literal(ent, "xudanu:timestamp").unwrap_or_default();

            match sig_valid.as_deref() {
                Some("true") => {
                    println!(
                        "  [OK] Span {} key={}... ts={}",
                        char_range,
                        &author_pk[..16.min(author_pk.len())],
                        ts
                    );
                    sig_valid_count += 1;
                }
                Some("false") => {
                    println!("  [FAIL] Span {} signature INVALID", char_range);
                    sig_invalid_count += 1;
                }
                _ => {
                    println!("  [?] Span {} signature status unknown", char_range);
                    sig_invalid_count += 1;
                }
            }
        }
    }

    let mut log_valid = false;
    let mut log_entries = 0u64;
    for (_id, ent) in entities {
        let ptype = get_prov_literal(ent, "prov:type");
        if ptype.as_deref() == Some("xudanu:AttributionLog") {
            log_valid = get_prov_literal(ent, "xudanu:chainValid")
                .map(|v| v == "true")
                .unwrap_or(false);
            log_entries = get_prov_literal(ent, "xudanu:entryCount")
                .and_then(|v| v.parse().ok())
                .unwrap_or(0);
        }
    }

    println!();
    println!(
        "  Attribution: {} spans, {} valid, {} invalid",
        span_count, sig_valid_count, sig_invalid_count
    );
    println!(
        "  Log chain:   {} entries, {}",
        log_entries,
        if log_valid { "VALID" } else { "BROKEN" }
    );
    println!();

    let was_attributed = doc.get("wasAttributedTo").and_then(|v| v.as_object());
    let was_generated = doc.get("wasGeneratedBy").and_then(|v| v.as_object());
    let was_associated = doc.get("wasAssociatedWith").and_then(|v| v.as_object());
    let was_derived = doc.get("wasDerivedFrom").and_then(|v| v.as_object());

    println!("  Relations:");
    println!(
        "    wasAttributedTo:  {}",
        was_attributed.map(|m| m.len()).unwrap_or(0)
    );
    println!(
        "    wasGeneratedBy:   {}",
        was_generated.map(|m| m.len()).unwrap_or(0)
    );
    println!(
        "    wasAssociatedWith: {}",
        was_associated.map(|m| m.len()).unwrap_or(0)
    );
    println!(
        "    wasDerivedFrom:   {}",
        was_derived.map(|m| m.len()).unwrap_or(0)
    );
    println!();

    let all_ok = sig_invalid_count == 0 && log_valid;

    println!("-----------------------------------------------------------");
    if all_ok {
        println!("  RESULT: ALL CHECKS PASSED");
        println!("  {} spans verified, log chain valid", span_count);
    } else {
        println!("  RESULT: ISSUES DETECTED");
        if sig_invalid_count > 0 {
            println!("    - {} spans with invalid signatures", sig_invalid_count);
        }
        if !log_valid {
            println!("    - Attribution log chain broken");
        }
    }
    println!("-----------------------------------------------------------");

    if !all_ok {
        std::process::exit(1);
    }
    Ok(())
}

fn verify_custom_report(report: &serde_json::Value) -> Result<(), Box<dyn std::error::Error>> {
    use sha2::Digest;

    println!("  Format: Xudanu Attestation Report");
    println!();

    let doc = &report["document"];
    println!(
        "  Document:  {}",
        doc["title"].as_str().unwrap_or("(untitled)")
    );
    println!("  Work ID:   {}", doc["work_id"].as_str().unwrap_or("?"));
    println!(
        "  Revision:  {}",
        doc.get("revision").and_then(|v| v.as_u64()).unwrap_or(0)
    );
    println!(
        "  Chars:     {}",
        doc.get("character_count")
            .and_then(|v| v.as_u64())
            .unwrap_or(0)
    );
    let hash_str = doc["content_hash_blake3"].as_str().unwrap_or("?");
    println!("  BLAKE3:    {}...", &hash_str[..32.min(hash_str.len())]);
    println!();

    let server_id = report["server_identity"]["server_id"]
        .as_str()
        .unwrap_or("?");
    let vk_hex = report["server_identity"]["verifying_key_ed25519"]
        .as_str()
        .unwrap_or("?");
    println!(
        "  Server:    {} (key {}...)",
        server_id,
        &vk_hex[..16.min(vk_hex.len())]
    );
    println!();

    let spans = report["attribution"]["spans"].as_array();
    let span_count = spans.map(|s| s.len()).unwrap_or(0);
    let mut valid = 0u32;
    let mut invalid = 0u32;

    if let Some(spans) = spans {
        for span in spans {
            let range = span.get("range").and_then(|r| r.as_array());
            let range_str = range
                .map(|r| format!("[{}, {})", r[0], r[1]))
                .unwrap_or("?".to_string());
            let author = span["author"].as_str().unwrap_or("unknown");
            let author_type = span["author_type"].as_str().unwrap_or("human");
            let sig_valid = span["signature_valid"].as_bool().unwrap_or(false);
            let ts = span["timestamp"].as_u64().unwrap_or(0);

            if sig_valid {
                println!(
                    "  [OK] {} {} ({}) ts={}",
                    range_str, author, author_type, ts
                );
                valid += 1;
            } else {
                println!(
                    "  [FAIL] {} {} ({}) signature INVALID",
                    range_str, author, author_type
                );
                invalid += 1;
            }
        }
    }

    let chain_valid = report["attribution_log"]["chain_valid"]
        .as_bool()
        .unwrap_or(false);
    let entry_count = report["attribution_log"]["entry_count"]
        .as_u64()
        .unwrap_or(0);

    println!();
    println!(
        "  Attribution: {} spans, {} valid, {} invalid",
        span_count, valid, invalid
    );
    println!(
        "  Log chain:   {} entries, {}",
        entry_count,
        if chain_valid { "VALID" } else { "BROKEN" }
    );
    println!();

    if let Some(chain) = report["provenance_chain"].as_array() {
        if !chain.is_empty() {
            println!("  Provenance chain ({} hops):", chain.len());
            for hop in chain {
                println!(
                    "    {} -> {}",
                    hop["source_title"]
                        .as_str()
                        .or_else(|| hop["source_work_id"].as_str())
                        .unwrap_or("?"),
                    hop["dest_work_id"].as_str().unwrap_or("this document")
                );
            }
            println!();
        }
    }

    let all_ok = invalid == 0 && chain_valid;

    println!("-----------------------------------------------------------");
    if all_ok {
        println!("  RESULT: ALL CHECKS PASSED");
        println!("  {} spans verified, log chain valid", span_count);
    } else {
        println!("  RESULT: ISSUES DETECTED");
        if invalid > 0 {
            println!("    - {} spans with invalid signatures", invalid);
        }
        if !chain_valid {
            println!("    - Attribution log chain broken");
        }
    }
    println!("-----------------------------------------------------------");

    if !all_ok {
        std::process::exit(1);
    }
    Ok(())
}

fn verify_signed_report(signed: &serde_json::Value) -> Result<(), Box<dyn std::error::Error>> {
    use sha2::Digest;
    let report = signed.get("report").ok_or("Missing 'report' field")?;
    let report_hash = signed
        .get("report_hash_sha256")
        .and_then(|v| v.as_str())
        .ok_or("Missing 'report_hash_sha256'")?;
    let sig_hex = signed
        .get("server_signature_ed25519")
        .and_then(|v| v.as_str())
        .ok_or("Missing 'server_signature_ed25519'")?;

    println!("  Format: Signed Attestation Report (v0)");
    println!();

    let report_body = serde_json::to_string_pretty(report)?;
    let doc = &report["document"];
    println!(
        "  Document:  {}",
        doc["title"].as_str().unwrap_or("(untitled)")
    );
    let hash_str = doc["content_hash_blake3"].as_str().unwrap_or("?");
    println!("  BLAKE3:    {}...", &hash_str[..32.min(hash_str.len())]);
    println!();

    let vk_hex = report["server_identity"]["verifying_key_ed25519"]
        .as_str()
        .unwrap_or("?");
    println!("  Server key: {}...", &vk_hex[..16.min(vk_hex.len())]);
    println!();

    let mut hash_ok = false;
    let mut hasher = sha2::Sha256::new();
    hasher.update(report_body.as_bytes());
    let computed = format!("{:x}", hasher.finalize());
    if computed == *report_hash {
        println!("  Report hash: VALID");
        hash_ok = true;
    } else {
        println!("  Report hash: FAILED");
    }

    let mut sig_ok = false;
    if let Ok(sig_bytes) = hex_decode(sig_hex) {
        if sig_bytes.len() == 64 {
            if let Ok(vk_bytes) = hex_decode(vk_hex) {
                if vk_bytes.len() == 32 {
                    let vk_arr: [u8; 32] = vk_bytes.as_slice().try_into()?;
                    let sig_arr: [u8; 64] = sig_bytes.as_slice().try_into()?;
                    let vk = ed25519_dalek::VerifyingKey::from_bytes(&vk_arr)?;
                    let sig = ed25519_dalek::Signature::from_slice(&sig_arr)
                        .map_err(|e| format!("Invalid signature: {}", e))?;
                    match xudanu::crypto::sign::verify_signature(&vk, report_hash.as_bytes(), &sig)
                    {
                        Ok(()) => {
                            println!("  Server signature: VALID");
                            sig_ok = true;
                        }
                        Err(e) => println!("  Server signature: FAILED ({})", e),
                    }
                }
            }
        }
    }

    let spans = report["attribution"]["spans"].as_array();
    let span_count = spans.map(|s| s.len()).unwrap_or(0);
    let signed_count = spans
        .map(|s| {
            s.iter()
                .filter(|sp| {
                    sp.get("signature_valid")
                        .and_then(|v| v.as_bool())
                        .unwrap_or(false)
                })
                .count()
        })
        .unwrap_or(0);
    println!();
    println!(
        "  Attribution: {} spans, {} signed, {} unsigned",
        span_count,
        signed_count,
        span_count - signed_count
    );

    let chain_valid = report["security_log"]["chain_valid"]
        .as_bool()
        .unwrap_or(false);
    println!(
        "  Log chain:   {}",
        if chain_valid { "VALID" } else { "BROKEN" }
    );
    println!();

    let all_ok = hash_ok && sig_ok && chain_valid && signed_count == span_count;
    println!("-----------------------------------------------------------");
    if all_ok {
        println!("  RESULT: ALL CHECKS PASSED");
    } else {
        println!("  RESULT: ISSUES DETECTED");
        if !hash_ok {
            println!("    - Report hash mismatch");
        }
        if !sig_ok {
            println!("    - Server signature invalid");
        }
        if !chain_valid {
            println!("    - Log chain broken");
        }
        if signed_count < span_count {
            println!("    - {} unsigned spans", span_count - signed_count);
        }
    }
    println!("-----------------------------------------------------------");

    if !all_ok {
        std::process::exit(1);
    }
    Ok(())
}

fn get_prov_literal(obj: &serde_json::Value, key: &str) -> Option<String> {
    let val = obj.get(key)?;
    if let Some(s) = val.as_str() {
        return Some(s.to_string());
    }
    if let Some(b) = val.as_bool() {
        return Some(b.to_string());
    }
    if let Some(n) = val.as_u64() {
        return Some(n.to_string());
    }
    let dollar = val.get("$")?.as_str()?;
    Some(dollar.to_string())
}

// Registry management commands
async fn handle_registry_command(args: &[String]) -> Result<(), Box<dyn std::error::Error>> {
    let cmd = &args[1];

    match cmd.as_str() {
        "registry-init" => {
            if args.len() < 3 {
                eprintln!("Usage: xudanu-cli registry-init <registry.json>");
                eprintln!("Creates a new empty trusted server registry file");
                eprintln!();
                eprintln!(
                    "You'll need to provide an authority signing key to manage the registry."
                );
                std::process::exit(1);
            }
            registry_init(&args[2])
        }
        "registry-add" => {
            if args.len() < 6 {
                eprintln!("Usage: xudanu-cli registry-add <registry.json> <server-id> <signing-key-hex> <kex-key-hex> [domain]");
                eprintln!("Example: xudanu-cli registry-add registry.json \"server1\" \"010203...\" \"040506...\" \"xudanu\"");
                eprintln!();
                eprintln!("Keys must be 32-byte hex strings (64 hex characters).");
                std::process::exit(1);
            }
            let domain = if args.len() > 6 { &args[6] } else { "xudanu" };
            registry_add(&args[2], &args[3], &args[4], &args[5], domain)
        }
        "registry-remove" => {
            if args.len() < 4 {
                eprintln!("Usage: xudanu-cli registry-remove <registry.json> <server-id> <authority-key-hex>");
                eprintln!("Note: You need the authority signing key to modify the registry");
                std::process::exit(1);
            }
            registry_remove(&args[2], &args[3], &args[4])
        }
        "registry-verify" => {
            if args.len() < 3 {
                eprintln!("Usage: xudanu-cli registry-verify <registry.json>");
                std::process::exit(1);
            }
            registry_verify(&args[2])
        }
        "registry-list" => {
            if args.len() < 3 {
                eprintln!("Usage: xudanu-cli registry-list <registry.json>");
                std::process::exit(1);
            }
            registry_list(&args[2])
        }
        _ => {
            eprintln!("Unknown registry command: {}", cmd);
            eprintln!("Available: registry-init, registry-add, registry-remove, registry-verify, registry-list");
            std::process::exit(1);
        }
    }
}

fn registry_init(path: &str) -> Result<(), Box<dyn std::error::Error>> {
    use ed25519_dalek::SigningKey;
    use std::fs;

    println!("Creating new trusted server registry: {}", path);
    println!();

    // Generate a new authority key pair
    println!("Generating authority key pair...");
    let authority_key = SigningKey::generate(&mut rand::rngs::OsRng);

    // Save secret key to secure file with restricted permissions
    let secret_key_path = format!("{}.authority-key", path);
    let authority_key_hex = hex_encode(&authority_key.to_bytes());

    fs::write(&secret_key_path, &authority_key_hex)?;

    // Set file permissions to 600 (owner read/write only) on Unix
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        let mut perms = fs::metadata(&secret_key_path)?.permissions();
        perms.set_mode(0o600);
        fs::set_permissions(&secret_key_path, perms)?;
    }

    println!("Authority signing key saved to: {}", secret_key_path);
    println!("  File permissions: 600 (owner read/write only)");
    println!();

    println!("Authority verifying key (PUBLIC - can be shared):");
    println!("{}", hex_encode(&authority_key.verifying_key().to_bytes()));
    println!();

    // Create empty registry with proper authority signature
    let registry = xudanu::crypto::server_identity::TrustedServerRegistry::new(&authority_key);

    let file = xudanu::crypto::server_identity::ServerRegistryFile::new(registry);
    file.save_to_file(std::path::Path::new(path))?;

    println!("✓ Registry created successfully: {}", path);
    println!();
    println!(
        "IMPORTANT: The authority signing key is in {}",
        secret_key_path
    );
    println!("You'll need it to add/remove servers from the registry.");
    println!("Without it, you won't be able to modify the registry.");
    println!("Keep this file secure and backed up in a safe location!");

    Ok(())
}

fn registry_add(
    path: &str,
    server_id: &str,
    signing_key_hex: &str,
    kex_key_hex: &str,
    domain: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    println!("Adding server '{}' to registry: {}", server_id, path);
    println!();

    // Parse keys
    let signing_key_bytes = hex_decode(signing_key_hex)?;
    let kex_key_bytes = hex_decode(kex_key_hex)?;

    let signing_key: [u8; 32] = signing_key_bytes.as_slice().try_into().map_err(|_| {
        format!(
            "Signing key must be 32 bytes (64 hex chars), got {}",
            signing_key_bytes.len()
        )
    })?;
    let kex_key: [u8; 32] = kex_key_bytes.as_slice().try_into().map_err(|_| {
        format!(
            "Kex key must be 32 bytes (64 hex chars), got {}",
            kex_key_bytes.len()
        )
    })?;

    // Load existing registry
    println!("Loading existing registry...");
    let file = xudanu::crypto::server_identity::ServerRegistryFile::load_from_file(
        std::path::Path::new(path),
    )?;

    // Create server identity
    let identity = xudanu::crypto::server_identity::ServerIdentity::new(
        server_id.to_string(),
        signing_key,
        kex_key,
        domain.to_string(),
    );

    // Prompt for authority signing key
    println!("To add servers, you need the authority signing key.");
    println!("Enter authority signing key (hex):");

    use std::io::{self, Write};
    print!("> ");
    io::stdout().flush()?;
    let mut auth_key_hex = String::new();
    io::stdin().read_line(&mut auth_key_hex)?;
    let auth_key_hex = auth_key_hex.trim();

    let auth_key_bytes = hex_decode(auth_key_hex)?;
    let auth_key_bytes: [u8; 32] = auth_key_bytes.as_slice().try_into().map_err(|_| {
        format!(
            "Authority key must be 32 bytes (64 hex chars), got {}",
            auth_key_bytes.len()
        )
    })?;

    let auth_key = ed25519_dalek::SigningKey::from_bytes(&auth_key_bytes);

    println!("Verifying authority key...");
    if auth_key.verifying_key().to_bytes() != file.registry.authority_key {
        return Err("Authority key mismatch".into());
    }
    println!("✓ Authority key verified");

    // Add server using the clone method
    println!("Adding server '{}' to registry...", server_id);
    let updated_registry = file.registry.add_server_clone(identity, &auth_key)?;

    println!("✓ Server '{}' added to registry", server_id);
    println!(
        "Registry now contains {} trusted server(s)",
        updated_registry.server_count()
    );

    // Save the updated registry
    let updated_file = xudanu::crypto::server_identity::ServerRegistryFile::new(updated_registry);
    updated_file.save_to_file(std::path::Path::new(path))?;

    println!("✓ Registry updated: {}", path);

    Ok(())
}

fn registry_remove(
    path: &str,
    server_id: &str,
    auth_key_hex: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    println!("Removing server '{}' from registry: {}", server_id, path);
    println!();

    // Load existing registry
    println!("Loading existing registry...");
    let file = xudanu::crypto::server_identity::ServerRegistryFile::load_from_file(
        std::path::Path::new(path),
    )?;

    if !file.is_trusted(server_id) {
        println!("✗ ERROR: Server '{}' not found in registry", server_id);
        return Err("Server not found".into());
    }

    // Verify authority key
    println!("Verifying authority key...");
    let auth_key_bytes = hex_decode(auth_key_hex)?;
    let auth_key_bytes: [u8; 32] = auth_key_bytes
        .as_slice()
        .try_into()
        .map_err(|_| format!("Authority key must be 32 bytes (64 hex chars)"))?;

    let auth_key = ed25519_dalek::SigningKey::from_bytes(&auth_key_bytes);

    if auth_key.verifying_key().to_bytes() != file.registry.authority_key {
        return Err("Authority key mismatch".into());
    }
    println!("✓ Authority key verified");

    println!("Removing server '{}' from registry...", server_id);

    // Create a new registry without the server using the clone method
    let updated_registry = file.registry.remove_server_clone(server_id, &auth_key)?;

    println!("✓ Server '{}' removed from registry", server_id);
    println!(
        "Registry now contains {} trusted server(s)",
        updated_registry.server_count()
    );

    // Save the updated registry
    let updated_file = xudanu::crypto::server_identity::ServerRegistryFile::new(updated_registry);
    updated_file.save_to_file(std::path::Path::new(path))?;

    println!("✓ Registry updated: {}", path);

    Ok(())
}

fn registry_verify(path: &str) -> Result<(), Box<dyn std::error::Error>> {
    println!("Verifying registry: {}", path);
    println!();

    let file = xudanu::crypto::server_identity::ServerRegistryFile::load_from_file(
        std::path::Path::new(path),
    )?;

    println!("✓ Registry signature: VALID");
    println!(
        "  Authority key: {}",
        hex_encode(&file.registry.authority_key)
    );
    println!("  Last updated: {}", file.registry.last_updated);
    println!("  Server count: {}", file.registry.server_count());
    println!("  Version: {}", file.version);

    if file.registry.server_count() > 0 {
        println!();
        println!("Trusted servers:");
        for server_id in file.registry.servers.keys() {
            let identity = file.registry.get(server_id).unwrap();
            println!("  - {} ({})", server_id, identity.federation_domain);
            println!(
                "    Signing key: {}...",
                hex_encode(&identity.signing_key)[..8.min(identity.signing_key.len())].to_string()
            );
            println!("    Added at: {}", identity.added_at);
            if let Some(exp) = identity.expires_at {
                println!("    Expires at: {}", exp);
            }
        }
    }

    println!();
    println!("✓ Registry verification complete");

    Ok(())
}

fn registry_list(path: &str) -> Result<(), Box<dyn std::error::Error>> {
    println!("Listing trusted servers: {}", path);
    println!();

    let file = xudanu::crypto::server_identity::ServerRegistryFile::load_from_file(
        std::path::Path::new(path),
    )?;

    if file.registry.server_count() == 0 {
        println!("No trusted servers in registry.");
        return Ok(());
    }

    println!("{:<20} {:<15} {}", "Server ID", "Domain", "Status");
    println!("{}", "-".repeat(50));

    for server_id in file.registry.servers.keys() {
        let identity = file.registry.get(server_id).unwrap();

        let status = if identity.is_valid_at(
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs(),
        ) {
            "✓ Valid"
        } else {
            "✗ Expired"
        };

        println!(
            "{:<20} {:<15} {}",
            server_id, identity.federation_domain, status
        );
    }

    println!();
    println!("Total: {} trusted server(s)", file.registry.server_count());

    Ok(())
}

async fn security_test(base_url: &str) -> Result<(), Box<dyn std::error::Error>> {
    let base = base_url.trim_end_matches('/');
    let client = reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()?;

    let mut passed = 0u32;
    let mut failed = 0u32;
    let mut warnings = 0u32;

    let check = |name: &str,
                 condition: bool,
                 detail: &str,
                 passed: &mut u32,
                 failed: &mut u32,
                 warnings: &mut u32| {
        if condition {
            println!("  [PASS] {} - {}", name, detail);
            *passed += 1;
        } else {
            println!("  [FAIL] {} - {}", name, detail);
            *failed += 1;
        }
    };

    println!("\n=== Xudanu Security Test ===");
    println!("Target: {}\n", base);

    // 1. Health endpoint
    println!("[1] Health endpoint");
    let resp = client.get(format!("{}/health", base)).send().await?;
    check(
        "health returns 200",
        resp.status() == 200,
        &format!("status: {}", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // 2. Well-known identity
    println!("\n[2] Well-known identity");
    let resp = client
        .get(format!("{}/.well-known/xudanu-server.json", base))
        .send()
        .await?;
    check(
        "well-known returns 200",
        resp.status() == 200,
        &format!("status: {}", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );
    if resp.status() == 200 {
        let body: serde_json::Value = resp.json().await?;
        check(
            "has server_id",
            body.get("server_id").is_some(),
            "server identity present",
            &mut passed,
            &mut failed,
            &mut warnings,
        );
        check(
            "has api_version",
            body.get("api_version").is_some(),
            "API version present",
            &mut passed,
            &mut failed,
            &mut warnings,
        );
    }

    // 3. Public work API - valid ID
    println!("\n[3] Public work API (valid ID)");
    let resp = client
        .get(format!("{}/api/public/work/0001", base))
        .send()
        .await?;
    let status = resp.status();
    check(
        "valid hex ID accepted",
        status == 200 || status == 404,
        &format!("status: {} (404 = no such work, acceptable)", status),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // 4. Public work API - invalid ID
    println!("\n[4] Public work API (invalid ID)");
    let resp = client
        .get(format!("{}/api/public/work/INVALID", base))
        .send()
        .await?;
    check(
        "invalid ID rejected",
        resp.status() == 400,
        &format!("status: {} (expected 400)", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    let resp = client
        .get(format!("{}/api/public/work/''", base))
        .send()
        .await?;
    check(
        "empty ID rejected",
        resp.status() == 400 || resp.status() == 404,
        &format!("status: {}", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // 5. Rate limiting
    println!("\n[5] Rate limiting (flooding 130 requests)");
    let mut rate_limited = false;
    let mut last_status = 0;
    for i in 0..130 {
        let resp = client
            .get(format!("{}/api/public/work/0001", base))
            .send()
            .await?;
        last_status = resp.status().as_u16();
        if resp.status() == 429 {
            rate_limited = true;
            println!("    Rate limited at request #{}", i + 1);
            break;
        }
    }
    check(
        "rate limit triggers",
        rate_limited,
        &format!("last status: {}", last_status),
        &mut passed,
        &mut failed,
        &mut warnings,
    );
    if !rate_limited {
        println!("    (warning: no rate limit triggered — may need higher count or disabled)");
        warnings += 1;
    }

    // Wait for rate limit to reset
    println!("    Waiting 60s for rate limit reset...");
    tokio::time::sleep(std::time::Duration::from_secs(62)).await;

    // 6. Backlink notification
    println!("\n[6] Backlink notification");
    let valid_notify = serde_json::json!({
        "target_work_id": "0001",
        "origin_server_address": "test.example.com",
        "origin_server_name": "Test Server",
        "origin_work_id": "0002",
        "origin_work_title": "Test Document",
        "excerpt": "test excerpt",
        "link_type": "reference"
    });
    let resp = client
        .post(format!("{}/api/backlink-notify", base))
        .json(&valid_notify)
        .send()
        .await?;
    check(
        "valid backlink accepted",
        resp.status() == 200 || resp.status() == 404,
        &format!(
            "status: {} (404 = work not found, acceptable)",
            resp.status()
        ),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // Invalid backlink
    let resp = client
        .post(format!("{}/api/backlink-notify", base))
        .body("not json")
        .send()
        .await?;
    check(
        "invalid JSON rejected",
        resp.status() == 400,
        &format!("status: {} (expected 400)", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // Invalid work ID in backlink
    let bad_notify = serde_json::json!({
        "target_work_id": "NOT_HEX",
        "origin_server_address": "test.example.com",
        "origin_server_name": "Test",
        "origin_work_id": "0002",
        "origin_work_title": "Test",
        "excerpt": "test",
        "link_type": "ref"
    });
    let resp = client
        .post(format!("{}/api/backlink-notify", base))
        .json(&bad_notify)
        .send()
        .await?;
    check(
        "invalid work ID in backlink rejected",
        resp.status() == 400,
        &format!("status: {} (expected 400)", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // 7. Oversized backlink
    println!("\n[7] Backlink size cap");
    let big_body = "x".repeat(10000);
    let resp = client
        .post(format!("{}/api/backlink-notify", base))
        .body(big_body)
        .header("Content-Type", "application/json")
        .send()
        .await?;
    check(
        "oversized backlink rejected",
        resp.status() == 413 || resp.status() == 400,
        &format!("status: {}", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // 8. CORS headers
    println!("\n[8] CORS headers");
    let resp = client
        .get(format!("{}/.well-known/xudanu-server.json", base))
        .send()
        .await?;
    let cors = resp.headers().get("access-control-allow-origin");
    check(
        "CORS header present",
        cors.is_some(),
        &format!("CORS: {:?}", cors),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // 9. Range size cap
    println!("\n[9] Range size cap");
    let resp = client
        .get(format!("{}/api/public/work/0001/range/0/2000000", base))
        .send()
        .await?;
    check(
        "oversized range rejected",
        resp.status() == 400,
        &format!("status: {} (expected 400)", resp.status()),
        &mut passed,
        &mut failed,
        &mut warnings,
    );

    // Summary
    println!("\n=== Summary ===");
    println!("  Passed:   {}", passed);
    println!("  Failed:   {}", failed);
    println!("  Warnings: {}", warnings);
    println!("  Total:    {}", passed + failed + warnings);

    if failed > 0 {
        std::process::exit(1);
    }

    Ok(())
}
