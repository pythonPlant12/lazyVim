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
      views = {
        cmdline_popup = {
          border = { style = "rounded" },
        },
        popupmenu = {
          border = { style = "rounded" },
        },
        hover = {
          border = { style = "rounded" },
        },
      },
    },
  },
}
