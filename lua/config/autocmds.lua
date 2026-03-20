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

  local function to_hex(color)
    if not color then
      return nil
    end
    return string.format("#%06x", color)
  end

  local visual = vim.api.nvim_get_hl(0, { name = "Visual", link = false })
  local visual_bg = to_hex(visual.bg) or "#35538F"

  hl(0, "Visual",                    { fg = "#CED0D6", bg = visual_bg })
  hl(0, "VisualNOS",                 { fg = "#CED0D6", bg = visual_bg })
  hl(0, "LspReferenceText",            { bg = "#2a2d31" })
  hl(0, "LspReferenceRead",            { bg = "#2a2d31" })
  hl(0, "LspReferenceWrite",           { bg = "#2a2d31" })
  hl(0, "DiagnosticVirtualTextError",  { fg = "#c44455" })
  hl(0, "DiagnosticVirtualTextWarn",   { fg = "#aa9260" })
  hl(0, "DiagnosticVirtualTextInfo",   { fg = "#4487c4" })
  hl(0, "DiagnosticVirtualTextHint",   { fg = "#7a7e85" })

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

  hl(0, "BlinkCmpKindClass",         { fg = "#EE9D28" })
  hl(0, "BlinkCmpKindEnum",          { fg = "#EE9D28" })
  hl(0, "BlinkCmpKindEvent",         { fg = "#EE9D28" })
  hl(0, "BlinkCmpKindMethod",        { fg = "#B180D7" })
  hl(0, "BlinkCmpKindFunction",      { fg = "#B180D7" })
  hl(0, "BlinkCmpKindConstructor",   { fg = "#B180D7" })
  hl(0, "BlinkCmpKindField",         { fg = "#75BEFF" })
  hl(0, "BlinkCmpKindVariable",      { fg = "#75BEFF" })
  hl(0, "BlinkCmpKindInterface",     { fg = "#75BEFF" })
  hl(0, "BlinkCmpKindEnumMember",    { fg = "#75BEFF" })
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
