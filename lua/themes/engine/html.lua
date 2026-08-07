-- HTML/Vue/Jinja color alignment: template languages get their tags, directives,
-- and strings recolored to match the main theme palette.
local palette = require("themes.engine.palette")

local M = {}

-- Only the own islands/catppuccin-style themes want these template tweaks.
local function is_islands_or_catppuccin()
  local cs = vim.g.colors_name or ""
  -- exclude rose-pine variants (islands-rose-pine-light/dark have their own colorscheme files)
  if cs:find("^islands%-rose%-pine") ~= nil then return false end
  return cs:find("^islands") ~= nil or cs:find("^catppuccin") ~= nil
end

function M.apply()
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
  local blue, amber, muted, text, green
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

  -- Vue <script> tokens arrive late from the LSP, so re-run the alignment shortly after.
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

  local c = palette.get()
  local string_fg = c.string_fg or green
  if c.string_fg then
    hl(0, "String",                 { fg = string_fg })
    hl(0, "Character",              { fg = string_fg })
    hl(0, "htmlString",             { fg = string_fg })
    hl(0, "htmlValue",              { fg = string_fg })
  end
  hl(0, "@string",                  { fg = string_fg })
  hl(0, "@string.html",             { fg = string_fg })
  hl(0, "@string.vue",              { fg = string_fg })
  hl(0, "@string.javascript",       { fg = string_fg })
  hl(0, "@string.typescript",       { fg = string_fg })

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

return M
