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
    eprintln!("  get-work <id>                           Get work edition");
    eprintln!("  list-works                              List all works");
    eprintln!("  grab <id>                               Grab a work for editing");
    eprintln!("  revise <id> <text>                      Revise a grabbed work");
    eprintln!("  release <id>                            Release a grabbed work");
    eprintln!("  history <id>                            Show revision count");
    eprintln!("  fetch-revision <id> <n>                 Fetch specific revision");
    eprintln!("  create-link <origin-id> <dest-id>       Create a link between works");
    eprintln!("  get-link <link-id>                      Get link details");
    eprintln!("  list-links <work-id>                    List links involving a work");
    eprintln!("  delete-link <link-id>                   Delete a link");
    eprintln!("  find-content <be-id>                    Find works containing content");
    eprintln!("  club-create [name]                      Create a club (optionally named)");
    eprintln!("  club-list                               List all clubs");
    eprintln!("  info                                    Server info");
    eprintln!("  login                                   Login as public");
    eprintln!("  login-admin                             Login as admin");
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
        let (stream, _) = tokio_tungstenite::connect_async(url).await?;
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
                .ok_or("usage: create-link <origin-id> <dest-id>")?
                .parse()?;
            let dest: u64 = args
                .get(1)
                .ok_or("usage: create-link <origin-id> <dest-id>")?
                .parse()?;
            let resp = client
                .request(
                    "link_create",
                    Some(serde_json::json!({
                        "origin": origin, "destination": dest
                    })),
                )
                .await;
            if resp["type"] == "error" {
                eprintln!("Error: {}", resp["message"].as_str().unwrap_or("unknown"));
            } else {
                let link_id = extract_value(&resp)["value"].as_u64().unwrap();
                println!("Link {} created: {} -> {}", link_id, origin, dest);
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
                println!("Link {} deleted.", id);
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
