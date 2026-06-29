if vim.fn.has("termguicolors") == 1 then
  vim.o.termguicolors = true
end

vim.o.background = "light"

local ui = {
  bg = "#FFFFFF",
  fg = "#3a3650",
  fg_bright = "#1a1830",
  muted = "#5e5a74",
  line = "#EEEEEE",
  line_alt = "#E5E5E5",
  selection = "#d4e4f4",
  search = "#c8daf0",
  border = "#DCDCDC",
}

local syn = {
  comment  = "#9298A4",
  string   = "#6F4100",
  number   = "#6F4100",
  func     = "#BF4568",
  keyword  = "#186D8C",
  operator = "#9298A4",
  type     = "#208CA8",
  constant = "#6F4100",
  preproc  = "#6C4AB6",
  special  = "#208CA8",
  ident    = "#3a3650",
  tag      = "#208CA8",
  tag_attr = "#6C4AB6",
  tag_delim = "#9298A4",
  iris     = "#6C4AB6",
  pine     = "#186D8C",
  foam     = "#208CA8",
  subtle   = "#9298A4",
  text     = "#3a3650",
  gold     = "#6F4100",
  rose     = "#BF4568",
  red      = "#941426",
}

vim.g.theme_custom_hl = {
  name = "islands-rose-pine-light",
  border = "#8F98A8",
  select_bg = ui.selection,
  ref_bg = "#F2F2F4",
  diag_err = syn.red,
  diag_warn = syn.gold,
  diag_info = syn.foam,
  diag_hint = ui.muted,
  diff_add = "#D4EDD9",
  diff_del = "#F5DADA",
  diff_change = "#F3E8D6",
  diff_text = "#EAD6B8",
  diff_context = "#E5E5E5",
  gadd_inline = "#A8D4AE",
  gdel_inline = "#E8B0B0",
  gchg_inline = "#EEDFC5",
  gadd_ln = "#D4EDD9",
  gdel_ln = "#F5DADA",
  gchg_ln = "#F2E8D6",
  neotree_added = "#3A7D50",
  neotree_mod = "#A8631A",
  neotree_red = "#BE3A4A",
  neotree_cursor_fg = "#2F496F",
  neotree_cursor_bg = "#D2E4F5",
  neotree_cursor_line_fg = "#1e2030",
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
  green = "#4D8454",
  text = syn.text,
  muted_text = syn.subtle,
  snacks_line_fg = "#2F496F",
  snacks_line_bg = ui.selection,
  snacks_file = syn.text,
  snacks_dir = ui.muted,
  snacks_match = syn.rose,
  snacks_row = syn.foam,
  snacks_col = ui.muted,
  snacks_directory = syn.foam,
  snacks_prompt = syn.iris,
  snacks_delim = "#7B8491",
  snacks_selected = syn.iris,
  snacks_unselected = ui.muted,
  snacks_comment = "#7B8491",
  snacks_search_bg = "#C8D8EE",
  indent_fg = "#C4CAD3",
  indent_scope_fg = "#8FA8C8",
  context_bg = ui.line_alt,
  fold_bg = "#EEF2F7",
  fold_fg = ui.muted,
  blame_fg = "#7B8491",
}

vim.cmd("highlight clear")
vim.g.colors_name = "islands-rose-pine-light"

local hl = vim.api.nvim_set_hl

hl(0, "Normal",        { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalNC",      { fg = ui.fg,        bg = ui.bg })
hl(0, "NormalFloat",   { fg = ui.fg,        bg = ui.bg })
hl(0, "Cursor",        { fg = "#FFFFFF",   bg = ui.fg_bright })
hl(0, "CursorInsert",  { fg = "#FFFFFF",   bg = syn.foam })
hl(0, "CursorReplace", { fg = "#FFFFFF",   bg = syn.rose })
hl(0, "lCursor",       { link = "CursorInsert" })
hl(0, "CursorIM",      { link = "CursorInsert" })
hl(0, "TermCursor",    { link = "Cursor" })
hl(0, "FloatBorder",   { fg = "#9098A6",    bg = ui.bg })
hl(0, "CursorLine",    { bg = ui.line_alt })
hl(0, "CursorLineNr",  { fg = ui.fg_bright, bg = ui.line_alt, bold = true })
hl(0, "LineNr",        { fg = ui.muted })
hl(0, "SignColumn",    { fg = ui.muted,     bg = ui.bg })
hl(0, "VertSplit",     { fg = "#C5C8CE",    bg = ui.bg })
hl(0, "WinSeparator",  { fg = "#C5C8CE",    bg = ui.bg })
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

hl(0, "NeoTreeGitAdded",                { fg = "#3A7D50", bold = true })
hl(0, "NeoTreeGitUntracked",            { fg = "#3A7D50", bold = true })
hl(0, "NeoTreeGitModified",             { fg = "#A8631A", bold = true })
hl(0, "NeoTreeGitConflict",             { fg = "#BE3A4A", bold = true })
hl(0, "NeoTreeGitDeleted",              { fg = "#BE3A4A", bold = true })
hl(0, "NeoTreeGitIgnored",              { fg = ui.muted,  bold = true })
hl(0, "NeoTreeGitRenamed",              { fg = "#7C52AE", bold = true })
hl(0, "NeoTreeGitStaged",               { fg = "#3A7D50", bold = true })

hl(0, "NeoTreeGitAddedFolderName",      { fg = "#3A7D50", bold = true })
hl(0, "NeoTreeGitUntrackedFolderName",  { fg = "#3A7D50", bold = true })
hl(0, "NeoTreeGitModifiedFolderName",   { fg = "#A8631A", bold = true })
hl(0, "NeoTreeGitConflictFolderName",   { fg = "#BE3A4A", bold = true })
hl(0, "NeoTreeGitDeletedFolderName",    { fg = "#BE3A4A", bold = true })
hl(0, "NeoTreeGitIgnoredFolderName",    { fg = ui.muted,  bold = true })
hl(0, "NeoTreeGitRenamedFolderName",    { fg = "#7C52AE", bold = true })

hl(0, "NeotestPassed",       { fg = syn.foam })
hl(0, "NeotestFailed",       { fg = syn.red })
hl(0, "NeotestRunning",      { fg = syn.gold })
hl(0, "NeotestSkipped",      { fg = ui.muted })
hl(0, "NeotestUnknown",      { fg = ui.muted })
hl(0, "NeotestNamespace",    { fg = syn.iris })
hl(0, "NeotestFile",         { fg = syn.pine })
hl(0, "NeotestDir",          { fg = syn.pine })
hl(0, "NeotestAdapterName",  { fg = syn.red })
hl(0, "NeotestTarget",       { fg = syn.red })
hl(0, "NeotestMarked",       { fg = syn.keyword, bold = true })
hl(0, "NeotestWatching",     { fg = syn.gold })
hl(0, "NeotestIndent",       { fg = ui.border })
hl(0, "NeotestExpandMarker", { fg = ui.muted })
hl(0, "NeotestWinSelect",    { fg = syn.foam, bold = true })
hl(0, "NeotestFocused",      { bold = true, underline = true })

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
