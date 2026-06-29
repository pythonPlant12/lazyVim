---@diagnostic disable: undefined-global, trailing-space

-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("FloatNoCursorLine", { clear = true }),
  callback = function()
    local cfg = vim.api.nvim_win_get_config(0)
    if cfg.relative ~= "" then
      vim.wo.cursorline = false
    else
      local ft = vim.bo.filetype
      local excluded = { ["grug-far"] = true, ["neo-tree"] = true, ["lazy"] = true, ["mason"] = true, ["Trouble"] = true, ["noice"] = true }
      if not excluded[ft] then
        vim.wo.cursorline = true
      end
    end
  end,
})


vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("EslintAutoFix", { clear = true }),
  pattern = { "*.js", "*.jsx", "*.ts", "*.tsx", "*.vue", "*.mjs", "*.cjs" },
  callback = function()
    if vim.g.eslint_autosave == false then return end
    local clients = vim.lsp.get_clients({ name = "eslint", bufnr = 0 })
    if #clients > 0 then
      vim.lsp.buf.format({
        async = false,
        filter = function(c) return c.name == "eslint" end,
        timeout_ms = 3000,
      })
    end
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  group = vim.api.nvim_create_augroup("AutoUnzoom", { clear = true }),
  callback = function()
    if vim.t.maximized then
      vim.cmd("wincmd =")
      vim.t.maximized = false
    end
  end,
})

local function is_islands_or_catppuccin()
  local cs = vim.g.colors_name or ""
  -- exclude rose-pine variants (islands-rose-pine-light/dark have their own colorscheme files)
  if cs:find("^islands%-rose%-pine") ~= nil then return false end
  return cs:find("^islands") ~= nil or cs:find("^catppuccin") ~= nil
end

local function is_transparent_theme()
  local cs = vim.g.colors_name or ""
  return cs == "islands-dark"
    or cs == "islands-white"
    or cs == "islands-light"
    or cs:find("^islands%-rose%-pine") ~= nil
end

local function apply_theme_blend()
  local blend = is_transparent_theme() and 10 or 0
  vim.o.winblend = blend
  vim.o.pumblend = blend

  if Snacks == nil or type(Snacks.config) ~= "table" then return end

  local transparent = is_transparent_theme()
  local function merge_style(name, style)
    Snacks.config.styles = Snacks.config.styles or {}
    Snacks.config.styles[name] = vim.tbl_deep_extend("force", Snacks.config.styles[name] or {}, style)
  end

  for _, name in ipairs({
    "float",
    "help",
    "input",
    "lazygit",
    "notification",
    "notification_history",
    "scratch",
    "snacks_image",
    "terminal",
  }) do
    merge_style(name, {
      backdrop = transparent and nil or false,
      wo = { winblend = blend },
    })
  end

  Snacks.config.picker = Snacks.config.picker or {}
  Snacks.config.picker.win = Snacks.config.picker.win or {}
  for _, name in ipairs({ "input", "list", "preview" }) do
    Snacks.config.picker.win[name] = vim.tbl_deep_extend("force", Snacks.config.picker.win[name] or {}, {
      wo = { winblend = blend },
    })
  end
end

local function is_default_theme()
  local cs = vim.g.colors_name or ""
  return cs == "default-dark" or cs == "default-white"
end

