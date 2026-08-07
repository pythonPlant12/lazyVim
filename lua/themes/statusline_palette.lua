-- Statusline colors for the active theme.
-- Each theme file publishes `vim.g.theme_custom_hl.statusline` with its own
-- colors; anything missing falls back to the light/dark defaults below, so
-- external themes (catppuccin, rose-pine) work without their own block.
local M = {}

-- Mode chip colors used when a theme doesn't declare its own.
local mode_light = {
  normal   = { fg = "#2F496F", bg = "#D2E4F5" },
  insert   = { fg = "#34523E", bg = "#D8E8DA" },
  visual   = { fg = "#342F67", bg = "#DDD9F7" },
  replace  = { fg = "#672D2D", bg = "#F5DADA" },
  command  = { fg = "#5A3A1A", bg = "#F0E0C8" },
}
local mode_dark = {
  normal   = { fg = "#E8F0FA", bg = "#2F496F" },
  insert   = { fg = "#EFF3F0", bg = "#34523E" },
  visual   = { fg = "#ECEBFB", bg = "#342F67" },
  replace  = { fg = "#FCF0F0", bg = "#672D2D" },
  command  = { fg = "#F5E8D0", bg = "#5A3A1A" },
}

-- Special editor states shown in the mode chip (macro recording, multicursor,
-- window resize). Any theme can override these in its statusline.states block.
local states_light = {
  recording         = { fg = "#5C1423", bg = "#F2B8C1" },
  multicursor_build = { fg = "#4F3800", bg = "#F4D58D" },
  resize            = { fg = "#5A2E00", bg = "#F1C7A6" },
  multicursor       = { fg = "#1B4D4A", bg = "#BFE7E3" },
}
local states_dark = {
  recording         = { fg = "#2B060D", bg = "#E37B8C" },
  multicursor_build = { fg = "#211600", bg = "#F2C14E" },
  resize            = { fg = "#271000", bg = "#E6985A" },
  multicursor       = { fg = "#081F1D", bg = "#7AD7CD" },
}

local defaults_light = {
  surface = "#F3F3F3",
  fg = "#4C4F69",
  muted = "#7A7880",
  mode = mode_light,
  states = states_light,
  git  = { bg = "#6B3CC8", fg = "#FFFFFF", green = "#7CA686", yellow = "#A8983A", peach = "#C87A3A", red = "#B85C5C" },
  diag = { cap = "#D5D0CA", bg = "#D5D0CA", base = "#7A7880", error = "#B85C5C", warn = "#A8983A", info = "#5A8FD4", hint = "#7CA686", cap_bg = "#E2DFDB", container = "#D5D0CA" },
  lsp  = { bg = "#D5D0CA", base = "#7A7880",
           on = "#7B72C9", spinner = "#A8983A", green = "#7CA686", yellow = "#A8983A", off = "#7A7880" },
  chips = { bgs = { "#D5D0CA", "#D5D0CA", "#D5D0CA" }, fg = "#4C4F69", arrow = "#2F3147", sep = "#9B9792" },
  path = { fg = "#FFFFFF", bg = "#2A6296" },
}

local defaults_dark = {
  surface = "#2B2D30",
  fg = "#BCBEC4",
  muted = "#6F737A",
  mode = mode_dark,
  states = states_dark,
  git  = { bg = "#cba6f7", fg = "#151619", green = "#a6e3a1", yellow = "#f9e2af", peach = "#fab387", red = "#f38ba8" },
  diag = { cap = "#313438", bg = "#313438", base = "#BCBEC4", error = "#f38ba8", warn = "#f9e2af", info = "#89b4fa", hint = "#a6e3a1", cap_bg = "#2B2D30", container = "#2B2D30" },
  lsp  = { bg = "#45475a", base = "#93a1a1",
           on = "#cba6f7", spinner = "#f9e2af", green = "#a6e3a1", yellow = "#f9e2af", off = "#586e75" },
  chips = { bgs = { "#3A3D41", "#42464D", "#4A4F57" }, fg = "#CED0D6", arrow = "#DCE0E8", sep = "#6B6F75" },
  path = { fg = "#151619", bg = "#9ccfd8" },
}

