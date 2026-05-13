---@diagnostic disable: undefined-global

local M = {}

local function instance_name(tabpage)
  return "__grug_far_tab_instance__" .. tostring(tabpage)
end

local function grug_window_instance(grug_far, tabpage)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "grug-far" then
      local inst = grug_far.get_instance(buf)
      if inst then return win, inst end
    end
  end
end

local function normalized_prefills(prefills)
  return vim.tbl_extend("force", {
    search = "",
    replacement = "",
    filesFilter = "",
    flags = "--fixed-strings",
    paths = "",
  }, prefills or {})
end

local function focus_window(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_set_current_win(win)
    return true
  end
  return false
end

local function focus_open_grug_window(grug_far, tabpage)
  local win, inst = grug_window_instance(grug_far, tabpage)
  if focus_window(win) then return inst end
end

local function focus_search_input(inst)
  inst:when_ready(function()
    vim.schedule(function()
      vim.schedule(function()
        if not inst:is_valid() then return end
        inst:open()
        pcall(function() inst:goto_input("search") end)
        if vim.api.nvim_get_current_buf() == inst:get_buf() then
          vim.cmd("startinsert!")
        end
      end)
    end)
  end)
end

function M.open_for_buffer(_, opts)
  local grug_far = require("grug-far")
  local tabpage = vim.api.nvim_get_current_tabpage()
  local name = instance_name(tabpage)
  opts = vim.deepcopy(opts or {})
  opts.prefills = normalized_prefills(opts.prefills)

  local inst = focus_open_grug_window(grug_far, tabpage)

  if not inst and grug_far.has_instance(name) then
    inst = grug_far.get_instance(name)
  end

  if not inst then
    opts.instanceName = name
    inst = grug_far.open(opts)
    focus_search_input(inst)
    return inst
  end

  inst:open()
  inst:update_input_values(opts.prefills, true)
  focus_search_input(inst)
  return inst
end

return M
