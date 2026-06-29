---@diagnostic disable: undefined-global, unused-local, unused-function

local M = {}

local _open_tab_next = false

function M.set_open_tab_next()
  _open_tab_next = true
end

local function is_lazygit_buf(buf)
  if vim.bo[buf].filetype ~= "snacks_terminal" then
    return false
  end

  local meta = vim.b[buf].snacks_terminal
  local cmd = type(meta) == "table" and meta.cmd or nil
  return (type(cmd) == "table" and cmd[1] == "lazygit")
    or (type(cmd) == "string" and cmd:find("lazygit", 1, true) ~= nil)
end

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

function M.is_current_lazygit()
  return is_lazygit_buf(vim.api.nvim_get_current_buf())
end

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

local function capture_origin()
  local ok_cursor, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
  local ok_view, view = pcall(vim.fn.winsaveview)

  return {
    tab = vim.api.nvim_get_current_tabpage(),
    win = vim.api.nvim_get_current_win(),
    cursor = ok_cursor and cursor or nil,
    view = ok_view and view or nil,
  }
end

local function restore_origin(origin)
  if not origin then return end

  vim.schedule(function()
    if origin.tab and vim.api.nvim_tabpage_is_valid(origin.tab) then
      pcall(vim.api.nvim_set_current_tabpage, origin.tab)
    end
    if origin.win and vim.api.nvim_win_is_valid(origin.win) then
      pcall(vim.api.nvim_set_current_win, origin.win)
      if origin.view then pcall(vim.fn.winrestview, origin.view) end
      if origin.cursor then pcall(vim.api.nvim_win_set_cursor, origin.win, origin.cursor) end
    end
  end)
end

local function close_diff_tab(origin, opts)
  local ok_cursor, cursor = pcall(vim.api.nvim_win_get_cursor, 0)

  if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("tabclose")
  else
    vim.cmd("diffoff!")
    vim.cmd("only")
  end

  if opts and opts.target_path then
    vim.schedule(function()
      M.open_same_tab(opts.target_path, ok_cursor and cursor[1] or nil, ok_cursor and cursor[2] or nil)
    end)
  else
    restore_origin(origin)
  end
end

local function bind_q_in_tab(origin, opts)
  local tabpage = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buf = vim.api.nvim_win_get_buf(win)
    vim.keymap.set("n", "q", function() close_diff_tab(origin, opts) end, { buffer = buf, silent = true })
  end
end

local function git_show(git_root, rev, relpath)
  local out = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(git_root)
    .. " show " .. vim.fn.shellescape(rev .. ":" .. relpath)
  )
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(out, "\n")
  end
  return out
end

local function git_root_for(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  local result = vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 then return nil end
  return result[1]
end

local function make_rev_buf(name, lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].swapfile   = false
  vim.bo[buf].modifiable = false
  if ft then vim.bo[buf].filetype = ft end
  return buf
end

function M._open_two_buf_diff(left_name, left_lines, right_name, right_lines, ft, opts)
  local origin = capture_origin()
  vim.cmd("tabnew")

  local left = make_rev_buf(left_name, left_lines, ft)
  vim.api.nvim_win_set_buf(0, left)

  vim.cmd("vsplit")
  local right = make_rev_buf(right_name, right_lines, ft)
  vim.api.nvim_win_set_buf(0, right)

  vim.cmd("windo diffthis")
  bind_q_in_tab(origin, opts)
end

function M.diff(path)
  if not path or path == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then return end

  local root = git_root_for(abs)
  if not root then
    vim.notify("Not a git repo: " .. abs, vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end

  local relpath = abs:sub(#root + 2)
  local ft = vim.filetype.match({ filename = relpath })

  local before = git_show(root, "HEAD", relpath) or {}
  local after
  if vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p") == abs then
    after = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  elseif vim.fn.filereadable(abs) == 1 then
    after = vim.fn.readfile(abs)
  else
    after = {}
  end

  M._open_two_buf_diff("HEAD:" .. relpath, before, "worktree:" .. relpath, after, ft, { target_path = abs })
end

function M.diff_commit(path, hash)
  if not path or path == "" or not hash or hash == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  local root = git_root_for(abs)
  if not root then
    vim.notify("Not a git repo: " .. abs, vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end

  local relpath = abs:sub(#root + 2)
  local ft = vim.filetype.match({ filename = relpath })

  local before, err1 = git_show(root, hash .. "^", relpath)
  local after,  err2 = git_show(root, hash,         relpath)

  if not before then
    vim.notify("Cannot get " .. hash .. "^:" .. relpath .. "\n" .. (err1 or ""), vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  if not after then
    vim.notify("Cannot get " .. hash .. ":" .. relpath .. "\n" .. (err2 or ""), vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end

  local short = hash:sub(1, 8)
  M._open_two_buf_diff(short .. "^:" .. relpath, before, short .. ":" .. relpath, after, ft)
end

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

local function normal_window_in_current_tab()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative == "" then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "snacks_terminal" then
        return win
      end
    end
  end
end

local function current_lazygit_window()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  return is_lazygit_buf(buf) and win or nil
end

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
