# Tish Playground Deployment Strategy

Tish is:
- **Published**: npm package (runtime, tooling)
- **Unpublished**: Cargo workspace (~22 crates) with feature flags, split by backend (native, WASM, Cranelift, LLVM, etc.)

This document outlines how to deploy the playground (and future crate consumers) without publishing to crates.io.

---

## Build Requirements

| Artifact | Crate(s) | Feature flags | Notes |
|----------|----------|---------------|-------|
| Tish CLI (compile) | `tish` | (default) | Compiles `.tish` → JS |
| lattish-runtime.js | `tish` | (default) | Output of `tish compile web-runtime.tish` |
| playground.js | `tish` | (default) | Output of `tish compile main.tish` |
| tish_vm.wasm | `tish_wasm_runtime` | `browser` | `tish_vm/wasm` transitively |
| tish_compiler.wasm | `tish_compiler_wasm` | (none) | Parse + bytecode + JS in browser |

All crates use path deps within the tish workspace. **Source must be available at build time.**

---

## Phase 1: Deploy Now (Source Available)

### 1A. Clone During Install

Clone tish in `installCommand`:

```json
"installCommand": "scripts/vercel-install.sh && npm install"
```

**scripts/vercel-install.sh:**
```bash
#!/bin/bash
set -e
TISH_REF="${TISH_REF:-main}"  # or tag: v0.1.0
git clone --depth 1 --branch "$TISH_REF" \
  "https://${GITHUB_TOKEN:+$GITHUB_TOKEN@}github.com/tishlang/tish.git" \
  tish
```

Set `GITHUB_TOKEN` (or `TISH_REF`) in Vercel env. Reproducible via tag.

---

### 1B. Monorepo

If tish and tish-playground live in the same repo:

```
tish-monorepo/
  tish/              <- compiler workspace
  tish-playground/   <- playground
```

Vercel: set **Root Directory** = `tish-playground`, then `TISH_ROOT=$VERCEL_SOURCE_DIR/../tish` or `$PWD/../tish` depending on `VERCEL_SOURCE_DIR` behavior. Test in a preview deploy.

---

## Phase 2: Rust on Vercel

Vercel’s build image does not ship Rust by default for generic Node/static projects. Options:

1. **Rust runtime detection**: A root `Cargo.toml` (even minimal) may trigger Rust toolchain. Add a stub if needed:
   ```toml
   [package]
   name = "tish-playground"
   version = "0.1.0"
   ```
   This is not guaranteed to install Rust for arbitrary `buildCommand`s.

2. **installCommand**: Install Rust explicitly:
   ```bash
   curl -sSf https://sh.rustup.rs | sh -s -- -y default
   . $HOME/.cargo/env
   rustup target add wasm32-unknown-unknown
   cargo install wasm-bindgen-cli
   ```
   Slow but reliable.

3. **Vercel Build Image / “Rust build agent”**: If Vercel exposes a Rust-capable image or framework, enable it in project settings and confirm `cargo` and `wasm-bindgen` are available before adding custom install logic.

---

## Phase 3: Publish Crates (Later)

When crates are ready for crates.io:

1. **Publish order** (dependency graph):
   - `tish_core`, `tish_ast`, `tish_lexer`, `tish_parser`
   - `tish_opt`, `tish_bytecode`, `tish_compile`, `tish_compile_js`, `tish_jsx_web`
   - `tish_vm`, `tish_compiler_wasm`, `tish_wasm_runtime`
   - `tish` (CLI)

2. **Feature flags**: Keep them. Consumers choose what they need:
   - Playground: `tish_wasm_runtime` with `browser`
   - Native CLI: `tish` with `http`, `fs`, `process`, etc.

3. **tish-playground Cargo.toml** (when publishing):
   ```toml
   [dependencies]
   tish = { version = "0.1", default-features = false }
   # Or use tish-cli if you split the binary crate
   ```

4. **Build flow**: `cargo install tish` or `cargo run -p tish` for the compile step; `tish_compiler_wasm` and `tish_wasm_runtime` as lib deps. No tish source clone needed.

---

## Phase 4: Pre-built Artifacts (Optional)

To avoid building Rust on Vercel:

1. **CI (GitHub Actions)**: On push to `main` (or release tag), build:
   - `tish` CLI binary (Linux x86_64)
   - `tish_vm_bg.wasm` + `tish_vm.js`
   - `tish_compiler_bg.wasm` + `tish_compiler.js`
   - `tish compile` output for `web-runtime.tish` and `main.tish`

2. **Publish**: As GitHub Release assets or to a CDN/S3.

3. **Vercel installCommand**: Download artifacts; `build.sh` only runs `tish compile` (if CLI is used) or copies pre-built JS/WASM.

Tradeoff: faster Vercel builds, but two-step release (tish release → playground download).

---

## Recommended Path

| Stage | Approach |
|-------|----------|
| **Now** | 1A (submodule) + explicit Rust install in `installCommand` until Rust is confirmed on the image |
| **Stable** | Pin submodule to tags (`v0.1.0`); add `TISH_REF` env for overrides |
| **Later** | Publish crates; switch to `cargo install tish` and remove submodule |

---

## build.sh Fix

`build.sh` line 36 references `tish-playground-compiler`, which does not exist in this repo. The justfile uses `tish_compiler_wasm` from the tish workspace. Update:

```bash
# Before (broken):
(cd "$PLAYGROUND_ROOT" && cargo build -p tish-playground-compiler ...)

# After:
(cd "$TISH_ROOT" && cargo build -p tish_compiler_wasm --target wasm32-unknown-unknown --release)
wasm-bindgen "$TISH_ROOT/target/wasm32-unknown-unknown/release/tish_compiler_wasm.wasm" \
  --out-dir "$PLAYGROUND_ROOT/public/dist" \
  --out-name tish_compiler \
  --target web
```

---

## Checklist

- [ ] Add tish as submodule or clone in install
- [ ] Fix `build.sh` to use `tish_compiler_wasm`
- [ ] Ensure Rust + `wasm32-unknown-unknown` + `wasm-bindgen-cli` available in Vercel build
- [ ] Remove `public/dist/` from `.gitignore` only if committing pre-built assets; otherwise keep ignored
- [ ] Set `GITHUB_TOKEN` in Vercel for private tish repo (if applicable)
- [ ] Enable "Include Git Submodules" in Vercel if using submodule
