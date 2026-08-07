-- Bufferline shows one tab per Neovim tabpage, colored to match the active theme.
return {
  {
    "akinsho/bufferline.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        mode = "tabs",
        separator_style = { "│", "│" },
        show_buffer_close_icons = false,
        show_close_icon = false,
        indicator = { style = "none" },
        diagnostics = false,
      })
      -- Bufferline acts as a tabline; each theme owns its tab colors.
      local palette = require("themes.tabline_palette").get

      -- Map palette colors onto every bufferline tab highlight group.
      local function tab_highlights()
        local c = palette()
        return {
          fill                    = { bg = c.bg },
          background              = { fg = c.muted, bg = c.bg },
          tab                     = { fg = c.muted, bg = c.bg },
          tab_selected            = { fg = c.active_fg, bg = c.active_bg, bold = true },
          tab_separator           = { fg = c.border, bg = c.bg },
          tab_separator_selected  = { fg = c.active_bg, bg = c.bg },
          tab_close               = { fg = c.muted, bg = c.bg },
          buffer_selected         = { fg = c.active_fg, bg = c.active_bg, bold = true, italic = false },
          buffer_visible          = { fg = c.fg, bg = c.bg, italic = false },
          numbers_selected        = { fg = c.active_fg, bg = c.active_bg, bold = true },
          numbers_visible         = { fg = c.fg, bg = c.bg },
          close_button            = { fg = c.muted, bg = c.bg },
          close_button_visible    = { fg = c.muted, bg = c.bg },
          close_button_selected   = { fg = c.active_fg, bg = c.active_bg },
          indicator_selected      = { fg = c.active_bg, bg = c.active_bg },
          indicator_visible       = { fg = c.bg, bg = c.bg },
          separator               = { fg = c.border, bg = c.bg },
          separator_selected      = { fg = c.active_bg, bg = c.bg },
          separator_visible       = { fg = c.border, bg = c.bg },
          duplicate_selected      = { fg = c.active_fg, bg = c.active_bg, bold = true, italic = false },
          duplicate               = { fg = c.muted, bg = c.bg, italic = false },
          duplicate_visible       = { fg = c.muted, bg = c.bg, italic = false },
          modified_selected       = { fg = c.active_fg, bg = c.active_bg, italic = false },
          modified                = { fg = c.muted, bg = c.bg, italic = false },
          modified_visible        = { fg = c.muted, bg = c.bg, italic = false },
        }
      end

      opts.highlights = tab_highlights()
      -- Recompute tab colors whenever the colorscheme changes.
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local ok, bufferline = pcall(require, "bufferline")
          if ok then
            opts.highlights = tab_highlights()
            bufferline.setup(opts)
          end
        end,
      })
      return opts
    end,
  },
}
