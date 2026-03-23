#!/usr/bin/env bash
set -euo pipefail

PLAYGROUND_ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="$PLAYGROUND_ROOT/node_modules/.bin:${HOME}/.cargo/bin:${PATH:-}"
# TISH_ROOT: npm package (node_modules/@tishlang/tish) or local sibling (../tish). Override with env.
NPM_TISH="$PLAYGROUND_ROOT/node_modules/@tishlang/tish"
LOCAL_TISH="$(cd "$PLAYGROUND_ROOT/.." 2>/dev/null && pwd)/tish"
if [[ -d "$NPM_TISH" ]]; then
  TISH_ROOT="${TISH_ROOT:-$NPM_TISH}"
elif [[ -d "$LOCAL_TISH" ]]; then
  TISH_ROOT="${TISH_ROOT:-$LOCAL_TISH}"
else
  TISH_ROOT="${TISH_ROOT:-}"
fi

# tish CLI: prefer explicit path from npm package, else PATH
TISH_CLI=""
if [[ -f "$PLAYGROUND_ROOT/node_modules/.bin/tish" ]]; then
  TISH_CLI="$PLAYGROUND_ROOT/node_modules/.bin/tish"
elif command -v tish &>/dev/null; then
  TISH_CLI="tish"
fi
if [[ -z "$TISH_CLI" ]]; then
  echo "Error: tish CLI not found"
  echo "Run: npm install (adds @tishlang/tish). Or for local dev: cd ../tish && just install-full"
  exit 1
fi

if [[ ! -d "$TISH_ROOT" ]]; then
  echo "Error: Tish source not found (needed for WASM build)"
  echo "Install @tishlang/tish via npm install, or set TISH_ROOT to your local tish repo"
  exit 1
fi

mkdir -p "$PLAYGROUND_ROOT/public/dist"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$PLAYGROUND_ROOT/target}"

echo "Building Lattish runtime..."
(cd "$PLAYGROUND_ROOT" && "$TISH_CLI" compile "$PLAYGROUND_ROOT/app/web-runtime.tish" \
  -o "$PLAYGROUND_ROOT/public/dist/lattish-runtime.js" \
  --target js --jsx lattish)

echo "Building playground app..."
(cd "$PLAYGROUND_ROOT" && "$TISH_CLI" compile "$PLAYGROUND_ROOT/app/main.tish" \
  -o "$PLAYGROUND_ROOT/public/dist/playground.js" \
  --target js --jsx lattish)

echo "Building WASM VM..."
(cd "$TISH_ROOT/crates/tish_wasm_runtime" && cargo build --target wasm32-unknown-unknown --release --features browser)
wasm-bindgen "$CARGO_TARGET_DIR/wasm32-unknown-unknown/release/tishlang_wasm_runtime.wasm" \
  --out-dir "$PLAYGROUND_ROOT/public/dist" \
  --out-name tish_vm \
  --target web

echo "Building compiler WASM..."
(cd "$TISH_ROOT" && cargo build -p tishlang_compiler_wasm --target wasm32-unknown-unknown --release)
wasm-bindgen "$CARGO_TARGET_DIR/wasm32-unknown-unknown/release/tishlang_compiler_wasm.wasm" \
  --out-dir "$PLAYGROUND_ROOT/public/dist" \
  --out-name tish_compiler \
  --target web

echo "Build complete. Output in public/"
ls -la "$PLAYGROUND_ROOT/public/dist/"
