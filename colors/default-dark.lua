local source = vim.fn.stdpath("config") .. "/colors/islands-dark.lua"
vim.g._islands_opaque_default = true
dofile(source)
vim.g._islands_opaque_default = nil

if type(vim.g.theme_custom_hl) == "table" then
  local t = vim.tbl_extend("force", vim.g.theme_custom_hl, {
    name = "default-dark",
    snacks_match = "#FFD6A3",
  })
  -- Opaque variant: statusline sits on a gray panel instead of transparency.
  t.statusline = vim.tbl_deep_extend("force", t.statusline or {}, { surface = "#2B2D30" })
  vim.g.theme_custom_hl = t
end
vim.o.winblend = 0
vim.o.pumblend = 0
vim.g.colors_name = "default-dark"
