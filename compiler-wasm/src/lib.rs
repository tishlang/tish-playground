//! Tish compiler exposed to JS via wasm-bindgen.
//! Used by the playground to compile source → bytecode and source → JS entirely in the browser.

use tish_compile_js::JsxMode;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn compile_to_bytecode(source: &str) -> Result<String, JsValue> {
    let program = tish_parser::parse(source.trim()).map_err(|e| JsValue::from_str(&e.to_string()))?;
    let program = tish_opt::optimize(&program);
    let chunk = tish_bytecode::compile(&program).map_err(|e| JsValue::from_str(&e.to_string()))?;
    let bytes = tish_bytecode::serialize(&chunk);
    Ok(base64::Engine::encode(
        &base64::engine::general_purpose::STANDARD,
        bytes,
    ))
}

#[wasm_bindgen]
pub fn compile_to_js(source: &str) -> Result<String, JsValue> {
    let program = tish_parser::parse(source.trim()).map_err(|e| JsValue::from_str(&e.to_string()))?;
    let js = tish_compile_js::compile_with_jsx(&program, true, JsxMode::LegacyDom)
        .map_err(|e| JsValue::from_str(&e.message))?;
    Ok(js)
}
