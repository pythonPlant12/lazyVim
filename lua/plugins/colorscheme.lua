local appearance = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("%s+", "")
local cs = appearance == "Dark" and "islands-dark" or "islands-light"

return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = cs,
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
      opts.scroll = opts.scroll or {}
      opts.scroll.enabled = false
      return opts
    end,
  },
}