local function apply_default_opaque_hl()
  if not is_default_theme() then return end

  local hl = vim.api.nvim_set_hl
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local normal_bg = (normal and normal.bg) and string.format("#%06x", normal.bg) or (vim.o.background == "light" and "#FFFFFF" or "#151619")
  local normal_fg = (normal and normal.fg) and string.format("#%06x", normal.fg) or (vim.o.background == "light" and "#4C4F69" or "#BCBEC4")
  local c = type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl or {}
  local context_bg = c.context_bg or (vim.o.background == "light" and "#E5E5E5" or "#313244")
  local border = c.border or normal_fg

  local function with_bg(group, group_bg, group_fg)
    local current = vim.api.nvim_get_hl(0, { name = group, link = false }) or {}
    current.bg = group_bg
    if group_fg then current.fg = group_fg end
    current.link = nil
    hl(0, group, current)
  end

  for _, group in ipairs({
    "NormalFloat",
    "FloatTitle",
    "FloatFooter",
    "Pmenu",
    "NoicePopup",
    "NoicePopupmenu",
    "NoiceCmdlinePopup",
    "WhichKey",
    "WhichKeyNormal",
    "BlinkCmpMenu",
    "BlinkCmpDoc",
    "BlinkCmpSignatureHelp",
    "Terminal",
    "SnacksPickerBox",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerPreview",
    "SnacksPickerTitle",
    "SnacksPickerFooter",
    "SnacksInputNormal",
    "SnacksInputTitle",
  }) do
    with_bg(group, normal_bg, normal_fg)
  end

  for _, group in ipairs({
    "FloatBorder",
    "PmenuBorder",
    "NoicePopupBorder",
    "NoiceCmdlinePopupBorder",
    "NoiceCmdlinePopupTitle",
    "WhichKeyBorder",
    "BlinkCmpMenuBorder",
    "BlinkCmpDocBorder",
    "BlinkCmpDocSeparator",
    "BlinkCmpSignatureHelpBorder",
    "SnacksPickerBorder",
    "SnacksInputBorder",
    "TreesitterContextSeparator",
  }) do
    with_bg(group, normal_bg, border)
  end

  for _, group in ipairs({
    "TreesitterContext",
    "TreesitterContextLineNumber",
    "TreesitterContextBottom",
    "TreesitterContextLineNumberBottom",
  }) do
    with_bg(group, context_bg, normal_fg)
  end

  -- nvim-treesitter-context opens noautocmd floating windows and maps only
  -- NormalFloat by default, so normal window autocommands can miss them.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local ok_context, is_context = pcall(function() return vim.w[win].treesitter_context end)
      local ok_line_number, is_line_number = pcall(function() return vim.w[win].treesitter_context_line_number end)
      local ok_terminal, terminal = pcall(function()
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.b[buf].snacks_terminal
      end)
      local is_lazygit = ok_terminal
        and type(terminal) == "table"
        and ((type(terminal.cmd) == "table" and terminal.cmd[1] == "lazygit")
          or (type(terminal.cmd) == "string" and terminal.cmd:find("lazygit", 1, true) ~= nil))
      if ok_context and is_context then
        pcall(function()
          vim.wo[win].winhl = table.concat({
            "Normal:TreesitterContext",
            "NormalNC:TreesitterContext",
            "NormalFloat:TreesitterContext",
            "FloatBorder:TreesitterContextSeparator",
            "EndOfBuffer:TreesitterContext",
          }, ",")
          vim.wo[win].winblend = vim.o.winblend
        end)
      elseif ok_line_number and is_line_number then
        pcall(function()
          vim.wo[win].winhl = table.concat({
            "Normal:TreesitterContextLineNumber",
            "NormalNC:TreesitterContextLineNumber",
            "NormalFloat:TreesitterContextLineNumber",
            "FloatBorder:TreesitterContextSeparator",
            "EndOfBuffer:TreesitterContextLineNumber",
          }, ",")
          vim.wo[win].winblend = vim.o.winblend
        end)
      elseif is_lazygit then
        pcall(function()
          vim.wo[win].winhl = table.concat({
            "Normal:NormalFloat",
            "NormalNC:NormalFloat",
            "NormalFloat:NormalFloat",
            "FloatBorder:FloatBorder",
            "EndOfBuffer:NormalFloat",
          }, ",")
          vim.wo[win].winblend = vim.o.winblend
        end)
      end
    end
  end
end

local function schedule_default_opaque_hl()
  if not is_default_theme() then return end

  apply_default_opaque_hl()
  vim.schedule(apply_default_opaque_hl)
  vim.defer_fn(apply_default_opaque_hl, 20)
  vim.defer_fn(apply_default_opaque_hl, 100)
end

local function apply_snacks_diff_hl()
  if Snacks == nil then return end
  local theme = type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl.name == vim.g.colors_name and vim.g.theme_custom_hl or {}
  local function bg(group, fallback)
    local ok, current = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    return ok and current and current.bg and string.format("#%06x", current.bg) or fallback
  end
  local diff_add = theme.diff_add or bg("DiffAdd", "NONE")
  local diff_del = theme.diff_del or bg("DiffDelete", "NONE")
  local diff_context = is_transparent_theme() and "NONE" or (theme.ref_bg or bg("Normal", "NONE"))
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

