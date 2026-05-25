return {
  { import = "lazyvim.plugins.extras.lang.rust" },
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        cmd = { "rustup", "run", "stable", "rust-analyzer" },
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = false,
          },
        },
      },
    },
  },
}
