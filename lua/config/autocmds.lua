-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here


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

local function apply_custom_hl()
  local hl = vim.api.nvim_set_hl
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local border_bg = (normal and normal.bg) and string.format("#%06x", normal.bg) or "#191A1C"
  local normal_fg = (normal and normal.fg) and string.format("#%06x", normal.fg) or "#BCBEC4"
  local is_light = vim.o.background == "light"

  local c = is_light and {
    border = "#8F98A8",
    select_bg = "#D9E7F4",
    ref_bg = "#F2F2F4",
    diag_err = "#B54A5C",
    diag_warn = "#8A6B20",
    diag_info = "#2A6296",
    diag_hint = "#6B7582",
    diff_add = "#DFF1E4",
    diff_del = "#F5DEDE",
    diff_change = "#F3E8D6",
    diff_text = "#EAD6B8",
    gadd_inline = "#D1E8D7",
    gdel_inline = "#EFD2D2",
    gchg_inline = "#EEDFC5",
    gadd_ln = "#E2F2E6",
    gdel_ln = "#F4E2E2",
    gchg_ln = "#F2E8D6",
    neotree_added = "#4D8454",
    neotree_mod = "#A8873A",
    neotree_red = "#B54A5C",
    neotree_cursor_fg = "#9E6534",
    neotree_cursor_bg = "#D8E2F0",
    param = "#6E52A8",
    vbuiltin = "#A15391",
    ctor = "#8A6B20",
    blue = "#2A6296",
    pink = "#A15391",
    rose = "#B06276",
    yellow = "#8A6B20",
    purple = "#6E52A8",
    cyan = "#2F6E7E",
    peach = "#8E5324",
    green = "#4D8454",
    text = "#4F5966",
    muted_text = "#66707C",
    snacks_line_fg = "#8E5D33",
    snacks_line_bg = "#D6E0EE",
    snacks_file = "#3E464F",
    snacks_dir = "#5E6874",
    snacks_match = "#9E6534",
    snacks_row = "#3C7E8F",
    snacks_col = "#6B7582",
    snacks_directory = "#2E6EA8",
    snacks_prompt = "#7A5EB4",
    snacks_delim = "#7B8491",
    snacks_selected = "#2E6EA8",
    snacks_comment = "#7B8491",
    snacks_search_bg = "#C8D8EE",
    indent_fg = "#D8DAE0",
    indent_scope_fg = "#8FA8C8",
    context_bg = "#f5f5f5",
  } or {
    border = "#585b70",
    select_bg = "#45475a",
    ref_bg = "#2a2d31",
    diag_err = "#c44455",
    diag_warn = "#aa9260",
    diag_info = "#4487c4",
    diag_hint = "#7a7e85",
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
    neotree_added = "#a6e3a1",
    neotree_mod = "#e5c07b",
    neotree_red = "#f38ba8",
    neotree_cursor_fg = "#fab387",
    neotree_cursor_bg = "#313244",
    param = "#C5B8F0",
    vbuiltin = "#C77DBB",
    ctor = "#f9e2af",
    blue = "#89b4fa",
    pink = "#f5c2e7",
    rose = "#eba0ac",
    yellow = "#f9e2af",
    purple = "#cba6f7",
    cyan = "#74c7ec",
    peach = "#fab387",
    green = "#a6e3a1",
    text = "#9399b2",
    muted_text = "#6c7086",
    snacks_line_fg = "#fab387",
    snacks_line_bg = "#313244",
    snacks_file = "#cdd6f4",
    snacks_dir = "#7f849c",
    snacks_match = "#fab387",
    snacks_row = "#94e2d5",
    snacks_col = "#7f849c",
    snacks_directory = "#89b4fa",
    snacks_prompt = "#cba6f7",
    snacks_delim = "#6c7086",
    snacks_selected = "#89b4fa",
    snacks_comment = "#6c7086",
    snacks_search_bg = "#1e3a5f",
    indent_fg = "#2E3138",
    indent_scope_fg = "#5B6B8A",
    context_bg = "#1e2030",
  }

  hl(0, "NormalFloat",               { fg = normal_fg, bg = border_bg })
  hl(0, "FloatBorder",               { fg = c.border, bg = border_bg })
  hl(0, "PmenuBorder",               { fg = c.border, bg = border_bg })
  hl(0, "SnacksPickerBorder",        { fg = c.border, bg = border_bg })
  hl(0, "SnacksInputBorder",         { fg = c.border, bg = border_bg })
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

  hl(0, "GitSignsAdd",    { fg = c.green })
  hl(0, "GitSignsChange", { fg = c.yellow })
  hl(0, "GitSignsDelete", { fg = c.rose })

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

  hl(0, "@variable.parameter",                { fg = c.param })
  hl(0, "@variable.parameter.builtin",        { fg = c.param })
  hl(0, "@lsp.type.parameter",                { fg = c.param })
  hl(0, "@lsp.typemod.parameter.declaration", { fg = c.param })
  hl(0, "@lsp.typemod.variable.readonly",     { fg = c.param })
  hl(0, "@lsp.typemod.variable.parameter",    { fg = c.param })

  hl(0, "@variable.builtin",          { fg = c.vbuiltin })
  hl(0, "@lsp.typemod.variable.self", { fg = c.vbuiltin })

  hl(0, "@constructor",                { fg = c.ctor })
  hl(0, "@lsp.type.class",             { fg = c.ctor })
  hl(0, "@lsp.typemod.class.callable", { fg = c.ctor })

  hl(0, "BlinkCmpKindMethod",        { fg = c.blue })
  hl(0, "BlinkCmpKindFunction",      { fg = c.blue })
  hl(0, "BlinkCmpKindConstructor",   { fg = c.pink })
  hl(0, "BlinkCmpKindColor",         { fg = c.pink })
  hl(0, "BlinkCmpKindSnippet",       { fg = c.rose })
  hl(0, "BlinkCmpKindClass",         { fg = c.yellow })
  hl(0, "BlinkCmpKindEnum",          { fg = c.yellow })
  hl(0, "BlinkCmpKindStruct",        { fg = c.yellow })
  hl(0, "BlinkCmpKindFolder",        { fg = c.yellow })
  hl(0, "BlinkCmpKindField",         { fg = c.purple })
  hl(0, "BlinkCmpKindInterface",     { fg = c.yellow })
  hl(0, "BlinkCmpKindModule",        { fg = c.cyan })
  hl(0, "BlinkCmpKindProperty",      { fg = c.purple })
  hl(0, "BlinkCmpKindVariable",      { fg = c.purple })
  hl(0, "BlinkCmpKindUnit",          { fg = c.cyan })
  hl(0, "BlinkCmpKindTypeParameter", { fg = c.cyan })
  hl(0, "BlinkCmpKindValue",         { fg = c.peach })
  hl(0, "BlinkCmpKindEnumMember",    { fg = c.peach })
  hl(0, "BlinkCmpKindKeyword",       { fg = c.rose })
  hl(0, "BlinkCmpKindConstant",      { fg = c.rose })
  hl(0, "BlinkCmpKindReference",     { fg = c.rose })
  hl(0, "BlinkCmpKindFile",          { fg = c.text })
  hl(0, "BlinkCmpKindEvent",         { fg = c.text })
  hl(0, "BlinkCmpKindText",          { fg = c.text })
  hl(0, "BlinkCmpKindOperator",      { fg = c.text })

  hl(0, "TroubleIconMethod",        { fg = c.blue })
  hl(0, "TroubleIconFunction",      { fg = c.blue })
  hl(0, "TroubleIconConstructor",   { fg = c.pink })
  hl(0, "TroubleIconClass",         { fg = c.yellow })
  hl(0, "TroubleIconEnum",          { fg = c.yellow })
  hl(0, "TroubleIconStruct",        { fg = c.yellow })
  hl(0, "TroubleIconFolder",        { fg = c.yellow })
  hl(0, "TroubleIconField",         { fg = c.purple })
  hl(0, "TroubleIconInterface",     { fg = c.yellow })
  hl(0, "TroubleIconModule",        { fg = c.cyan })
  hl(0, "TroubleIconProperty",      { fg = c.purple })
  hl(0, "TroubleIconVariable",      { fg = c.purple })
  hl(0, "TroubleIconUnit",          { fg = c.cyan })
  hl(0, "TroubleIconTypeParameter", { fg = c.cyan })
  hl(0, "TroubleIconValue",         { fg = c.peach })
  hl(0, "TroubleIconEnumMember",    { fg = c.peach })
  hl(0, "TroubleIconKeyword",       { fg = c.rose })
  hl(0, "TroubleIconConstant",      { fg = c.rose })
  hl(0, "TroubleIconReference",     { fg = c.rose })
  hl(0, "TroubleIconFile",          { fg = c.text })
  hl(0, "TroubleIconEvent",         { fg = c.text })
  hl(0, "TroubleIconText",          { fg = c.text })
  hl(0, "TroubleIconOperator",      { fg = c.text })
  hl(0, "TroubleIconSnippet",       { fg = c.rose })
  hl(0, "TroubleIconColor",         { fg = c.pink })
  hl(0, "TroubleIconArray",         { fg = c.text })
  hl(0, "TroubleIconBoolean",       { fg = c.peach })
  hl(0, "TroubleIconKey",           { fg = c.rose })
  hl(0, "TroubleIconNamespace",     { fg = c.cyan })
  hl(0, "TroubleIconNull",          { fg = c.peach })
  hl(0, "TroubleIconNumber",        { fg = c.peach })
  hl(0, "TroubleIconObject",        { fg = c.rose })
  hl(0, "TroubleIconPackage",       { fg = c.cyan })
  hl(0, "TroubleIconString",        { fg = c.green })

  hl(0, "SnacksPickerListCursorLine",    { fg = c.snacks_line_fg, bg = c.snacks_line_bg })
  hl(0, "SnacksPickerFile",              { fg = c.snacks_file, bold = true })
  hl(0, "SnacksPickerDir",               { fg = c.snacks_dir })
  hl(0, "SnacksPickerMatch",             { fg = c.snacks_match, bold = true })
  hl(0, "SnacksPickerSearch",            { bg = c.snacks_search_bg })
  hl(0, "SnacksPickerRow",               { fg = c.snacks_row })
  hl(0, "SnacksPickerCol",               { fg = c.snacks_col })
  hl(0, "SnacksPickerDirectory",         { fg = c.snacks_directory })
  hl(0, "SnacksPickerPrompt",            { fg = c.snacks_prompt })
  hl(0, "SnacksPickerDelim",             { fg = c.snacks_delim })
  hl(0, "SnacksPickerSelected",          { fg = c.snacks_selected })
  hl(0, "SnacksPickerComment",           { fg = c.snacks_comment })
  hl(0, "SnacksPickerGitStatusAdded",    { fg = c.green })
   hl(0, "SnacksPickerGitStatusModified", { fg = c.yellow })
  hl(0, "SnacksPickerGitStatusDeleted",  { fg = c.rose })
  hl(0, "SnacksPickerGitStatusUntracked",{ fg = c.cyan })

  hl(0, "RainbowDelimiterBlueMuted",   { fg = "#7a98bd" })
  hl(0, "RainbowDelimiterGoldMuted",   { fg = "#b29a72" })
  hl(0, "RainbowDelimiterCyanMuted",   { fg = "#6fa0a7" })
  hl(0, "RainbowDelimiterPurpleMuted", { fg = "#9c86c9" })
  hl(0, "RainbowDelimiterGreenMuted",  { fg = "#7f9f85" })
  hl(0, "RainbowDelimiterAmberMuted",  { fg = "#b48770" })

  hl(0, "SnacksIndent",      { fg = c.indent_fg })
  hl(0, "SnacksIndentScope", { fg = c.indent_scope_fg, bold = false })

  hl(0, "TreesitterContext",           { bg = c.context_bg })
  hl(0, "TreesitterContextLineNumber", { bg = c.context_bg })
  hl(0, "TreesitterContextBottom",     { bg = c.context_bg, underline = false })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CustomHl", { clear = true }),
  callback = apply_custom_hl,
})
apply_custom_hl()

