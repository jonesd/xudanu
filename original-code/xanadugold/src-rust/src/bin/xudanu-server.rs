use std::path::PathBuf;
use xudanu::server::Server;
use xudanu::server::transport::{AppState, build_router};

fn usage() {
    eprintln!("Usage: xudanu-server <command> [options]");
    eprintln!();
    eprintln!("Commands:");
    eprintln!("  init <data-dir>          Initialize a new data directory");
    eprintln!("  run [addr] [data-dir]    Run the server (default: 127.0.0.1:8080)");
    eprintln!("  verify <data-dir>        Verify data integrity");
    eprintln!();
    eprintln!("Run options:");
    eprintln!("  --static-dir <dir>       Serve frontend from directory instead of embedded HTML");
    eprintln!("  --tls-cert <path>        TLS certificate PEM file");
    eprintln!("  --tls-key <path>         TLS private key PEM file");
    eprintln!("  --peer <addr>            Federation peer address (repeatable, e.g. ws://host:port/federation)");
    eprintln!("  --federation-mode <mode> Federation mode: closed (default) or open");
}

fn cmd_init(data_dir: &str) {
    let path = PathBuf::from(data_dir);
    if path.exists() {
        let snapshot_path = path.join("server.json");
        if snapshot_path.exists() {
            eprintln!("Error: data directory already exists: {}", data_dir);
            std::process::exit(1);
        }
    }
    std::fs::create_dir_all(&path).expect("failed to create data directory");
    std::fs::create_dir_all(path.join("blobs")).expect("failed to create blobs directory");
    let mut server = Server::new();
    let snapshot_path = path.join("server.json");
    server.restore_keypair_from_dir(&path).expect("failed to init keypair");
    server.set_checkpoint_path(snapshot_path.clone());
    server.checkpoint_to_file(&snapshot_path).expect("failed to write initial checkpoint");
    eprintln!("Initialized xudanu data directory: {}", data_dir);
}

