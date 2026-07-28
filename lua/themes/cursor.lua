local M = {}

local themes = {
  dark = {
    name = "cursor-dark",
    bg = "#181818",
    bg_nc = "#181818",
    sidebar = "#141414",
    panel = "#141414",
    panel_alt = "#181818",
    line = "#262626",
    line_alt = "#202020",
    selection = "#404040",
    selection_inactive = "#333333",
    search = "#343434",
    border = "#343434",
    fg = "#F0F0F0",
    fg_dim = "#D6D6DD",
    muted = "#A4A4A4",
    faint = "#626262",
    comment = "#6A9955",
    string = "#E394DC",
    number = "#F8C762",
    boolean = "#82D2CE",
    keyword = "#82D2CE",
    func = "#EBC88D",
    method_decl = "#EFB080",
    type = "#87C3FF",
    property = "#AAA0FA",
    param = "#C8A2C8",
    constant = "#82D2CE",
    preproc = "#AAA0FA",
    special = "#88C0D0",
    red = "#E34671",
    warn = "#F1B467",
    info = "#88C0D0",
    hint = "#88C0D0",
    green = "#70B489",
    blue = "#87C3FF",
    accent = "#81A1C1",
    status_fg = "#A4A4A4",
    status_bg = "#141414",
    tab_active = "#181818",
    tab_inactive = "#141414",
    tab_inactive_fg = "#626262",
  },
  midnight = {
    name = "cursor-dark-midnight",
    bg = "#1e2127",
    bg_nc = "#1e2127",
    sidebar = "#191c22",
    panel = "#191c22",
    panel_alt = "#20242c",
    line = "#2a2f3a",
    line_alt = "#21242b",
    selection = "#434c5e",
    selection_inactive = "#373f4d",
    search = "#3d5d6f",
    border = "#272c36",
    fg = "#D8DEE9",
    fg_dim = "#7b88a1",
    muted = "#7c818e",
    faint = "#4b5163",
    comment = "#66728a",
    string = "#A3BE8C",
    number = "#B48EAD",
    boolean = "#B48EAD",
    keyword = "#81A1C1",
    func = "#88C0D0",
    method_decl = "#88C0D0",
    type = "#8FBCBB",
    property = "#D8DEE9",
    param = "#B48EAD",
    constant = "#81A1C1",
    preproc = "#5E81AC",
    special = "#88C0D0",
    red = "#BF616A",
    warn = "#EBCB8B",
    info = "#88C0D0",
    hint = "#88C0D0",
    green = "#A3BE8C",
    blue = "#81A1C1",
    accent = "#88C0D0",
    status_fg = "#4b5163",
    status_bg = "#191c22",
    tab_active = "#1e2127",
    tab_inactive = "#191c22",
    tab_inactive_fg = "#4b5163",
  },
  light = {
    name = "cursor-light",
    bg = "#FCFCFC",
    bg_nc = "#FCFCFC",
    sidebar = "#F3F3F3",
    panel = "#F3F3F3",
    panel_alt = "#EAEAEA",
    line = "#EAEAEA",
    line_alt = "#F3F3F3",
    selection = "#E2E2E2",
    selection_inactive = "#E8E8E8",
    search = "#DDEAF7",
    border = "#D0D0D0",
    fg = "#141414",
    fg_dim = "#444444",
    muted = "#6E6E6E",
    faint = "#999999",
    comment = "#6E6E6E",
    string = "#7565CC",
    number = "#92156A",
    boolean = "#3B7E84",
    keyword = "#A30034",
    func = "#A8552A",
    method_decl = "#A8552A",
    type = "#005293",
    property = "#654DC0",
    param = "#A8552A",
    constant = "#005293",
    preproc = "#007041",
    special = "#176C74",
    red = "#BE1744",
    warn = "#A46700",
    info = "#176C74",
    hint = "#176C74",
    green = "#007041",
    blue = "#005293",
    accent = "#2778C1",
    status_fg = "#666666",
    status_bg = "#F3F3F3",
    tab_active = "#FCFCFC",
    tab_inactive = "#F3F3F3",
    tab_inactive_fg = "#444444",
  },
}

