-- Transparency handling: which themes render see-through, Snacks backdrops,
-- and clearing backgrounds that plugins keep reintroducing.
local M = {}

-- Theme names that render see-through (terminal opacity shows).
local transparent_names = {
  ["islands-dark"] = true,
  ["islands-white"] = true,
  ["islands-light"] = true,
  ["islands-rose-pine-dark"] = true,
  ["cursor-dark-midnight"] = true,
}

-- True when the given colorscheme name is a transparent variant.
function M.is_transparent_name(name)
  return transparent_names[name or ""] == true
end

-- True only for the active theme when it is a transparent variant.
function M.is_transparent_theme()
  return M.is_transparent_name(vim.g.colors_name)
end

-- Transparent themes keep the dim backdrop behind Snacks floats; opaque themes drop it.
function M.apply_snacks_backdrop()
  if Snacks == nil or type(Snacks.config) ~= "table" then return end

  local transparent = M.is_transparent_theme()
  local function merge_style(name, style)
    Snacks.config.styles = Snacks.config.styles or {}
    Snacks.config.styles[name] = vim.tbl_deep_extend("force", Snacks.config.styles[name] or {}, style)
  end

  for _, name in ipairs({
    "float",
    "help",
        "notification",
    "notification_history",
    "scratch",
    "snacks_image",
    "terminal",
  }) do
    merge_style(name, { backdrop = transparent and nil or false })
  end
  -- vim.ui.input prompts and lazygit never dim the editor behind them (see colorscheme.lua).
  merge_style("input", { backdrop = false })
  merge_style("lazygit", { backdrop = false })
end

-- Clear backgrounds on groups that plugins often repaint after loading.
function M.apply_transparent_hl()
  if not M.is_transparent_theme() then return end

  local hl = vim.api.nvim_set_hl
  local bgless_groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "FloatFooter",
    "FloatShadow",
    "FloatShadowThrough",
    "SignColumn",
    "FoldColumn",
    "LineNr",
    "EndOfBuffer",
    "WinSeparator",
    "VertSplit",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "StatusLine",
    "StatusLineNC",
    "StatusLineTerm",
    "StatusLineTermNC",
    "lualine_transparent",
    "TabLine",
    "TabLineFill",
    "Pmenu",
    "TreesitterContext",
    "TreesitterContextLineNumber",
    "TreesitterContextBottom",
    "TreesitterContextLineNumberBottom",
    "TreesitterContextSeparator",
    "SnacksPickerBorder",
    "SnacksPickerBox",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerPreview",
    "SnacksPickerTitle",
    "SnacksPickerFooter",
    "SnacksInputNormal",
    "SnacksInputBorder",
    "SnacksInputTitle",
    "NoiceCmdlinePopup",
    "NoiceCmdlinePopupBorder",
    "NoiceCmdlinePopupTitle",
    "NoicePopup",
    "NoicePopupBorder",
    "NoicePopupmenu",
    "WhichKey",
    "WhichKeyNormal",
    "WhichKeyBorder",
    "BlinkCmpMenu",
    "BlinkCmpMenuBorder",
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    "BlinkCmpDocSeparator",
    "BlinkCmpSignatureHelp",
    "BlinkCmpSignatureHelpBorder",
    "PmenuBorder",
    "Terminal",
  }

  -- A theme that publishes `sidebar_bg` keeps neo-tree on that surface, and
  -- `context_opaque` keeps the treesitter-context panel on its own background.
  local c = type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl or {}
  local keep = {
    NeoTree = c.sidebar_bg ~= nil,
    TreesitterContext = c.context_opaque == true,
  }
  for _, group in ipairs(bgless_groups) do
    local prefix = group:match("^NeoTree") or group:match("^TreesitterContext")
    if not (prefix and keep[prefix]) then
      local current = vim.api.nvim_get_hl(0, { name = group, link = false })
      current.bg = "NONE"
      hl(0, group, current)
    end
  end
end

-- Apply transparent highlights now and once more after a short delay.
function M.schedule_transparent_hl()
  if not M.is_transparent_theme() then return end

  M.apply_transparent_hl()
  vim.defer_fn(M.apply_transparent_hl, 50)
end

return M
