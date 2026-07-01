-- Combine UI plugin specs in their original declaration order.
local specs = {}

for _, module in ipairs({
  "plugins.ui.pickers",
  "plugins.ui.icons",
  "plugins.ui.explorer",
  "plugins.ui.chrome",
  "plugins.ui.statusline",
}) do
  vim.list_extend(specs, require(module))
end

return specs