function M.apply(variant)
  local p = assert(themes[variant], "unknown Cursor theme variant: " .. tostring(variant))

  if vim.fn.has("termguicolors") == 1 then
    vim.o.termguicolors = true
  end
  vim.o.background = variant == "light" and "light" or "dark"
  vim.o.winblend = 0
  vim.o.pumblend = 0

  vim.g.theme_custom_hl = {
    name = p.name,
    border = p.border,
    select_bg = p.selection,
    ref_bg = p.line_alt,
    diag_err = p.red,
    diag_warn = p.warn,
    diag_info = p.info,
    diag_hint = p.hint,
    diff_add = p.name == "cursor-light" and "#D8F0E3" or (p.name == "cursor-dark" and "#1F3327" or "#2B3A32"),
    diff_del = p.name == "cursor-light" and "#FFDDE3" or (p.name == "cursor-dark" and "#331720" or "#3A2429"),
    diff_change = p.line_alt,
    diff_text = p.selection,
    diff_context = p.bg,
    gadd_inline = p.green,
    gdel_inline = p.red,
    gchg_inline = p.warn,
    gadd_ln = p.name == "cursor-light" and "#D8F0E3" or (p.name == "cursor-dark" and "#1F3327" or "#2B3A32"),
    gdel_ln = p.name == "cursor-light" and "#FFDDE3" or (p.name == "cursor-dark" and "#331720" or "#3A2429"),
    gchg_ln = p.line_alt,
    neotree_added = p.green,
    neotree_mod = p.warn,
    neotree_red = p.red,
    neotree_cursor_fg = p.fg,
    neotree_cursor_bg = p.name == "cursor-light" and "#E2E2E2" or (p.name == "cursor-dark" and "#242424" or "#21242b"),
    neotree_cursor_line_fg = p.fg,
    neotree_fg = p.fg_dim,
    neotree_active_indent = p.accent,
    param = p.param,
    vbuiltin = p.keyword,
    ctor = p.type,
    blue = p.blue,
    pink = p.string,
    rose = p.string,
    yellow = p.type,
    purple = p.property,
    cyan = p.special,
    peach = p.method_decl,
    green = p.green,
    text = p.fg,
    muted_text = p.muted,
    snacks_line_fg = p.fg,
    snacks_line_bg = p.name == "cursor-light" and "#E2E2E2" or (p.name == "cursor-dark" and "#242424" or "#21242b"),
    snacks_file = p.fg,
    snacks_dir = p.muted,
    snacks_match = p.warn,
    snacks_row = p.special,
    snacks_col = p.muted,
    snacks_directory = p.accent,
    snacks_prompt = p.accent,
    snacks_delim = p.faint,
    snacks_selected = p.accent,
    snacks_unselected = p.muted,
    snacks_comment = p.muted,
    snacks_search_bg = p.search,
    indent_fg = p.name == "cursor-dark" and "#2C2C2C" or "#272c36",
    indent_scope_fg = p.name == "cursor-dark" and "#626262" or "#4c566a",
    context_bg = p.line_alt,
    treesitter_context_bg = p.line_alt,
    fold_bg = p.panel_alt,
    fold_fg = p.muted,
    blame_fg = p.faint,
  }

  vim.cmd("highlight clear")
  vim.g.colors_name = p.name

  local hl = vim.api.nvim_set_hl

  hl(0, "Normal",        { fg = p.fg, bg = p.bg })
  hl(0, "NormalNC",      { fg = p.fg_dim, bg = p.bg_nc })
  hl(0, "NormalFloat",   { fg = p.fg, bg = p.panel })
  hl(0, "FloatBorder",   { fg = p.border, bg = p.panel })
  hl(0, "FloatTitle",    { fg = p.fg, bg = p.panel, bold = true })

  -- Pickers (Snacks) sit on the editor background, not the gray panel, so the
  -- list and preview read like normal editing rather than a gray overlay.
  for _, g in ipairs({
    "SnacksPickerBox", "SnacksPickerInput", "SnacksPickerList",
    "SnacksPickerPreview", "SnacksPickerTitle", "SnacksPickerFooter",
    "SnacksInputNormal", "SnacksInputTitle",
  }) do
    hl(0, g, { fg = p.fg, bg = p.bg })
  end
  hl(0, "SnacksPickerBorder", { fg = p.border, bg = p.bg })
  hl(0, "SnacksInputBorder",  { fg = p.border, bg = p.bg })

  hl(0, "Cursor",        { fg = p.bg, bg = p.fg })
  hl(0, "CursorInsert",  { fg = p.bg, bg = p.accent })
  hl(0, "CursorReplace", { fg = p.bg, bg = p.warn })
  hl(0, "lCursor",       { link = "CursorInsert" })
  hl(0, "CursorIM",      { link = "CursorInsert" })
  hl(0, "TermCursor",    { link = "Cursor" })
  hl(0, "CursorLine",    { bg = p.line })
  hl(0, "CursorLineNr",  { fg = p.fg, bg = p.line, bold = true })
  hl(0, "LineNr",        { fg = p.faint, bg = p.bg })
  hl(0, "SignColumn",    { fg = p.faint, bg = p.bg })
  hl(0, "VertSplit",     { fg = p.border, bg = p.bg })
  hl(0, "WinSeparator",  { fg = p.border, bg = p.bg })
  hl(0, "EndOfBuffer",   { fg = p.bg, bg = p.bg })

  hl(0, "Pmenu",       { fg = p.fg, bg = p.panel })
  hl(0, "PmenuSel",    { fg = p.fg, bg = p.selection })
  hl(0, "PmenuSbar",   { bg = p.panel_alt })
  hl(0, "PmenuThumb",  { bg = p.muted })
  hl(0, "PmenuBorder", { fg = p.border, bg = p.panel })

  hl(0, "Visual",      { fg = p.fg, bg = p.selection })
  hl(0, "VisualNOS",   { bg = p.selection_inactive })
  hl(0, "Search",      { fg = p.fg, bg = p.search })
  hl(0, "IncSearch",   { fg = p.bg, bg = p.warn, bold = true })
  hl(0, "MatchParen",  { fg = p.fg, bg = p.selection_inactive, bold = true })

  hl(0, "StatusLine",   { fg = p.status_fg, bg = p.status_bg })
  hl(0, "StatusLineNC", { fg = p.faint, bg = p.status_bg })
  hl(0, "TabLine",      { fg = p.tab_inactive_fg, bg = p.tab_inactive })
  hl(0, "TabLineSel",   { fg = p.fg, bg = p.tab_active, bold = true })
  hl(0, "TabLineFill",  { fg = p.faint, bg = p.tab_inactive })
  hl(0, "Folded",       { fg = vim.g.theme_custom_hl.fold_fg, bg = vim.g.theme_custom_hl.fold_bg })
  hl(0, "FoldColumn",   { fg = vim.g.theme_custom_hl.fold_fg, bg = p.bg })
  hl(0, "UfoFoldedFg",  { fg = vim.g.theme_custom_hl.fold_fg })
  hl(0, "UfoFoldedBg",  { bg = vim.g.theme_custom_hl.fold_bg })
  hl(0, "UfoFoldedEllipsis", { fg = vim.g.theme_custom_hl.fold_fg, bg = vim.g.theme_custom_hl.fold_bg })

  hl(0, "Comment",     { fg = p.comment, italic = false })
  hl(0, "String",      { fg = p.string })
  hl(0, "Character",   { fg = p.string })
  hl(0, "Number",      { fg = p.number })
  hl(0, "Boolean",     { fg = p.boolean })
  hl(0, "Float",       { fg = p.number })
  hl(0, "Identifier",  { fg = p.fg })
  hl(0, "Function",    { fg = p.func })
  hl(0, "Statement",   { fg = p.keyword })
  hl(0, "Keyword",     { fg = p.keyword })
  hl(0, "Conditional", { fg = p.keyword })
  hl(0, "Repeat",      { fg = p.keyword })
  hl(0, "Operator",    { fg = p.fg })
  hl(0, "Type",        { fg = p.type })
  hl(0, "Constant",    { fg = p.constant })
  hl(0, "PreProc",     { fg = p.preproc })
  hl(0, "Special",     { fg = p.special })
  hl(0, "Delimiter",   { fg = p.fg })

  hl(0, "@variable",                   { fg = p.fg })
  hl(0, "@variable.member",            { fg = p.property })
  hl(0, "@variable.parameter",         { fg = p.param })
  hl(0, "@variable.parameter.builtin", { fg = p.method_decl })
  hl(0, "@parameter",                  { fg = p.param })
  hl(0, "@variable.builtin",           { fg = p.keyword })
  hl(0, "@property",                   { fg = p.property })
  hl(0, "@field",                      { fg = p.property })
  hl(0, "@function",                   { fg = p.func })
  hl(0, "@function.call",              { fg = p.func })
  hl(0, "@function.method",            { fg = p.func })
  hl(0, "@function.method.call",       { fg = p.func })
  hl(0, "@function.special",           { fg = p.special })
  hl(0, "@constructor",                { fg = p.type })
  hl(0, "@type",                       { fg = p.type })
  hl(0, "@type.builtin",               { fg = p.keyword })
  hl(0, "@constant",                   { fg = p.constant })
  hl(0, "@constant.builtin",           { fg = p.boolean })
  hl(0, "@string",                     { fg = p.string })
  hl(0, "@string.special.url",         { fg = p.special, underline = true })
  hl(0, "@number",                     { fg = p.number })
  hl(0, "@boolean",                    { fg = p.boolean })
  hl(0, "@keyword",                    { fg = p.keyword })
  hl(0, "@operator",                   { fg = p.fg })
  hl(0, "@punctuation.bracket",        { fg = p.fg })
  hl(0, "@punctuation.delimiter",      { fg = p.fg })
  hl(0, "@comment",                    { fg = p.comment, italic = false })

  hl(0, "@tag",               { fg = p.keyword })
  hl(0, "@tag.builtin",       { fg = p.keyword })
  hl(0, "@tag.attribute",     { fg = p.type })
  hl(0, "@tag.delimiter",     { fg = p.muted })
  hl(0, "htmlTag",            { fg = p.muted })
  hl(0, "htmlEndTag",         { fg = p.muted })
  hl(0, "htmlTagName",        { fg = p.keyword })
  hl(0, "htmlSpecialTagName", { fg = p.keyword })
  hl(0, "htmlArg",            { fg = p.type })
  hl(0, "htmlString",         { fg = p.string })
  hl(0, "htmlValue",          { fg = p.string })

  local lsp_groups = {
    ["@lsp.type.class"] = p.type,
    ["@lsp.type.decorator"] = p.green,
    ["@lsp.type.enum"] = p.type,
    ["@lsp.type.enumMember"] = p.param,
    ["@lsp.type.function"] = p.func,
    ["@lsp.type.interface"] = p.type,
    ["@lsp.type.method"] = p.func,
    ["@lsp.type.namespace"] = p.blue,
    ["@lsp.type.parameter"] = p.param,
    ["@lsp.type.property"] = p.property,
    ["@lsp.type.struct"] = p.type,
    ["@lsp.type.type"] = p.type,
    ["@lsp.type.typeAlias"] = p.type,
    ["@lsp.type.typeParameter"] = p.type,
    ["@lsp.type.variable"] = p.fg,
    ["@lsp.typemod.variable.readonly"] = p.constant,
    ["@lsp.typemod.variable.defaultLibrary"] = p.fg,
    ["@lsp.typemod.parameter.declaration"] = p.param,
    ["@lsp.typemod.parameter.readonly"] = p.param,
    ["@lsp.typemod.variable.parameter"] = p.param,
    ["@lsp.typemod.variable.parameter.readonly"] = p.param,
    ["@lsp.typemod.variable.readonly.parameter"] = p.param,
    ["@lsp.typemod.function.declaration"] = p.method_decl,
    ["@lsp.typemod.method.declaration"] = p.method_decl,
  }
  for group, fg in pairs(lsp_groups) do
    hl(0, group, { fg = fg })
    for _, lang in ipairs({ "rust", "typescript", "javascript", "python" }) do
      hl(0, group .. "." .. lang, { fg = fg })
    end
  end

  hl(0, "DiagnosticError", { fg = p.red })
  hl(0, "DiagnosticWarn",  { fg = p.warn })
  hl(0, "DiagnosticInfo",  { fg = p.info })
  hl(0, "DiagnosticHint",  { fg = p.hint })
  hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = p.red })
  hl(0, "DiagnosticUnderlineWarn",  { undercurl = true, sp = p.warn })
  hl(0, "DiagnosticUnderlineInfo",  { undercurl = true, sp = p.info })
  hl(0, "DiagnosticUnderlineHint",  { undercurl = true, sp = p.hint })

  hl(0, "Directory",              { fg = p.fg_dim, bold = true })
  hl(0, "NeoTreeNormal",          { fg = p.fg_dim, bg = p.sidebar })
  hl(0, "NeoTreeNormalNC",        { fg = p.fg_dim, bg = p.sidebar })
  hl(0, "NeoTreeSignColumn",      { fg = p.faint, bg = p.sidebar })
  hl(0, "NeoTreeEndOfBuffer",     { fg = p.sidebar, bg = p.sidebar })
  hl(0, "NeoTreeDirectoryName",   { fg = p.fg_dim, bold = true })
  hl(0, "NeoTreeDirectoryIcon",   { fg = p.fg_dim })
  hl(0, "NeoTreeRootName",        { fg = p.fg, bold = true })
  hl(0, "NeoTreeFileName",        { fg = p.fg_dim })
  hl(0, "NeoTreeFileNameOpened",  { fg = p.fg })
  hl(0, "NeoTreeIndentMarker",    { fg = p.border })
  hl(0, "NeoTreeCursorLine",      { fg = p.fg, bg = vim.g.theme_custom_hl.neotree_cursor_bg })
  hl(0, "NvimTreeFolderName",       { fg = p.fg_dim, bold = true })
  hl(0, "NvimTreeFolderIcon",       { fg = p.fg_dim })
  hl(0, "NvimTreeOpenedFolderName", { fg = p.fg, bold = true })

  hl(0, "NeoTreeGitAdded",     { fg = vim.g.theme_custom_hl.neotree_added, bold = true })
  hl(0, "NeoTreeGitUntracked", { fg = p.info, bold = true })
  hl(0, "NeoTreeGitStaged",    { fg = vim.g.theme_custom_hl.neotree_added, bold = true })
  hl(0, "NeoTreeGitModified",  { fg = vim.g.theme_custom_hl.neotree_mod, bold = true })
  hl(0, "NeoTreeGitRenamed",   { fg = vim.g.theme_custom_hl.neotree_mod, bold = true })
  hl(0, "NeoTreeGitDeleted",   { fg = vim.g.theme_custom_hl.neotree_red, bold = true })
  hl(0, "NeoTreeGitConflict",  { fg = vim.g.theme_custom_hl.neotree_red, bold = true })

  vim.g.terminal_color_0 = p.sidebar
  vim.g.terminal_color_1 = p.red
  vim.g.terminal_color_2 = p.green
  vim.g.terminal_color_3 = p.warn
  vim.g.terminal_color_4 = p.blue
  vim.g.terminal_color_5 = p.property
  vim.g.terminal_color_6 = p.special
  vim.g.terminal_color_7 = p.fg_dim
  vim.g.terminal_color_8 = p.faint
  vim.g.terminal_color_9 = p.red
  vim.g.terminal_color_10 = p.green
  vim.g.terminal_color_11 = p.warn
  vim.g.terminal_color_12 = p.blue
  vim.g.terminal_color_13 = p.property
  vim.g.terminal_color_14 = p.special
  vim.g.terminal_color_15 = p.fg
end

return M
