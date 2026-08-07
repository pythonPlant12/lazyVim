# Config reorganization plan (in progress)

Goal: modular repo — one plugin per file, big custom logic in feature modules,
each theme fully defined in one file, everything briefly commented, nothing broken.

## Target layout

```
init.lua                  -- bootstraps lua/config/lazy.lua
colors/<theme>.lua        -- ONE complete theme per file: palette, UI/plugin/git/diff
                          -- colors, lualine palette, transparency. Source of truth.
lua/
  config/                 -- options, lazy.nvim setup, entry delegators
  plugins/                -- lazy.nvim specs, ONE plugin per file
    ai/                   -- copilot, copilot-chat, avante
    coding/               -- blink-cmp, comment, surround, inc-rename, ts-context,
                          -- multicursor, illuminate, folds, rainbow, colorizer
    editor/               -- bookmarks, markdown-preview, grug-far/scooter
    git/                  -- gitsigns, undotree
    lang/                 -- lsp core + java, rust, backend(py), frontend, html,
                          -- formatting, testing
    ui/                   -- statusline, neo-tree, pickers, icons, bufferline,
                          -- noice, snacks, trouble, which-key
    themes.lua            -- catppuccin + rose-pine plugin specs, colorscheme pick
  themes/
    engine/               -- theme machinery (was autocmds/highlights.lua):
                          -- applies a theme's declared colors to plugin UIs,
                          -- transparency, cursor, keyword/semantic normalization
    semantic.lua          -- token-group registry (kept)
  features/               -- big custom logic, one module per feature
                          -- (lazygit edit, window resize mode, stub generator,
                          --  search grep, tab jump, lsp resolver, git statusline)
  keymaps/                -- thin bindings that call features/
  autocmds/               -- small event glue, no theme code
  lsp/                    -- server settings modules
```

## Phases

- [x] A. Survey + plan
- [x] B. Mechanical plugin splits (one plugin per file, subdir imports, drop
      ui.lua/ui/core.lua shim, delete example.lua)
- [x] C. Themes: move per-theme conditionals (statusline palettes, rose-pine
      dawn block, transparency lists) into colors/<theme>.lua declared data;
      highlights.lua becomes generic engine under lua/themes/engine/
- [x] D. Extract big logic from keymaps into features/
- [x] E. Simplify git diff view return-to-file logic (debug with user)
- [x] F. Dead code cleanup + 2-line plain-language comments everywhere
- [ ] G. Full verification with user. NO commit/push until user OK.

## Key wiring facts (for anyone reading later)

- lazy.nvim imports: config/lazy.lua `{ import = "plugins" }` + per-subdir imports.
- Each colors/<theme>.lua publishes `vim.g.theme_custom_hl` (+ new
  `vim.g.theme_lualine`); the engine consumes those, with generic fallbacks
  derived from standard highlight groups for external themes (catppuccin,
  rose-pine).
- Theme switch: `<leader>ut` picker persists to stdpath("state")/theme, read at
  startup by plugins/colorscheme bootstrap.