local function apply_html_hl()
  local hl = vim.api.nvim_set_hl
  local blue, amber, muted, cyan, text, green
  if vim.o.background == "light" then
    blue   = "#356FAF"
    amber  = "#8E5324"
    muted  = "#7B8596"
    cyan   = "#2A6678"
    text   = "#4C4F69"
    green  = "#4F7C61"
  else
    blue   = "#56A8F5"
    amber  = "#CF8E6D"
    muted  = "#6F737A"
    cyan   = "#2AACB8"
    text   = "#BCBEC4"
    green  = "#a6e3a1"
  end
  hl(0, "htmlTag",                  { fg = muted })
  hl(0, "htmlEndTag",               { fg = muted })
  hl(0, "htmlTagName",              { fg = amber })
  hl(0, "htmlSpecialTagName",       { fg = blue })
  hl(0, "htmlArg",                  { fg = amber })
  hl(0, "htmlSpecialChar",          { fg = cyan })
  hl(0, "htmlString",               { fg = green })
  hl(0, "htmlValue",                { fg = green })
  hl(0, "@tag",                     { fg = blue })
  hl(0, "@tag.builtin",             { fg = blue })
  hl(0, "@tag.attribute",           { fg = amber })
  hl(0, "@tag.delimiter",           { fg = muted })
  hl(0, "@punctuation.bracket",     { fg = muted })
  hl(0, "@punctuation.special",     { fg = blue })
  hl(0, "@attribute",               { fg = amber })
  hl(0, "@tag.html",                { fg = blue })
  hl(0, "@tag.builtin.html",        { fg = blue })
  hl(0, "@tag.attribute.html",      { fg = amber })
  hl(0, "@tag.delimiter.html",      { fg = muted })
  hl(0, "@punctuation.bracket.html", { fg = muted })
  hl(0, "@string.special.url.html", { fg = cyan, underline = true })
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
  hl(0, "@function.method.vue",     { fg = blue })
  hl(0, "@character.special.vue",   { fg = blue })
  hl(0, "@variable.vue",            { fg = text })
  hl(0, "@variable.member.vue",     { fg = text })
  hl(0, "@none.vue",                { fg = text })
  hl(0, "@property",                { fg = text })
  hl(0, "@property.vue",            { fg = text })
  hl(0, "@string",                  { fg = green })
  hl(0, "@string.html",             { fg = green })
  hl(0, "@string.vue",              { fg = green })
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("HtmlTsColors", { clear = true }),
  pattern = { "html", "vue" },
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

