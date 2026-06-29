local source = vim.fn.stdpath("config") .. "/colors/islands-light.lua"
dofile(source)

if type(vim.g.theme_custom_hl) == "table" then
  vim.g.theme_custom_hl.name = "islands-white"
end
vim.g.colors_name = "islands-white"
