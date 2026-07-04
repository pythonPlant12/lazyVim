return {
  { import = "lazyvim.plugins.extras.lang.rust" },
  {
    "mrcjkb/rustaceanvim",
    opts = {
      server = {
        -- Run the stable rust-analyzer explicitly; bacon handles save-time checks.
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