local plain_keyword_groups = {
  "@conditional",
  "@keyword",
  "@keyword.conditional",
  "@keyword.conditional.ternary",
  "@keyword.coroutine",
  "@keyword.debug",
  "@keyword.directive",
  "@keyword.directive.define",
  "@keyword.exception",
  "@keyword.function",
  "@keyword.import",
  "@keyword.modifier",
  "@keyword.operator",
  "@keyword.repeat",
  "@keyword.return",
  "@repeat",
  "@lsp.type.keyword",
}

local plain_keyword_langs = {
  "lua",
  "python",
  "javascript",
  "javascriptreact",
  "jsx",
  "typescript",
  "typescriptreact",
  "tsx",
  "rust",
  "vue",
  "html",
  "css",
  "scss",
  "jinja",
  "jinja2",
  "htmldjango",
}

local function apply_plain_keyword_hl()
  local keyword = vim.api.nvim_get_hl(0, { name = "Keyword", link = false })
  if not keyword or not keyword.fg then
    return
  end
  local keyword_fg = string.format("#%06x", keyword.fg)
  local hl = vim.api.nvim_set_hl

  for _, group in ipairs({ "Statement", "Keyword", "Conditional", "Repeat", "Label", "Exception" }) do
    hl(0, group, { fg = keyword_fg })
  end
  for _, group in ipairs(plain_keyword_groups) do
    hl(0, group, { fg = keyword_fg })
    for _, lang in ipairs(plain_keyword_langs) do
      hl(0, group .. "." .. lang, { fg = keyword_fg })
    end
  end
end

local function schedule_plain_keyword_hl()
  apply_plain_keyword_hl()
  for _, delay in ipairs({ 50, 200, 1000 }) do
    vim.defer_fn(apply_plain_keyword_hl, delay)
  end
end

local function apply_semantic_token_hl()
  local function fg(name)
    local group = vim.api.nvim_get_hl(0, { name = name, link = false })
    return group and group.fg and string.format("#%06x", group.fg) or nil
  end
  local normal_fg = fg("Normal")
  local function_fg = fg("@function") or fg("Function") or normal_fg
  local type_fg = fg("@type") or fg("Type") or normal_fg
  local variable_fg = fg("@variable") or fg("Identifier") or normal_fg
  local hl = vim.api.nvim_set_hl

  local function_groups = {
    "@lsp.type.function",
    "@lsp.type.method",
    "@lsp.typemod.function.async",
    "@lsp.typemod.function.async.typescript",
    "@lsp.typemod.function.async.javascript",
    "@lsp.typemod.function.declaration",
    "@lsp.typemod.function.declaration.typescript",
    "@lsp.typemod.function.declaration.javascript",
    "@lsp.typemod.method.declaration",
    "@lsp.typemod.method.declaration.typescript",
    "@lsp.typemod.method.declaration.javascript",
  }
  for _, group in ipairs(function_groups) do
    hl(0, group, { fg = function_fg })
  end

  local type_groups = {
    "@interface",
    "@lsp.type.interface",
    "@lsp.type.interface.rust",
    "@lsp.typemod.interface.declaration",
    "@lsp.typemod.interface.declaration.rust",
    "@lsp.typemod.interface.macro",
    "@lsp.typemod.interface.macro.rust",
    "@lsp.typemod.interface.procMacro",
    "@lsp.typemod.interface.procMacro.rust",
    "@lsp.typemod.interface.public",
    "@lsp.typemod.interface.public.rust",
  }
  for _, group in ipairs(type_groups) do
    hl(0, group, { fg = type_fg })
  end

  local variable_groups = {
    "@lsp.type.variable",
    "@lsp.type.variable.typescript",
    "@lsp.type.variable.javascript",
    "@lsp.typemod.variable.readonly",
    "@lsp.typemod.variable.readonly.typescript",
    "@lsp.typemod.variable.readonly.javascript",
    "@lsp.typemod.variable.declaration",
    "@lsp.typemod.variable.declaration.typescript",
    "@lsp.typemod.variable.declaration.javascript",
  }
  for _, group in ipairs(variable_groups) do
    hl(0, group, { fg = variable_fg })
  end
end

local function schedule_semantic_token_hl()
  apply_semantic_token_hl()
  for _, delay in ipairs({ 50, 200, 1000 }) do
    vim.defer_fn(apply_semantic_token_hl, delay)
  end
end

