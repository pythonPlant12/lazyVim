local M = {}

local function instance_name(bufnr)
  return "__grug_far_buf_instance__" .. tostring(bufnr)
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
  inst:open()
  if opts.prefills then
    inst:update_input_values(opts.prefills, false)
  end
  return inst
end

return M
