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
  cs = appearance == "Dark" and "default-dark" or "default-white"
end

do
  local light_schemes = {
    ["default-white"] = true,
    ["islands-white"] = true,
    ["islands-light"] = true,
    ["islands-rose-pine-light"] = true,
    ["rose-pine-dawn"] = true,
  }
  local is_light = light_schemes[cs] or (cs == "catppuccin" and catppuccin_flavour == "latte")
  vim.o.background = is_light and "light" or "dark"
  if cs == "default-white" or cs == "islands-white" or cs == "islands-light" then
    vim.g._lualine_theme_hint = "islands-light"
  elseif cs == "default-dark" or cs == "islands-dark" then
    vim.g._lualine_theme_hint = "islands-dark"
  else
    vim.g._lualine_theme_hint = cs:find("^islands") and ("islands-" .. (is_light and "light" or "dark")) or "auto"
  end
end

local function is_transparent_theme_name(name)
  return name == "islands-dark"
    or name == "islands-white"
    or name == "islands-light"
    or name:find("^islands%-rose%-pine") ~= nil
end

do
  local blend = is_transparent_theme_name(cs) and 10 or 0
  vim.o.winblend = blend
  vim.o.pumblend = blend
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
      local transparent = is_transparent_theme_name(cs)
      local blend = transparent and 10 or 0

      opts.styles = opts.styles or {}
      local function merge_style(name, style)
        opts.styles[name] = vim.tbl_deep_extend("force", opts.styles[name] or {}, style)
      end

      for _, name in ipairs({
        "float",
        "help",
        "input",
        "lazygit",
        "notification",
        "notification_history",
        "scratch",
        "snacks_image",
        "terminal",
      }) do
        merge_style(name, {
          backdrop = transparent and nil or false,
          wo = { winblend = blend },
        })
      end

      opts.picker = opts.picker or {}
      opts.picker.win = opts.picker.win or {}
      for _, name in ipairs({ "input", "list", "preview" }) do
        opts.picker.win[name] = vim.tbl_deep_extend("force", opts.picker.win[name] or {}, {
          wo = { winblend = blend },
        })
      end

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
      no_bold = true,
      no_italic = true,
    },
  },
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {
      styles = {
        italic = false,
        bold = false,
      },
    },
  },
}
