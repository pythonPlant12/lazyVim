return {
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      delay = 100,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = {},
      },
      modes_allowlist = { "n" },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)

      local function set_illuminate_hl()
        local bg = vim.o.background == "light" and "#E6E6E6" or "#3A3A4A"
        vim.api.nvim_set_hl(0, "IlluminatedWordText",  { bg = bg, underline = false })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead",  { bg = bg, underline = false })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = bg, underline = false })
      end

      set_illuminate_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_illuminate_hl })
    end,
  },
}
