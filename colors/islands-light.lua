if vim.fn.has("termguicolors") == 1 then
  vim.o.termguicolors = true
end

vim.o.background = "light"

local palette = {
  bg = "#FFFFFF",
  fg = "#4C4F69",
  fg_bright = "#1E2030",
  muted = "#6E7380",
  comment = "#6E7380",
  line = "#FBFAF8",
  line_alt = "#F9F8F7",
  blue = "#356FAF",
  cyan = "#2A6678",
  green = "#4F7C61",
  amber = "#9C5F2B",
  gold = "#857125",
  magenta = "#775EAA",
  red = "#B85A64",
  purple = "#6E52A8",
  selection = "#DEE9F5",
  search = "#D6E5F2",
  border = "#F3F1EE",
}

vim.g.colors_name = "islands-light"
vim.cmd("highlight clear")

local hl = vim.api.nvim_set_hl

hl(0, "Normal", { fg = palette.fg, bg = palette.bg })
hl(0, "NormalNC", { fg = palette.fg, bg = palette.bg })
hl(0, "NormalFloat", { fg = palette.fg, bg = palette.bg })
hl(0, "FloatBorder", { fg = "#9098A6", bg = palette.bg })
hl(0, "CursorLine", { bg = palette.line_alt })
hl(0, "CursorLineNr", { fg = palette.fg_bright, bg = palette.line_alt, bold = true })
hl(0, "LineNr", { fg = palette.muted })
hl(0, "SignColumn", { fg = palette.muted, bg = palette.bg })
hl(0, "VertSplit",    { fg = "#C5C8CE", bg = palette.bg })
hl(0, "WinSeparator", { fg = "#C5C8CE", bg = palette.bg })
hl(0, "Pmenu", { fg = palette.fg, bg = palette.bg })
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

hl(0, "htmlTag", { fg = "#7B8596" })
hl(0, "htmlEndTag", { fg = "#7B8596" })
hl(0, "htmlTagName", { fg = "#356FAF" })
hl(0, "htmlSpecialTagName", { fg = "#356FAF" })
hl(0, "htmlArg", { fg = "#8E5324" })
hl(0, "htmlString", { fg = palette.green })
hl(0, "htmlValue", { fg = palette.green })
hl(0, "htmlSpecialChar", { fg = palette.cyan })
hl(0, "htmlComment", { fg = palette.comment, italic = false })
hl(0, "htmlCommentPart", { fg = palette.comment, italic = false })

hl(0, "@tag", { fg = "#356FAF" })
hl(0, "@tag.builtin", { fg = "#356FAF" })
hl(0, "@tag.attribute", { fg = "#8E5324" })
hl(0, "@tag.delimiter", { fg = "#7B8596" })
hl(0, "@punctuation.bracket", { fg = "#7B8596" })
hl(0, "@punctuation.special", { fg = "#356FAF" })
hl(0, "@attribute", { fg = "#8E5324" })
hl(0, "@string.special.url", { fg = "#2A6678", underline = true })

hl(0, "@tag.html", { fg = "#356FAF" })
hl(0, "@tag.builtin.html", { fg = "#356FAF" })
hl(0, "@tag.attribute.html", { fg = "#8E5324" })
hl(0, "@tag.delimiter.html", { fg = "#7B8596" })
hl(0, "@punctuation.bracket.html", { fg = "#7B8596" })
hl(0, "@string.special.url.html", { fg = "#2A6678", underline = true })

hl(0, "@tag.vue", { fg = "#356FAF" })
hl(0, "@tag.builtin.vue", { fg = "#356FAF" })
hl(0, "@tag.attribute.vue", { fg = "#8E5324" })
hl(0, "@tag.delimiter.vue", { fg = "#7B8596" })
hl(0, "@punctuation.bracket.vue", { fg = "#7B8596" })
hl(0, "@punctuation.special.vue", { fg = "#356FAF" })
hl(0, "@constructor.vue", { fg = "#356FAF" })
hl(0, "@attribute.vue", { fg = "#8E5324" })
hl(0, "@keyword.directive.vue", { fg = "#356FAF" })
hl(0, "@keyword.modifier.vue", { fg = "#356FAF" })
hl(0, "@function.method.vue", { fg = "#356FAF" })
hl(0, "@character.special.vue", { fg = "#356FAF" })
hl(0, "@variable.vue", { fg = palette.fg })
hl(0, "@variable.member.vue", { fg = palette.fg })
hl(0, "@none.vue", { fg = palette.fg })
hl(0, "@property", { fg = palette.fg })
hl(0, "@property.vue", { fg = palette.fg })
hl(0, "@string", { fg = palette.green })
hl(0, "@string.html", { fg = palette.green })
hl(0, "@string.vue", { fg = palette.green })

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

hl(0, "NeotestPassed",       { fg = palette.green })
hl(0, "NeotestFailed",       { fg = palette.red })
hl(0, "NeotestRunning",      { fg = palette.gold })
hl(0, "NeotestSkipped",      { fg = palette.muted })
hl(0, "NeotestUnknown",      { fg = palette.muted })
hl(0, "NeotestNamespace",    { fg = palette.magenta })
hl(0, "NeotestFile",         { fg = palette.cyan })
hl(0, "NeotestDir",          { fg = palette.cyan })
hl(0, "NeotestAdapterName",  { fg = palette.red })
hl(0, "NeotestTarget",       { fg = palette.red })
hl(0, "NeotestMarked",       { fg = palette.amber, bold = true })
hl(0, "NeotestWatching",     { fg = palette.gold })
hl(0, "NeotestIndent",       { fg = palette.border })
hl(0, "NeotestExpandMarker", { fg = palette.muted })
hl(0, "NeotestWinSelect",    { fg = palette.blue, bold = true })
hl(0, "NeotestFocused",      { bold = true, underline = true })
