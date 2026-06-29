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
  selection = "#253A63",
  search = "#114957",
  border = "#393B40",
}

local syn = {
  comment  = "#908caa",
  string   = "#e0a84e",
  number   = "#e0a84e",
  func     = "#ebbcba",
  keyword  = "#4da8c5",
  operator = "#908caa",
  type     = "#9ccfd8",
  constant = "#e0a84e",
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
  gold     = "#e0a84e",
  rose     = "#ebbcba",
  red      = "#eb6f92",
}

vim.g.theme_custom_hl = {
  name = "islands-rose-pine-dark",
  border = "#585b70",
  select_bg = ui.selection,
  ref_bg = "#2a2d31",
  diag_err = syn.red,
  diag_warn = syn.gold,
  diag_info = syn.foam,
  diag_hint = ui.muted,
  diff_add = "#1e3028",
  diff_del = "#361515",
  diff_change = "#2c2518",
  diff_text = "#453b25",
  gadd_inline = "#2a4535",
  gdel_inline = "#4d1e1e",
  gchg_inline = "#453b25",
  gadd_ln = "#1e3028",
  gdel_ln = "#361515",
  gchg_ln = "#2c2518",
  neotree_added = "#6AAB6A",
  neotree_mod = "#B8865A",
  neotree_red = "#B85C5C",
  neotree_cursor_fg = "#E8F0FA",
  neotree_cursor_bg = "#2F496F",
  neotree_cursor_line_fg = "#D0D2D8",
  neotree_fg = "#D0D2D8",
  param = syn.iris,
  vbuiltin = syn.rose,
  ctor = syn.type,
  blue = syn.foam,
  pink = syn.rose,
  rose = syn.rose,
  yellow = syn.gold,
  purple = syn.iris,
  cyan = syn.foam,
  peach = syn.gold,
  green = "#a6e3a1",
  text = syn.text,
  muted_text = syn.subtle,
  snacks_line_fg = "#E8F0FA",
  snacks_line_bg = ui.selection,
  snacks_file = syn.text,
  snacks_dir = syn.subtle,
  snacks_match = syn.gold,
  snacks_row = syn.foam,
  snacks_col = syn.subtle,
  snacks_directory = syn.foam,
  snacks_prompt = syn.iris,
  snacks_delim = syn.subtle,
  snacks_selected = syn.iris,
  snacks_unselected = syn.subtle,
  snacks_comment = syn.subtle,
  snacks_search_bg = "#1e3a5f",
  indent_fg = "#40454F",
  indent_scope_fg = "#5B6B8A",
  context_bg = "#313244",
  fold_bg = "#242833",
  fold_fg = syn.subtle,
  blame_fg = "#7f849c",
}

vim.cmd("highlight clear")
vim.g.colors_name = "islands-rose-pine-dark"

local hl = vim.api.nvim_set_hl

hl(0, "Normal",        { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalNC",      { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalFloat",   { fg = ui.fg,        bg = ui.bg })
hl(0, "Cursor",        { fg = ui.bg,        bg = "#e0def4" })
hl(0, "CursorInsert",  { fg = ui.bg,        bg = syn.foam })
hl(0, "CursorReplace", { fg = ui.bg,        bg = syn.rose })
hl(0, "lCursor",       { link = "CursorInsert" })
hl(0, "CursorIM",      { link = "CursorInsert" })
hl(0, "TermCursor",    { link = "Cursor" })
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

hl(0, "@variable.parameter",                         { fg = syn.iris })
hl(0, "@variable.parameter.builtin",                 { fg = syn.iris })
hl(0, "@lsp.type.parameter",                         { fg = syn.iris })
hl(0, "@lsp.type.parameter.python",                  { fg = syn.iris })
hl(0, "@lsp.typemod.parameter.declaration",          { fg = syn.iris })
hl(0, "@lsp.typemod.parameter.declaration.python",   { fg = syn.iris })
hl(0, "@lsp.typemod.variable.parameter",             { fg = syn.iris })
hl(0, "@lsp.typemod.variable.parameter.python",      { fg = syn.iris })
hl(0, "@variable.builtin",                           { fg = syn.rose })
hl(0, "@variable.builtin.python",                    { fg = syn.rose })
hl(0, "@lsp.typemod.variable.self",                  { fg = syn.rose })
hl(0, "@lsp.typemod.variable.self.python",           { fg = syn.rose })
hl(0, "@variable.typescript",              { fg = syn.ident })
hl(0, "@variable.javascript",              { fg = syn.ident })
hl(0, "@function.special",            { fg = syn.rose })
hl(0, "@function.special.typescript", { fg = syn.rose })
hl(0, "@function.special.javascript", { fg = syn.rose })
hl(0, "@function.special.vue",        { fg = syn.rose })
hl(0, "@constructor",                { fg = syn.type })
hl(0, "@lsp.type.class",             { fg = syn.type })
hl(0, "@lsp.typemod.class.callable", { fg = syn.type })
hl(0, "@lsp.type.struct",            { fg = syn.type })
hl(0, "@lsp.type.interface",         { fg = syn.type })
hl(0, "@lsp.type.enum",              { fg = syn.type })
hl(0, "@lsp.type.type",              { fg = syn.type })
hl(0, "@lsp.type.typeAlias",         { fg = syn.type })
hl(0, "@lsp.type.namespace",         { fg = syn.type })
hl(0, "@lsp.type.typeParameter",     { fg = syn.iris })
hl(0, "@lsp.type.enumMember",        { fg = syn.constant })
hl(0, "@string",      { fg = syn.string })
hl(0, "@string.html", { fg = syn.string })
hl(0, "@string.vue",  { fg = syn.string })

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

vim.o.winblend = 10
vim.o.pumblend = 10

for _, group in ipairs({
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
  "Folded",
  "UfoFoldedBg",
  "UfoFoldedEllipsis",
  "LineNr",
  "EndOfBuffer",
  "WinSeparator",
  "VertSplit",
  "StatusLine",
  "StatusLineNC",
  "StatusLineTerm",
  "StatusLineTermNC",
  "TabLine",
  "TabLineFill",
  "Pmenu",
}) do
  local current = vim.api.nvim_get_hl(0, { name = group, link = false })
  current.bg = "NONE"
  hl(0, group, current)
end