local function apply_cursor_hl()
  local is_light = vim.o.background == "light"
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg = normal and normal.bg and string.format("#%06x", normal.bg) or (is_light and "#FFFFFF" or "#151619")
  local cursor_text = is_light and "#FFFFFF" or bg
  local cursor = is_light and "#2A3038" or "#E8F0FA"
  local insert = is_light and "#2D6DB8" or "#56A8F5"
  local replace = is_light and "#A8631A" or "#CF8E6D"
  local hl = vim.api.nvim_set_hl

  hl(0, "Cursor",        { fg = cursor_text, bg = cursor })
  hl(0, "CursorInsert",  { fg = cursor_text, bg = insert })
  hl(0, "CursorReplace", { fg = cursor_text, bg = replace })
  hl(0, "lCursor",       { link = "CursorInsert" })
  hl(0, "CursorIM",      { link = "CursorInsert" })
  hl(0, "TermCursor",    { link = "Cursor" })
end

local function color_from_hl(group, key, fallback)
  local ok, current = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
  local value = ok and current and current[key] or nil
  return value and string.format("#%06x", value) or fallback
end

local function current_custom_hl_palette()
  if type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl.name == vim.g.colors_name then
    return vim.g.theme_custom_hl
  end

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
    fold_bg = cursorline,
    fold_fg = muted,
    blame_fg = color_from_hl("GitSignsCurrentLineBlame", "fg", muted),
  }
end

local function apply_transparent_hl()
  if not is_transparent_theme() then return end

  local hl = vim.api.nvim_set_hl
  local bgless_groups = {
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
    "LineNr",
    "EndOfBuffer",
    "WinSeparator",
    "VertSplit",
    "NeoTreeNormal",
    "NeoTreeNormalNC",
    "StatusLine",
    "StatusLineNC",
    "StatusLineTerm",
    "StatusLineTermNC",
    "lualine_transparent",
    "TabLine",
    "TabLineFill",
    "Pmenu",
    "TreesitterContext",
    "TreesitterContextLineNumber",
    "TreesitterContextBottom",
    "TreesitterContextLineNumberBottom",
    "TreesitterContextSeparator",
    "SnacksPickerBorder",
    "SnacksPickerBox",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerPreview",
    "SnacksPickerTitle",
    "SnacksPickerFooter",
    "SnacksInputNormal",
    "SnacksInputBorder",
    "SnacksInputTitle",
    "NoiceCmdlinePopup",
    "NoiceCmdlinePopupBorder",
    "NoiceCmdlinePopupTitle",
    "NoicePopup",
    "NoicePopupBorder",
    "NoicePopupmenu",
    "WhichKey",
    "WhichKeyNormal",
    "WhichKeyBorder",
    "BlinkCmpMenu",
    "BlinkCmpMenuBorder",
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    "BlinkCmpDocSeparator",
    "BlinkCmpSignatureHelp",
    "BlinkCmpSignatureHelpBorder",
    "PmenuBorder",
    "Terminal",
  }

  for _, group in ipairs(bgless_groups) do
    local current = vim.api.nvim_get_hl(0, { name = group, link = false })
    current.bg = "NONE"
    hl(0, group, current)
  end
end

local function schedule_transparent_hl()
  if not is_transparent_theme() then return end

  apply_transparent_hl()
  vim.defer_fn(apply_transparent_hl, 50)
end