-- Per-server LSP chip colors (defaults; a theme may override via lsp.servers).
M.lsp_servers_dark = {
  vtsls = "#89b4fa", ts_ls = "#89b4fa", tsserver = "#89b4fa",
  vue_ls = "#a6e3a1", volar = "#a6e3a1", tailwindcss = "#94e2d5",
  lua_ls = "#89b4fa", pyright = "#fab387", basedpyright = "#fab387", pylsp = "#fab387",
  jsonls = "#f9e2af", html = "#fab387", cssls = "#74c7ec", emmet_ls = "#fab387",
  bashls = "#a6e3a1", dockerls = "#89dceb", yamlls = "#f9e2af",
  copilot = "#cba6f7", ["null-ls"] = "#94e2d5",
  ruff = "#e5c07b", ty = "#7dc4e4", jinja_lsp = "#c6a0f6", ["jinja-lsp"] = "#c6a0f6",
  bacon_ls = "#ed8796", ["bacon-ls"] = "#ed8796",
  rust_analyzer = "#e78a76", ["rust-analyzer"] = "#e78a76", jdtls = "#CC7832",
  eslint = "#a78bfa",
}
M.lsp_servers_light = {
  vtsls = "#0B74D6", ts_ls = "#0B74D6", tsserver = "#0B74D6",
  vue_ls = "#2E7D4F", volar = "#2E7D4F", tailwindcss = "#1A8894",
  lua_ls = "#0B74D6", pyright = "#A04B10", basedpyright = "#A04B10", pylsp = "#A04B10",
  jsonls = "#7A5C00", html = "#A04B10", cssls = "#1A8894", emmet_ls = "#A04B10",
  bashls = "#2E7D4F", dockerls = "#1A8894", yamlls = "#7A5C00",
  copilot = "#6B3CC8", ["null-ls"] = "#1A8894",
  ruff = "#8A6B20", ty = "#155E9E", jinja_lsp = "#6B3CC8", ["jinja-lsp"] = "#6B3CC8",
  bacon_ls = "#B54A5C", ["bacon-ls"] = "#B54A5C",
  rust_analyzer = "#A0430A", ["rust-analyzer"] = "#A0430A", jdtls = "#8E5324",
  eslint = "#4B32C3",
}

-- Ghostty renders colored cell backgrounds translucent (background-opacity-cells)
-- but glyphs stay opaque. Pill cap glyphs must be pre-blended toward the terminal
-- background by the opacity, or they look more saturated than the pill bodies.
local ghostty_cache
local function ghostty_info()
  if ghostty_cache then return ghostty_cache end
  ghostty_cache = { alpha = 1, backdrop = "#1e1e1e" }
  local dir = vim.fn.expand("~/Library/Application Support/com.mitchellh.ghostty")
  if vim.fn.isdirectory(dir) == 0 then dir = vim.fn.expand("~/.config/ghostty") end
  local theme
  local ok, lines = pcall(vim.fn.readfile, dir .. "/config")
  if ok then
    for _, l in ipairs(lines) do
      local a = l:match("^%s*background%-opacity%s*=%s*([%d%.]+)")
      if a then ghostty_cache.alpha = tonumber(a) or 1 end
      theme = l:match("^%s*theme%s*=%s*(%S+)") or theme
    end
  end
  if theme then
    local ok2, tl = pcall(vim.fn.readfile, dir .. "/themes/" .. theme)
    if ok2 then
      for _, l in ipairs(tl) do
        local bgc = l:match("^%s*background%s*=%s*(#%x%x%x%x%x%x)")
        if bgc then ghostty_cache.backdrop = bgc break end
      end
    end
  end
  return ghostty_cache
end

-- Re-read the ghostty settings (called when the colorscheme changes).
function M.refresh_ghostty()
  ghostty_cache = nil
end

-- What a translucent cell of `hex` visually looks like; use for cap glyph colors.
function M.blend_cap(hex)
  if type(hex) ~= "string" or not hex:match("^#%x%x%x%x%x%x$") then return hex end
  local g = ghostty_info()
  if g.alpha >= 0.999 then return hex end
  local function mix(i)
    local c = tonumber(hex:sub(i, i + 1), 16)
    local b = tonumber(g.backdrop:sub(i, i + 1), 16)
    return math.floor(c * g.alpha + b * (1 - g.alpha) + 0.5)
  end
  return string.format("#%02X%02X%02X", mix(2), mix(4), mix(6))
end

-- The statusline block a theme published, or nil for external themes.
local function theme_block()
  local t = vim.g.theme_custom_hl
  if type(t) == "table" and t.name == vim.g.colors_name and type(t.statusline) == "table" then
    return t.statusline
  end
  return nil
end

-- Resolved palette: theme block merged over the light/dark defaults.
function M.get()
  local base = vim.o.background == "light" and defaults_light or defaults_dark
  local block = theme_block()
  if not block then
    return vim.deepcopy(base)
  end
  return vim.tbl_deep_extend("force", vim.deepcopy(base), block)
end

-- Per-server chip colors, allowing a theme to override individual servers.
function M.lsp_servers()
  local base = vim.o.background == "light" and M.lsp_servers_light or M.lsp_servers_dark
  local block = theme_block()
  if block and type(block.lsp) == "table" and type(block.lsp.servers) == "table" then
    return vim.tbl_extend("force", vim.deepcopy(base), block.lsp.servers)
  end
  return base
end

-- Lualine mode theme built from the resolved palette.
function M.lualine_theme()
  local p = M.get()
  local surface = p.surface
  local function row(m)
    return {
      a = { fg = p.mode[m].fg, bg = p.mode[m].bg, gui = "bold" },
      b = { fg = p.fg, bg = surface, gui = "bold" },
      c = { fg = p.fg, bg = surface },
    }
  end
  return {
    normal   = row("normal"),
    insert   = row("insert"),
    visual   = row("visual"),
    replace  = row("replace"),
    command  = row("command"),
    inactive = {
      a = { fg = p.muted, bg = surface },
      b = { fg = p.muted, bg = surface },
      c = { fg = p.muted, bg = surface },
    },
  }
end

return M
