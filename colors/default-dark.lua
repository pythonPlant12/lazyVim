local source = vim.fn.stdpath("config") .. "/colors/islands-dark.lua"
vim.g._islands_opaque_default = true
dofile(source)
vim.g._islands_opaque_default = nil

if type(vim.g.theme_custom_hl) == "table" then
  vim.g.theme_custom_hl.name = "default-dark"
  vim.g.theme_custom_hl.snacks_match = "#FFD6A3"
end
vim.o.winblend = 0
vim.o.pumblend = 0
vim.g.colors_name = "default-dark"