local function apply_custom_hl()
  apply_theme_blend()

  local hl = vim.api.nvim_set_hl
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local border_bg = (normal and normal.bg) and string.format("#%06x", normal.bg) or "#191A1C"
  local normal_fg = (normal and normal.fg) and string.format("#%06x", normal.fg) or "#BCBEC4"
  local c = current_custom_hl_palette()

  local kind_hl_colors = {
    Text = c.text,
    Method = c.blue,
    Function = c.blue,
    Constructor = c.pink,
    Field = c.purple,
    Variable = c.purple,
    Class = c.yellow,
    Interface = c.yellow,
    Module = c.cyan,
    Property = c.purple,
    Unit = c.cyan,
    Value = c.peach,
    Enum = c.yellow,
    Keyword = c.rose,
    Snippet = c.rose,
    Color = c.pink,
    File = c.text,
    Reference = c.rose,
    Folder = c.yellow,
    EnumMember = c.peach,
    Constant = c.rose,
    Struct = c.yellow,
    Event = c.text,
    Operator = c.text,
    TypeParameter = c.cyan,
    Boolean = c.peach,
    Array = c.text,
    Object = c.rose,
    Package = c.cyan,
    String = c.green,
    Number = c.peach,
    Namespace = c.cyan,
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
  local snacks_diff_context = is_transparent_theme() and "NONE" or c.ref_bg
  hl(0, "SnacksDiffContext",         { bg = snacks_diff_context })
  hl(0, "SnacksDiffContextLineNr",   { bg = snacks_diff_context })
  hl(0, "SnacksGhDiffContext",       { bg = snacks_diff_context })
  hl(0, "SnacksGhDiffContextLineNr", { bg = snacks_diff_context })

  vim.schedule(apply_snacks_diff_hl)
  apply_cursor_hl()
  apply_plain_keyword_hl()
  apply_semantic_token_hl()

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
   hl(0, "NeoTreeCursorLine",   { fg = c.neotree_cursor_fg, bg = c.neotree_cursor_bg, bold = true })

   hl(0, "NeoTreeGitAddedCursorLine",     { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitUntrackedCursorLine", { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitStagedCursorLine",    { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitModifiedCursorLine",  { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitRenamedCursorLine",   { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitUnstagedCursorLine",  { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitDeletedCursorLine",   { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })
    hl(0, "NeoTreeGitConflictCursorLine",  { fg = c.neotree_cursor_line_fg, bg = c.neotree_cursor_bg, bold = true })

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

  hl(0, "TreesitterContext",           { fg = normal_fg, bg = c.context_bg })
  hl(0, "TreesitterContextLineNumber", { fg = c.muted_text or c.fold_fg, bg = c.context_bg })
  hl(0, "TreesitterContextBottom",     { bg = c.context_bg, underline = false })

  hl(0, "Folded",            { fg = c.fold_fg, bg = c.fold_bg })
  hl(0, "FoldColumn",        { fg = c.fold_fg, bg = c.fold_bg })
  hl(0, "UfoFoldedFg",       { fg = c.fold_fg })
  hl(0, "UfoFoldedBg",       { bg = c.fold_bg })
  hl(0, "UfoFoldedEllipsis", { fg = c.fold_fg, bg = c.fold_bg })

  hl(0, "CursorLine",   { bg = c.context_bg })
  hl(0, "CursorLineNr", { fg = normal_fg, bg = c.context_bg, bold = true })
  if is_transparent_theme() then
    apply_transparent_hl()
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CustomHl", { clear = true }),
  callback = function()
    apply_theme_blend()
    apply_custom_hl()
    apply_cursor_hl()
    schedule_plain_keyword_hl()
    schedule_semantic_token_hl()
    schedule_default_opaque_hl()
    schedule_transparent_hl()
  end,
})
apply_theme_blend()
apply_custom_hl()
schedule_plain_keyword_hl()
schedule_semantic_token_hl()
schedule_default_opaque_hl()
schedule_transparent_hl()

vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "TermOpen", "LspAttach" }, {
  group = vim.api.nvim_create_augroup("PlainKeywordHl", { clear = true }),
  callback = function()
    schedule_plain_keyword_hl()
    schedule_semantic_token_hl()
    schedule_default_opaque_hl()
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("DefaultOpaqueHl", { clear = true }),
  callback = schedule_default_opaque_hl,
})

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinScrolled" }, {
  group = vim.api.nvim_create_augroup("DefaultOpaqueDynamicHl", { clear = true }),
  callback = function()
    if not is_default_theme() then return end
    vim.schedule(apply_default_opaque_hl)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = { "VeryLazy", "LazyLoad" },
  group = vim.api.nvim_create_augroup("DefaultOpaquePluginHl", { clear = true }),
  callback = schedule_default_opaque_hl,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  group = vim.api.nvim_create_augroup("SnacksPickerDiffHl", { clear = true }),
  once = true,
  callback = function()
    if Snacks == nil then return end
    local orig_set_hl = Snacks.util.set_hl
    Snacks.util.set_hl = function(groups, opts)
      if opts and opts.default then
        local c = current_custom_hl_palette()
        local context_bg = is_transparent_theme() and "NONE" or c.ref_bg
        local overrides = {
          DiffContext       = { bg = context_bg },
          DiffContextLineNr = { bg = context_bg },
          DiffAdd           = { bg = c.diff_add },
          DiffDelete        = { bg = c.diff_del },
          DiffAddLineNr     = { bg = c.diff_add },
          DiffDeleteLineNr  = { bg = c.diff_del },
        }
        for k, v in pairs(overrides) do
          if groups[k] ~= nil then
            groups[k] = v
          end
        end
      end
      orig_set_hl(groups, opts)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lazy",
  group = vim.api.nvim_create_augroup("LazyHl", { clear = true }),
  callback = function()
    local is_light = vim.o.background == "light"
    local hl = vim.api.nvim_set_hl
    if is_light then
      hl(0, "LazyNormal",     { fg = "#2F496F", bg = "#EAF2FB" })
      hl(0, "LazyCursorLine", { fg = "#2F496F", bg = "#D2E4F5", bold = true })
    else
      hl(0, "LazyNormal",     { fg = "#E8F0FA", bg = "#1C2D40" })
      hl(0, "LazyCursorLine", { fg = "#E8F0FA", bg = "#2F496F", bold = true })
    end
    vim.opt_local.winhighlight = "Normal:LazyNormal,CursorLine:LazyCursorLine"
  end,
})

