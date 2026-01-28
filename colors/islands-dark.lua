-- Islands Dark colorscheme (derived from PyCharm Islands Dark .icls)
if vim.fn.has("termguicolors") == 1 then
  vim.o.termguicolors = true
end

local palette = {
  bg = "#191A1C",
  fg = "#BCBEC4",
  fg_bright = "#CED0D6",
  muted = "#6F737A",
  comment = "#7A7E85",
  line = "#2B2D30",
  line_alt = "#1F2024",
  blue = "#56A8F5",
  cyan = "#2AACB8",
  green = "#7CA686",
  amber = "#CF8E6D",
  gold = "#D5B778",
  magenta = "#C77DBB",
  red = "#F75464",
  purple = "#B189F5",
  selection = "#35538F",
  search = "#114957",
  border = "#393B40",
}

vim.g.colors_name = "islands-dark"
vim.cmd("highlight clear")

local hl = vim.api.nvim_set_hl

-- UI
hl(0, "Normal", { fg = palette.fg, bg = palette.bg })
hl(0, "NormalNC", { fg = palette.fg, bg = palette.bg })
hl(0, "NormalFloat", { fg = palette.fg, bg = palette.line_alt })
hl(0, "FloatBorder", { fg = palette.border, bg = palette.line_alt })
hl(0, "CursorLine", { bg = palette.line_alt })
hl(0, "CursorLineNr", { fg = palette.fg_bright, bg = palette.line_alt, bold = true })
hl(0, "LineNr", { fg = palette.muted })
hl(0, "SignColumn", { fg = palette.muted, bg = palette.bg })
hl(0, "VertSplit", { fg = palette.line, bg = palette.bg })
hl(0, "WinSeparator", { fg = palette.line, bg = palette.bg })
hl(0, "Pmenu", { fg = palette.fg, bg = palette.line_alt })
hl(0, "PmenuSel", { fg = palette.fg_bright, bg = palette.selection })
hl(0, "PmenuSbar", { bg = palette.line })
hl(0, "PmenuThumb", { bg = palette.border })

-- Selection / Search
hl(0, "Visual", { fg = palette.fg_bright, bg = palette.selection })
hl(0, "Search", { fg = palette.fg_bright, bg = palette.search })
hl(0, "IncSearch", { fg = palette.fg_bright, bg = palette.search, bold = true })
hl(0, "MatchParen", { bg = palette.border, bold = true })

-- Statusline / tabs
hl(0, "StatusLine", { fg = palette.fg_bright, bg = palette.line })
hl(0, "StatusLineNC", { fg = palette.muted, bg = palette.line })
hl(0, "TabLine", { fg = palette.muted, bg = palette.line })
hl(0, "TabLineSel", { fg = palette.fg_bright, bg = palette.line_alt, bold = true })
hl(0, "TabLineFill", { fg = palette.muted, bg = palette.line })

-- Syntax
hl(0, "Comment", { fg = palette.comment, italic = false })
hl(0, "String", { fg = palette.green })
hl(0, "Character", { fg = palette.green })
hl(0, "Number", { fg = palette.cyan })
hl(0, "Boolean", { fg = palette.cyan })
hl(0, "Float", { fg = palette.cyan })
hl(0, "Identifier", { fg = palette.fg })
hl(0, "Function", { fg = palette.blue })
hl(0, "Statement", { fg = palette.amber })
hl(0, "Keyword", { fg = palette.amber })
hl(0, "Operator", { fg = palette.fg })
hl(0, "Type", { fg = palette.gold })
hl(0, "Constant", { fg = palette.magenta })
hl(0, "PreProc", { fg = palette.magenta })
hl(0, "Special", { fg = palette.blue })

-- Diagnostics
hl(0, "DiagnosticError", { fg = palette.red })
hl(0, "DiagnosticWarn", { fg = palette.gold })
hl(0, "DiagnosticInfo", { fg = palette.blue })
hl(0, "DiagnosticHint", { fg = palette.muted })
hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = palette.red })
hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = palette.gold })
hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = palette.blue })
hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = palette.muted })
