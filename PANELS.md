# Modular panels (Lattish + JSX)

All panels are **Lattish components** under [`app/panels/`](app/panels/). They use **JSX** only—no `document.createElement`, no `setAttribute`. Import hooks (or other symbols) from the **lattish** package (`import { ... } from 'lattish'`); the merged bundle supplies the JSX runtime. For JSX-only panels, `import {} from 'lattish'` pulls the module in with no extra bindings. The shell uses `createRoot` and composes panels via `{EditorPanel(...)}`, etc.

## Current panels

| Module | Export | Responsibility |
|--------|--------|----------------|
| [`EditorPanel.tish`](app/panels/EditorPanel.tish) | `EditorPanel(apiRef)` | Textarea + highlight; undo/redo (⌘/Ctrl+Z, ⇧⌘Z / Ctrl+Y); `apiRef.current` = `{ getContent, setContent, setOnBlur }` |
| [`TerminalPanel.tish`](app/panels/TerminalPanel.tish) | `TerminalPanel(apiRef)` | Console output; fills `apiRef.current` with `{ appendLine, clear }` |
| [`FileBrowserPanel.tish`](app/panels/FileBrowserPanel.tish) | `FileBrowserPanel(paths, currentPath, onSelect)` | File list with selection |
| [`WebPreviewPanel.tish`](app/panels/WebPreviewPanel.tish) | `WebPreviewPanel(apiRef)` | Iframe + fallback pre; fills `apiRef.current` with `{ setText, runJs }` |

## How to swap a panel

1. Add a new Lattish/JSX component, e.g. `app/panels/EditorPanelCodemirror.tish`, exporting a function that returns JSX and uses `useRef`/`useLayoutEffect` to expose the same API via the given `apiRef`.
2. In [`app/shell.tish`](app/shell.tish), change the import and the JSX usage, e.g. `{EditorPanelCodemirror(editorApiRef)}`.
3. Rebuild: `just build-app`.

## Imports and virtual files

Compile runs **100% in the browser** (compiler WASM). The playground supports top-level `import` and `export` across virtual files. When you Run, the compiler resolves imports from the file map (main.tish, lib.tish) and merges them into a single program for bytecode and JS targets.
