-- The revision label of a tab names the commit in the left pane of its
-- revision diff: the tab line shows `file @hash`, the statusline `hash (source)`.
local M = {}

-- Label the tab with the file at ref (short hash) from source; no ref drops it.
function M.set(tab, abs, ref, source)
  if not vim.api.nvim_tabpage_is_valid(tab) then return end
  vim.t[tab].revision = ref and { file = vim.fs.basename(abs), ref = ref:gsub("^(%x%x%x%x%x%x%x)%x*", "%1"), source = source } or nil
  vim.cmd.redrawtabline()
  local ok, lualine = pcall(require, "lualine")
  if ok then lualine.refresh({ place = { "statusline" } }) end
end

-- file, ref, source of the tab's label (default: current tab); nil without one.
function M.get(tab)
  local r = vim.t[tab or 0].revision
  if r then return r.file, r.ref, r.source end
end

return M
