# Local `target/` for this repo (avoids shared sandbox target dirs).
export CARGO_TARGET_DIR := justfile_directory() + "/target"

# Path to the Tish compiler workspace (contains Cargo.toml + crates/).
TISH_ROOT := env_var_or_default("TISH_ROOT", justfile_directory() + "/../tish")

default:
    @just --list

# Tishact runtime for web preview iframe (prepended to user-compiled JS).
build-runtime:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ TISH_ROOT }}" && env -u CARGO_TARGET_DIR cargo run -p tish --release -- compile "{{ justfile_directory() }}/app/web-runtime.tish" -o "{{ justfile_directory() }}/public/dist/tishact-runtime.js" --target js --jsx tishact

# Compile playground UI (Tish → JS, legacy DOM). Output to public/dist/.
# Depends on build-runtime so web preview has Tishact in the iframe.
build-app: build-runtime
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ TISH_ROOT }}" && env -u CARGO_TARGET_DIR cargo run -p tish --release -- compile "{{ justfile_directory() }}/app/main.tish" -o "{{ justfile_directory() }}/public/dist/playground.js" --target js --jsx tishact

# Build browser VM WASM + wasm-bindgen glue into public/dist/.
build-vm:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ TISH_ROOT }}" && env -u CARGO_TARGET_DIR cargo build -p tish_wasm_runtime --target wasm32-unknown-unknown --release --features browser
    wasm-bindgen "{{ TISH_ROOT }}/target/wasm32-unknown-unknown/release/tish_wasm_runtime.wasm" --out-dir "{{ justfile_directory() }}/public/dist" --out-name tish_vm --target web

# Build compiler WASM (parse + bytecode + JS, runs 100% in browser).
build-compiler:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cargo build -p tish-playground-compiler --target wasm32-unknown-unknown --release
    wasm-bindgen "{{ justfile_directory() }}/target/wasm32-unknown-unknown/release/tish_playground_compiler.wasm" --out-dir "{{ justfile_directory() }}/public/dist" --out-name tish_compiler --target web

# Compile API server binary.
build-server:
    cargo build -p tish-playground-server --release

# App + VM + compiler WASM + server. Compile runs 100% in browser.
build: build-app build-vm build-compiler build-server

# Build then serve static at http://127.0.0.1:8765 (or PORT=3000 just dev).
dev: build
    ./target/release/tish-playground-server
