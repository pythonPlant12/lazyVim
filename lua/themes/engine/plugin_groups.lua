-- Applies the active theme's palette to plugin UI highlight groups:
-- completion kinds, pickers, git signs, diffs, Neo-tree, folds, and more.
local palette = require("themes.engine.palette")
local transparency = require("themes.engine.transparency")
local normalize = require("themes.engine.normalize")

local M = {}

-- Snacks computes diff groups lazily; patch them after it is available.
function M.apply_snacks_diff_hl()
  if Snacks == nil then return end
  local theme = type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl.name == vim.g.colors_name and vim.g.theme_custom_hl or {}
  local function bg(group, fallback)
    local ok, current = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    return ok and current and current.bg and string.format("#%06x", current.bg) or fallback
  end
  local diff_add = theme.diff_add or bg("DiffAdd", "NONE")
  local diff_del = theme.diff_del or bg("DiffDelete", "NONE")
  local diff_context = transparency.is_transparent_theme() and "NONE" or bg("Normal", "NONE")
  Snacks.util.set_hl({
    SnacksDiffAdd             = { bg = diff_add },
    SnacksDiffDelete          = { bg = diff_del },
    SnacksDiffContext         = { bg = diff_context },
    SnacksDiffContextLineNr   = { bg = diff_context },
    SnacksDiffAddLineNr       = { bg = diff_add },
    SnacksDiffDeleteLineNr    = { bg = diff_del },
    SnacksGhDiffAdd           = { bg = diff_add },
    SnacksGhDiffDelete        = { bg = diff_del },
    SnacksGhDiffContext       = { bg = diff_context },
    SnacksGhDiffContextLineNr = { bg = diff_context },
    SnacksGhDiffAddLineNr     = { bg = diff_add },
    SnacksGhDiffDeleteLineNr  = { bg = diff_del },
  })
end

