-- Colorscheme bootstrap: pick/persist the theme, sync background & transparency, then configure providers (catppuccin, rose-pine, snacks).
-- Theme selection is persisted in state so <leader>ut survives restarts.
local state_file = vim.fn.stdpath("state") .. "/theme"
local f = io.open(state_file, "r")
local cs
local catppuccin_flavour = "mocha"

local valid_schemes = {
  ["default-dark"] = true,
  ["default-light"] = true,
  ["islands-dark"] = true,
  ["islands-white"] = true,
  ["islands-light"] = true,
  ["islands-rose-pine-dark"] = true,
  ["islands-rose-pine-light"] = true,
  ["cursor-dark"] = true,
  ["cursor-dark-midnight"] = true,
  ["cursor-light"] = true,
  ["rose-pine"] = true,
  ["rose-pine-dawn"] = true,
  ["rose-pine-moon"] = true,
  ["rose-pine-dark-dimmed"] = true,
}

if f then
  local saved = f:read("*l")
  f:close()
  if saved and saved ~= "" then
    saved = saved:gsub("%s+", "")
    if saved:match("^catppuccin:") then
      catppuccin_flavour = saved:sub(12)
      cs = "catppuccin"
    elseif valid_schemes[saved] then
      cs = saved
    end
  end
end

-- No saved theme: match the macOS light/dark appearance.
if not cs then
  local appearance = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("%s+", "")
  cs = appearance == "Dark" and "default-dark" or "default-light"
end

-- Set background/lualine hint before UI plugins derive their palettes.
do
  local light_schemes = {
    ["default-light"] = true,
    ["islands-white"] = true,
    ["islands-light"] = true,
    ["islands-rose-pine-light"] = true,
    ["rose-pine-dawn"] = true,
    ["cursor-light"] = true,
  }
  local is_light = light_schemes[cs] or (cs == "catppuccin" and catppuccin_flavour == "latte")
  vim.o.background = is_light and "light" or "dark"
  if cs == "cursor-dark" or cs == "cursor-dark-midnight" or cs == "cursor-light" then
    vim.g._lualine_theme_hint = cs
  elseif cs == "default-light" or cs == "islands-white" or cs == "islands-light" then
    vim.g._lualine_theme_hint = "islands-light"
  elseif cs == "default-dark" or cs == "islands-dark" then
    vim.g._lualine_theme_hint = "islands-dark"
  else
    vim.g._lualine_theme_hint = cs:find("^islands") and ("islands-" .. (is_light and "light" or "dark")) or "auto"
  end
end

-- Transparent themes need blended popups; opaque themes should stay solid.
local function is_transparent_theme_name(name)
  return name == "islands-dark"
    or name == "islands-white"
    or name == "islands-light"
    or name == "islands-rose-pine-dark"
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

      -- Keep Snacks float/picker opacity aligned with the active theme.
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
      -- Disable animated scroll to keep cursor movement smooth.
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
      palette = {
        dawn = {
          _nc = "#fbfbfd",
          base = "#fbfbfd",
          surface = "#fbfbfd",
          overlay = "#f1f2f5",
          muted = "#6f6a7f",
          subtle = "#8e899b",
          text = "#4f4a63",
          love = "#a34655",
          gold = "#8a6b35",
          rose = "#9f5572",
          pine = "#68647a",
          foam = "#6f6a7f",
          iris = "#7d5fa6",
          leaf = "#5f7f52",
          highlight_low = "#f1f2f5",
          highlight_med = "#dedcf0",
          highlight_high = "#cec9d6",
        },
      },
      before_highlight = function(group, highlight, palette)
        if palette.base ~= "#fbfbfd" then
          return
        end

        local overrides = {
          String = { fg = "#5f7f52" },
          Character = { fg = "#5f7f52" },
          ["@string"] = { fg = "#5f7f52" },
          Directory = { fg = "#4f4a63", bold = true },
          NormalFloat = { fg = "#4f4a63", bg = "#fbfbfd" },
          Pmenu = { fg = "#4f4a63", bg = "#fbfbfd" },
        }
        if overrides[group] then
          highlight.link = nil
          for key, value in pairs(overrides[group]) do
            highlight[key] = value
          end
        end
      end,
      styles = {
        italic = false,
        bold = false,
      },
    },
  },
}
