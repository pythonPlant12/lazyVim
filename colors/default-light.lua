-- Single light theme: a soft off-white editor with gray panels/menus.
-- Base comes from islands-light (opaque variant); everything below overrides it.
local source = vim.fn.stdpath("config") .. "/colors/islands-light.lua"
vim.g._islands_opaque_default = true
dofile(source)
vim.g._islands_opaque_default = nil

local hl = vim.api.nvim_set_hl
local fg = "#4C4F69"
local bg = "#FCFCFC" -- editor background (soft off-white)
local panel_bg = "#F3F3F3" -- gray surface for menus / sidebar / general floats
local border = "#D0D0D0"
local string_fg = "#2F6F4E"

if type(vim.g.theme_custom_hl) == "table" then
  local t = vim.tbl_extend("force", vim.g.theme_custom_hl, {
    name = "default-light",
    string_fg = string_fg,
    snacks_match = "#2366A6",
    panel_bg = panel_bg,
    picker_bg = bg, -- pickers sit on the editor bg, not the gray panel
  })
  -- Opaque variant: statusline sits on a gray panel instead of transparency.
  t.statusline = vim.tbl_deep_extend("force", t.statusline or {}, { surface = "#F3F3F3" })
  -- Tab bar covers the gray panel so it reads as a distinct bar.
  t.tabline = { fg = "#4C4F69", muted = "#7A7880", border = "#D0D0D0", active_bg = "#D2E4F5", active_fg = "#2F496F", bg = "#F3F3F3" }
  vim.g.theme_custom_hl = t
end

vim.o.winblend = 0
vim.o.pumblend = 0
vim.g.colors_name = "default-light"

-- Strings.
for _, g in ipairs({
  "String", "Character", "htmlString", "htmlValue",
  "@string", "@string.html", "@string.vue", "@string.javascript", "@string.typescript",
}) do
  hl(0, g, { fg = string_fg })
end

-- Editor surfaces.
hl(0, "Normal",       { fg = fg, bg = bg })
hl(0, "NormalNC",     { fg = fg, bg = bg })
hl(0, "EndOfBuffer",  { fg = bg, bg = bg })
hl(0, "LineNr",       { fg = "#6E7380", bg = bg })
hl(0, "SignColumn",   { fg = "#6E7380", bg = bg })
hl(0, "FoldColumn",   { fg = "#66707C", bg = bg })
hl(0, "VertSplit",    { fg = "#C5C8CE", bg = bg })
hl(0, "WinSeparator", { fg = "#C5C8CE", bg = bg })

-- Gray panels: general floats, autocomplete menu, and Neo-tree sidebar.
for _, g in ipairs({
  "NormalFloat", "FloatTitle", "FloatFooter",
  "Pmenu",
  "NoicePopup", "NoicePopupmenu", "NoiceCmdlinePopup",
  "WhichKey", "WhichKeyNormal",
  "BlinkCmpMenu", "BlinkCmpDoc", "BlinkCmpSignatureHelp",
  "Terminal",
  "NeoTreeNormal", "NeoTreeNormalNC",
}) do
  hl(0, g, { fg = fg, bg = panel_bg })
end
hl(0, "NeoTreeSignColumn",  { fg = "#6E7380", bg = panel_bg })
hl(0, "NeoTreeEndOfBuffer", { fg = panel_bg, bg = panel_bg })

-- Gray-panel borders.
for _, g in ipairs({
  "FloatBorder", "PmenuBorder",
  "NoicePopupBorder", "NoiceCmdlinePopupBorder",
  "WhichKeyBorder",
  "BlinkCmpMenuBorder", "BlinkCmpDocBorder", "BlinkCmpDocSeparator",
  "BlinkCmpSignatureHelpBorder",
}) do
  hl(0, g, { fg = border, bg = panel_bg })
end

-- Pickers (Snacks) sit on the editor background, not the gray panel, with a
-- subtle border so they still read as floating windows.
for _, g in ipairs({
  "SnacksPickerBox", "SnacksPickerInput", "SnacksPickerList",
  "SnacksPickerPreview", "SnacksPickerTitle", "SnacksPickerFooter",
  "SnacksInputNormal", "SnacksInputTitle",
}) do
  hl(0, g, { fg = fg, bg = bg })
end
for _, g in ipairs({ "SnacksPickerBorder", "SnacksInputBorder" }) do
  hl(0, g, { fg = border, bg = bg })
end
