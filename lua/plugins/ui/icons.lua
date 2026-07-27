-- Language icons use explicit colors so file chips stay readable across themes.
local language_icon_theme_colors = {
  ["default-dark"] = { typescript = "#4FA6E8", javascript = "#F0D55C", python = "#5DADE2" },
  ["cursor-dark"] = { typescript = "#87C3FF", javascript = "#F8C762", python = "#88C0D0" },
  ["cursor-dark-midnight"] = { typescript = "#81A1C1", javascript = "#EBCB8B", python = "#88C0D0" },
  ["cursor-light"] = { typescript = "#005293", javascript = "#A8552A", python = "#176C74" },
  ["default-light"] = { typescript = "#256FB8", javascript = "#B8860B", python = "#2F6F9F" },
  ["default-white"] = { typescript = "#256FB8", javascript = "#B8860B", python = "#2F6F9F" },
  ["islands-dark"] = { typescript = "#4FA6E8", javascript = "#F0D55C", python = "#5DADE2" },
  ["islands-light"] = { typescript = "#256FB8", javascript = "#B8860B", python = "#2F6F9F" },
  ["islands-white"] = { typescript = "#256FB8", javascript = "#B8860B", python = "#2F6F9F" },
  ["islands-rose-pine-dark"] = { typescript = "#4FA6E8", javascript = "#E8D05A", python = "#5BA8D9" },
  ["islands-rose-pine-light"] = { typescript = "#7d5fa6", javascript = "#8b5f85", python = "#68647a" },
  ["rose-pine"] = { typescript = "#4FA6E8", javascript = "#E8D05A", python = "#5BA8D9" },
  ["rose-pine-main"] = { typescript = "#4FA6E8", javascript = "#E8D05A", python = "#5BA8D9" },
  ["rose-pine-moon"] = { typescript = "#66B2EA", javascript = "#EAD56A", python = "#6DB2DE" },
  ["rose-pine-dark-dimmed"] = { typescript = "#6e9eb0", javascript = "#a89780", python = "#476991" },
  ["rose-pine-dawn"] = { typescript = "#2F76B7", javascript = "#9A7600", python = "#286B96" },
  ["catppuccin"] = { typescript = "#89B4FA", javascript = "#F9E2AF", python = "#74C7EC" },
  ["catppuccin-mocha"] = { typescript = "#89B4FA", javascript = "#F9E2AF", python = "#74C7EC" },
  ["catppuccin-macchiato"] = { typescript = "#8AADF4", javascript = "#EED49F", python = "#7DC4E4" },
  ["catppuccin-frappe"] = { typescript = "#8CAAEE", javascript = "#E5C890", python = "#99D1DB" },
  ["catppuccin-latte"] = { typescript = "#1E66F5", javascript = "#A17900", python = "#209FB5" },
}

-- Pick the icon color set for the active colorscheme, defaulting to islands-dark.
local function language_icon_colors()
  local theme = vim.g.colors_name or ""
  return language_icon_theme_colors[theme] or language_icon_theme_colors["islands-dark"]
end

local function apply_language_icon_hl()
  -- Reapply after colorscheme changes because MiniIcons highlight groups are global.
  local colors = language_icon_colors()
  vim.api.nvim_set_hl(0, "MiniIconsLanguageTypeScript", { fg = colors.typescript })
  vim.api.nvim_set_hl(0, "MiniIconsLanguageJavaScript", { fg = colors.javascript })
  vim.api.nvim_set_hl(0, "MiniIconsLanguagePython", { fg = colors.python })
end

local function language_icon_extension_overrides()
  -- MiniIcons defaults are adjusted for common TS/JS/Python variants.
  return {
    ts = { glyph = "󰛦", hl = "MiniIconsLanguageTypeScript" },
    tsx = { glyph = "", hl = "MiniIconsLanguageTypeScript" },
    mts = { glyph = "󰛦", hl = "MiniIconsLanguageTypeScript" },
    cts = { glyph = "󰛦", hl = "MiniIconsLanguageTypeScript" },
    js = { glyph = "󰌞", hl = "MiniIconsLanguageJavaScript" },
    jsx = { glyph = "", hl = "MiniIconsLanguageJavaScript" },
    mjs = { glyph = "󰌞", hl = "MiniIconsLanguageJavaScript" },
    cjs = { glyph = "󰌞", hl = "MiniIconsLanguageJavaScript" },
    py = { glyph = "󰌠", hl = "MiniIconsLanguagePython" },
    pyi = { glyph = "󰌠", hl = "MiniIconsLanguagePython" },
  }
end

return {
  {
    "LazyVim/LazyVim",
    opts = {
      icons = {
        -- Kind icons are shared by completion, breadcrumbs, and diagnostics UI.
        kinds = {
          Text          = "󰉿 ",
          Method        = "󰆧 ",
          Function      = "󰊕 ",
          Constructor   = "󰊓 ",
          Field         = "󰆧 ",
          Variable      = "󰆦 ",
          Class         = "󰠱 ",
          Interface     = "󰜰 ",
          Module        = "󰅩 ",
          Property      = "󰆧 ",
          Unit          = "󰑭 ",
          Value         = "󰎠 ",
          Enum          = "󰍜 ",
          Keyword       = "󰌋 ",
          Snippet       = "󰅧 ",
          Color         = "󰏘 ",
          File          = "󰈙 ",
          Reference     = "󰈇 ",
          Folder        = "󰉋 ",
          EnumMember    = "󰲣 ",
          Constant      = "󰏿 ",
          Struct        = "󰙅 ",
          Event         = "󰑧 ",
          Operator      = "󰆕 ",
          TypeParameter = "󰬛 ",
          Array         = " ",
          Boolean       = "󰨙 ",
          Key           = " ",
          Namespace     = "󰦮 ",
          Null          = " ",
          Number        = "󰎠 ",
          Object        = " ",
          Package       = " ",
          String        = " ",
        },
      },
    },
  },
  {
    "nvim-mini/mini.icons",
    opts = function(_, opts)
      opts.extension = vim.tbl_deep_extend("force", opts.extension or {}, language_icon_extension_overrides())
      return opts
    end,
    init = function()
      apply_language_icon_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("LanguageFileIconHl", { clear = true }),
        callback = function()
          vim.schedule(apply_language_icon_hl)
        end,
      })
    end,
  },
}
