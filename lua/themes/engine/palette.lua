-- Resolves the UI color palette for the active theme.
-- Own themes publish vim.g.theme_custom_hl; for external themes (catppuccin,
-- rose-pine) the palette is derived from their standard highlight groups.
local M = {}

-- Read one color attribute from a highlight group, returning a hex string or fallback.
function M.color_from_hl(group, key, fallback)
  local ok, current = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  local value = ok and current and current[key] or nil
  return value and string.format("#%06x", value) or fallback
end

-- The active palette: the theme's own table, or one derived from highlight groups.
function M.get()
  if type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl.name == vim.g.colors_name then
    return vim.g.theme_custom_hl
  end

  local color_from_hl = M.color_from_hl
  local normal_fg = color_from_hl("Normal", "fg", "#BCBEC4")
  local normal_bg = color_from_hl("Normal", "bg", "#191A1C")
  local muted = color_from_hl("Comment", "fg", normal_fg)
  local selection = color_from_hl("Visual", "bg", normal_bg)
  local cursorline = color_from_hl("CursorLine", "bg", normal_bg)
  local picker_match = vim.o.background == "light" and "#2366A6" or "#FFD6A3"

  return {
    border = color_from_hl("FloatBorder", "fg", muted),
    select_bg = selection,
    ref_bg = cursorline,
    diag_err = color_from_hl("DiagnosticVirtualTextError", "fg", color_from_hl("DiagnosticError", "fg", normal_fg)),
    diag_warn = color_from_hl("DiagnosticVirtualTextWarn", "fg", color_from_hl("DiagnosticWarn", "fg", normal_fg)),
    diag_info = color_from_hl("DiagnosticVirtualTextInfo", "fg", color_from_hl("DiagnosticInfo", "fg", normal_fg)),
    diag_hint = color_from_hl("DiagnosticVirtualTextHint", "fg", color_from_hl("DiagnosticHint", "fg", muted)),
    diff_add = color_from_hl("DiffAdd", "bg", cursorline),
    diff_del = color_from_hl("DiffDelete", "bg", cursorline),
    diff_change = color_from_hl("DiffChange", "bg", cursorline),
    diff_text = color_from_hl("DiffText", "bg", cursorline),
    diff_context = vim.o.background == "light" and "#E5E5E5" or "#1e2a30",
    gadd_inline = color_from_hl("DiffAdd", "bg", cursorline),
    gdel_inline = color_from_hl("DiffDelete", "bg", cursorline),
    gchg_inline = color_from_hl("DiffChange", "bg", cursorline),
    gadd_ln = color_from_hl("DiffAdd", "bg", cursorline),
    gdel_ln = color_from_hl("DiffDelete", "bg", cursorline),
    gchg_ln = color_from_hl("DiffChange", "bg", cursorline),
    neotree_added = color_from_hl("String", "fg", normal_fg),
    neotree_mod = color_from_hl("DiagnosticWarn", "fg", normal_fg),
    neotree_red = color_from_hl("DiagnosticError", "fg", normal_fg),
    neotree_cursor_fg = normal_fg,
    neotree_cursor_bg = selection,
    neotree_cursor_line_fg = normal_fg,
    neotree_fg = normal_fg,
    neotree_active_indent = color_from_hl("Directory", "fg", normal_fg),
    param = color_from_hl("@variable.parameter", "fg", normal_fg),
    vbuiltin = color_from_hl("@variable.builtin", "fg", normal_fg),
    ctor = color_from_hl("Type", "fg", normal_fg),
    blue = color_from_hl("Function", "fg", normal_fg),
    pink = color_from_hl("Special", "fg", normal_fg),
    rose = color_from_hl("Constant", "fg", normal_fg),
    yellow = color_from_hl("Type", "fg", normal_fg),
    purple = color_from_hl("@variable.parameter", "fg", normal_fg),
    cyan = color_from_hl("DiagnosticInfo", "fg", normal_fg),
    peach = color_from_hl("Number", "fg", normal_fg),
    green = color_from_hl("String", "fg", normal_fg),
    text = normal_fg,
    muted_text = muted,
    snacks_line_fg = normal_fg,
    snacks_line_bg = selection,
    snacks_file = normal_fg,
    snacks_dir = muted,
    snacks_match = picker_match,
    snacks_row = color_from_hl("DiagnosticInfo", "fg", normal_fg),
    snacks_col = muted,
    snacks_directory = color_from_hl("Directory", "fg", normal_fg),
    snacks_prompt = color_from_hl("Special", "fg", normal_fg),
    snacks_delim = muted,
    snacks_selected = color_from_hl("Directory", "fg", normal_fg),
    snacks_unselected = muted,
    snacks_comment = muted,
    snacks_search_bg = color_from_hl("Search", "bg", selection),
    indent_fg = color_from_hl("LineNr", "fg", muted),
    indent_scope_fg = muted,
    context_bg = cursorline,
    treesitter_context_bg = vim.o.background == "light" and "#F3F3F3" or cursorline,
    fold_bg = cursorline,
    fold_fg = muted,
    blame_fg = color_from_hl("GitSignsCurrentLineBlame", "fg", muted),
  }
end

return M