local function apply_grugfar_hl()
  local search = vim.api.nvim_get_hl(0, { name = "Search", link = false })
  vim.api.nvim_set_hl(0, "GrugFarResultsMatch", { bg = search.bg, fg = search.fg, bold = search.bold })
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("GrugFarHl", { clear = true }),
  callback = apply_grugfar_hl,
})
apply_grugfar_hl()

local function apply_html_hl()
  if not is_islands_or_catppuccin() then return end
  local hl = vim.api.nvim_set_hl
  local function copy_hl(dst, src, fallback)
    local source = vim.api.nvim_get_hl(0, { name = src, link = false })
    if source and next(source) ~= nil then
      hl(0, dst, source)
    elseif fallback then
      hl(0, dst, fallback)
    end
  end
  local blue, amber, muted, cyan, text, green
  if vim.o.background == "light" then
    blue   = "#356FAF"
    amber  = "#8E5324"
    muted  = "#7B8596"
    text   = "#4C4F69"
    green  = "#4D8454"
  else
    blue   = "#56A8F5"
    amber  = "#CF8E6D"
    muted  = "#6F737A"
    text   = "#BCBEC4"
    green  = "#a6e3a1"
  end
  hl(0, "@tag.vue",                 { link = "@tag" })
  hl(0, "@tag.builtin.vue",         { link = "@tag.builtin" })
  hl(0, "@tag.attribute.vue",       { link = "@tag.attribute" })
  hl(0, "@tag.delimiter.vue",       { link = "@tag.delimiter" })
  hl(0, "@punctuation.bracket.vue", { link = "@punctuation.bracket" })
  hl(0, "@constructor.vue",         { link = "@tag" })
  hl(0, "@lsp.type.component",      { link = "@tag" })
  hl(0, "@lsp.type.component.vue",  { link = "@tag.vue" })
  hl(0, "@keyword.directive.jinja", { fg = blue })
  hl(0, "@keyword.directive.htmldjango", { fg = blue })
  hl(0, "@tag.vue",                 { fg = blue })
  hl(0, "@tag.builtin.vue",         { fg = blue })
  hl(0, "@tag.attribute.vue",       { fg = amber })
  hl(0, "@tag.delimiter.vue",       { fg = muted })
  hl(0, "@punctuation.bracket.vue", { fg = muted })
  hl(0, "@punctuation.special.vue", { fg = blue })
  hl(0, "@constructor.vue",         { fg = blue })
  hl(0, "@attribute.vue",           { fg = amber })
  hl(0, "@keyword.directive.vue",   { fg = blue })
  hl(0, "@keyword.modifier.vue",    { fg = blue })
  copy_hl("@function.vue",            "@function",        { fg = blue })
  copy_hl("@function.special.vue",     "@variable.builtin", { fg = blue })
  copy_hl("@function.call.vue",       "@function.call",   { fg = blue })
  copy_hl("@function.method.vue",     "@function.method", { fg = blue })
  copy_hl("@function.method.call.vue", "@function.method.call", { fg = blue })
  hl(0, "@character.special.vue",   { fg = blue })
  copy_hl("@variable.vue",            "@variable",        { fg = text })
  copy_hl("@variable.member.vue",     "@variable.member", { fg = text })
  hl(0, "@none.vue",                { fg = text })
  hl(0, "@property",                { fg = text })
  copy_hl("@property.vue",            "@property",        { fg = text })
  local vue_param = vim.o.background == "light" and "#7A48B3" or "#A87EC8"
  copy_hl("@lsp.type.variable.vue",             "@lsp.type.variable",             { fg = text })
  copy_hl("@lsp.typemod.variable.readonly.vue", "@lsp.typemod.variable.readonly", { fg = text })
  copy_hl("@lsp.typemod.variable.declaration.vue", "@lsp.typemod.variable.declaration", { fg = text })
  copy_hl("@lsp.type.property.vue",             "@lsp.type.property",             { fg = text })
  copy_hl("@lsp.typemod.property.readonly.vue", "@lsp.typemod.property.readonly", { fg = text })
  copy_hl("@lsp.type.method.vue",               "@lsp.type.method",               { fg = blue })
  copy_hl("@lsp.typemod.method.declaration.vue", "@lsp.typemod.method.declaration", { fg = blue })
  copy_hl("@lsp.mod.readonly.vue",              "@lsp.typemod.variable.readonly", { fg = text })
  hl(0, "@variable.parameter.vue",                  { fg = vue_param })
  hl(0, "@variable.parameter.builtin.vue",          { fg = vue_param })
  hl(0, "@lsp.type.parameter.vue",                  { fg = vue_param })
  hl(0, "@lsp.typemod.parameter.declaration.vue",   { fg = vue_param })
  hl(0, "@lsp.typemod.parameter.readonly.vue",      { fg = vue_param })
  hl(0, "@lsp.typemod.variable.parameter.vue",      { fg = vue_param })
  hl(0, "@lsp.typemod.variable.parameter.readonly.vue", { fg = vue_param })
  hl(0, "@lsp.typemod.variable.readonly.parameter.vue", { fg = vue_param })

  local function align_vue_script_hl()
    copy_hl("@function.vue",            "@function",        { fg = blue })
    copy_hl("@function.special.vue",     "@variable.builtin", { fg = blue })
    copy_hl("@function.call.vue",       "@function.call",   { fg = blue })
    copy_hl("@function.method.vue",     "@function.method", { fg = blue })
    copy_hl("@function.method.call.vue", "@function.method.call", { fg = blue })
    copy_hl("@variable.vue",            "@variable",        { fg = text })
    copy_hl("@variable.member.vue",     "@variable.member", { fg = text })
    copy_hl("@property.vue",            "@property",        { fg = text })
    copy_hl("@lsp.type.variable.vue",             "@lsp.type.variable",             { fg = text })
    copy_hl("@lsp.typemod.variable.readonly.vue", "@lsp.typemod.variable.readonly", { fg = text })
    copy_hl("@lsp.typemod.variable.declaration.vue", "@lsp.typemod.variable.declaration", { fg = text })
    copy_hl("@lsp.type.property.vue",             "@lsp.type.property",             { fg = text })
    copy_hl("@lsp.typemod.property.readonly.vue", "@lsp.typemod.property.readonly", { fg = text })
    copy_hl("@lsp.type.method.vue",               "@lsp.type.method",               { fg = blue })
    copy_hl("@lsp.typemod.method.declaration.vue", "@lsp.typemod.method.declaration", { fg = blue })
    copy_hl("@lsp.mod.readonly.vue",              "@lsp.typemod.variable.readonly", { fg = text })
  end
  align_vue_script_hl()
  vim.defer_fn(align_vue_script_hl, 50)

  local palette = current_custom_hl_palette()
  local string_fg = palette.string_fg or green
  if palette.string_fg then
    hl(0, "String",                 { fg = string_fg })
    hl(0, "Character",              { fg = string_fg })
    hl(0, "htmlString",             { fg = string_fg })
    hl(0, "htmlValue",              { fg = string_fg })
  end
  hl(0, "@string",                  { fg = string_fg })
  hl(0, "@string.html",             { fg = string_fg })
  hl(0, "@string.vue",              { fg = string_fg })

  hl(0, "jinjaTagBlock",            { fg = blue })
  hl(0, "jinjaVarBlock",            { fg = blue })
  hl(0, "jinjaStatement",           { fg = amber })
  hl(0, "jinjaVariable",            { fg = text })
  hl(0, "jinjaFilter",              { fg = blue })
  hl(0, "jinjaNumber",              { fg = amber })
  hl(0, "jinjaOperator",            { fg = muted })
  hl(0, "jinjaComment",             { fg = muted, italic = true })

  hl(0, "djangoTagBlock",           { fg = blue })
  hl(0, "djangoVarBlock",           { fg = blue })
  hl(0, "djangoStatement",          { fg = amber })
  hl(0, "djangoFilter",             { fg = blue })
  hl(0, "djangoArgument",           { fg = text })
  hl(0, "djangoComment",            { fg = muted, italic = true })
  hl(0, "djangoComBlock",           { fg = muted, italic = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("HtmlTsColors", { clear = true }),
  pattern = { "html", "vue", "jinja", "jinja2", "htmldjango" },
  callback = function()
    vim.schedule(apply_html_hl)
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("HtmlTsColorsScheme", { clear = true }),
  callback = apply_html_hl,
})
apply_html_hl()

vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("NeoTreeBookmarkToggle", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= "neo-tree" then return end
    vim.keymap.set("n", "<C-b>b", function()
      vim.notify("Bookmarks cannot be added from neo-tree", vim.log.levels.WARN, { title = "Bookmarks" })
    end, { buffer = ev.buf, desc = "Bookmark not available in neo-tree" })
  end,
})

local function bind_lazygit_tab_nav(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "snacks_terminal" then
    return false
  end

  local meta = vim.b[buf].snacks_terminal
  if type(meta) ~= "table" then
    return false
  end

  local cmd = meta.cmd
  local is_lazygit = (type(cmd) == "table" and cmd[1] == "lazygit")
    or (type(cmd) == "string" and cmd:find("lazygit", 1, true) ~= nil)

  if not is_lazygit then
    return false
  end

  vim.keymap.set("t", "<C-j>", function()
    vim.cmd.stopinsert()
    vim.schedule(function() vim.cmd.tabprev() end)
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Previous tab from LazyGit",
  })
  vim.keymap.set("t", "<C-k>", function()
    vim.cmd.stopinsert()
    vim.schedule(function() vim.cmd.tabnext() end)
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Next tab from LazyGit",
  })
  vim.keymap.set("n", "<C-j>", ":tabprev<CR>", {
    buffer = buf,
    silent = true,
    desc = "Previous tab from LazyGit",
  })
  vim.keymap.set("n", "<C-k>", ":tabnext<CR>", {
    buffer = buf,
    silent = true,
    desc = "Next tab from LazyGit",
  })

  return true
