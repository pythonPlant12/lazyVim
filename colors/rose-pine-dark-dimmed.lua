if vim.fn.has("termguicolors") == 1 then
  vim.o.termguicolors = true
end
vim.o.background = "dark"

local ui = {
  bg = "#191724",
  fg = "#b0acbc",
  fg_bright = "#c7c3d1",
  muted = "#5e5a6e",
  subtle = "#7a7686",
  line = "#26233a",
  line_alt = "#1f1d2e",
  selection = "#403d52",
  search = "#2d4d59",
  border = "#524f67",
}

local syn = {
  comment  = "#7a7686",
  string   = "#b09040",
  number   = "#b09040",
  func     = "#b59191",
  keyword  = "#476991",
  operator = "#7a7686",
  type     = "#6e9eb0",
  constant = "#b09040",
  preproc  = "#8579a6",
  special  = "#6e9eb0",
  ident    = "#b0acbc",
  tag      = "#6e9eb0",
  tag_attr = "#8579a6",
  tag_delim = "#7a7686",
  property = "#6e9eb0",
  iris     = "#8579a6",
  pine     = "#476991",
  foam     = "#6e9eb0",
  subtle   = "#7a7686",
  text     = "#b0acbc",
  gold     = "#b09040",
  rose     = "#b59191",
  red      = "#c97c7c",
  leaf     = "#7cae7c",
}

vim.g.theme_custom_hl = {
  name = "rose-pine-dark-dimmed",
  border = ui.border,
  select_bg = ui.selection,
  ref_bg = ui.line,
  diag_err = syn.red,
  diag_warn = syn.gold,
  diag_info = syn.foam,
  diag_hint = ui.muted,
  diff_add = "#1a3822",
  diff_del = "#3d1212",
  diff_change = "#2c2518",
  diff_text = "#453b25",
  diff_context = "#1e2a30",
  gadd_inline = "#3a7a52",
  gdel_inline = "#7a2020",
  gchg_inline = "#453b25",
  gadd_ln = "#1a3822",
  gdel_ln = "#3d1212",
  gchg_ln = "#2c2518",
  neotree_added = syn.leaf,
  neotree_mod = syn.gold,
  neotree_red = syn.red,
  neotree_cursor_fg = ui.fg_bright,
  neotree_cursor_bg = ui.selection,
  neotree_cursor_line_fg = ui.fg_bright,
  neotree_fg = ui.fg_bright,
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
  green = syn.leaf,
  text = syn.text,
  muted_text = syn.subtle,
  snacks_line_fg = ui.fg_bright,
  snacks_line_bg = ui.selection,
  snacks_file = syn.text,
  snacks_dir = syn.subtle,
  snacks_match = syn.rose,
  snacks_row = syn.foam,
  snacks_col = syn.subtle,
  snacks_directory = syn.foam,
  snacks_prompt = syn.iris,
  snacks_delim = syn.subtle,
  snacks_selected = syn.iris,
  snacks_unselected = syn.subtle,
  snacks_comment = syn.subtle,
  snacks_search_bg = ui.search,
  indent_fg = ui.line,
  indent_scope_fg = ui.border,
  context_bg = ui.line,
  fold_bg = ui.line,
  fold_fg = syn.subtle,
  blame_fg = syn.subtle,
}

vim.cmd("highlight clear")
vim.g.colors_name = "rose-pine-dark-dimmed"

local hl = vim.api.nvim_set_hl

hl(0, "Normal",        { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalNC",      { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalFloat",   { fg = ui.fg,        bg = ui.bg })
hl(0, "Cursor",        { fg = ui.bg,        bg = syn.text })
hl(0, "CursorInsert",  { fg = ui.bg,        bg = syn.foam })
hl(0, "CursorReplace", { fg = ui.bg,        bg = syn.rose })
hl(0, "lCursor",       { link = "CursorInsert" })
hl(0, "CursorIM",      { link = "CursorInsert" })
hl(0, "TermCursor",    { link = "Cursor" })
hl(0, "FloatBorder",   { fg = ui.border,    bg = ui.bg })
hl(0, "CursorLine",    { bg = ui.line_alt })
hl(0, "CursorLineNr",  { fg = ui.fg_bright, bg = ui.line_alt, bold = true })
hl(0, "LineNr",        { fg = ui.muted })
hl(0, "SignColumn",    { fg = ui.muted,     bg = ui.bg })
hl(0, "VertSplit",     { fg = ui.border,    bg = ui.bg })
hl(0, "WinSeparator",  { fg = ui.border,    bg = ui.bg })
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

hl(0, "NeoTreeGitAdded",                { fg = syn.leaf, bold = true })
hl(0, "NeoTreeGitUntracked",            { fg = syn.leaf, bold = true })
hl(0, "NeoTreeGitModified",             { fg = syn.gold, bold = true })
hl(0, "NeoTreeGitConflict",             { fg = syn.red,  bold = true })
hl(0, "NeoTreeGitDeleted",              { fg = syn.red,  bold = true })
hl(0, "NeoTreeGitIgnored",              { fg = ui.muted, bold = true })
hl(0, "NeoTreeGitRenamed",              { fg = syn.iris, bold = true })
hl(0, "NeoTreeGitStaged",               { fg = syn.leaf, bold = true })

hl(0, "NeoTreeGitAddedFolderName",      { fg = syn.leaf, bold = true })
hl(0, "NeoTreeGitUntrackedFolderName",  { fg = syn.leaf, bold = true })
hl(0, "NeoTreeGitModifiedFolderName",   { fg = syn.gold, bold = true })
hl(0, "NeoTreeGitConflictFolderName",   { fg = syn.red,  bold = true })
hl(0, "NeoTreeGitDeletedFolderName",    { fg = syn.red,  bold = true })
hl(0, "NeoTreeGitIgnoredFolderName",    { fg = ui.muted, bold = true })
hl(0, "NeoTreeGitRenamedFolderName",    { fg = syn.iris, bold = true })
