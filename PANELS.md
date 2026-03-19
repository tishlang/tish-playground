# Modular panels

Each UI region is a **separate Tish module** under [`app/panels/`](app/panels/) with a **unique exported function name** (the JS merge emits one flat file; multiple `export fn render` would collide).

## Current exports

| Module | Export | Responsibility |
|--------|--------|----------------|
| [`editor.tish`](app/panels/editor.tish) | `renderEditor(parent)` | Returns `{ getContent, setContent }` |
| [`terminal.tish`](app/panels/terminal.tish) | `renderTerminal(parent)` | Returns `{ appendLine, clear }` |
| [`file_browser.tish`](app/panels/file_browser.tish) | `renderFileBrowser(parent, paths, onSelect)` | Renders virtual file buttons |
| [`web_preview.tish`](app/panels/web_preview.tish) | `renderWebPreview(parent)` | Returns `{ setText }` for stdout mirror |

## How to swap a panel

1. Add a new file, e.g. `app/panels/editor_codemirror.tish`, exporting **`renderEditor`** (or pick a new name and update the shell import).
2. In [`app/shell.tish`](app/shell.tish), change the import line:

   ```tish
   import { renderEditor } from "./panels/editor_codemirror.tish"
   ```

3. Rebuild: `just build-app`.

The shell does **not** import panel internals—only the stable entry function—so replacements stay isolated.

## Web preview

Today the preview duplicates terminal output (plain text). A future implementation could use an `<iframe>` `srcdoc` or sandboxed document for visual user output once the runtime exposes DOM or a dedicated preview channel.

## Single-file compile

`POST /api/compile` parses **one** source string. Top-level `import` / `export` is not supported for bytecode in this path, so each virtual file must be runnable on its own. Use **main.tish** for primary examples; other tabs are extra buffers until the server merges a project graph.
