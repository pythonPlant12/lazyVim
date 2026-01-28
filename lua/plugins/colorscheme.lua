return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "islands-dark",
    },
  },
  {
    "folke/snacks.nvim",
    priority = 1000,
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.styles = opts.styles or {}
      opts.styles.transparency = false
      return opts
    end,
  },
}
