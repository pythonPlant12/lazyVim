local source = vim.fn.stdpath("config") .. "/colors/islands-dark.lua"
vim.g._islands_opaque_default = true
dofile(source)
vim.g._islands_opaque_default = nil

-- Softer than islands-dark: the background a step lighter, a gray active line
-- and selection, and every color a little less strong (a milder Meteorite Gray
-- Dimmed: 80% of the saturation, bright colors pulled a tenth toward mid).
local bg_from, bg_to = "#151619", "#1B1C20"
local cursorline = "#222428"
local selection = "#363940"
-- Islands blue selection and active line -> gray.
local recolor_bg = { ["#253A63"] = selection, ["#1F2024"] = cursorline }

package.loaded["themes.cursor"] = nil
local dim = require("themes.cursor").dim
local function soft(hex, dark)
  hex = hex:upper()
  if hex == bg_from then return bg_to end
  if dark and recolor_bg[hex] then return recolor_bg[hex] end
  local out = dim(hex, dark, 0.8, 0.1)
  -- dim() skips dark colors; text colors there still get the saturation cut.
  if out == hex and not dark then out = dim(hex, true, 0.8, 0.1) end
  return out
end

local function soften_table(t)
  for k, v in pairs(t) do
    if type(v) == "table" then
      soften_table(v)
    elseif type(v) == "string" and v:match("^#%x%x%x%x%x%x$") then
      -- Background keys (…bg, surface, cap, container): saturation cut only.
      local key = tostring(k)
      t[k] = soft(v, key:find("bg") ~= nil or key == "surface" or key == "cap" or key == "container")
    end
  end
end

if type(vim.g.theme_custom_hl) == "table" then
  local t = vim.tbl_extend("force", vim.g.theme_custom_hl, {
    name = "default-dark",
    snacks_match = "#FFD6A3",
  })
  -- Opaque variant: statusline sits on a gray panel instead of transparency.
  t.statusline = vim.tbl_deep_extend("force", t.statusline or {}, { surface = "#2B2D30" })
  soften_table(t)
  t.select_bg = selection
  t.cursorline_bg = cursorline
  vim.g.theme_custom_hl = t
end
vim.g.colors_name = "default-dark"

-- Same LSP group coverage as the Meteorite themes, in this theme's colors.
package.loaded["themes.semantic"] = nil
require("themes.semantic").fill_lsp()

-- The theme engine and plugins set more groups on ColorScheme; soften every
-- group after them.
local function soften_groups()
  local function hex(n) return string.format("#%06X", n) end
  for name, spec in pairs(vim.api.nvim_get_hl(0, {})) do
    if not spec.link and (spec.fg or spec.bg or spec.sp) then
      if spec.fg then spec.fg = soft(hex(spec.fg), false) end
      if spec.sp then spec.sp = soft(hex(spec.sp), false) end
      if spec.bg then spec.bg = soft(hex(spec.bg), true) end
      vim.api.nvim_set_hl(0, name, spec)
    end
  end
  -- Attributes, keys and HTML/Vue element names use the variable color
  -- (white-gray).
  local variable_fg = vim.api.nvim_get_hl(0, { name = "@variable", link = false }).fg
  require("themes.semantic").apply(vim.api.nvim_set_hl, { member = { fg = variable_fg } })
  for _, g in ipairs({
    "htmlTagName", "htmlTagN", "htmlSpecialTagName",
    "@tag", "@tag.builtin", "@tag.html", "@tag.builtin.html", "@tag.vue", "@tag.builtin.vue",
    "@constructor.vue", "@lsp.type.component", "@lsp.type.component.vue",
  }) do
    vim.api.nvim_set_hl(0, g, { fg = variable_fg })
  end
  vim.api.nvim_set_hl(0, "CursorLine", { bg = cursorline })
  for _, g in ipairs({ { "CursorLineNr", cursorline }, { "Visual", selection } }) do
    local spec = vim.api.nvim_get_hl(0, { name = g[1], link = false })
    spec.bg = g[2]
    vim.api.nvim_set_hl(0, g[1], spec)
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("DefaultDarkSoften", { clear = true }),
  callback = function()
    if vim.g.colors_name == "default-dark" then soften_groups() end
  end,
})
