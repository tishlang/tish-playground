# Modular panels (Tishact + JSX)

All panels are **Tishact components** under [`app/panels/`](app/panels/). They use **JSX** only—no `document.createElement`, no `setAttribute`. The shell uses `createRoot` and composes these panels via `{EditorPanel(...)}`, etc.

## Current panels

| Module | Export | Responsibility |
|--------|--------|----------------|
| [`EditorPanel.tish`](app/panels/EditorPanel.tish) | `EditorPanel(apiRef)` | Textarea editor; fills `apiRef.current` with `{ getContent, setContent, setOnBlur }` |
| [`TerminalPanel.tish`](app/panels/TerminalPanel.tish) | `TerminalPanel(apiRef)` | Console output; fills `apiRef.current` with `{ appendLine, clear }` |
| [`FileBrowserPanel.tish`](app/panels/FileBrowserPanel.tish) | `FileBrowserPanel(paths, currentPath, onSelect)` | File list with selection |
| [`WebPreviewPanel.tish`](app/panels/WebPreviewPanel.tish) | `WebPreviewPanel(apiRef)` | Iframe + fallback pre; fills `apiRef.current` with `{ setText, runJs }` |

## How to swap a panel

1. Add a new Tishact/JSX component, e.g. `app/panels/EditorPanelCodemirror.tish`, exporting a function that returns JSX and uses `useRef`/`useLayoutEffect` to expose the same API via the given `apiRef`.
2. In [`app/shell.tish`](app/shell.tish), change the import and the JSX usage, e.g. `{EditorPanelCodemirror(editorApiRef)}`.
3. Rebuild: `just build-app`.

## Single-file compile

`POST /api/compile` parses **one** source string. Top-level `import` / `export` is not supported for bytecode in this path, so each virtual file must be runnable on its own. Use **main.tish** for primary examples; other tabs are extra buffers until the server merges a project graph.
