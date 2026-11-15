-- Theme engine entry point: applies the active theme's colors to all plugin
-- UIs and re-applies them whenever the colorscheme or relevant windows change.
-- Per-theme colors live in colors/<theme>.lua; this file only wires events.
local transparency = require("themes.engine.transparency")
local normalize = require("themes.engine.normalize")
local opaque = require("themes.engine.opaque")
local plugin_groups = require("themes.engine.plugin_groups")
local html = require("themes.engine.html")
local palette = require("themes.engine.palette")
local rose_pine_dawn = require("themes.overrides.rose-pine-dawn")

-- Vim's regex javascript syntax (.vue <script> without a Treesitter parser)
-- links plain code to Special and braces to Function; keep them text-colored so
-- only LSP tokens add color.
local function apply_regex_js_hl()
  vim.api.nvim_set_hl(0, "javaScript", { link = "Identifier" })
  vim.api.nvim_set_hl(0, "javaScriptBraces", { link = "Identifier" })
end

-- Colorschemes reset highlight groups, so reapply all custom layers afterward.
local function apply_all()
  apply_regex_js_hl()
  transparency.apply_snacks_backdrop()
  rose_pine_dawn.apply()
  plugin_groups.apply_custom_hl()
  normalize.apply_cursor_hl()
  normalize.schedule_plain_keyword_hl()
  normalize.schedule_semantic_token_hl()
  opaque.schedule_default_opaque_hl()
  transparency.schedule_transparent_hl()
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("CustomHl", { clear = true }),
  callback = apply_all,
})
apply_all()

-- Diagnostic floats get their own opaque surface colors.
do
  local open_diagnostic_float = vim.diagnostic.open_float
  vim.diagnostic.open_float = function(...)
    local bufnr, win = open_diagnostic_float(...)
    if win and vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winhighlight = "NormalFloat:DiagnosticFloat,FloatBorder:DiagnosticFloatBorder"
    end
    return bufnr, win
  end
end

-- Some plugins create highlights after load/attach; delayed reapplies keep them aligned.
vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "TermOpen", "LspAttach" }, {
  group = vim.api.nvim_create_augroup("PlainKeywordHl", { clear = true }),
  callback = function()
    normalize.schedule_plain_keyword_hl()
    normalize.schedule_semantic_token_hl()
    opaque.schedule_default_opaque_hl()
  end,
})

-- Window events catch context/lazygit floating windows without doing work on every move.
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
  group = vim.api.nvim_create_augroup("DefaultOpaqueHl", { clear = true }),
  callback = opaque.schedule_default_opaque_hl,
})

vim.api.nvim_create_autocmd("User", {
  pattern = { "VeryLazy", "LazyLoad" },
  group = vim.api.nvim_create_augroup("DefaultOpaquePluginHl", { clear = true }),
  callback = opaque.schedule_default_opaque_hl,
})

-- Once Snacks loads, wrap its set_hl to inject theme-aware diff colors on defaults.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  group = vim.api.nvim_create_augroup("SnacksPickerDiffHl", { clear = true }),
  once = true,
  callback = function()
    if Snacks == nil then return end
    local orig_set_hl = Snacks.util.set_hl
    Snacks.util.set_hl = function(groups, opts)
      if opts and opts.default then
        local c = palette.get()
        local context_bg = transparency.is_transparent_theme() and "NONE"
          or palette.color_from_hl("Normal", "bg", c.diff_context or c.ref_bg)
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

-- Lazy.nvim has its own buffer highlights; align them with the active light/dark mode.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lazy",
  group = vim.api.nvim_create_augroup("LazyHl", { clear = true }),
  callback = function()
    local is_light = vim.o.background == "light"
    local selection_bg = palette.get().select_bg
    local hl = vim.api.nvim_set_hl
    if is_light then
      hl(0, "LazyNormal",     { fg = "#2F496F", bg = "#EAF2FB" })
      hl(0, "LazyCursorLine", { fg = "#2F496F", bg = selection_bg, bold = true })
    else
      hl(0, "LazyNormal",     { fg = "#E8F0FA", bg = "#1C2D40" })
      hl(0, "LazyCursorLine", { fg = "#E8F0FA", bg = selection_bg, bold = true })
    end
    vim.opt_local.winhighlight = "Normal:LazyNormal,CursorLine:LazyCursorLine"
  end,
})

-- grug-far result matches reuse the Search colors of the active theme.
local function apply_grugfar_hl()
  local search = vim.api.nvim_get_hl(0, { name = "Search", link = false })
  vim.api.nvim_set_hl(0, "GrugFarResultsMatch", { bg = search.bg, fg = search.fg, bold = search.bold })
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("GrugFarHl", { clear = true }),
  callback = apply_grugfar_hl,
})
apply_grugfar_hl()

-- Template languages (HTML/Vue/Jinja) re-align when opened or after theme changes.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("HtmlTsColors", { clear = true }),
  pattern = { "html", "vue", "jinja", "jinja2", "htmldjango" },
  callback = function()
    vim.schedule(html.apply)
  end,
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("HtmlTsColorsScheme", { clear = true }),
  callback = html.apply,
})
html.apply()

-- default-light: self/this/super/cls arrive from some servers as plain
-- variables or classes (lua_ls self, Python super); give them the keyword
-- color like Treesitter's @variable.builtin.
local self_words = { self = true, this = true, super = true, cls = true }
vim.api.nvim_create_autocmd("LspTokenUpdate", {
  group = vim.api.nvim_create_augroup("SelfKeywordHl", { clear = true }),
  callback = function(args)
    if vim.g.colors_name ~= "default-light" then return end
    local token = args.data.token
    if token.line ~= token.end_line then return end
    local line = vim.api.nvim_buf_get_lines(args.buf, token.line, token.line + 1, false)[1] or ""
    if self_words[line:sub(token.start_col + 1, token.end_col)] then
      vim.lsp.semantic_tokens.highlight_token(token, args.buf, args.data.client_id, "@variable.builtin", { priority = 130 })
    end
  end,
})

-- Vue templates: the server sends every <script> binding (constants, refs,
-- props) as a property, like a real member access. Give the top-level ones
-- (not after a ".") the variable color they have in <script>.
local function in_vue_script(buf, row, col)
  local ok, node = pcall(vim.treesitter.get_node, { bufnr = buf, pos = { row, col }, ignore_injections = true })
  while ok and node do
    if node:type() == "script_element" then return true end
    node = node:parent()
  end
  return false
end
vim.api.nvim_create_autocmd("LspTokenUpdate", {
  group = vim.api.nvim_create_augroup("VueTemplateBindingHl", { clear = true }),
  callback = function(args)
    local token = args.data.token
    if token.type ~= "property" or token.line ~= token.end_line or vim.bo[args.buf].filetype ~= "vue" then return end
    local line = vim.api.nvim_buf_get_lines(args.buf, token.line, token.line + 1, false)[1] or ""
    if line:sub(1, token.start_col):match("%.%s*$") or in_vue_script(args.buf, token.line, token.start_col) then return end
    vim.lsp.semantic_tokens.highlight_token(token, args.buf, args.data.client_id, "@variable", { priority = 130 })
  end,
})
