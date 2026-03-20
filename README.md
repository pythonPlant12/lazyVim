# Frontend LSP Guide (JS/TS/Vue)

This Neovim config uses LazyVim with custom frontend LSP root logic.

## Active frontend LSP servers

- `vtsls`: primary TypeScript and JavaScript language server
- `vue_ls`: Vue single-file component language server (works together with `vtsls`)
- `eslint`: ESLint language server for lint diagnostics and fixes

Implementation location:

- `lua/plugins/lsp.lua`

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
