#!/usr/bin/env bash
set -euo pipefail

PLAYGROUND_ROOT="$(cd "$(dirname "$0")" && pwd)"
TISH_ROOT="${TISH_ROOT:-$PLAYGROUND_ROOT/node_modules/@tishlang/tish}"

if [[ ! -d "$TISH_ROOT" ]]; then
  echo "Error: Tish compiler not found at $TISH_ROOT"
  echo "Run: npm install"
  exit 1
fi

mkdir -p "$PLAYGROUND_ROOT/public/dist"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$PLAYGROUND_ROOT/target}"

echo "Building Lattish runtime..."
(cd "$PLAYGROUND_ROOT" && npx tish compile "$PLAYGROUND_ROOT/app/web-runtime.tish" \
  -o "$PLAYGROUND_ROOT/public/dist/lattish-runtime.js" \
  --target js --jsx lattish)

echo "Building playground app..."
(cd "$PLAYGROUND_ROOT" && npx tish compile "$PLAYGROUND_ROOT/app/main.tish" \
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
