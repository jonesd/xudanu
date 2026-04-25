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
    let server = Server::new();
    let snapshot_path = path.join("server.json");
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
    match Server::restore_from_file(&snapshot_path) {
        Ok(server) => {
            eprintln!("Snapshot OK: {} works",
                server.work_count(),
            );
        }
        Err(e) => {
            eprintln!("Error: corrupt snapshot: {}", e);
            std::process::exit(1);
        }
    }
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        usage();
        std::process::exit(1);
    }

    match args[1].as_str() {
        "init" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_init(data_dir);
        }
        "verify" => {
            let data_dir = args.get(2).map(|s| s.as_str()).unwrap_or("./data");
            cmd_verify(data_dir);
        }
        "run" => {
            let addr = args.get(2)
                .filter(|s| s.contains(':'))
                .cloned()
                .unwrap_or_else(|| "127.0.0.1:8080".to_string());
            let data_dir = args.get(2)
                .filter(|s| !s.contains(':'))
                .cloned()
                .or_else(|| args.get(3).cloned());

            let server = if let Some(ref dir) = data_dir {
                let path = PathBuf::from(dir);
                let snapshot_path = path.join("server.json");
                if snapshot_path.exists() {
                    tracing::info!("Restoring from {}", snapshot_path.display());
                    Server::restore_from_file(&snapshot_path).expect("failed to restore snapshot")
                } else {
                    tracing::info!("Initializing new data directory: {}", dir);
                    std::fs::create_dir_all(&path).expect("failed to create data directory");
                    let s = Server::new();
                    s.checkpoint_to_file(&snapshot_path).expect("failed to write initial checkpoint");
                    s
                }
            } else {
                Server::new()
            };

            let state = AppState::new(server).shared();
            let app = build_router(state.clone())
                .into_make_service_with_connect_info::<std::net::SocketAddr>();

            tracing::info!("xudanu server listening on {}", addr);

            let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();

            let shutdown_state = state.clone();
            let shutdown_data_dir = data_dir.clone();
            let shutdown_handler = tokio::spawn(async move {
                tokio::signal::ctrl_c().await.expect("failed to listen for ctrl-c");
                tracing::info!("Shutting down...");
                if let Some(ref dir) = shutdown_data_dir {
                    let snapshot_path = PathBuf::from(dir).join("server.json");
                    shutdown_state.server.with_server_ref(|server| {
                        match server.checkpoint_to_file(&snapshot_path) {
                            Ok(()) => tracing::info!("Checkpoint saved to {}", snapshot_path.display()),
                            Err(e) => tracing::error!("Checkpoint failed: {}", e),
                        }
                    });
                }
                std::process::exit(0);
            });

            axum::serve(listener, app)
                .with_graceful_shutdown(async {
                    shutdown_handler.await.ok();
                })
                .await
                .unwrap();
        }
        _ => {
            usage();
            std::process::exit(1);
        }
    }
}
