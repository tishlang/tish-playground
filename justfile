# Local `target/` for this repo (avoids shared sandbox target dirs).
export CARGO_TARGET_DIR := justfile_directory() + "/target"

# Local dev: ../tish must exist. Run `just install-full` in ../tish, then `just dev`.
# CI/standalone: use build.sh (uses npm @tishlang/tish).
TISH_ROOT := env_var_or_default("TISH_ROOT", justfile_directory() + "/../tish")

default:
    @just --list

# Lattish runtime for web preview iframe (prepended to user-compiled JS).
# Uses `tish` from PATH (run `just install-full` in ../tish for fixed compiler).
build-runtime:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ justfile_directory() }}" && tish compile "{{ justfile_directory() }}/app/web-runtime.tish" -o "{{ justfile_directory() }}/public/dist/lattish-runtime.js" --target js 

# Compile playground UI (Tish → JS, --jsx lattish). Output to public/dist/.
# Depends on build-runtime so web preview has Lattish in the iframe.
build-app: build-runtime
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ justfile_directory() }}" && tish compile "{{ justfile_directory() }}/app/main.tish" -o "{{ justfile_directory() }}/public/dist/playground.js" --target js

# Build VM WASM (uses tish package's tish_wasm_runtime crate).
build-vm:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ justfile_directory() }}" && cargo build -p tishlang_wasm_runtime --manifest-path "{{ TISH_ROOT }}/Cargo.toml" --target wasm32-unknown-unknown --release --features browser
    wasm-bindgen "{{ CARGO_TARGET_DIR }}/wasm32-unknown-unknown/release/tishlang_wasm_runtime.wasm" --out-dir "{{ justfile_directory() }}/public/dist" --out-name tish_vm --target web

# Build compiler WASM (parse + bytecode + JS, runs 100% in browser).
build-compiler:
    mkdir -p "{{ justfile_directory() }}/public/dist"
    cd "{{ justfile_directory() }}" && cargo build -p tishlang_compiler_wasm --manifest-path "{{ TISH_ROOT }}/Cargo.toml" --target wasm32-unknown-unknown --release
    wasm-bindgen "{{ CARGO_TARGET_DIR }}/wasm32-unknown-unknown/release/tishlang_compiler_wasm.wasm" --out-dir "{{ justfile_directory() }}/public/dist" --out-name tish_compiler --target web

# App + VM + compiler WASM. Compile runs 100% in browser.
build: build-app build-vm build-compiler

# Build then serve static at http://127.0.0.1:8765 (or PORT=8765 just dev).
# Dev server needs fs/http/process; npm tish binary lacks them, so we build from source.
dev: build
    cd "{{ justfile_directory() }}" && cargo run -p tishlang --manifest-path "{{ TISH_ROOT }}/Cargo.toml" --release --features full -- run dev-server.tish

# Serve with Python's built-in HTTP server (fallback if Tish dev server hangs).
# Run `just build` first. Uses port 8765 or PORT env. Open http://127.0.0.1:8765/
serve:
    cd "{{ justfile_directory() }}/public" && python3 -m http.server "{{ env_var_or_default('PORT', '8765') }}"
