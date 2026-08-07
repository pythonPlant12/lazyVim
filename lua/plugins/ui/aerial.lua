-- Aerial: symbol outline used for the winbar breadcrumb; filters noisy symbol kinds.
return {
  {
    "stevearc/aerial.nvim",
    opts = {
      -- Per-filetype allow-list. "_" is the default for all other filetypes.
      -- Vue/HTML exclude Struct: template elements and custom component tags
      -- are reported as Struct by the LSP and add noise to the breadcrumb.
      filter_kind = {
        _ = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct" },
        vue  = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method" },
        html = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method" },
      },
    },
  },
}
