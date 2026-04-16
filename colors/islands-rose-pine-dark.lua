if vim.fn.has("termguicolors") == 1 then
  vim.o.termguicolors = true
end
vim.o.background = "dark"

local ui = {
  bg = "#212120",
  fg = "#BCBEC4",
  fg_bright = "#CED0D6",
  muted = "#6F737A",
  line = "#2B2D30",
  line_alt = "#1F2024",
  selection = "#35538F",
  search = "#114957",
  border = "#393B40",
}

local syn = {
  comment  = "#908caa",
  string   = "#f6c177",
  number   = "#f6c177",
  func     = "#ebbcba",
  keyword  = "#4da8c5",
  operator = "#908caa",
  type     = "#9ccfd8",
  constant = "#f6c177",
  preproc  = "#c4a7e7",
  special  = "#9ccfd8",
  ident    = "#e0def4",
  tag      = "#9ccfd8",
  tag_attr = "#c4a7e7",
  tag_delim = "#908caa",
  property = "#9ccfd8",
  iris     = "#c4a7e7",
  pine     = "#31748f",
  foam     = "#9ccfd8",
  subtle   = "#908caa",
  text     = "#e0def4",
  gold     = "#f6c177",
  rose     = "#ebbcba",
  red      = "#eb6f92",
}

vim.g.colors_name = "islands-rose-pine-dark"
vim.cmd("highlight clear")

local hl = vim.api.nvim_set_hl

hl(0, "Normal",        { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalNC",      { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalFloat",   { fg = ui.fg,        bg = ui.bg })
hl(0, "FloatBorder",   { fg = "#585b70",    bg = ui.bg })
hl(0, "CursorLine",    { bg = ui.line_alt })
hl(0, "CursorLineNr",  { fg = ui.fg_bright, bg = ui.line_alt, bold = true })
hl(0, "LineNr",        { fg = ui.muted })
hl(0, "SignColumn",    { fg = ui.muted,     bg = ui.bg })
hl(0, "VertSplit",     { fg = "#3E4248",    bg = ui.bg })
hl(0, "WinSeparator",  { fg = "#3E4248",    bg = ui.bg })
hl(0, "Pmenu",         { fg = ui.fg,        bg = ui.bg })
hl(0, "PmenuSel",      { fg = ui.fg_bright, bg = ui.selection })
hl(0, "PmenuSbar",     { bg = ui.line })
hl(0, "PmenuThumb",    { bg = ui.border })

hl(0, "Visual",        { fg = ui.fg_bright, bg = ui.selection })
hl(0, "Search",        { fg = ui.fg_bright, bg = ui.search })
hl(0, "IncSearch",     { fg = ui.fg_bright, bg = ui.search, bold = true })
hl(0, "MatchParen",    { bg = ui.border,    bold = true })

hl(0, "StatusLine",    { fg = ui.fg_bright, bg = ui.line })
hl(0, "StatusLineNC",  { fg = ui.muted,     bg = ui.line })
hl(0, "TabLine",       { fg = ui.muted,     bg = ui.line })
hl(0, "TabLineSel",    { fg = ui.fg_bright, bg = ui.line_alt, bold = true })
hl(0, "TabLineFill",   { fg = ui.muted,     bg = ui.line })

hl(0, "Comment",       { fg = syn.comment,  italic = false })
hl(0, "String",        { fg = syn.string })
hl(0, "Character",     { fg = syn.string })
hl(0, "Number",        { fg = syn.number })
hl(0, "Boolean",       { fg = syn.number })
hl(0, "Float",         { fg = syn.number })
hl(0, "Identifier",    { fg = syn.ident })
hl(0, "Function",      { fg = syn.func })
hl(0, "Statement",     { fg = syn.keyword })
hl(0, "Keyword",       { fg = syn.keyword })
hl(0, "Operator",      { fg = syn.operator })
hl(0, "Type",          { fg = syn.type })
hl(0, "Constant",      { fg = syn.constant })
hl(0, "PreProc",       { fg = syn.preproc })
hl(0, "Special",       { fg = syn.special })

hl(0, "DiagnosticError",          { fg = syn.red })
hl(0, "DiagnosticWarn",           { fg = syn.gold })
hl(0, "DiagnosticInfo",           { fg = syn.foam })
hl(0, "DiagnosticHint",           { fg = ui.muted })
hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = syn.red })
hl(0, "DiagnosticUnderlineWarn",  { undercurl = true, sp = syn.gold })
hl(0, "DiagnosticUnderlineInfo",  { undercurl = true, sp = syn.foam })
hl(0, "DiagnosticUnderlineHint",  { undercurl = true, sp = ui.muted })

