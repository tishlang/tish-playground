#!/usr/bin/env bash
set -euo pipefail

PLAYGROUND_ROOT="$(cd "$(dirname "$0")" && pwd)"
TISH_ROOT="${TISH_ROOT:-$PLAYGROUND_ROOT/../tish}"

if [[ ! -d "$TISH_ROOT" ]]; then
  echo "Error: Tish compiler not found at $TISH_ROOT"
  echo "Set TISH_ROOT or ensure tish is at ../tish (e.g. monorepo with tish and tish-playground)"
  exit 1
fi

mkdir -p "$PLAYGROUND_ROOT/public/dist"

echo "Building Tishact runtime..."
(cd "$TISH_ROOT" && env -u CARGO_TARGET_DIR cargo run -p tish --release -- \
  compile "$PLAYGROUND_ROOT/app/web-runtime.tish" \
  -o "$PLAYGROUND_ROOT/public/dist/tishact-runtime.js" \
  --target js --jsx tishact)

echo "Building playground app..."
(cd "$TISH_ROOT" && env -u CARGO_TARGET_DIR cargo run -p tish --release -- \
  compile "$PLAYGROUND_ROOT/app/main.tish" \
  -o "$PLAYGROUND_ROOT/public/dist/playground.js" \
  --target js --jsx tishact)

echo "Building WASM VM..."
(cd "$TISH_ROOT" && env -u CARGO_TARGET_DIR cargo build -p tish_wasm_runtime \
  --target wasm32-unknown-unknown --release --features browser)
wasm-bindgen "$TISH_ROOT/target/wasm32-unknown-unknown/release/tish_wasm_runtime.wasm" \
  --out-dir "$PLAYGROUND_ROOT/public/dist" \
  --out-name tish_vm \
  --target web

echo "Building compiler WASM..."
(cd "$PLAYGROUND_ROOT" && cargo build -p tish-playground-compiler --target wasm32-unknown-unknown --release)
wasm-bindgen "$PLAYGROUND_ROOT/target/wasm32-unknown-unknown/release/tish_playground_compiler.wasm" \
  --out-dir "$PLAYGROUND_ROOT/public/dist" \
  --out-name tish_compiler \
  --target web

echo "Build complete. Output in public/"
ls -la "$PLAYGROUND_ROOT/public/dist/"
