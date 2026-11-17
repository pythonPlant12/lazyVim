-- Single light theme: a soft off-white editor with gray panels/menus.
-- Base comes from islands-light (opaque variant); everything below overrides it.
local source = vim.fn.stdpath("config") .. "/colors/islands-light.lua"
vim.g._islands_opaque_default = true
dofile(source)
vim.g._islands_opaque_default = nil

local hl = vim.api.nvim_set_hl
local fg = "#4C4F69"
local bg = "#FCFCFC" -- editor background (soft off-white)
local panel_bg = "#F3F3F3" -- gray surface for menus / sidebar / general floats
local border = "#D0D0D0"
local string_fg = "#2F6F4E"

if type(vim.g.theme_custom_hl) == "table" then
  local t = vim.tbl_extend("force", vim.g.theme_custom_hl, {
    name = "default-light",
    string_fg = string_fg,
    snacks_match = "#2366A6",
    panel_bg = panel_bg,
    picker_bg = bg, -- pickers sit on the editor bg, not the gray panel
    ref_bg = "#ECECEF", -- word-under-cursor matches, a step darker than islands-light
    blame_fg = "#9AA1AC", -- git blame (also inlay hints), a step lighter than islands-light
  })
  -- Opaque variant: statusline sits on a gray panel instead of transparency.
  t.statusline = vim.tbl_deep_extend("force", t.statusline or {}, { surface = "#F3F3F3" })
  -- Tab bar covers the gray panel so it reads as a distinct bar.
  t.tabline = { fg = "#4C4F69", muted = "#7A7880", border = "#D0D0D0", active_bg = "#D2E4F5", active_fg = "#2F496F", bg = "#F3F3F3" }
  vim.g.theme_custom_hl = t
end

vim.g.colors_name = "default-light"

-- Strings.
for _, g in ipairs({
  "String", "Character", "htmlString", "htmlValue",
  "@string", "@string.html", "@string.vue", "@string.javascript", "@string.typescript",
}) do
  hl(0, g, { fg = string_fg })
end

-- Editor surfaces.
hl(0, "Normal",       { fg = fg, bg = bg })
hl(0, "NormalNC",     { fg = fg, bg = bg })
hl(0, "EndOfBuffer",  { fg = bg, bg = bg })
hl(0, "LineNr",       { fg = "#6E7380", bg = bg })
hl(0, "SignColumn",   { fg = "#6E7380", bg = bg })
hl(0, "FoldColumn",   { fg = "#66707C", bg = bg })
hl(0, "VertSplit",    { fg = "#C5C8CE", bg = bg })
hl(0, "WinSeparator", { fg = "#C5C8CE", bg = bg })

-- Gray panels: general floats, autocomplete menu, and Neo-tree sidebar.
for _, g in ipairs({
  "NormalFloat", "FloatTitle", "FloatFooter",
  "Pmenu",
  "NoicePopup", "NoicePopupmenu", "NoiceCmdlinePopup",
  "WhichKey", "WhichKeyNormal",
  "BlinkCmpMenu", "BlinkCmpDoc", "BlinkCmpSignatureHelp",
  "Terminal",
  "NeoTreeNormal", "NeoTreeNormalNC",
}) do
  hl(0, g, { fg = fg, bg = panel_bg })
end
hl(0, "NeoTreeSignColumn",  { fg = "#6E7380", bg = panel_bg })
hl(0, "NeoTreeEndOfBuffer", { fg = panel_bg, bg = panel_bg })

-- Gray-panel borders.
for _, g in ipairs({
  "FloatBorder", "PmenuBorder",
  "NoicePopupBorder", "NoiceCmdlinePopupBorder",
  "WhichKeyBorder",
  "BlinkCmpMenuBorder", "BlinkCmpDocBorder", "BlinkCmpDocSeparator",
  "BlinkCmpSignatureHelpBorder",
}) do
  hl(0, g, { fg = border, bg = panel_bg })
end

-- Pickers (Snacks) sit on the editor background, not the gray panel, with a
-- subtle border so they still read as floating windows.
for _, g in ipairs({
  "SnacksPickerBox", "SnacksPickerInput", "SnacksPickerList",
  "SnacksPickerPreview", "SnacksPickerTitle", "SnacksPickerFooter",
  "SnacksInputNormal", "SnacksInputTitle",
}) do
  hl(0, g, { fg = fg, bg = bg })
end
for _, g in ipairs({ "SnacksPickerBorder", "SnacksInputBorder" }) do
  hl(0, g, { fg = border, bg = bg })
end

