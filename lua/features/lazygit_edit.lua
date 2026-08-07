-- LazyGit <-> Neovim integration: pressing "e" in LazyGit opens the file in a
-- normal Neovim window (same tab by default, new tab via the one-shot flag).
-- Called by scripts/lazygit-edit through nvim --remote.
local M = {}

-- One-shot flag: next LazyGit edit opens in a new Neovim tab.
local _open_tab_next = false

function M.set_open_tab_next()
  _open_tab_next = true
end

-- True if the buffer is a Snacks terminal running LazyGit.
local function is_lazygit_buf(buf)
  if vim.bo[buf].filetype ~= "snacks_terminal" then
    return false
  end

  local meta = vim.b[buf].snacks_terminal
  local cmd = type(meta) == "table" and meta.cmd or nil
  return (type(cmd) == "table" and cmd[1] == "lazygit")
    or (type(cmd) == "string" and cmd:find("lazygit", 1, true) ~= nil)
end

-- Ask LazyGit to edit the selected file in a new tab (sends "e" to its terminal).
function M.open_tab_next_and_edit()
  _open_tab_next = true
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if is_lazygit_buf(buf) then
      local chan = vim.bo[buf].channel
      if chan and chan > 0 then
        vim.api.nvim_chan_send(chan, "e")
        return
      end
    end
  end
  _open_tab_next = false
end

-- True if the current buffer is the LazyGit terminal.
function M.is_current_lazygit()
  return is_lazygit_buf(vim.api.nvim_get_current_buf())
end

-- Focus the LazyGit terminal window across any tab; false if not open.
function M.jump_to_lazygit()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if is_lazygit_buf(buf) then
        vim.api.nvim_set_current_tabpage(tab)
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end

  return false
end

-- Open a file in a new tab, optionally at a line.
function M.open(path, line)
  if not path or path == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then return end

  local escaped = vim.fn.fnameescape(abs)
  if line and tonumber(line) and tonumber(line) > 0 then
    vim.cmd(("tabedit +%d %s"):format(tonumber(line), escaped))
  else
    vim.cmd("tabedit " .. escaped)
  end
end

-- Same-tab opens reuse a real editing window and avoid terminal/float windows.
local function normal_window_in_current_tab()
  local function usable(win)
    if vim.api.nvim_win_get_config(win).relative ~= "" then return false end
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.bo[buf].filetype ~= "snacks_terminal"
  end

  -- Prefer the current window so the file reopens exactly where it was launched from.
  local cur = vim.api.nvim_get_current_win()
  if usable(cur) then return cur end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if usable(win) then return win end
  end
end

-- The LazyGit window in the current tab, if focused.
local function current_lazygit_window()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  return is_lazygit_buf(buf) and win or nil
end

-- Close the LazyGit window after a short delay.
local function close_lazygit_window(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end, 50)
end

-- Clamp the cursor to a target column on the current line.
local function restore_cursor_col(col)
  if not col then return end
  local function restore()
    local ok_cursor, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
    if not ok_cursor then return end
    local line_len = #(vim.api.nvim_get_current_line() or "")
    pcall(vim.api.nvim_win_set_cursor, 0, { cursor[1], math.min(tonumber(col) or 0, line_len) })
  end

  restore()
  vim.schedule(restore)
end

-- LazyGit edit hook opens in this tab unless the one-shot tab flag is set.
function M.open_same_tab(path, line, col)
  if not path or path == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then return end

  if _open_tab_next then
    _open_tab_next = false
    M.open(abs, line)
    return
  end

  local lazygit_win = current_lazygit_window()
  local target = normal_window_in_current_tab()

  local escaped = vim.fn.fnameescape(abs)
  local edit_cmd
  if line and tonumber(line) and tonumber(line) > 0 then
    edit_cmd = ("edit +%d %s"):format(tonumber(line), escaped)
  else
    edit_cmd = "edit " .. escaped
  end

  if target and vim.api.nvim_win_is_valid(target) then
    vim.api.nvim_set_current_win(target)
    vim.cmd(edit_cmd)
    restore_cursor_col(col)
  else
    close_lazygit_window(lazygit_win)
    vim.defer_fn(function()
      vim.cmd(edit_cmd)
      restore_cursor_col(col)
    end, 60)
    return
  end

  close_lazygit_window(lazygit_win)
end

return M
