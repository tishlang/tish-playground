#!/usr/bin/env bash
set -euo pipefail

# Install Node deps
npm install

# Rust: Vercel's Rust runtime (Cargo.toml + api/*.rs) provisions cargo at build time.
# If not present, install rustup. Then add wasm32 target + wasm-bindgen-cli for our WASM build.
if ! command -v cargo &>/dev/null; then
  echo "Installing Rust..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
fi

rustup target add wasm32-unknown-unknown 2>/dev/null || true
if ! command -v wasm-bindgen &>/dev/null; then
  cargo install wasm-bindgen-cli --version 0.2.114
fi
