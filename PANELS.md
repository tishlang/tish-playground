# Modular panels (Lattish + JSX)

All panels are **Lattish components** now extracted into the `@tishlang/tish-ide-panels` package. The source is located in `../tish-ide-panels/src/`. They use **JSX** only—no `document.createElement`, no `setAttribute`. Import hooks (or other symbols) from the **lattish** package (`import { ... } from 'lattish'`); the merged bundle supplies the JSX runtime. For JSX-only panels, `import {} from 'lattish'` pulls the module in with no extra bindings. The shell uses `createRoot` and composes panels via `{EditorPanel(...)}`, etc.

## Current panels

| Module | Export | Responsibility |
|--------|--------|----------------|
| `EditorPanel.tish` | `EditorPanel(apiRef)` | Textarea + highlight; undo/redo (⌘/Ctrl+Z, ⇧⌘Z / Ctrl+Y); `apiRef.current` = `{ getContent, setContent, setOnBlur }` |
| `TerminalPanel.tish` | `TerminalPanel(apiRef)` | Console output; fills `apiRef.current` with `{ appendLine, clear }` |
| `FileBrowserPanel.tish` | `FileBrowserPanel(paths, currentPath, onSelect)` | File list with selection |
| `WebPreviewPanel.tish` | `WebPreviewPanel(apiRef)` | Iframe + fallback pre; fills `apiRef.current` with `{ setText, runJs }` |

## How to swap a panel

1. Add a new Lattish/JSX component, e.g. in `tish-ide-panels`, exporting a function that returns JSX and uses `useRef`/`useLayoutEffect` to expose the same API via the given `apiRef`.
2. In the `SandboxIde` or shell component, change the import and the JSX usage, e.g. `{EditorPanelCodemirror(editorApiRef)}`.
3. Rebuild the app: `just build-app` (or rebuild `tish-ide-panels` if making changes there).

## Imports and virtual files

Compile runs **100% in the browser** (compiler WASM). The playground supports top-level `import` and `export` across virtual files. When you Run, the compiler resolves imports from the file map (main.tish, lib.tish) and merges them into a single program for bytecode and JS targets.