fn cmd_verify(data_dir: &str) {
    let path = PathBuf::from(data_dir);
    let snapshot_path = path.join("server.json");
    if !snapshot_path.exists() {
        eprintln!("Error: no snapshot found at {}", snapshot_path.display());
        std::process::exit(1);
    }
    let content = match std::fs::read_to_string(&snapshot_path) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Error: cannot read snapshot: {}", e);
            std::process::exit(1);
        }
    };
    let raw: serde_json::Value = match serde_json::from_str(&content) {
        Ok(v) => v,
        Err(e) => {
            eprintln!("Error: corrupt JSON: {}", e);
            std::process::exit(1);
        }
    };
    let version = xudanu::server::transport::snapshot::detect_version(&raw);
    let data = if version >= 1 {
        let versioned: serde_json::Value = raw.clone();
        match xudanu::server::transport::snapshot::read_and_migrate(&snapshot_path) {
            Ok((d, _, _)) => d,
            Err(e) => {
                eprintln!("Error: migration failed: {}", e);
                std::process::exit(1);
            }
        }
    } else {
        raw.clone()
    };
    let report = xudanu::server::transport::snapshot::validate_snapshot(&data);
    match Server::restore_from_file_with_persistence(&snapshot_path) {
        Ok(server) => {
            println!("Snapshot OK");
            println!("  Format version: v{}", version);
            println!("  Server version: {}", env!("CARGO_PKG_VERSION"));
            println!("  Works: {}", server.work_count());
            println!("  Clubs: {}", server.club_count());
            println!("  Blobs: {}", server.blob_count());
            println!("  Server ID: {}", server.federation_server_id());
            if report.has_warnings() {
                for w in &report.warnings {
                    println!("  Warning: {}", w);
                }
            }
            if !report.is_valid() {
                for e in &report.errors {
                    eprintln!("  Error: {}", e);
                }
                std::process::exit(1);
            }
            if version < 1 {
                println!("  Note: snapshot is v0 (legacy). It will be auto-migrated to v1 on next startup.");
            }
        }
        Err(e) => {
            eprintln!("Error: corrupt snapshot: {}", e);
            std::process::exit(1);
        }
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt()
        .with_target(true)
        .with_timer(tracing_subscriber::fmt::time::time())
        .init();

    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        usage();
        std::process::exit(1);
    }

    match args[1].as_str() {
        "--version" | "-V" => {
            println!("xudanu {}", env!("CARGO_PKG_VERSION"));
        }
        "init" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_init(data_dir);
        }
        "verify" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_verify(data_dir);
        }
        "run" => {
            let mut addr = "127.0.0.1:8080".to_string();
            let mut data_dir: Option<String> = None;
            let mut static_dir: Option<PathBuf> = None;
            let mut tls_cert: Option<PathBuf> = None;
            let mut tls_key: Option<PathBuf> = None;
            let mut federation_peers: Vec<String> = Vec::new();
            let mut federation_mode = "closed".to_string();
            let mut i = 2;
            while i < args.len() {
                match args[i].as_str() {
                    "--static-dir" => {
                        i += 1;
                        static_dir = Some(PathBuf::from(args.get(i).map(|s| s.as_str()).unwrap_or_else(|| {
                            eprintln!("Error: --static-dir requires a path");
                            std::process::exit(1);
                        })));
                    }
                    "--tls-cert" => {
                        i += 1;
                        tls_cert = Some(PathBuf::from(args.get(i).map(|s| s.as_str()).unwrap_or_else(|| {
                            eprintln!("Error: --tls-cert requires a path");
                            std::process::exit(1);
                        })));
                    }
                    "--tls-key" => {
                        i += 1;
                        tls_key = Some(PathBuf::from(args.get(i).map(|s| s.as_str()).unwrap_or_else(|| {
                            eprintln!("Error: --tls-key requires a path");
                            std::process::exit(1);
                        })));
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
                    s if s.contains(':') => {
                        addr = s.to_string();
                    }
                    s => {
                        data_dir = Some(s.to_string());
                    }
                }
                i += 1;
            }

            let mut server = if let Some(ref dir) = data_dir {
                let path = PathBuf::from(dir);
                let snapshot_path = path.join("server.json");
                if snapshot_path.exists() {
                    tracing::info!("Restoring from {}", snapshot_path.display());
                    let start = std::time::Instant::now();
                    let mut s = Server::restore_from_file_with_persistence(&snapshot_path)
                        .expect("failed to restore snapshot");
                    let elapsed = start.elapsed();
                    tracing::info!(
                        "Restored in {:.2}ms: {}",
                        elapsed.as_secs_f64() * 1000.0,
                        s.recovery_stats()
                    );
                    s
                } else {
                    tracing::info!("Initializing new data directory: {}", dir);
                    std::fs::create_dir_all(&path).expect("failed to create data directory");
                    std::fs::create_dir_all(path.join("blobs")).expect("failed to create blobs directory");
                    let mut s = Server::new();
                    let _ = s.restore_keypair_from_dir(&path);
                    s.set_checkpoint_path(snapshot_path.clone());
                    s.checkpoint_to_file(&snapshot_path).expect("failed to write initial checkpoint");
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
                tracing::info!("Federation enabled with {} peer(s), mode={}", config.peers.len(), federation_mode);
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
                app.shared()
            };
            let client_router = build_router(state.clone());
            let federation_router = xudanu::server::transport::federation_handler::build_federation_router(state.clone());
            let app = xudanu::server::transport::federation_handler::merge_routers(client_router, federation_router);

            tracing::info!("xudanu server listening on {}{}", addr, if tls_cert.is_some() { " (TLS)" } else { "" });

            let shutdown_state = state.clone();
            let shutdown_data_dir = data_dir.clone();
            let shutdown_handler = tokio::spawn(async move {
                tokio::signal::ctrl_c().await.expect("failed to listen for ctrl-c");
                tracing::info!("Shutting down...");
                if let Some(ref dir) = shutdown_data_dir {
                    let snapshot_path = PathBuf::from(dir).join("server.json");
                    shutdown_state.server.with_server_ref(|server| {
                        let start = std::time::Instant::now();
                        match server.checkpoint_to_file(&snapshot_path) {
                            Ok(()) => tracing::info!(
                                "Checkpoint saved to {} in {:.2}ms",
                                snapshot_path.display(),
                                start.elapsed().as_secs_f64() * 1000.0
                            ),
                            Err(e) => tracing::error!("Checkpoint failed: {}", e),
                        }
                    });
                }
                std::process::exit(0);
            });

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
                let config = axum_server::tls_rustls::RustlsConfig::from_config(std::sync::Arc::new(server_config));
                tracing::info!("TLS enabled");
                let handle = axum_server::Handle::new();
                let shutdown_handle = handle.clone();
                tokio::spawn(async move {
                    shutdown_handler.await.ok();
                    shutdown_handle.shutdown();
                });
                axum_server::bind_rustls(addr.parse().unwrap(), config)
                    .handle(handle)
                    .serve(app.into_make_service_with_connect_info::<std::net::SocketAddr>())
                    .await
                    .unwrap();
            } else {
                let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
                axum::serve(listener, app.into_make_service_with_connect_info::<std::net::SocketAddr>())
                    .with_graceful_shutdown(async {
                        shutdown_handler.await.ok();
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
