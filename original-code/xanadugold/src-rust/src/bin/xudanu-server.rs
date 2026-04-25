use axum::extract::connect_info;
use xudanu::server::Server;
use xudanu::server::transport::{AppState, build_router};

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let addr = std::env::args()
        .nth(1)
        .unwrap_or_else(|| "127.0.0.1:8080".to_string());

    let server = Server::new();
    let state = AppState::new(server).shared();
    let app = build_router(state).into_make_service_with_connect_info::<std::net::SocketAddr>();

    tracing::info!("xudanu server listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
