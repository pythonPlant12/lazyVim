local M = {}

local function instance_name(bufnr)
  return "__grug_far_buf_instance__" .. tostring(bufnr)
end

local function focus_open_grug_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "grug-far" then
      vim.api.nvim_set_current_win(win)
      return true
    end
  end
  return false
end

function M.open_for_buffer(bufnr, opts)
  local grug_far = require("grug-far")
  local name = instance_name(bufnr)
  opts = vim.deepcopy(opts or {})

  if not grug_far.has_instance(name) then
    opts.instanceName = name
    return grug_far.open(opts)
  end

  local inst = grug_far.get_instance(name)
  focus_open_grug_window()
  inst:open()
  if opts.prefills then
    inst:update_input_values(opts.prefills, false)
  end
  return inst
end

return M
