local state_file = vim.fn.stdpath("state") .. "/theme"
local f = io.open(state_file, "r")
local cs
local catppuccin_flavour = "mocha"

if f then
  local saved = f:read("*l")
  f:close()
  if saved and saved ~= "" then
    saved = saved:gsub("%s+", "")
    if saved:match("^catppuccin:") then
      catppuccin_flavour = saved:sub(12)
      cs = "catppuccin"
    else
      cs = saved
    end
  end
end

if not cs then
  local appearance = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("%s+", "")
  cs = appearance == "Dark" and "islands-dark" or "islands-light"
end

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
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      flavour = catppuccin_flavour,
    },
  },
}
