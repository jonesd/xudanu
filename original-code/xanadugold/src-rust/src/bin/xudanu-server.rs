use std::path::PathBuf;
use xudanu::server::transport::{build_router, AppState};
use xudanu::server::Server;

fn init_tracing(data_dir: Option<&str>) {
    use tracing_subscriber::prelude::*;
    use xudanu::server::transport::chained_log::ChainedLogWriter;

    let env_filter = tracing_subscriber::EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info"));

    let console = tracing_subscriber::fmt::layer()
        .with_target(true)
        .with_timer(tracing_subscriber::fmt::time::time())
        .with_filter(env_filter);

    let security_filter = tracing_subscriber::filter::Targets::new()
        .with_target("xudanu::security", tracing::Level::INFO);

    if let Some(dir) = data_dir {
        let log_dir = PathBuf::from(dir);
        if let Err(e) = std::fs::create_dir_all(&log_dir) {
            eprintln!(
                "warning: cannot create log directory {}: {}",
                log_dir.display(),
                e
            );
            tracing_subscriber::registry().with(console).init();
            return;
        }
        let file_appender = tracing_appender::rolling::daily(&log_dir, "security.log");
        let seed_path = log_dir.join("security.log.seed");
        let chained = match ChainedLogWriter::new(file_appender, &seed_path) {
            Ok(w) => w,
            Err(e) => {
                eprintln!("warning: cannot create chained log writer: {}", e);
                tracing_subscriber::registry().with(console).init();
                return;
            }
        };
        let security_file = tracing_subscriber::fmt::layer()
            .with_writer(std::sync::Mutex::new(chained))
            .with_timer(tracing_subscriber::fmt::time::time())
            .with_target(true)
            .with_filter(security_filter);

        tracing_subscriber::registry()
            .with(console)
            .with(security_file)
            .init();
    } else {
        tracing_subscriber::registry().with(console).init();
    }
}

fn usage() {
    eprintln!(
        "xudanu {} — conflict-preserving hypertext document store",
        env!("CARGO_PKG_VERSION")
    );
    eprintln!();
    eprintln!("Usage: xudanu-server <command> [options]");
    eprintln!();
    eprintln!("Commands:");
    eprintln!("  init <data-dir>          Initialize a new data directory");
    eprintln!("  run [addr] [data-dir]    Run the server (default: 127.0.0.1:8080)");
    eprintln!("  verify <data-dir>        Verify data integrity");
    eprintln!("  rebuild-manifest <dir>   Rebuild manifest from chunks");
    eprintln!("  verify-security-log <dir> Verify security log chain integrity");
    eprintln!("  preflight <data-dir>     Check data dir is safe to start (no port binding)");
    eprintln!();
    eprintln!("Run options:");
    eprintln!("  --static-dir <dir>       Serve frontend from directory instead of embedded HTML");
    eprintln!("  --tls-cert <path>        TLS certificate PEM file");
    eprintln!("  --tls-key <path>         TLS private key PEM file");
    eprintln!("  --peer <addr>            Federation peer address (repeatable, e.g. ws://host:port/federation)");
    eprintln!("  --federation-mode <mode> Federation mode: closed (default) or open");
    eprintln!("  --allowed-origin <url>   Allowed WebSocket origin (repeatable, e.g. https://example.com)");
    eprintln!("  --csrf-token             Require CSRF token for WebSocket connections");
    eprintln!("  --key-passphrase <pw>   Passphrase for encrypted server key file");
    eprintln!("                         (can also set XUDANU_KEY_PASSPHRASE env var)");
    eprintln!("  --github-client-id <id>      GitHub OAuth app client ID");
    eprintln!("  --github-client-secret <key> GitHub OAuth app client secret");
    eprintln!("  --google-client-id <id>      Google OAuth app client ID");
    eprintln!("  --google-client-secret <key> Google OAuth app client secret");
    eprintln!(
        "  --oauth-redirect-base <url>  Base URL for OAuth callbacks (default: https://xudanu.com)"
    );
    eprintln!();
    eprintln!("Flags:");
    eprintln!("  --version, -V            Print version");
    eprintln!("  --help, -h               Print this help message");
}

