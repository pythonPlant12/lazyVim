# Frontend LSP Guide (JS/TS/Vue)

This Neovim config uses LazyVim with custom frontend LSP root logic.

## Active frontend LSP servers

- `vtsls`: primary TypeScript and JavaScript language server
- `vue_ls`: Vue single-file component language server (works together with `vtsls`)
- `eslint`: ESLint language server for lint diagnostics and fixes

Implementation locations:

- `lua/plugins/lsp.lua` (generic LSP behavior + `:CheckLsp` command)
- `lua/plugins/lsp-frontend.lua` (JS/TS/Vue + ESLint)
- `lua/plugins/lsp-backend.lua` (Python + Ruff + Pyright/BasedPyright)
- `lua/config/lsp_resolver.lua` (shared root and fallback logic)

## How root resolution works

This config computes roots from the current file directory and walks upward until the current Neovim working directory (`:pwd`).

- Workspace boundary: `workspace_root() = vim.fn.getcwd()`
- File walk helper: `ancestors_until(file_dir, workspace_root)`

### vtsls root markers

Nearest ancestor containing one of:

- `tsconfig.json`
- `jsconfig.json`
- `package.json`
- `pnpm-workspace.yaml`
- `pnpm-lock.yaml`
- `yarn.lock`
- `package-lock.json`
- `bun.lock`
- `bun.lockb`

### vue_ls root markers

Nearest ancestor containing one of:

- `nuxt.config.ts`
- `nuxt.config.js`
- `nuxt.config.mjs`
- `nuxt.config.cjs`
- `vue.config.js`
- `tsconfig.json`
- `jsconfig.json`
- `package.json`
- `pnpm-workspace.yaml`

### eslint root markers

`eslint_root()` prefers the nearest folder with ESLint config and boundary hints:

- ESLint config files: `eslint.config.*`, `.eslintrc*`, or `eslintConfig` in `package.json`
- Boundary files: `.gitignore` or `.eslintignore`
- If nothing better is found, fallback is the current Neovim cwd

## Monorepo example

Given:

- `project/frontend-project1/node_modules`
- `project/frontend-project1/tsconfig.json`
- `project/frontend-project1/file.ts`
- `project/frontend-project2/nested-project1/node_modules`
- `project/frontend-project2/nested-project1/tsconfig.json`
- `project/frontend-project2/nested-project1/eslintrc.js`
- `project/frontend-project2/nested-project1/file.ts`
- `project/frontend-project2/node_modules`
- `project/frontend-project2/tsconfig.json`
- `project/frontend-project2/file.ts`
- `project/frontend-project2/eslintrc.js`

If Neovim cwd is `project/`, opening each file will usually resolve to the nearest matching subproject:

- `frontend-project1/file.ts` -> `frontend-project1`
- `frontend-project2/nested-project1/file.ts` -> `frontend-project2/nested-project1`
- `frontend-project2/file.ts` -> `frontend-project2`

Important caveat: roots are bounded by your current `:pwd`. If you start Neovim from a deeper folder, root detection will not walk above that boundary.

## Check command

Use:

- `:CheckLsp`
- `:check-lsp` (alias)

The command shows:

- current cwd
- current file
- computed roots for `vtsls`, `vue_ls`, `eslint`
- attached clients and their active roots

## Pinned example output

```text
cwd: /Users/nikita/programming/airconsole/projects/airconsole-appengine
file: /Users/nikita/programming/airconsole/projects/airconsole-appengine/packages/store/src/utils/requestTimeout.js

computed roots:
  vtsls  -> /Users/nikita/programming/airconsole/projects/airconsole-appengine/packages/store
  vue_ls -> /Users/nikita/programming/airconsole/projects/airconsole-appengine/packages/store
  eslint -> /Users/nikita/programming/airconsole/projects/airconsole-appengine

attached clients:
  eslint -> /Users/nikita/programming/airconsole/projects/airconsole-appengine
  tailwindcss -> /Users/nikita/programming/airconsole/projects/airconsole-appengine/packages/store
  vtsls -> /Users/nikita/programming/airconsole/projects/airconsole-appengine/packages/store
```

---

# Rust LSP Guide

## Active Rust LSP servers

- `rust-analyzer` (via `rustaceanvim`): type inference, inline diagnostics, code actions
- `bacon-ls`: continuous background checker — pushes `cargo check`/`clippy` diagnostics without saving

Implementation locations:

- `lua/plugins/lang-rust.lua` (LazyVim rust extra + rustaceanvim overrides)
- `lua/plugins/lsp-rust.lua` (bacon-ls + rust-analyzer experimental settings)

## How it works

`rust-analyzer` provides real-time diagnostics from its own analysis engine (type mismatches, borrow checker via `experimental.enable = true`). These update as you type.

`bacon` runs `cargo check` continuously in the background as a separate process. `bacon-ls` reads its output and pushes the results into Neovim as LSP diagnostics. This replaces the default `checkOnSave` behavior, so you get compiler errors without needing to save.

`checkOnSave = false` is set in `lang-rust.lua` so `rustaceanvim` does not run a competing `cargo check`.

## Setup (one-time per machine)

Install `bacon` and `bacon-ls` via mason (`:MasonInstall bacon bacon-ls`), or globally:

```sh
cargo install bacon bacon-ls
```

Then in each Rust project root, start bacon in a terminal:

```sh
bacon
```

bacon writes its output to `.bacon-locations` which `bacon-ls` reads automatically.

## Check command

Use `:CheckLsp` to see attached clients and their roots for the current buffer.