do
  vim.g.buf_history = vim.g.buf_history or {}

  local guard = false

  local function is_picker_open()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())) do
      local ok, ft = pcall(function()
        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype or ""
      end)
      if ok and ft:find("^snacks_picker") then return true end
    end
    return false
  end

  local function push_buf_history(bufnr)
    local h = vim.g.buf_history
    if h[#h] == bufnr then return end
    table.insert(h, bufnr)
    if #h > 50 then table.remove(h, 1) end
    vim.g.buf_history = h
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("TabReuseOnBufEnter", { clear = true }),
    callback = function(ev)
      if guard then return end
      if vim.bo[ev.buf].buftype ~= "" then return end
      if vim.api.nvim_buf_get_name(ev.buf) == "" then return end
      if is_picker_open() then return end

      push_buf_history(ev.buf)

      local cur_tab = vim.api.nvim_get_current_tabpage()
      local cur_win = vim.api.nvim_get_current_win()
      local target_tab, target_win

      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        if tab ~= cur_tab then
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            if vim.api.nvim_win_get_buf(win) == ev.buf then
              target_tab, target_win = tab, win
              break
            end
          end
          if target_tab then break end
        end
      end

      if not target_tab then return end

      guard = true
      vim.schedule(function()
        local prev = vim.fn.bufnr('#')
        if prev > 0 and prev ~= ev.buf and vim.api.nvim_buf_is_valid(prev) then
          vim.api.nvim_win_set_buf(cur_win, prev)
        else
          vim.api.nvim_win_call(cur_win, function() vim.cmd("bprevious") end)
        end
        vim.api.nvim_set_current_tabpage(target_tab)
        vim.api.nvim_set_current_win(target_win)
        guard = false
      end)
    end,
  })
end