fn cmd_init(data_dir: &str, passphrase: Option<&[u8]>) {
    let path = std::path::PathBuf::from(data_dir);
    if path.join("manifest.json").exists() || path.join("server.json").exists() {
        eprintln!("Error: data directory already exists: {}", data_dir);
        std::process::exit(1);
    }
    let mut server = Server::new();
    server
        .init_data_dir(&path, passphrase)
        .expect("failed to initialize data directory");
}

fn cmd_verify(data_dir: &str) {
    let path = PathBuf::from(data_dir);
    if !path.join("manifest.json").exists() {
        eprintln!(
            "Error: no manifest.json found at {}",
            path.join("manifest.json").display()
        );
        std::process::exit(1);
    }
    match xudanu::persist::verify::verify_store(&path) {
        Ok(report) => {
            println!("Verification report:");
            println!(
                "  Chunks: {} total, {} verified",
                report.chunks_total, report.chunks_verified
            );
            if !report.chunks_missing.is_empty() {
                println!("  MISSING chunks: {}", report.chunks_missing.len());
                for h in &report.chunks_missing {
                    println!("    {}", h);
                }
            }
            if !report.chunks_corrupt.is_empty() {
                println!("  CORRUPT chunks: {}", report.chunks_corrupt.len());
                for h in &report.chunks_corrupt {
                    println!("    {}", h);
                }
            }
            if !report.chunks_orphaned.is_empty() {
                println!("  Orphaned chunks: {}", report.chunks_orphaned.len());
            }
            if !report.deserialization_errors.is_empty() {
                println!(
                    "  Deserialization errors: {}",
                    report.deserialization_errors.len()
                );
                for e in &report.deserialization_errors {
                    println!("    {}", e);
                }
            }
            println!(
                "  Works: {} ok, {} failed",
                report.works_ok, report.works_failed
            );
            println!(
                "  Clubs: {} ok, {} failed",
                report.clubs_ok, report.clubs_failed
            );
            println!(
                "  Standalone editions: {} ok, {} failed",
                report.standalone_ok, report.standalone_failed
            );

            if report.is_ok() {
                println!("  Status: OK");
            } else {
                println!("  Status: ISSUES FOUND");
                std::process::exit(1);
            }
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}

fn cmd_rebuild_manifest(data_dir: &str) {
    let path = PathBuf::from(data_dir);
    match xudanu::persist::verify::rebuild_manifest(&path) {
        Ok(report) => {
            println!("Rebuild complete:");
            println!(
                "  Chunks: {} total, {} verified",
                report.chunks_total, report.chunks_verified
            );
            if report.is_ok() {
                println!("  Status: OK");
            } else {
                println!("  Status: ISSUES FOUND (see verify for details)");
                std::process::exit(1);
            }
        }
        Err(e) => {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
}

fn cmd_verify_security_log(data_dir: &str) {
    use xudanu::server::transport::chained_log::ChainedLogWriter;
    let path = PathBuf::from(data_dir);
    let seed_path = path.join("security.log.seed");

    let seed = match std::fs::read_to_string(&seed_path) {
        Ok(s) => s.trim().to_string(),
        Err(e) => {
            eprintln!("Error: cannot read {}: {}", seed_path.display(), e);
            std::process::exit(1);
        }
    };

    let mut log_files: Vec<PathBuf> = std::fs::read_dir(&path)
        .unwrap_or_else(|e| {
            eprintln!("Error: cannot read {}: {}", path.display(), e);
            std::process::exit(1);
        })
        .filter_map(|e| e.ok())
        .filter(|e| {
            let name = e.file_name().to_string_lossy().to_string();
            name.starts_with("security.log") && !name.ends_with(".seed")
        })
        .map(|e| e.path())
        .filter(|p| p.is_file())
        .collect();

    if log_files.is_empty() {
        println!("No security log files found in {}", path.display());
        return;
    }

    log_files.sort();

    let mut total_lines = 0;
    let mut errors = 0;
    let mut chain_seed = seed;
    for log_file in &log_files {
        let content = std::fs::read_to_string(log_file).unwrap_or_else(|e| {
            eprintln!("Error: cannot read {}: {}", log_file.display(), e);
            std::process::exit(1);
        });
        match ChainedLogWriter::<std::fs::File>::verify_log(&content, &chain_seed) {
            Ok((count, final_hash)) => {
                println!(
                    "  {}  {} lines  OK",
                    log_file.file_name().unwrap_or_default().to_string_lossy(),
                    count
                );
                total_lines += count;
                chain_seed = final_hash;
            }
            Err(e) => {
                println!(
                    "  {}  FAIL at line {}",
                    log_file.file_name().unwrap_or_default().to_string_lossy(),
                    e.line_number
                );
                println!("    {}", e);
                errors += 1;
            }
        }
    }

    println!();
    if errors == 0 {
        println!(
            "Verification passed: {} log lines, {} files, chain intact",
            total_lines,
            log_files.len()
        );
    } else {
        println!(
            "Verification FAILED: {} error(s) in {} files",
            errors,
            log_files.len()
        );
        std::process::exit(1);
    }
}

fn cmd_preflight(data_dir: &str) {
    let path = PathBuf::from(data_dir);
    println!(
        "xudanu-server {} preflight check",
        env!("CARGO_PKG_VERSION")
    );
    println!();
    let report = xudanu::persist::manifest::preflight_check(&path);
    println!("{}", report);
    if report.can_start {
        std::process::exit(0);
    } else {
        std::process::exit(1);
    }
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        usage();
        std::process::exit(1);
    }

    let data_dir_for_tracing = match args[1].as_str() {
        "run" => args
            .iter()
            .position(|a| !a.starts_with('-') && !a.contains(':'))
            .and_then(|p| args.get(p + 1).cloned())
            .or_else(|| {
                args.get(2).and_then(|a| {
                    if !a.starts_with('-') && !a.contains(':') {
                        Some(a.clone())
                    } else {
                        None
                    }
                })
            }),
        "init" | "verify" | "rebuild-manifest" | "verify-security-log" | "preflight" => {
            args.get(2).cloned()
        }
        _ => None,
    };
    init_tracing(data_dir_for_tracing.as_deref());

    match args[1].as_str() {
        "--version" | "-V" => {
            println!("xudanu {}", env!("CARGO_PKG_VERSION"));
        }
        "--help" | "-h" => {
            usage();
        }
        "init" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            let passphrase = std::env::var("XUDANU_KEY_PASSPHRASE").ok();
            cmd_init(data_dir, passphrase.as_deref().map(|s| s.as_bytes()));
        }
        "verify" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_verify(data_dir);
        }
        "rebuild-manifest" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_rebuild_manifest(data_dir);
        }
        "verify-security-log" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_verify_security_log(data_dir);
        }
        "preflight" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_preflight(data_dir);
        }
        "run" => {
            let mut addr = "127.0.0.1:8080".to_string();
            let mut data_dir: Option<String> = None;
            let mut static_dir: Option<PathBuf> = None;
            let mut tls_cert: Option<PathBuf> = None;
            let mut tls_key: Option<PathBuf> = None;
            let mut federation_peers: Vec<String> = Vec::new();
            let mut federation_mode = "closed".to_string();
            let mut allowed_origins: std::collections::HashSet<String> =
                std::collections::HashSet::new();
            let mut csrf_enabled = false;
            let mut key_passphrase: Option<String> = std::env::var("XUDANU_KEY_PASSPHRASE").ok();
            let mut github_client_id: Option<String> =
                std::env::var("XUDANU_GITHUB_CLIENT_ID").ok();
            let mut github_client_secret: Option<String> =
                std::env::var("XUDANU_GITHUB_CLIENT_SECRET").ok();
            let mut google_client_id: Option<String> =
                std::env::var("XUDANU_GOOGLE_CLIENT_ID").ok();
            let mut google_client_secret: Option<String> =
                std::env::var("XUDANU_GOOGLE_CLIENT_SECRET").ok();
            let mut oauth_redirect_base: Option<String> =
                std::env::var("XUDANU_OAUTH_REDIRECT_BASE").ok();
            let mut i = 2;
            while i < args.len() {
                match args[i].as_str() {
                    "--static-dir" => {
                        i += 1;
                        static_dir = Some(PathBuf::from(
                            args.get(i).map(|s| s.as_str()).unwrap_or_else(|| {
                                eprintln!("Error: --static-dir requires a path");
                                std::process::exit(1);
                            }),
                        ));
                    }
                    "--tls-cert" => {
                        i += 1;
                        tls_cert = Some(PathBuf::from(
                            args.get(i).map(|s| s.as_str()).unwrap_or_else(|| {
                                eprintln!("Error: --tls-cert requires a path");
                                std::process::exit(1);
                            }),
                        ));
                    }
                    "--tls-key" => {
                        i += 1;
                        tls_key = Some(PathBuf::from(
                            args.get(i).map(|s| s.as_str()).unwrap_or_else(|| {
                                eprintln!("Error: --tls-key requires a path");
                                std::process::exit(1);
                            }),
                        ));
                    }
                    "--peer" => {
                        i += 1;
                        let peer = args.get(i).map(|s| s.to_string()).unwrap_or_else(|| {
                            eprintln!("Error: --peer requires an address");
                            std::process::exit(1);
                        });
                        federation_peers.push(peer);
                    }
                    "--federation-mode" => {
                        i += 1;
                        federation_mode = args.get(i).map(|s| s.to_string()).unwrap_or_else(|| {
                            eprintln!("Error: --federation-mode requires a value");
                            std::process::exit(1);
                        });
                    }
                    "--allowed-origin" => {
                        i += 1;
                        let origin = args.get(i).map(|s| s.to_string()).unwrap_or_else(|| {
                            eprintln!("Error: --allowed-origin requires a URL origin");
                            std::process::exit(1);
                        });
                        allowed_origins.insert(origin);
                    }
                    "--csrf-token" => {
                        csrf_enabled = true;
                    }
                    "--key-passphrase" => {
                        i += 1;
                        key_passphrase =
                            Some(args.get(i).map(|s| s.clone()).unwrap_or_else(|| {
                                eprintln!("Error: --key-passphrase requires a value");
                                std::process::exit(1);
                            }));
                    }
                    "--github-client-id" => {
                        i += 1;
                        github_client_id =
                            Some(args.get(i).map(|s| s.clone()).unwrap_or_else(|| {
                                eprintln!("Error: --github-client-id requires a value");
                                std::process::exit(1);
                            }));
                    }
                    "--github-client-secret" => {
                        i += 1;
                        github_client_secret =
                            Some(args.get(i).map(|s| s.clone()).unwrap_or_else(|| {
                                eprintln!("Error: --github-client-secret requires a value");
                                std::process::exit(1);
                            }));
                    }
                    "--google-client-id" => {
                        i += 1;
                        google_client_id =
                            Some(args.get(i).map(|s| s.clone()).unwrap_or_else(|| {
                                eprintln!("Error: --google-client-id requires a value");
                                std::process::exit(1);
                            }));
                    }
                    "--google-client-secret" => {
                        i += 1;
                        google_client_secret =
                            Some(args.get(i).map(|s| s.clone()).unwrap_or_else(|| {
                                eprintln!("Error: --google-client-secret requires a value");
                                std::process::exit(1);
                            }));
                    }
                    "--oauth-redirect-base" => {
                        i += 1;
                        oauth_redirect_base =
                            Some(args.get(i).map(|s| s.clone()).unwrap_or_else(|| {
                                eprintln!("Error: --oauth-redirect-base requires a URL");
                                std::process::exit(1);
                            }));
                    }
                    s if s.contains(':') => {
                        addr = s.to_string();
                    }
                    s => {
                        data_dir = Some(s.to_string());
                    }
                }
                i += 1;
            }

            let pass_bytes: Option<&[u8]> = key_passphrase.as_deref().map(|s| s.as_bytes());

            let mut server = if let Some(ref dir) = data_dir {
                let path = PathBuf::from(dir);
                let manifest_path = path.join("manifest.json");
                let legacy_path = path.join("server.json");

                if manifest_path.exists() {
                    tracing::info!("Restoring from {}", manifest_path.display());

                    let preflight = xudanu::persist::manifest::preflight_check(&path);
                    tracing::info!("{}", preflight);
                    if !preflight.can_start {
                        eprintln!("Error: Preflight check failed — cannot start server.");
                        eprintln!("{}", preflight);
                        std::process::exit(1);
                    }

                    let start = std::time::Instant::now();
                    let mut s = Server::new();
                    if let Err(e) = s.restore_from_data_dir(&path, pass_bytes) {
                        eprintln!("Error: Failed to restore from data directory: {}", e);
                        eprintln!("Hints:");
                        eprintln!(
                            "  - Run 'xudanu-server verify {}' to check data integrity",
                            dir
                        );
                        eprintln!(
                            "  - Run 'xudanu-server rebuild-manifest {}' to rebuild the manifest",
                            dir
                        );
                        eprintln!(
                            "  - Remove the data directory to start fresh (all data will be lost)"
                        );
                        std::process::exit(1);
                    }
                    let elapsed = start.elapsed();
                    tracing::info!(
                        "Restored in {:.2}ms: {}",
                        elapsed.as_secs_f64() * 1000.0,
                        s.recovery_stats()
                    );
                    s
                } else if legacy_path.exists() {
                    eprintln!("Error: Found legacy server.json in {} — this format is no longer supported.", dir);
                    eprintln!("To migrate, rename server.json and run `xudanu-server init {}` to start fresh.", dir);
                    eprintln!("Your data in server.json will NOT be loaded. Back it up first.");
                    std::process::exit(1);
                } else {
                    tracing::info!("Initializing new data directory: {}", dir);
                    let mut s = Server::new();
                    s.init_data_dir(&path, pass_bytes)
                        .expect("failed to initialize data directory");
                    s
                }
            } else {
                Server::new()
            };

            if !federation_peers.is_empty() {
                let peers: Vec<xudanu::server::federation::PeerAddress> = federation_peers
                    .iter()
                    .filter_map(|p| {
                        let addr = p.trim_start_matches("ws://").trim_start_matches("wss://");
                        let addr = addr.split('/').next().unwrap_or(addr);
                        let parts: Vec<&str> = addr.split(':').collect();
                        match (parts.first(), parts.get(1)) {
                            (Some(host), Some(port_str)) => {
                                let port: u16 = port_str.parse().unwrap_or_else(|_| {
                                    eprintln!("Error: invalid peer port in '{}'", p);
                                    std::process::exit(1);
                                });
                                Some(xudanu::server::federation::PeerAddress::new(*host, port))
                            }
                            (Some(host), None) => {
                                Some(xudanu::server::federation::PeerAddress::new(*host, 8080))
                            }
                            _ => None,
                        }
                    })
                    .collect();
                let mode = match federation_mode.as_str() {
                    "open" => xudanu::server::federation::FederationMode::Open,
                    _ => xudanu::server::federation::FederationMode::Closed,
                };
                let config = xudanu::server::federation::FederationConfig {
                    enabled: true,
                    peers,
                    mode,
                    min_endorsements: 2,
                };
                tracing::info!(
                    "Federation enabled with {} peer(s), mode={}",
                    config.peers.len(),
                    federation_mode
                );
                server.set_federation_config(config);
            }

            let state = {
                let app = AppState::new(server);
                let app = match static_dir {
                    Some(ref dir) => {
                        tracing::info!("Serving static files from {}", dir.display());
                        app.with_static_dir(dir.clone())
                    }
                    None => app,
                };
                let app = if !allowed_origins.is_empty() {
                    tracing::info!(
                        "WebSocket origin check: {} allowed origin(s)",
                        allowed_origins.len()
                    );
                    app.with_allowed_origins(allowed_origins)
                } else {
                    app
                };
                let app = if csrf_enabled {
                    tracing::info!("CSRF token protection enabled for WebSocket");
                    app.with_csrf(true)
                } else {
                    app
                };
                let has_oauth = github_client_id.is_some() || google_client_id.is_some();
                let app = if has_oauth {
                    let oauth_config = xudanu::server::transport::oauth::OAuthConfig {
                        github_client_id,
                        github_client_secret,
                        google_client_id,
                        google_client_secret,
                        redirect_base: oauth_redirect_base
                            .unwrap_or_else(|| "https://xudanu.com".to_string()),
                    };
                    tracing::info!(
                        "OAuth enabled: github={}, google={}, redirect_base={}",
                        oauth_config.github_client_id.is_some(),
                        oauth_config.google_client_id.is_some(),
                        oauth_config.redirect_base,
                    );
                    app.with_oauth(oauth_config)
                } else {
                    app
                };
                app.shared()
            };
            let client_router = build_router(state.clone());
            let federation_router =
                xudanu::server::transport::federation_handler::build_federation_router(
                    state.clone(),
                );
            let app = xudanu::server::transport::federation_handler::merge_routers(
                client_router,
                federation_router,
            );

            tracing::info!(
                "xudanu server listening on {}{}",
                addr,
                if tls_cert.is_some() { " (TLS)" } else { "" }
            );

            let shutdown_state = state.clone();
            let shutdown_data_dir = data_dir.clone();
            let (shutdown_tx, shutdown_rx) = tokio::sync::oneshot::channel::<()>();
            let _shutdown_handler = tokio::spawn(async move {
                let sigint = async {
                    tokio::signal::ctrl_c()
                        .await
                        .expect("failed to listen for ctrl-c");
                    "SIGINT"
                };
                #[cfg(unix)]
                let which = {
                    let sigterm = async {
                        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
                            .expect("failed to listen for SIGTERM")
                            .recv()
                            .await;
                        "SIGTERM"
                    };
                    tokio::select! {
                        s = sigint => s,
                        s = sigterm => s,
                    }
                };
                #[cfg(not(unix))]
                let which = { sigint.await };
                tracing::info!("Received {}, shutting down...", which);
                if let Some(ref _dir) = shutdown_data_dir {
                    shutdown_state.server.with_server(|server| {
                        let start = std::time::Instant::now();
                        if server.chunk_store().is_some() {
                            match server.checkpoint_to_store() {
                                Ok(()) => tracing::info!(
                                    "Checkpoint saved in {:.2}ms (chunk store)",
                                    start.elapsed().as_secs_f64() * 1000.0
                                ),
                                Err(e) => tracing::error!("Checkpoint failed: {}", e),
                            }
                        } else if let Some(ref path) = server.checkpoint_path() {
                            match server.checkpoint_to_file(path) {
                                Ok(()) => tracing::info!(
                                    "Checkpoint saved to {} in {:.2}ms",
                                    path.display(),
                                    start.elapsed().as_secs_f64() * 1000.0
                                ),
                                Err(e) => tracing::error!("Checkpoint failed: {}", e),
                            }
                        }
                    });
                }
                let _ = shutdown_tx.send(());
            });

            {
                let autosave_state = state.clone();
                tokio::spawn(async move {
                    let mut interval = tokio::time::interval(std::time::Duration::from_secs(5));
                    loop {
                        interval.tick().await;
                        let saved = autosave_state.server.with_server(|srv| {
                            let count = srv.materialize_all_pending();
                            if let Some(_cs) = srv.chunk_store() {
                                let now = std::time::SystemTime::now()
                                    .duration_since(std::time::UNIX_EPOCH)
                                    .unwrap_or_default()
                                    .as_secs();
                                let elapsed = now.saturating_sub(srv.last_checkpoint_time());
                                if elapsed >= 5 {
                                    if let Err(e) = srv.checkpoint_to_store() {
                                        tracing::error!("periodic checkpoint failed: {}", e);
                                    }
                                }
                            }
                            count
                        });
                        if saved > 0 {
                            tracing::info!("auto-save: materialized {} work(s)", saved);
                        }
                    }
                });
            }

            if let (Some(cert_path), Some(key_path)) = (tls_cert, tls_key) {
                rustls::crypto::ring::default_provider()
                    .install_default()
                    .expect("failed to install rustls crypto provider");
                let certs = {
                    let f = std::fs::File::open(&cert_path).unwrap_or_else(|e| {
                        eprintln!("Error: cannot open TLS cert {}: {}", cert_path.display(), e);
                        std::process::exit(1);
                    });
                    let mut reader = std::io::BufReader::new(f);
                    rustls_pemfile::certs(&mut reader)
                        .collect::<Result<Vec<_>, _>>()
                        .unwrap_or_else(|e| {
                            eprintln!("Error: failed to parse TLS cert: {}", e);
                            std::process::exit(1);
                        })
                };
                let key = {
                    let f = std::fs::File::open(&key_path).unwrap_or_else(|e| {
                        eprintln!("Error: cannot open TLS key {}: {}", key_path.display(), e);
                        std::process::exit(1);
                    });
                    let mut reader = std::io::BufReader::new(f);
                    rustls_pemfile::private_key(&mut reader)
                        .unwrap_or_else(|e| {
                            eprintln!("Error: failed to parse TLS key: {}", e);
                            std::process::exit(1);
                        })
                        .expect("no private key found in TLS key file")
                };
                let mut server_config = rustls::ServerConfig::builder()
                    .with_no_client_auth()
                    .with_single_cert(certs, key)
                    .unwrap_or_else(|e| {
                        eprintln!("Error: invalid TLS config: {}", e);
                        std::process::exit(1);
                    });
                server_config.alpn_protocols = vec![b"http/1.1".to_vec()];
                let config = axum_server::tls_rustls::RustlsConfig::from_config(
                    std::sync::Arc::new(server_config),
                );
                tracing::info!("TLS enabled");
                let handle = axum_server::Handle::new();
                let shutdown_handle = handle.clone();
                let tls_shutdown_rx = shutdown_rx;
                tokio::spawn(async move {
                    let _ = tls_shutdown_rx.await;
                    shutdown_handle.shutdown();
                });
                axum_server::bind_rustls(addr.parse().unwrap(), config)
                    .handle(handle)
                    .serve(app.into_make_service_with_connect_info::<std::net::SocketAddr>())
                    .await
                    .unwrap();
            } else {
                let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
                axum::serve(
                    listener,
                    app.into_make_service_with_connect_info::<std::net::SocketAddr>(),
                )
                .with_graceful_shutdown(async {
                    let _ = shutdown_rx.await;
                })
                .await
                .unwrap();
            }
        }
        _ => {
            usage();
            std::process::exit(1);
        }
    }
}
