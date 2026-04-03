if vim.fn.has("termguicolors") == 1 then
  vim.o.termguicolors = true
end

vim.o.background = "light"

local palette = {
  bg = "#FFFFFF",
  fg = "#4C4F69",
  fg_bright = "#1E2030",
  muted = "#7A7880",
  comment = "#7A7880",
  line = "#FBFAF8",
  line_alt = "#FEFDFC",
  blue = "#5A8FD4",
  cyan = "#007A90",
  green = "#7CA686",
  amber = "#C87A3A",
  gold = "#A8983A",
  magenta = "#9B87C4",
  red = "#B85C5C",
  purple = "#7B72C9",
  selection = "#F1EFEC",
  search = "#C5D8E8",
  border = "#F3F1EE",
}

vim.g.colors_name = "islands-light"
vim.cmd("highlight clear")

local hl = vim.api.nvim_set_hl

hl(0, "Normal", { fg = palette.fg, bg = palette.bg })
hl(0, "NormalNC", { fg = palette.fg, bg = palette.bg })
hl(0, "NormalFloat", { fg = palette.fg, bg = palette.bg })
hl(0, "FloatBorder", { fg = "#a4a9b3", bg = palette.bg })
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

hl(0, "Visual", { fg = palette.fg_bright, bg = palette.selection })
hl(0, "Search", { fg = palette.fg_bright, bg = palette.search })
hl(0, "IncSearch", { fg = palette.fg_bright, bg = palette.search, bold = true })
hl(0, "MatchParen", { bg = palette.border, bold = true })

hl(0, "StatusLine", { fg = palette.fg_bright, bg = palette.line })
hl(0, "StatusLineNC", { fg = palette.muted, bg = palette.line })
hl(0, "TabLine", { fg = palette.muted, bg = palette.line })
hl(0, "TabLineSel", { fg = palette.fg_bright, bg = palette.line_alt, bold = true })
hl(0, "TabLineFill", { fg = palette.muted, bg = palette.line })

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

hl(0, "DiagnosticError", { fg = palette.red })
hl(0, "DiagnosticWarn", { fg = palette.gold })
hl(0, "DiagnosticInfo", { fg = palette.blue })
hl(0, "DiagnosticHint", { fg = palette.muted })
hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = palette.red })
hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = palette.gold })
hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = palette.blue })
hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = palette.muted })

hl(0, "Directory", { fg = palette.fg, bold = true })
hl(0, "NeoTreeDirectoryName", { fg = palette.fg, bold = true })
hl(0, "NeoTreeDirectoryIcon", { fg = palette.fg })
hl(0, "NeoTreeRootName", { fg = palette.gold, bold = true })
hl(0, "NeoTreeFileName", { fg = palette.fg })
hl(0, "NeoTreeFileNameOpened", { fg = palette.fg_bright })
hl(0, "NeoTreeIndentMarker", { fg = palette.border })
hl(0, "NeoTreeNormal", { fg = palette.fg, bg = palette.bg })
hl(0, "NeoTreeNormalNC", { fg = palette.fg, bg = palette.bg })

hl(0, "NvimTreeFolderName", { fg = palette.fg, bold = true })
hl(0, "NvimTreeFolderIcon", { fg = palette.fg })
hl(0, "NvimTreeOpenedFolderName", { fg = palette.fg, bold = true })

hl(0, "htmlTag", { fg = palette.muted })
hl(0, "htmlEndTag", { fg = palette.muted })
hl(0, "htmlTagName", { fg = palette.amber })
hl(0, "htmlSpecialTagName", { fg = palette.blue })
hl(0, "htmlArg", { fg = palette.amber })
hl(0, "htmlString", { fg = palette.green })
hl(0, "htmlValue", { fg = palette.green })
hl(0, "htmlSpecialChar", { fg = palette.cyan })
hl(0, "htmlComment", { fg = palette.comment, italic = false })
hl(0, "htmlCommentPart", { fg = palette.comment, italic = false })

hl(0, "@tag", { fg = palette.purple })
hl(0, "@tag.builtin", { fg = palette.blue })
hl(0, "@tag.attribute", { fg = palette.amber })
hl(0, "@tag.delimiter", { fg = palette.muted })
hl(0, "@punctuation.bracket", { fg = palette.muted })
hl(0, "@string.special.url", { fg = palette.cyan, underline = true })

hl(0, "@tag.html", { fg = palette.amber })
hl(0, "@tag.builtin.html", { fg = palette.blue })
hl(0, "@tag.attribute.html", { fg = palette.amber })
hl(0, "@tag.delimiter.html", { fg = palette.muted })
hl(0, "@punctuation.bracket.html", { fg = palette.muted })
hl(0, "@string.special.url.html", { fg = palette.cyan, underline = true })

hl(0, "@tag.vue", { fg = palette.purple })
hl(0, "@tag.builtin.vue", { fg = palette.blue })
hl(0, "@tag.attribute.vue", { fg = palette.amber })
hl(0, "@tag.delimiter.vue", { fg = palette.muted })
hl(0, "@punctuation.bracket.vue", { fg = palette.muted })

hl(0, "@lsp.type.keyword.vue", { fg = palette.amber })

hl(0, "NeoTreeGitAdded", { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitUntracked", { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitModified", { fg = "#B8865A", bold = true })
hl(0, "NeoTreeGitConflict", { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitDeleted", { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitIgnored", { fg = palette.muted, bold = true })
hl(0, "NeoTreeGitRenamed", { fg = "#9B87C4", bold = true })
hl(0, "NeoTreeGitStaged", { fg = "#6AAB6A", bold = true })

hl(0, "NeoTreeGitAddedFolderName", { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitUntrackedFolderName", { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitModifiedFolderName", { fg = "#B8865A", bold = true })
hl(0, "NeoTreeGitConflictFolderName", { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitDeletedFolderName", { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitIgnoredFolderName", { fg = palette.muted, bold = true })
hl(0, "NeoTreeGitRenamedFolderName", { fg = "#9B87C4", bold = true })