hl(0, "Directory",              { fg = ui.fg,        bold = true })
hl(0, "NeoTreeDirectoryName",   { fg = ui.fg,        bold = true })
hl(0, "NeoTreeDirectoryIcon",   { fg = ui.fg })
hl(0, "NeoTreeRootName",        { fg = syn.gold,     bold = true })
hl(0, "NeoTreeFileName",        { fg = ui.fg })
hl(0, "NeoTreeFileNameOpened",  { fg = ui.fg_bright })
hl(0, "NeoTreeIndentMarker",    { fg = ui.border })
hl(0, "NeoTreeNormal",          { fg = ui.fg,        bg = ui.bg })
hl(0, "NeoTreeNormalNC",        { fg = ui.fg,        bg = ui.bg })

hl(0, "NvimTreeFolderName",         { fg = ui.fg, bold = true })
hl(0, "NvimTreeFolderIcon",         { fg = ui.fg })
hl(0, "NvimTreeOpenedFolderName",   { fg = ui.fg, bold = true })

hl(0, "htmlTag",            { fg = syn.subtle })
hl(0, "htmlEndTag",         { fg = syn.subtle })
hl(0, "htmlTagName",        { fg = syn.foam })
hl(0, "htmlSpecialTagName", { fg = syn.foam })
hl(0, "htmlArg",            { fg = syn.iris })
hl(0, "htmlString",         { fg = syn.string })
hl(0, "htmlValue",          { fg = syn.string })
hl(0, "htmlSpecialChar",    { fg = syn.pine })
hl(0, "htmlComment",        { fg = syn.comment, italic = false })
hl(0, "htmlCommentPart",    { fg = syn.comment, italic = false })

hl(0, "@tag",                       { fg = syn.foam })
hl(0, "@tag.builtin",               { fg = syn.foam })
hl(0, "@tag.attribute",             { fg = syn.iris })
hl(0, "@tag.delimiter",             { fg = syn.subtle })
hl(0, "@punctuation.bracket",       { fg = syn.subtle })
hl(0, "@string.special.url",        { fg = syn.foam, underline = true })

hl(0, "@tag.html",                  { fg = syn.foam })
hl(0, "@tag.builtin.html",          { fg = syn.foam })
hl(0, "@tag.attribute.html",        { fg = syn.iris })
hl(0, "@tag.delimiter.html",        { fg = syn.subtle })
hl(0, "@punctuation.bracket.html",  { fg = syn.subtle })
hl(0, "@string.special.url.html",   { fg = syn.foam, underline = true })

hl(0, "@tag.vue",                   { fg = syn.foam })
hl(0, "@tag.builtin.vue",           { fg = syn.foam })
hl(0, "@tag.attribute.vue",         { fg = syn.iris })
hl(0, "@tag.delimiter.vue",         { fg = syn.subtle })
hl(0, "@punctuation.bracket.vue",   { fg = syn.subtle })
hl(0, "@lsp.type.keyword.vue",      { fg = syn.keyword })

hl(0, "NeoTreeGitAdded",                { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitUntracked",            { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitModified",             { fg = "#B8865A", bold = true })
hl(0, "NeoTreeGitConflict",             { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitDeleted",              { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitIgnored",              { fg = ui.muted,  bold = true })
hl(0, "NeoTreeGitRenamed",              { fg = "#9B87C4", bold = true })
hl(0, "NeoTreeGitStaged",               { fg = "#6AAB6A", bold = true })

hl(0, "NeoTreeGitAddedFolderName",      { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitUntrackedFolderName",  { fg = "#6AAB6A", bold = true })
hl(0, "NeoTreeGitModifiedFolderName",   { fg = "#B8865A", bold = true })
hl(0, "NeoTreeGitConflictFolderName",   { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitDeletedFolderName",    { fg = "#B85C5C", bold = true })
hl(0, "NeoTreeGitIgnoredFolderName",    { fg = ui.muted,  bold = true })
hl(0, "NeoTreeGitRenamedFolderName",    { fg = "#9B87C4", bold = true })