-- Token colors follow the Meteorite (cursor.lua) category split, in this
-- theme's palette: every Treesitter + LSP group comes from the shared registry.
package.loaded["themes.semantic"] = nil
local semantic = require("themes.semantic")
local c = {
  func     = "#2D6DB8",
  special  = "#2F6E7E", -- builtin functions, literals (Meteorite teal role)
  keyword  = "#A8631A",
  type     = "#8A7220",
  param    = "#7A48B3",
  constant = "#7C52AE",
  number   = "#0E7294",
  decorator = "#3A7D50",
  comment  = "#979BAA",
  tag      = "#356FAF",
  attribute = "#8E5324", -- attribute names (class, :options, @click)
}
local langs = { "rust", "typescript", "javascript", "python", "vue" }
semantic.apply(hl, {
  ["function.call"]       = c.func,
  ["function.definition"] = c.func,
  ["function.special"]    = c.special,
  ["type"]                = c.type,
  ["type.builtin"]        = c.keyword,
  ["variable"]            = fg,
  ["variable.builtin"]    = c.keyword,
  ["member"]              = fg, -- attributes and keys: the variable color
  ["parameter"]           = c.param,
  ["parameter.builtin"]   = c.func,
  ["constant"]            = c.constant,
  ["constant.builtin"]    = c.special,
  ["enum.member"]         = c.param,
  ["namespace"]           = c.constant,
  ["decorator"]           = c.decorator,
  ["string"]              = string_fg,
  ["number"]              = c.number,
  ["boolean"]             = c.special,
  ["keyword"]             = c.keyword,
  ["operator"]            = fg,
  ["punctuation"]         = fg,
  ["comment"]             = { fg = c.comment, italic = false },
}, langs)

-- islands-light pins per-language Treesitter variants (@variable.typescript,
-- @property.vue, ...); point them back at the registry base group.
for _, groups in pairs(semantic.registry) do
  for _, g in ipairs(groups) do
    if g:sub(1, 5) ~= "@lsp." then
      for _, lang in ipairs({ "typescript", "javascript", "tsx", "python", "rust", "lua", "vue", "html" }) do
        hl(0, g .. "." .. lang, { link = g })
      end
    end
  end
end
hl(0, "@lsp.typemod.variable.self",        { link = "@variable.builtin" })
hl(0, "@lsp.typemod.variable.self.python", { link = "@variable.builtin" })
hl(0, "@lsp.typemod.class.callable",       { fg = c.type })
hl(0, "Boolean",                           { fg = c.special })
-- Readonly variables (const) keep the text color; only Treesitter @constant
-- (UPPER_CASE names) gets the constant color.
hl(0, "@lsp.typemod.variable.readonly", { fg = fg })
for _, lang in ipairs(langs) do
  hl(0, "@lsp.typemod.variable.readonly." .. lang, { fg = fg })
end

-- Keyword-like words (this, typeof, instanceof, self, and/or/not, ...) use the
-- keyword color. Vim regex syntax (used where no Treesitter parser runs, e.g.
-- <script> in .vue) links these to plain Operator/Identifier.
for _, g in ipairs({ "javaScriptOperator", "javaScriptIdentifier", "pythonOperator", "luaOperator",
  "typescriptOperator", "typescriptKeywordOp", "typescriptIdentifier" }) do
  hl(0, g, { fg = c.keyword })
end
hl(0, "@lsp.type.selfKeyword",          { link = "@variable.builtin" })
hl(0, "@lsp.type.selfKeyword.rust",     { link = "@variable.builtin" })
hl(0, "@lsp.type.selfTypeKeyword",      { link = "@variable.builtin" })
hl(0, "@lsp.type.selfTypeKeyword.rust", { link = "@variable.builtin" })

-- Template tags (HTML/Vue): Treesitter groups, the vim regex html* groups
-- (used when no Treesitter parser is active), and Vue LSP component tokens.
for _, g in ipairs({ "@tag", "@tag.builtin", "htmlTagN", "htmlTagName", "htmlSpecialTagName",
  "@keyword.directive.vue", "@keyword.modifier.vue", "@constructor.vue", "@character.special.vue" }) do
  hl(0, g, { fg = c.tag })
end
-- Delimiters share the tag color, as in Meteorite. The :, @ or # prefix of a
-- Vue directive is htmlTag too; the name after it is htmlArg
-- (after/syntax/html.vim).
for _, g in ipairs({ "@tag.delimiter", "htmlTag", "htmlEndTag" }) do
  hl(0, g, { fg = c.tag })
end
-- Attribute names (class, :options, :disabled) are orange, as in the dark theme.
for _, g in ipairs({ "@tag.attribute", "htmlArg" }) do
  hl(0, g, { fg = c.attribute })
end
for _, lang in ipairs({ "html", "vue" }) do
  hl(0, "@tag." .. lang,           { link = "@tag" })
  hl(0, "@tag.builtin." .. lang,   { link = "@tag.builtin" })
  hl(0, "@tag.attribute." .. lang, { link = "@tag.attribute" })
  hl(0, "@tag.delimiter." .. lang, { link = "@tag.delimiter" })
end
hl(0, "@lsp.type.component",     { link = "@tag" })
hl(0, "@lsp.type.component.vue", { link = "@tag" })
hl(0, "@punctuation.special",     { fg = c.special })
hl(0, "@punctuation.special.vue", { fg = c.special })
hl(0, "@function.method.vue",     { link = "@function.method" })
hl(0, "@none.vue",                { fg = fg })

-- Any registry LSP group still undefined links to its category.
semantic.fill_lsp()
