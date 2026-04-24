return {
  { import = "lazyvim.plugins.extras.lang.rust" },
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = false,
          },
        },
      },
    },
  },
}
