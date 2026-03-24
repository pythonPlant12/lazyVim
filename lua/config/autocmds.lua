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

  hl(0, "NormalFloat",               { fg = normal_fg, bg = border_bg })
  hl(0, "FloatBorder",               { fg = "#585b70", bg = border_bg })
  hl(0, "PmenuBorder",               { fg = "#585b70", bg = border_bg })
  hl(0, "SnacksPickerBorder",        { fg = "#585b70", bg = border_bg })
  hl(0, "SnacksInputBorder",         { fg = "#585b70", bg = border_bg })
  hl(0, "NoiceCmdlinePopupBorder",   { fg = "#585b70", bg = border_bg })
  hl(0, "WhichKeyBorder",            { fg = "#585b70", bg = border_bg })
  hl(0, "Visual",                    { bg = "#45475a" })
  hl(0, "VisualNOS",                 { bg = "#45475a" })
  hl(0, "PmenuSel",                  { bg = "#45475a" })
  hl(0, "BlinkCmpMenuSelection",     { bg = "#45475a" })
  hl(0, "LspReferenceText",            { bg = "#2a2d31" })
  hl(0, "LspReferenceRead",            { bg = "#2a2d31" })
  hl(0, "LspReferenceWrite",           { bg = "#2a2d31" })
  hl(0, "DiagnosticVirtualTextError",  { fg = "#c44455" })
  hl(0, "DiagnosticVirtualTextWarn",   { fg = "#aa9260" })
  hl(0, "DiagnosticVirtualTextInfo",   { fg = "#4487c4" })
  hl(0, "DiagnosticVirtualTextHint",   { fg = "#7a7e85" })

  hl(0, "DiffAdd",    { bg = "#1e3028" })
  hl(0, "DiffDelete", { bg = "#361515" })
  hl(0, "DiffChange", { bg = "#2c2518" })
  hl(0, "DiffText",   { bg = "#453b25" })

  hl(0, "GitSignsAdd",    { fg = "#a6e3a1" })
  hl(0, "GitSignsChange", { fg = "#f9e2af" })
  hl(0, "GitSignsDelete", { fg = "#f38ba8" })

  hl(0, "GitSignsAddInline",      { bg = "#2a4535" })
  hl(0, "GitSignsDeleteInline",   { bg = "#4d1e1e" })
  hl(0, "GitSignsChangeInline",   { bg = "#453b25" })
  hl(0, "GitSignsAddLnInline",    { bg = "#1e3028" })
  hl(0, "GitSignsDeleteLnInline", { bg = "#361515" })
  hl(0, "GitSignsChangeLnInline", { bg = "#2c2518" })

  hl(0, "NeoTreeGitAdded",     { fg = "#a6e3a1" })
  hl(0, "NeoTreeGitUntracked", { fg = "#a6e3a1" })
  hl(0, "NeoTreeGitStaged",    { fg = "#a6e3a1" })
  hl(0, "NeoTreeGitModified",  { fg = "#e5c07b" })
  hl(0, "NeoTreeGitRenamed",   { fg = "#e5c07b" })
  hl(0, "NeoTreeGitUnstaged",  { fg = "#e5c07b" })
  hl(0, "NeoTreeGitDeleted",   { fg = "#f38ba8" })
  hl(0, "NeoTreeGitConflict",  { fg = "#f38ba8" })

  hl(0, "@variable.parameter",                  { fg = "#C5B8F0" })
  hl(0, "@variable.parameter.builtin",          { fg = "#C5B8F0" })
  hl(0, "@lsp.type.parameter",                  { fg = "#C5B8F0" })
  hl(0, "@lsp.typemod.parameter.declaration",   { fg = "#C5B8F0" })
  hl(0, "@lsp.typemod.variable.readonly",       { fg = "#C5B8F0" })
  hl(0, "@lsp.typemod.variable.parameter",      { fg = "#C5B8F0" })

  hl(0, "@variable.builtin",                    { fg = "#C77DBB" })
  hl(0, "@lsp.typemod.variable.self",           { fg = "#C77DBB" })

  hl(0, "@constructor",                         { fg = "#f9e2af" })
  hl(0, "@lsp.type.class",                      { fg = "#f9e2af" })
  hl(0, "@lsp.typemod.class.callable",          { fg = "#f9e2af" })

  hl(0, "BlinkCmpKindMethod",        { fg = "#89b4fa" })
  hl(0, "BlinkCmpKindFunction",      { fg = "#89b4fa" })
  hl(0, "BlinkCmpKindConstructor",   { fg = "#f5c2e7" })
  hl(0, "BlinkCmpKindColor",         { fg = "#f5c2e7" })
  hl(0, "BlinkCmpKindSnippet",       { fg = "#f2cdcd" })
  hl(0, "BlinkCmpKindClass",         { fg = "#f9e2af" })
  hl(0, "BlinkCmpKindEnum",          { fg = "#f9e2af" })
  hl(0, "BlinkCmpKindStruct",        { fg = "#f9e2af" })
  hl(0, "BlinkCmpKindFolder",        { fg = "#f9e2af" })
  hl(0, "BlinkCmpKindField",         { fg = "#cba6f7" })
  hl(0, "BlinkCmpKindInterface",     { fg = "#f9e2af" })
  hl(0, "BlinkCmpKindModule",        { fg = "#74c7ec" })
  hl(0, "BlinkCmpKindProperty",      { fg = "#cba6f7" })
  hl(0, "BlinkCmpKindVariable",      { fg = "#cba6f7" })
  hl(0, "BlinkCmpKindUnit",          { fg = "#94e2d5" })
  hl(0, "BlinkCmpKindTypeParameter", { fg = "#94e2d5" })
  hl(0, "BlinkCmpKindValue",         { fg = "#fab387" })
  hl(0, "BlinkCmpKindEnumMember",    { fg = "#fab387" })
  hl(0, "BlinkCmpKindKeyword",       { fg = "#f38ba8" })
  hl(0, "BlinkCmpKindConstant",      { fg = "#eba0ac" })
  hl(0, "BlinkCmpKindReference",     { fg = "#eba0ac" })
  hl(0, "BlinkCmpKindFile",          { fg = "#f5e0dc" })
  hl(0, "BlinkCmpKindEvent",         { fg = "#f5e0dc" })
  hl(0, "BlinkCmpKindText",          { fg = "#9399b2" })
  hl(0, "BlinkCmpKindOperator",      { fg = "#9399b2" })

  hl(0, "TroubleIconMethod",        { fg = "#89b4fa" })
  hl(0, "TroubleIconFunction",      { fg = "#89b4fa" })
  hl(0, "TroubleIconConstructor",   { fg = "#f5c2e7" })
  hl(0, "TroubleIconClass",         { fg = "#f9e2af" })
  hl(0, "TroubleIconEnum",          { fg = "#f9e2af" })
  hl(0, "TroubleIconStruct",        { fg = "#f9e2af" })
  hl(0, "TroubleIconFolder",        { fg = "#f9e2af" })
  hl(0, "TroubleIconField",         { fg = "#cba6f7" })
  hl(0, "TroubleIconInterface",     { fg = "#f9e2af" })
  hl(0, "TroubleIconModule",        { fg = "#74c7ec" })
  hl(0, "TroubleIconProperty",      { fg = "#cba6f7" })
  hl(0, "TroubleIconVariable",      { fg = "#cba6f7" })
  hl(0, "TroubleIconUnit",          { fg = "#94e2d5" })
  hl(0, "TroubleIconTypeParameter", { fg = "#94e2d5" })
  hl(0, "TroubleIconValue",         { fg = "#fab387" })
  hl(0, "TroubleIconEnumMember",    { fg = "#fab387" })
  hl(0, "TroubleIconKeyword",       { fg = "#f38ba8" })
  hl(0, "TroubleIconConstant",      { fg = "#eba0ac" })
  hl(0, "TroubleIconReference",     { fg = "#eba0ac" })
  hl(0, "TroubleIconFile",          { fg = "#f5e0dc" })
  hl(0, "TroubleIconEvent",         { fg = "#f5e0dc" })
  hl(0, "TroubleIconText",          { fg = "#9399b2" })
  hl(0, "TroubleIconOperator",      { fg = "#9399b2" })
  hl(0, "TroubleIconSnippet",       { fg = "#f2cdcd" })
  hl(0, "TroubleIconColor",         { fg = "#f5c2e7" })
  hl(0, "TroubleIconArray",         { fg = "#9399b2" })
  hl(0, "TroubleIconBoolean",       { fg = "#fab387" })
  hl(0, "TroubleIconKey",           { fg = "#f38ba8" })
  hl(0, "TroubleIconNamespace",     { fg = "#74c7ec" })
  hl(0, "TroubleIconNull",          { fg = "#fab387" })
  hl(0, "TroubleIconNumber",        { fg = "#fab387" })
  hl(0, "TroubleIconObject",        { fg = "#eba0ac" })
  hl(0, "TroubleIconPackage",       { fg = "#74c7ec" })
  hl(0, "TroubleIconString",        { fg = "#a6e3a1" })

  hl(0, "SnacksPickerListCursorLine",    { fg = "#fab387", bg = "#313244" })
  hl(0, "SnacksPickerFile",              { fg = "#cdd6f4", bold = true })
  hl(0, "SnacksPickerDir",               { fg = "#7f849c" })
  hl(0, "SnacksPickerMatch",             { fg = "#fab387", bold = true })
  hl(0, "SnacksPickerRow",               { fg = "#94e2d5" })
  hl(0, "SnacksPickerCol",               { fg = "#7f849c" })
  hl(0, "SnacksPickerDirectory",         { fg = "#89b4fa" })
  hl(0, "SnacksPickerPrompt",            { fg = "#cba6f7" })
  hl(0, "SnacksPickerDelim",             { fg = "#6c7086" })
  hl(0, "SnacksPickerSelected",          { fg = "#89b4fa" })
  hl(0, "SnacksPickerComment",           { fg = "#6c7086" })
  hl(0, "SnacksPickerGitStatusAdded",    { fg = "#a6e3a1" })
  hl(0, "SnacksPickerGitStatusModified", { fg = "#f9e2af" })
  hl(0, "SnacksPickerGitStatusDeleted",  { fg = "#f38ba8" })
  hl(0, "SnacksPickerGitStatusUntracked",{ fg = "#94e2d5" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CustomHl", { clear = true }),
  callback = apply_custom_hl,
})
apply_custom_hl()

local function apply_html_hl()
  local hl = vim.api.nvim_set_hl
  local blue    = "#56A8F5"
  local amber   = "#CF8E6D"
  local muted   = "#6F737A"
  local cyan    = "#2AACB8"
  hl(0, "@tag",                     { fg = blue })
  hl(0, "@tag.builtin",             { fg = blue })
  hl(0, "@tag.attribute",           { fg = amber })
  hl(0, "@tag.delimiter",           { fg = muted })
  hl(0, "@tag.html",                { fg = blue })
  hl(0, "@tag.builtin.html",        { fg = blue })
  hl(0, "@tag.attribute.html",      { fg = amber })
  hl(0, "@tag.delimiter.html",      { fg = muted })
  hl(0, "@string.special.url.html", { fg = cyan, underline = true })
  hl(0, "@tag.vue",                 { fg = blue })
  hl(0, "@tag.builtin.vue",         { fg = blue })
  hl(0, "@tag.attribute.vue",       { fg = amber })
  hl(0, "@tag.delimiter.vue",       { fg = muted })
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("HtmlTsColors", { clear = true }),
  pattern = { "html", "vue" },
  callback = apply_html_hl,
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
