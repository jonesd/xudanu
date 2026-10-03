//! FR-141: docuverse MCP server (stdio). Phase 1 read-only tools;
//! Phase 2 mutation tools behind --enable-agent-writes; live-server
//! mode via --server ws://host:port (server owns durability).
//!
//! Usage:
//!   xudanu-mcp <data-dir> [--enable-agent-writes] [--llm-model <id>]
//!   xudanu-mcp --server ws://127.0.0.1:8080 [--enable-agent-writes] [--llm-model <id>]
//!
//! Speaks newline-delimited JSON-RPC (MCP stdio transport) on stdin/
//! stdout; diagnostics go to stderr. Data-dir mode opens the store
//! directly — use a copy or a dedicated agent dir unless the server is
//! stopped; --server mode talks to a RUNNING xudanu server. With
//! writes enabled, agent revisions are stamped AuthorType::Llm with
//! the given model identity (default "mcp-agent").

use std::io::{self, BufRead, Write};

use xudanu::server::mcp::{handle_message, AgentSession, Docuverse};
use xudanu::server::server::Server;

fn main() {
    let mut data_dir: Option<String> = None;
    let mut server_url: Option<String> = None;
    let mut enable_writes = false;
    let mut llm_model = "mcp-agent".to_string();
    let mut args = std::env::args().skip(1);
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "--enable-agent-writes" => enable_writes = true,
            "--llm-model" => match args.next() {
                Some(model) => llm_model = model,
                None => {
                    eprintln!("--llm-model requires a value");
                    std::process::exit(2);
                }
            },
            "--server" => match args.next() {
                Some(url) => server_url = Some(url),
                None => {
                    eprintln!("--server requires a ws:// URL");
                    std::process::exit(2);
                }
            },
            other if data_dir.is_none() && other.starts_with('-') => {
                eprintln!("unknown argument: {}", other);
                std::process::exit(2);
            }
            other if data_dir.is_none() => data_dir = Some(other.to_string()),
            other => {
                eprintln!("unknown argument: {}", other);
                std::process::exit(2);
            }
        }
    }

    let mut target = match (&server_url, &data_dir) {
        (Some(url), _) => {
            let mut ws = match xudanu::server::mcp_ws::WsDocuverse::connect(url) {
                Ok(ws) => ws,
                Err(e) => {
                    eprintln!("connect to {} failed: {}", url, e);
                    std::process::exit(1);
                }
            };
            if let Err(e) = ws.login_public() {
                eprintln!("{}", e);
                std::process::exit(1);
            }
            if enable_writes {
                if let Err(e) = ws.set_author_type(&llm_model) {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            }
            eprintln!(
                "xudanu-mcp: live server {} ({} tools)",
                url,
                if enable_writes {
                    "read+write"
                } else {
                    "read-only"
                }
            );
            Docuverse::Remote {
                ws,
                writes_enabled: enable_writes,
            }
        }
        (None, Some(dir)) => {
            let mut server = Server::new();
            if let Err(e) = server.restore_from_data_dir(std::path::Path::new(dir), None) {
                eprintln!("restore from {} failed: {}", dir, e);
                std::process::exit(1);
            }
            let mut agent = match AgentSession::new(server) {
                Ok(agent) => agent,
                Err(e) => {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            };
            if enable_writes {
                if let Err(e) = agent.enable_writes(&llm_model) {
                    eprintln!("{}", e);
                    std::process::exit(1);
                }
            }
            eprintln!(
                "xudanu-mcp: docuverse ready ({} tools), data dir {}",
                if enable_writes {
                    "read+write"
                } else {
                    "read-only"
                },
                dir
            );
            Docuverse::Local(agent)
        }
        (None, None) => {
            eprintln!(
                "usage: xudanu-mcp <data-dir> [--enable-agent-writes] [--llm-model <id>]\n       xudanu-mcp --server ws://host:port [...]"
            );
            std::process::exit(2);
        }
    };

    let stdin = io::stdin();
    let stdout = io::stdout();
    let mut out = stdout.lock();
    for line in stdin.lock().lines() {
        let line = match line {
            Ok(line) => line,
            Err(_) => break,
        };
        if line.trim().is_empty() {
            continue;
        }
        if let Some(response) = handle_message(&mut target, &line) {
            if writeln!(out, "{}", response).is_err() {
                break;
            }
            let _ = out.flush();
        }
    }
    // Graceful stop (data-dir mode only): flush mutations to a
    // checkpoint so agent writes survive restart (auto_checkpoint is
    // throttled; a quit-after-write session could otherwise leave its
    // last edits WAL-only).
    if let Docuverse::Local(agent) = &mut target {
        if agent.writes_enabled {
            let _ = out.flush();
            if let Err(e) = agent.server.checkpoint_to_store() {
                eprintln!("final checkpoint failed: {}", e);
            }
        }
    }
}
