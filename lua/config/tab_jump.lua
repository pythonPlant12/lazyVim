local M = {}

local uv = vim.uv or vim.loop

local function canonical(path)
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

local function ordered_tabs(prefer_other_tabs)
  local current = vim.api.nvim_get_current_tabpage()
  local tabs = vim.api.nvim_list_tabpages()
  if prefer_other_tabs == false then
    return tabs
  end

  local ordered = {}
  for _, tab in ipairs(tabs) do
    if tab ~= current then
      ordered[#ordered + 1] = tab
    end
  end
  ordered[#ordered + 1] = current
  return ordered
end

local function find_visible(match, opts)
  for _, tab in ipairs(ordered_tabs(opts and opts.prefer_other_tabs)) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local cfg = vim.api.nvim_win_get_config(win)
      if cfg.relative == "" and not vim.w[win].snacks_picker_preview then
      local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype ~= "snacks_picker_preview" and match(buf, win, tab) then
          return tab, win, buf
        end
      end
    end
  end
end

local function restore_window_buf(bufnr, restore)
  if not restore or not restore.win or not restore.buf then
    return
  end
  if restore.buf == bufnr then
    return
  end
  if not vim.api.nvim_win_is_valid(restore.win) or not vim.api.nvim_buf_is_valid(restore.buf) then
    return
  end
  if vim.api.nvim_win_get_buf(restore.win) ~= bufnr then
    return
  end
  pcall(vim.api.nvim_win_set_buf, restore.win, restore.buf)
end

local function goto_visible(tab, win, bufnr, opts)
  if not (tab and win) then
    return false
  end

  local current_tab = vim.api.nvim_get_current_tabpage()
  if tab ~= current_tab then
    restore_window_buf(bufnr, opts and opts.restore)
    vim.api.nvim_set_current_tabpage(tab)
  end
  if vim.api.nvim_get_current_win() ~= win then
    vim.api.nvim_set_current_win(win)
  end
  return true
end

function M.find_visible_buf(bufnr, opts)
  if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, nil, nil
  end
  return find_visible(function(buf)
    return buf == bufnr
  end, opts)
end

function M.find_visible_path(path, opts)
  local target = canonical(path)
  if not target then
    return nil, nil, nil
  end
  return find_visible(function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    return name ~= "" and canonical(name) == target
  end, opts)
end

function M.goto_visible_buf(bufnr, opts)
  local tab, win = M.find_visible_buf(bufnr, opts)
  return goto_visible(tab, win, bufnr, opts)
end

function M.goto_visible_path(path, opts)
  local tab, win, bufnr = M.find_visible_path(path, opts)
  return goto_visible(tab, win, bufnr, opts)
end

function M.edit_or_goto_path(path, opts)
  if M.goto_visible_path(path, opts) then
    return true
  end

  local escaped = vim.fn.fnameescape(path)
  local ok, err = pcall(vim.cmd, "edit " .. escaped)
  if not ok then
    return false, err
  end
  return true
end

function M.jump(motion)
  local pre_buf = vim.api.nvim_get_current_buf()
  local pre_win = vim.api.nvim_get_current_win()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(motion, true, false, true), "n", false)

  vim.schedule(function()
    local post_buf = vim.api.nvim_get_current_buf()
    if post_buf == pre_buf or not vim.api.nvim_buf_is_valid(post_buf) then
      return
    end
    if vim.bo[post_buf].buftype ~= "" or vim.api.nvim_buf_get_name(post_buf) == "" then
      return
    end
    M.goto_visible_buf(post_buf, {
      restore = { win = pre_win, buf = pre_buf },
    })
  end)
end

return M
