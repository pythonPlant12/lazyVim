local source = vim.fn.stdpath("config") .. "/colors/islands-light.lua"
vim.g._islands_opaque_default = true
dofile(source)
vim.g._islands_opaque_default = nil

if type(vim.g.theme_custom_hl) == "table" then
  vim.g.theme_custom_hl.name = "default-white"
  vim.g.theme_custom_hl.string_fg = "#2F6F4E"
  vim.g.theme_custom_hl.snacks_match = "#2366A6"
end
vim.g.colors_name = "default-white"

local hl = vim.api.nvim_set_hl
local string_fg = vim.g.theme_custom_hl and vim.g.theme_custom_hl.string_fg or "#2F6F4E"
local fg = "#4C4F69"
local bg = "#FFFFFF"
local panel_bg = "#FFFFFF"
local context_bg = vim.g.theme_custom_hl and vim.g.theme_custom_hl.context_bg or "#E5E5E5"
local border = vim.g.theme_custom_hl and vim.g.theme_custom_hl.border or "#8F98A8"

local function with_bg(group, group_bg, group_fg)
  local current = vim.api.nvim_get_hl(0, { name = group, link = false }) or {}
  current.bg = group_bg
  if group_fg then current.fg = group_fg end
  current.link = nil
  hl(0, group, current)
end

hl(0, "String", { fg = string_fg })
hl(0, "Character", { fg = string_fg })
hl(0, "htmlString", { fg = string_fg })
hl(0, "htmlValue", { fg = string_fg })
hl(0, "@string", { fg = string_fg })
hl(0, "@string.html", { fg = string_fg })
hl(0, "@string.vue", { fg = string_fg })

for _, group in ipairs({
  "NormalFloat",
  "FloatTitle",
  "FloatFooter",
  "Pmenu",
  "NoicePopup",
  "NoicePopupmenu",
  "NoiceCmdlinePopup",
  "WhichKey",
  "WhichKeyNormal",
  "BlinkCmpMenu",
  "BlinkCmpDoc",
  "BlinkCmpSignatureHelp",
  "Terminal",
  "SnacksPickerBox",
  "SnacksPickerInput",
  "SnacksPickerList",
  "SnacksPickerPreview",
  "SnacksPickerTitle",
  "SnacksPickerFooter",
  "SnacksInputNormal",
  "SnacksInputTitle",
}) do
  with_bg(group, panel_bg, fg)
end

for _, group in ipairs({
  "FloatBorder",
  "PmenuBorder",
  "NoicePopupBorder",
  "NoiceCmdlinePopupBorder",
  "NoiceCmdlinePopupTitle",
  "WhichKeyBorder",
  "BlinkCmpMenuBorder",
  "BlinkCmpDocBorder",
  "BlinkCmpDocSeparator",
  "BlinkCmpSignatureHelpBorder",
  "SnacksPickerBorder",
  "SnacksInputBorder",
  "TreesitterContextSeparator",
}) do
  with_bg(group, bg, border)
end

for _, group in ipairs({
  "TreesitterContext",
  "TreesitterContextLineNumber",
  "TreesitterContextBottom",
  "TreesitterContextLineNumberBottom",
}) do
  with_bg(group, context_bg, fg)
end