-- Central place for custom UI colors shared by completion, pickers, Git, folds, and Neo-tree.
function M.apply_custom_hl()
  transparency.apply_theme_blend()

  local hl = vim.api.nvim_set_hl
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local border_bg = (normal and normal.bg) and string.format("#%06x", normal.bg) or "#191A1C"
  local normal_fg = (normal and normal.fg) and string.format("#%06x", normal.fg) or "#BCBEC4"
  local c = palette.get()

  -- Prefer the theme's real syntax token colors (c.kind_*) so completion items
  -- match the color of the element itself; fall back to the generic aliases.
  local kind_hl_colors = {
    Text = c.text,
    Method = c.kind_function or c.blue,
    Function = c.kind_function or c.blue,
    Constructor = c.kind_type or c.pink,
    Field = c.kind_property or c.purple,
    Variable = c.kind_variable or c.purple,
    Class = c.kind_type or c.yellow,
    Interface = c.kind_type or c.yellow,
    Module = c.kind_namespace or c.cyan,
    Property = c.kind_property or c.purple,
    Unit = c.cyan,
    Value = c.kind_number or c.peach,
    Enum = c.kind_type or c.yellow,
    Keyword = c.kind_keyword or c.rose,
    Snippet = c.rose,
    Color = c.pink,
    File = c.text,
    Reference = c.rose,
    Folder = c.kind_type or c.yellow,
    EnumMember = c.kind_constant or c.peach,
    Constant = c.kind_constant or c.rose,
    Struct = c.kind_type or c.yellow,
    Event = c.text,
    Operator = c.text,
    TypeParameter = c.kind_type or c.cyan,
    Boolean = c.kind_number or c.peach,
    Array = c.text,
    Object = c.kind_type or c.rose,
    Package = c.kind_namespace or c.cyan,
    String = c.kind_string or c.green,
    Number = c.kind_number or c.peach,
    Namespace = c.kind_namespace or c.cyan,
    Null = c.peach,
    Key = c.rose,
    Unknown = c.text,
  }

  hl(0, "BlinkCmpKind", { fg = c.text })
  for kind, fg in pairs(kind_hl_colors) do
    hl(0, "BlinkCmpKind" .. kind, { fg = fg })
    hl(0, "TroubleIcon" .. kind, { fg = fg })
  end

  hl(0, "NormalFloat",               { fg = normal_fg, bg = border_bg })
  hl(0, "FloatBorder",               { fg = c.border, bg = border_bg })
  hl(0, "PmenuBorder",               { fg = c.border, bg = border_bg })
  hl(0, "SnacksPickerBorder",        { fg = c.border, bg = border_bg })
  hl(0, "SnacksPickerBox",           { fg = normal_fg, bg = border_bg })
  hl(0, "SnacksPickerInput",         { fg = normal_fg, bg = border_bg })
  hl(0, "SnacksPickerList",          { fg = normal_fg, bg = border_bg })
  hl(0, "SnacksPickerPreview",       { fg = normal_fg, bg = border_bg })
  hl(0, "SnacksPickerTitle",         { fg = normal_fg, bg = border_bg, bold = true })
  hl(0, "SnacksPickerFooter",        { fg = c.muted_text or c.snacks_comment, bg = border_bg })
  hl(0, "SnacksInputNormal",         { fg = normal_fg, bg = border_bg })
  hl(0, "SnacksInputBorder",         { fg = c.border, bg = border_bg })
  hl(0, "SnacksInputTitle",          { fg = normal_fg, bg = border_bg, bold = true })
  hl(0, "NoiceCmdlinePopupBorder",   { fg = c.border, bg = border_bg })
  hl(0, "WhichKeyBorder",            { fg = c.border, bg = border_bg })
  hl(0, "Visual",                    { bg = c.select_bg })
  hl(0, "VisualNOS",                 { bg = c.select_bg })
  hl(0, "PmenuSel",                  { bg = c.select_bg })
  hl(0, "BlinkCmpMenuSelection",     { bg = c.select_bg })
  hl(0, "BlinkCmpGhostText",         { fg = c.ghost_fg or c.blame_fg })
  hl(0, "LspReferenceText",          { bg = c.ref_bg })
  hl(0, "LspReferenceRead",          { bg = c.ref_bg })
  hl(0, "LspReferenceWrite",         { bg = c.ref_bg })
  hl(0, "DiagnosticVirtualTextError",{ fg = c.diag_err })
  hl(0, "DiagnosticVirtualTextWarn", { fg = c.diag_warn })
  hl(0, "DiagnosticVirtualTextInfo", { fg = c.diag_info })
  hl(0, "DiagnosticVirtualTextHint", { fg = c.diag_hint })

  hl(0, "DiffAdd",    { bg = c.diff_add })
  hl(0, "DiffDelete", { bg = c.diff_del })
  hl(0, "DiffChange", { bg = c.diff_change })
  hl(0, "DiffText",   { bg = c.diff_text })
  local snacks_diff_context = transparency.is_transparent_theme() and "NONE" or border_bg
  hl(0, "SnacksDiffContext",         { bg = snacks_diff_context })
  hl(0, "SnacksDiffContextLineNr",   { bg = snacks_diff_context })
  hl(0, "SnacksGhDiffContext",       { bg = snacks_diff_context })
  hl(0, "SnacksGhDiffContextLineNr", { bg = snacks_diff_context })

  vim.schedule(M.apply_snacks_diff_hl)
  normalize.apply_cursor_hl()
  normalize.apply_plain_keyword_hl()
  normalize.apply_semantic_token_hl()

  hl(0, "GitSignsAdd",    { fg = c.green })
  hl(0, "GitSignsChange", { fg = c.yellow })
  hl(0, "GitSignsDelete", { fg = c.rose })
  local blame_fg = c.blame_fg
  hl(0, "GitSignsCurrentLineBlame", { fg = blame_fg, bg = "NONE" })
  hl(0, "LspInlayHint", { fg = blame_fg, bg = "NONE" })

  hl(0, "GitSignsAddInline",      { bg = c.gadd_inline })
  hl(0, "GitSignsDeleteInline",   { bg = c.gdel_inline })
  hl(0, "GitSignsChangeInline",   { bg = c.gchg_inline })
  hl(0, "GitSignsAddLnInline",    { bg = c.gadd_ln })
  hl(0, "GitSignsDeleteLnInline", { bg = c.gdel_ln })
  hl(0, "GitSignsChangeLnInline", { bg = c.gchg_ln })

  hl(0, "NeoTreeGitAdded",     { fg = c.neotree_added, bold = true })
  hl(0, "NeoTreeGitUntracked", { fg = c.neotree_added, bold = true })
  hl(0, "NeoTreeGitStaged",    { fg = c.neotree_added, bold = true })
  hl(0, "NeoTreeGitModified",  { fg = c.neotree_mod,   bold = true })
  hl(0, "NeoTreeGitRenamed",   { fg = c.neotree_mod,   bold = true })
  hl(0, "NeoTreeGitUnstaged",  { fg = c.neotree_mod,   bold = true })
  hl(0, "NeoTreeGitDeleted",   { fg = c.neotree_red,   bold = true })
  hl(0, "NeoTreeGitConflict",  { fg = c.neotree_red,   bold = true })
  hl(0, "NeoTreeCursorLine",   { bg = c.neotree_cursor_bg, bold = true })

  hl(0, "NeoTreeGitAddedCursorLine",     { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitUntrackedCursorLine", { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitStagedCursorLine",    { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitModifiedCursorLine",  { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitRenamedCursorLine",   { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitUnstagedCursorLine",  { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitDeletedCursorLine",   { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeGitConflictCursorLine",  { bg = c.neotree_cursor_bg, bold = true })
  hl(0, "NeoTreeActiveIndentMarker",     { fg = c.neotree_active_indent, bold = true })

  if c.neotree_fg then
    hl(0, "NeoTreeFileName",       { fg = c.neotree_fg })
    hl(0, "NeoTreeDirectoryName",  { fg = c.neotree_fg, bold = true })
  end

  local picker_colors = {
    line_fg = c.snacks_line_fg, line_bg = c.snacks_line_bg,
    file = c.snacks_file, dir = c.snacks_dir, match = c.snacks_match,
    search_bg = c.snacks_search_bg, row = c.snacks_row, col = c.snacks_col,
    directory = c.snacks_directory, prompt = c.snacks_prompt,
    delim = c.snacks_delim, selected = c.snacks_selected, unselected = c.snacks_unselected or c.snacks_comment,
    comment = c.snacks_comment,
    green = c.green, yellow = c.yellow, rose = c.rose, cyan = c.cyan,
  }
  hl(0, "SnacksPickerMatch", { fg = picker_colors.match, bold = true })
  vim.defer_fn(function()
    hl(0, "SnacksPickerListCursorLine",     { fg = picker_colors.line_fg,    bg = picker_colors.line_bg })
    hl(0, "SnacksPickerFile",               { fg = picker_colors.file,       bold = true })
    hl(0, "SnacksPickerDir",                { fg = picker_colors.dir })
    hl(0, "SnacksPickerMatch",              { fg = picker_colors.match,      bold = true })
    hl(0, "SnacksPickerSearch",             { bg = picker_colors.search_bg })
    hl(0, "SnacksPickerRow",                { fg = picker_colors.row })
    hl(0, "SnacksPickerCol",                { fg = picker_colors.col })
    hl(0, "SnacksPickerDirectory",          { fg = picker_colors.directory })
    hl(0, "SnacksPickerPrompt",             { fg = picker_colors.prompt })
    hl(0, "SnacksPickerDelim",              { fg = picker_colors.delim })
    hl(0, "SnacksPickerSelected",           { fg = picker_colors.selected })
    hl(0, "SnacksPickerUnselected",         { fg = picker_colors.unselected })
    hl(0, "SnacksPickerComment",            { fg = picker_colors.comment })
    hl(0, "SnacksPickerGitStatusAdded",     { fg = picker_colors.green })
    hl(0, "SnacksPickerGitStatusModified",  { fg = picker_colors.yellow })
    hl(0, "SnacksPickerGitStatusDeleted",   { fg = picker_colors.rose })
    hl(0, "SnacksPickerGitStatusUntracked", { fg = picker_colors.cyan })
  end, 20)

  hl(0, "RainbowDelimiterBlueMuted",   { fg = normal_fg })
  hl(0, "RainbowDelimiterGoldMuted",   { fg = normal_fg })
  hl(0, "RainbowDelimiterCyanMuted",   { fg = normal_fg })
  hl(0, "RainbowDelimiterPurpleMuted", { fg = normal_fg })
  hl(0, "RainbowDelimiterGreenMuted",  { fg = normal_fg })
  hl(0, "RainbowDelimiterAmberMuted",  { fg = normal_fg })

  hl(0, "SnacksIndent",      { fg = c.indent_fg })
  hl(0, "SnacksIndentScope", { fg = c.indent_scope_fg, bold = false })

  local treesitter_context_bg = c.treesitter_context_bg or c.context_bg
  hl(0, "TreesitterContext",           { bg = treesitter_context_bg })
  hl(0, "TreesitterContextLineNumber", { fg = c.muted_text or c.fold_fg, bg = treesitter_context_bg })
  hl(0, "TreesitterContextBottom",     { bg = treesitter_context_bg, underline = false })

  hl(0, "Folded",            { fg = c.fold_fg, bg = c.fold_bg })
  hl(0, "FoldColumn",        { fg = c.fold_fg, bg = c.fold_bg })
  hl(0, "UfoFoldedFg",       { fg = c.fold_fg })
  hl(0, "UfoFoldedBg",       { bg = c.fold_bg })
  hl(0, "UfoFoldedEllipsis", { fg = c.fold_fg, bg = c.fold_bg })

  hl(0, "CursorLine",   { bg = c.context_bg })
  hl(0, "CursorLineNr", { fg = normal_fg, bg = c.context_bg, bold = true })
  if transparency.is_transparent_theme() then
    transparency.apply_transparent_hl()
  end
end

return M