end

local function bind_lazygit_tab_nav_deferred(buf)
  if bind_lazygit_tab_nav(buf) then
    return
  end

  vim.defer_fn(function()
    if bind_lazygit_tab_nav(buf) then
      return
    end

    vim.defer_fn(function()
      bind_lazygit_tab_nav(buf)
    end, 150)
  end, 25)
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("LazyGitTerminalTabNav", { clear = true }),
  callback = function(ev)
    bind_lazygit_tab_nav_deferred(ev.buf)
  end,
})

do
  vim.g.buf_history = vim.g.buf_history or {}

  local function push_buf_history(bufnr)
    local h = vim.g.buf_history
    if h[#h] == bufnr then return end
    table.insert(h, bufnr)
    if #h > 50 then table.remove(h, 1) end
    vim.g.buf_history = h
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("BufHistory", { clear = true }),
    callback = function(ev)
      if vim.bo[ev.buf].buftype ~= "" then return end
      if vim.api.nvim_buf_get_name(ev.buf) == "" then return end
      push_buf_history(ev.buf)
    end,
  })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CursorTheme", { clear = true }),
  callback = function()
    apply_custom_hl()
  end,
})

-- Prevent conceal-related cursor blink in JSON files.
-- Treesitter JSON has @conceal captures for " chars; with conceallevel>=1 this
-- causes a redraw (and visible cursor flicker) on every vertical cursor movement.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("JsonNoConceallevel", { clear = true }),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.concealcursor = "nvic"
  end,
})

-- Treesitter markdown highlights use (#set! conceal_lines "") to fully hide
-- fenced code block delimiters (```) when conceallevel >= 1. This makes code
-- blocks appear to collapse/vanish. Disable conceal for markdown files.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MarkdownNoConceallevel", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})
