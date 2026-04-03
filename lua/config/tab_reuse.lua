local M = {}

local uv = vim.uv or vim.loop

function M.canonical(path)
  if not path or path == "" then
    return nil
  end
  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then
    return nil
  end
  local real = uv.fs_realpath(abs)
  local normalized = vim.fs.normalize(real or abs)
  return normalized:gsub("[\\/]$", "")
end

local function find_window_for_path(canonical_path, opts)
  opts = opts or {}
  local current_tab = vim.api.nvim_get_current_tabpage()
  local tabs = vim.api.nvim_list_tabpages()
  local ordered_tabs = {}

  if opts.prefer_other_tabs == false then
    ordered_tabs = tabs
  else
    for _, tab in ipairs(tabs) do
      if tab ~= current_tab then
        table.insert(ordered_tabs, tab)
      end
    end
    table.insert(ordered_tabs, current_tab)
  end

  for _, tab in ipairs(ordered_tabs) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local bufnr = vim.api.nvim_win_get_buf(win)
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      if bufname ~= "" and M.canonical(bufname) == canonical_path then
        return tab, win
      end
    end
  end
end

function M.jump_to_path(path, opts)
  local target = M.canonical(path)
  if not target then
    return false
  end
  local tab, win = find_window_for_path(target, opts)
  if not (tab and win) then
    return false
  end
  vim.api.nvim_set_current_tabpage(tab)
  vim.api.nvim_set_current_win(win)
  return true
end

function M.find_window_for_path(path, opts)
  local target = M.canonical(path)
  if not target then
    return nil, nil
  end
  return find_window_for_path(target, opts)
end

function M.jump_to_buf(bufnr, opts)
  if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return false
  end
  return M.jump_to_path(name, opts)
end

return M
