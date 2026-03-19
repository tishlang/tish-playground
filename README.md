# Tish playground

Minimal web playground: **UI in Tish** (compiled to JavaScript with legacy DOM), **user code** compiled to bytecode by a small Rust server and executed in the **Tish VM** as WebAssembly.

## Layout

| Path | Role |
|------|------|
| [`app/`](app/) | Tish sources (`main.tish`, `shell.tish`, modular `panels/`) |
| [`public/`](public/) | Static assets: `index.html`, `playground.css`, generated `playground.js`, `tish_vm*.wasm` |
| [`server/`](server/) | Axum app: `POST /api/compile` + static file fallback |

## Prerequisites

- [Rust](https://rustup.rs/) + `just` (optional but recommended)
- [`wasm-bindgen-cli`](https://rustwasm.github.io/wasm-bindgen/reference/cli.html): `cargo install wasm-bindgen-cli`
- `rustup target add wasm32-unknown-unknown`
- Sibling checkout of the **Tish** compiler repo (default: `../tish` relative to this directory). Override with `TISH_ROOT`.

## Build & run

```bash
just dev
```

This sets `CARGO_TARGET_DIR` to `./target`, builds the UI (`tish compile … --target js --jsx legacy`), builds the VM WASM + bindgen output, builds the server, then serves **http://127.0.0.1:8765** (open `/` for the app, `/api/compile` for the API).

Individual steps:

```bash
just build-app     # Tish → public/playground.js
just build-vm      # tish_wasm_runtime → public/tish_vm.js + tish_vm_bg.wasm
just build-server  # ./target/release/tish-playground-server
```

## Swapping panels

See [`PANELS.md`](PANELS.md).

## Limitations

- **Compile API** accepts a **single** source string (the active editor tab). `import` / `export` are not supported on that bytecode path yet; each buffer should be a self-contained program. Multi-file **project** compile can be added to the server later.

## Note: browser WASM build

The VM crate needs `getrandom` with the `wasm_js` feature on `wasm32-unknown-unknown`. This repo expects the Tish workspace to include the extra dependency on `tish_wasm_runtime` (see that crate’s `Cargo.toml`). If you use an older Tish tree without it, `just build-vm` may fail until you add the same stanza.

## License

Same as the parent Tish project unless you specify otherwise.
