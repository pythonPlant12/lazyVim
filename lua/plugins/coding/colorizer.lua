-- Colorizer: shows color codes (#RRGGBB, rgb(), names) painted in their color.
return {
  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = { "*" },
      options = {
        parsers = {
          css = true,
          tailwind = {
            enable = true,
            lsp = { enable = true },
            update_names = true,
          },
        },
        display = {
          mode = "virtualtext",
          virtualtext = {
            char = "■",
            position = "after",
          },
        },
      },
    },
  },
}
