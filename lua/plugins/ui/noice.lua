-- Noice: nicer command line, messages, and LSP popups with rounded borders.
return {
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      -- Throttle UI updates to reduce error frequency and avoid the panic/auto-disable threshold.
      throttle = 1000 / 30,
      -- winblend 0 keeps text behind the popup hidden; transparent themes set
      -- a global winblend of 10, which these floats would otherwise inherit.
      views = {
        cmdline_popup = {
          border = { style = "rounded" },
          win_options = { winblend = 0 },
        },
        popupmenu = {
          border = { style = "rounded" },
          win_options = { winblend = 0 },
        },
        hover = {
          border = { style = "rounded" },
          win_options = { winblend = 0 },
        },
      },
    },
  },
}
