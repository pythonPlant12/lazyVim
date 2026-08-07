-- Rose Pine Dawn (light) is an external plugin theme; this file is its
-- companion source of truth: a balanced palette published as theme_custom_hl
-- plus a few direct highlight corrections.
local M = {}

function M.is_active()
  local cs = vim.g.colors_name or ""
  return cs == "rose-pine-dawn" or (cs == "rose-pine" and vim.o.background == "light")
end

function M.apply()
  if not M.is_active() then return end

  local ui = {
    bg = "#fbfbfd",
    fg = "#4f4a63",
    fg_bright = "#27233a",
    muted = "#6f6a7f",
    line = "#f1f2f5",
    selection = "#dedcf0",
    border = "#9c96a7",
  }
  local syn = {
    comment = "#8e899b",
    string = "#5f7f52",
    number = "#8b5f85",
    func = "#9f5572",
    keyword = "#6f5a9b",
    operator = "#7a7486",
    type = "#71618f",
    constant = "#8b5f85",
    preproc = "#7d5fa6",
    special = "#8b5f85",
    gold = "#8a6b35",
    red = "#a34655",
    green = "#5f7f52",
  }

  vim.g.theme_custom_hl = vim.tbl_extend("force", vim.g.theme_custom_hl or {}, {
    name = "rose-pine-dawn-balanced",
    border = ui.border,
    select_bg = ui.selection,
    ref_bg = "#f0edf4",
    diag_err = syn.red,
    diag_warn = syn.gold,
    diag_info = ui.muted,
    diag_hint = ui.muted,
    diff_add = "#D4EDD9",
    diff_del = "#F5DADA",
    diff_change = "#f0eaf0",
    diff_text = "#e8dfe8",
    diff_context = ui.bg,
    gadd_inline = "#A8D4AE",
    gdel_inline = "#E8B0B0",
    gchg_inline = "#e8dfe8",
    gadd_ln = "#D4EDD9",
    gdel_ln = "#F5DADA",
    gchg_ln = "#f0eaf0",
    neotree_added = syn.green,
    neotree_mod = syn.gold,
    neotree_red = syn.red,
    neotree_cursor_fg = ui.fg,
    neotree_cursor_bg = ui.selection,
    neotree_cursor_line_fg = ui.fg_bright,
    neotree_fg = ui.fg,
    neotree_active_indent = ui.muted,
    param = syn.preproc,
    vbuiltin = syn.func,
    ctor = syn.type,
    blue = ui.muted,
    pink = syn.func,
    rose = syn.constant,
    yellow = syn.gold,
    purple = syn.preproc,
    cyan = ui.muted,
    peach = syn.constant,
    green = syn.green,
    text = ui.fg,
    muted_text = syn.comment,
    snacks_line_fg = ui.fg,
    snacks_line_bg = ui.selection,
    snacks_file = ui.fg,
    snacks_dir = ui.muted,
    snacks_match = syn.func,
    snacks_row = ui.muted,
    snacks_col = ui.muted,
    snacks_directory = ui.fg,
    snacks_prompt = syn.preproc,
    snacks_delim = "#837d8f",
    snacks_selected = syn.preproc,
    snacks_unselected = ui.muted,
    snacks_comment = "#837d8f",
    snacks_search_bg = "#e6dded",
    indent_fg = "#d4d0dc",
    indent_scope_fg = "#aaa0c2",
    context_bg = ui.line,
    treesitter_context_bg = ui.line,
    fold_bg = ui.line,
    fold_fg = ui.muted,
    blame_fg = "#837d8f",
  })

  local hl = vim.api.nvim_set_hl
  hl(0, "Normal",      { fg = ui.fg, bg = ui.bg })
  hl(0, "NormalNC",    { fg = ui.fg, bg = ui.bg })
  hl(0, "NormalFloat", { fg = ui.fg, bg = ui.bg })
  hl(0, "Pmenu",       { fg = ui.fg, bg = ui.bg })
  hl(0, "NeoTreeNormal",   { fg = ui.fg, bg = ui.bg })
  hl(0, "NeoTreeNormalNC", { fg = ui.fg, bg = ui.bg })
  hl(0, "CursorLine",  { bg = ui.line })
  hl(0, "LineNr",      { fg = ui.muted, bg = ui.bg })
  hl(0, "SignColumn",  { fg = ui.muted, bg = ui.bg })
  hl(0, "FloatBorder", { fg = ui.border, bg = ui.bg })
  hl(0, "Directory",   { fg = ui.fg, bold = true })
  hl(0, "String",      { fg = syn.string })
  hl(0, "Character",   { fg = syn.string })
  hl(0, "Number",      { fg = syn.number })
  hl(0, "Boolean",     { fg = syn.number })
  hl(0, "Float",       { fg = syn.number })
  hl(0, "Identifier",  { fg = ui.fg })
  hl(0, "Function",    { fg = syn.func })
  hl(0, "Statement",   { fg = syn.keyword })
  hl(0, "Keyword",     { fg = syn.keyword })
  hl(0, "Operator",    { fg = syn.operator })
  hl(0, "Type",        { fg = syn.type })
  hl(0, "Constant",    { fg = syn.constant })
  hl(0, "PreProc",     { fg = syn.preproc })
  hl(0, "Special",     { fg = syn.special })
  hl(0, "Comment",     { fg = syn.comment, italic = false })
  hl(0, "@string",     { fg = syn.string })
  hl(0, "@string.rust", { fg = syn.string })
  hl(0, "@string.javascript", { fg = syn.string })
  hl(0, "@string.typescript", { fg = syn.string })
end

return M
