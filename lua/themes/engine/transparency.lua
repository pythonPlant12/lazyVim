-- Transparency handling: which themes render see-through, window blending,
-- and clearing backgrounds that plugins keep reintroducing.
local M = {}

-- True only for the fully transparent theme variants that need blended floats.
function M.is_transparent_theme()
  local cs = vim.g.colors_name or ""
  return cs == "islands-dark"
    or cs == "islands-white"
    or cs == "islands-light"
    or cs == "islands-rose-pine-dark"
end

-- Transparent themes keep floats blended; opaque themes force normal backgrounds.
function M.apply_theme_blend()
  local blend = M.is_transparent_theme() and 10 or 0
  vim.o.winblend = blend
  vim.o.pumblend = blend

  if Snacks == nil or type(Snacks.config) ~= "table" then return end

  local transparent = M.is_transparent_theme()
  local function merge_style(name, style)
    Snacks.config.styles = Snacks.config.styles or {}
    Snacks.config.styles[name] = vim.tbl_deep_extend("force", Snacks.config.styles[name] or {}, style)
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

  Snacks.config.picker = Snacks.config.picker or {}
  Snacks.config.picker.win = Snacks.config.picker.win or {}
  for _, name in ipairs({ "input", "list", "preview" }) do
    Snacks.config.picker.win[name] = vim.tbl_deep_extend("force", Snacks.config.picker.win[name] or {}, {
      wo = { winblend = blend },
    })
  end
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

  for _, group in ipairs(bgless_groups) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    current.bg = "NONE"
    hl(0, group, current)
  end
end

-- Apply transparent highlights now and once more after a short delay.
function M.schedule_transparent_hl()
  if not M.is_transparent_theme() then return end

  M.apply_transparent_hl()
  vim.defer_fn(M.apply_transparent_hl, 50)
end

return M
