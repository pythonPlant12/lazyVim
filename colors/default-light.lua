local source = vim.fn.stdpath("config") .. "/colors/default-white.lua"
dofile(source)

local bg = "#FFFFFF"
local panel_bg = "#F3F3F3"
local fg = "#4C4F69"
local hl = vim.api.nvim_set_hl

vim.g.theme_custom_hl = vim.tbl_extend("force", vim.g.theme_custom_hl or {}, {
  name = "default-light",
  panel_bg = panel_bg,
})

hl(0, "Normal",             { fg = fg, bg = bg })
hl(0, "NormalNC",           { fg = fg, bg = bg })
hl(0, "EndOfBuffer",        { fg = bg, bg = bg })
hl(0, "LineNr",             { fg = "#6E7380", bg = bg })
hl(0, "SignColumn",         { fg = "#6E7380", bg = bg })
hl(0, "FoldColumn",         { fg = "#66707C", bg = bg })
hl(0, "VertSplit",          { fg = "#C5C8CE", bg = bg })
hl(0, "WinSeparator",       { fg = "#C5C8CE", bg = bg })
hl(0, "NormalFloat",        { fg = fg, bg = panel_bg })
hl(0, "Pmenu",              { fg = fg, bg = panel_bg })
hl(0, "NeoTreeNormal",      { fg = fg, bg = panel_bg })
hl(0, "NeoTreeNormalNC",    { fg = fg, bg = panel_bg })
hl(0, "NeoTreeSignColumn",  { fg = "#6E7380", bg = panel_bg })
hl(0, "NeoTreeEndOfBuffer", { fg = panel_bg, bg = panel_bg })

vim.o.winblend = 0
vim.o.pumblend = 0
vim.g.colors_name = "default-light"
