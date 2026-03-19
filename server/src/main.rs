//! POST /api/compile — bytecode for VM. POST /api/compile-js — JS for web preview iframe.

use axum::{
    extract::State,
    http::StatusCode,
    response::{IntoResponse, Response},
    routing::post,
    Json, Router,
};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tower_http::cors::{Any, CorsLayer};
use tower_http::services::ServeDir;

#[derive(Clone)]
struct AppState {
    tishact_runtime: String,
}

#[derive(Deserialize)]
struct CompileRequest {
    source: String,
}

#[derive(Serialize)]
struct CompileResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    bytecode: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

#[derive(Serialize)]
struct CompileJsResponse {
    #[serde(skip_serializing_if = "Option::is_none")]
    js: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}

async fn compile_handler(Json(body): Json<CompileRequest>) -> Response {
    let result = compile_source(&body.source);
    match result {
        Ok(bytes) => {
            let b64 = base64::Engine::encode(&base64::engine::general_purpose::STANDARD, bytes);
            (
                StatusCode::OK,
                Json(CompileResponse {
                    bytecode: Some(b64),
                    error: None,
                }),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::BAD_REQUEST,
            Json(CompileResponse {
                bytecode: None,
                error: Some(e),
            }),
        )
            .into_response(),
    }
}

fn compile_source(source: &str) -> Result<Vec<u8>, String> {
    let program = tish_parser::parse(source.trim()).map_err(|e| e.to_string())?;
    let program = tish_opt::optimize(&program);
    let chunk = tish_bytecode::compile(&program).map_err(|e| e.to_string())?;
    Ok(tish_bytecode::serialize(&chunk))
}

async fn compile_js_handler(
    State(state): State<AppState>,
    Json(body): Json<CompileRequest>,
) -> Response {
    let result = compile_source_to_js(&body.source);
    match result {
        Ok(js) => {
            let js_with_runtime = format!("{}\n{}", state.tishact_runtime, js);
            (
                StatusCode::OK,
                Json(CompileJsResponse {
                    js: Some(js_with_runtime),
                    error: None,
                }),
            )
                .into_response()
        }
        Err(e) => (
            StatusCode::BAD_REQUEST,
            Json(CompileJsResponse {
                js: None,
                error: Some(e),
            }),
        )
            .into_response(),
    }
}

fn compile_source_to_js(source: &str) -> Result<String, String> {
    use tish_compile_js::JsxMode;
    let program = tish_parser::parse(source.trim()).map_err(|e| e.to_string())?;
    let program = tish_opt::optimize(&program);
    tish_compile_js::compile_with_jsx(&program, true, JsxMode::LegacyDom)
        .map_err(|e| e.message.clone())
}

#[tokio::main]
async fn main() {
    let public_dir = std::env::var("PLAYGROUND_PUBLIC")
        .map(PathBuf::from)
        .unwrap_or_else(|_| {
            std::env::current_dir()
                .expect("cwd")
                .join("public")
        });

    let runtime_path = public_dir.join("dist").join("tishact-runtime.js");
    let tishact_runtime = std::fs::read_to_string(&runtime_path).unwrap_or_default();

    let state = AppState { tishact_runtime };

    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    let app = Router::new()
        .route("/api/compile", post(compile_handler))
        .route("/api/compile-js", post(compile_js_handler))
        .fallback_service(ServeDir::new(public_dir))
        .with_state(state)
        .layer(cors);

    let port = std::env::var("PORT")
        .ok()
        .and_then(|s| s.parse::<u16>().ok())
        .unwrap_or(8765);
    let addr = std::net::SocketAddr::from(([127, 0, 0, 1], port));
    println!("Tish playground server at http://{addr}");
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
