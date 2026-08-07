-- Tab bar (bufferline) colors for the active theme.
-- A theme may publish `vim.g.theme_custom_hl.tabline`; otherwise light/dark
-- defaults apply, with a small special case for the external rose-pine plugin.
local M = {}

function M.get()
  local t = vim.g.theme_custom_hl
  if type(t) == "table" and t.name == vim.g.colors_name and type(t.tabline) == "table" then
    return t.tabline
  end

  -- External rose-pine plugin themes have no theme file of their own.
  local name = vim.g.colors_name or ""
  if name:find("rose%-pine") and vim.o.background == "dark" then
    return { fg = "#e0def4", muted = "#908caa", border = "#524f67", active_bg = "#26233a", active_fg = "#e0def4", bg = "NONE" }
  end

  if vim.o.background == "light" then
    return { fg = "#4C4F69", muted = "#7A7880", border = "#B8B2A8", active_bg = "#D2E4F5", active_fg = "#2F496F", bg = "NONE" }
  end
  return { fg = "#BCBEC4", muted = "#6F737A", border = "#4A4F57", active_bg = "#2F496F", active_fg = "#E8F0FA", bg = "NONE" }
end

return M
