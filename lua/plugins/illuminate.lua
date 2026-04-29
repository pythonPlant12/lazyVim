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
    end,
  },
}
