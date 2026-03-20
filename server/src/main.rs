//! Static file server for local dev. Compile runs 100% in browser (WASM).

use std::path::PathBuf;
use tower_http::services::ServeDir;

#[tokio::main]
async fn main() {
    let public = std::env::var("PLAYGROUND_PUBLIC")
        .map(PathBuf::from)
        .unwrap_or_else(|_| std::env::current_dir().unwrap().join("public"));
    let port = std::env::var("PORT")
        .ok()
        .and_then(|s| s.parse::<u16>().ok())
        .unwrap_or(8765);
    let app = axum::Router::new().fallback_service(ServeDir::new(public));
    let addr = std::net::SocketAddr::from(([127, 0, 0, 1], port));
    println!("Tish playground at http://{addr}");
    axum::serve(
        tokio::net::TcpListener::bind(addr).await.unwrap(),
        app,
    )
    .await
    .unwrap();
}
