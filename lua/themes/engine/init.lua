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

-- Colorschemes reset highlight groups, so reapply all custom layers afterward.
local function apply_all()
  transparency.apply_theme_blend()
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
