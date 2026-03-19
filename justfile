# Local `target/` for this repo (avoids shared sandbox target dirs).
export CARGO_TARGET_DIR := justfile_directory() + "/target"

# Path to the Tish compiler workspace (contains Cargo.toml + crates/).
TISH_ROOT := env_var_or_default("TISH_ROOT", justfile_directory() + "/../tish")

default:
    @just --list

# Compile playground UI (Tish → JS, legacy DOM). Output to public/dist/.
# Clear CARGO_TARGET_DIR so the Tish workspace uses its own ./target (not this repo's).
build-app:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ TISH_ROOT }}" && env -u CARGO_TARGET_DIR cargo run -p tish --release -- compile "{{ justfile_directory() }}/app/main.tish" -o "{{ justfile_directory() }}/public/dist/playground.js" --target js --jsx legacy

# Build browser VM WASM + wasm-bindgen glue into public/dist/.
build-vm:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ TISH_ROOT }}" && env -u CARGO_TARGET_DIR cargo build -p tish_wasm_runtime --target wasm32-unknown-unknown --release --features browser
    wasm-bindgen "{{ TISH_ROOT }}/target/wasm32-unknown-unknown/release/tish_wasm_runtime.wasm" --out-dir "{{ justfile_directory() }}/public/dist" --out-name tish_vm --target web

# Compile API server binary.
build-server:
    cargo build -p tish-playground-server --release

# App + VM + server.
build: build-app build-vm build-server

# Build then serve static + /api/compile on http://127.0.0.1:8765 (or PORT=3000 just dev).
dev: build
    ./target/release/tish-playground-server
