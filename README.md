# Tish playground

Minimal web playground: **UI in Tish** (compiled to JS), **user code** compiled and run **100% in the browser** (VM WASM + compiler WASM). Dev server written in Tish.

## Layout

| Path | Role |
|------|------|
| [`app/`](app/) | Tish sources (`main.tish`, `shell.tish`, modular `panels/`) |
| [`public/`](public/) | Static assets: `index.html`, `playground.css`, generated `playground.js`, `tish_vm*.wasm`, `tish_compiler*.wasm` |
| [`compiler-wasm/`](compiler-wasm/) | Rust crate: tish compiler as WASM for browser |
| [`dev-server.tish`](dev-server.tish) | Static file server (Tish) for local dev |

## Prerequisites

- [Rust](https://rustup.rs/) + `just` (optional)
- [`wasm-bindgen-cli`](https://rustwasm.github.io/wasm-bindgen/reference/cli.html): `cargo install wasm-bindgen-cli`
- `rustup target add wasm32-unknown-unknown`
- Sibling checkout of **Tish** (default: `../tish`). Override with `TISH_ROOT`.

**Local Tish development**: The playground uses the local tish repo (not npm). After pulling tish changes, run `npm run install-tish` to reinstall the CLI, then `npm run verify` to confirm JSX text (e.g. `<h1>Web preview works!</h1>`) compiles correctly.

## Build & run

```bash
just dev
```

Builds the UI, VM WASM, and compiler WASM, then serves **http://127.0.0.1:8765** via the Tish dev server.

Individual steps:

```bash
just build-app      # Tish → public/dist/playground.js
just build-vm       # tish_wasm_runtime → public/dist/tish_vm*.wasm
just build-compiler # tish-playground-compiler → public/dist/tish_compiler*.wasm
```

## Swapping panels

See [`PANELS.md`](PANELS.md).

## License

Same as the parent Tish project unless you specify otherwise.
