mod app;
mod convert;
mod convert_assertion;
mod routes;
mod state;

use std::collections::HashMap;
use std::sync::Arc;

use tokio::sync::RwLock;

#[tokio::main]
async fn main() {
    let state: state::SharedState = Arc::new(RwLock::new(HashMap::new()));
    let app = app::app(state);
    let port: u16 = std::env::var("ENT_PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(3001);
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{port}"))
        .await
        .unwrap();
    println!("ent-server listening on :{port}");
    axum::serve(listener, app).await.unwrap();
}
