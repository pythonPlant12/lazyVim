-- Share tab-aware buffer and path jumps between keymaps and picker actions.
local M = {}

local uv = vim.uv or vim.loop

-- Resolve a path to a normalized absolute real path (follows symlinks) for reliable comparison.
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

-- Return tab handles to search, putting OTHER tabs before the current one so an
-- existing copy elsewhere is preferred over the current tab.
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

-- Skip floats and picker preview windows; only jump to real editing windows.
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

-- After cross-tab jump, restore the temporary buffer shown in the old window.
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

-- Switch to the given tab/window; restore the old buffer in the window we left behind.
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

-- Locate the tab/window currently displaying the given buffer number.
function M.find_visible_buf(bufnr, opts)
  if not bufnr or bufnr <= 0 or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, nil, nil
  end
  return find_visible(function(buf)
    return buf == bufnr
  end, opts)
end

-- Locate the tab/window currently displaying the buffer for the given file path.
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

-- Jump to an existing window showing this buffer; returns true on success.
function M.goto_visible_buf(bufnr, opts)
  local tab, win = M.find_visible_buf(bufnr, opts)
  return goto_visible(tab, win, bufnr, opts)
end

-- Jump to an existing window showing this path; returns true on success.
function M.goto_visible_path(path, opts)
  local tab, win, bufnr = M.find_visible_path(path, opts)
  return goto_visible(tab, win, bufnr, opts)
end

-- Prefer already-visible buffers before opening another copy of the same path.
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

-- Wrap jumplist motions (<C-o>/<C-i>) so they land on an already-visible copy of
-- the target buffer in another tab instead of duplicating it in the current window.
function M.jump(motion)
  local pre_buf = vim.api.nvim_get_current_buf()
  local pre_win = vim.api.nvim_get_current_win()
  -- The "x" flag forces the fed motion to run immediately, so we can inspect the
  -- result synchronously (scheduling could run before the jump finished).
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(motion, true, false, true), "nx", false)

  local post_buf = vim.api.nvim_get_current_buf()
  -- Nothing to do if the motion stayed in the same buffer or landed on a scratch/no-name buffer.
  if post_buf == pre_buf or not vim.api.nvim_buf_is_valid(post_buf) then
    return
  end
  if vim.bo[post_buf].buftype ~= "" or vim.api.nvim_buf_get_name(post_buf) == "" then
    return
  end
  -- Jump to the existing tab/window showing this buffer and put the old buffer back
  -- in the window we came from (restore), avoiding a duplicate.
  M.goto_visible_buf(post_buf, {
    restore = { win = pre_win, buf = pre_buf },
  })
end

-- Cross-tab back/forward history. Neovim's jumplist is per-window, so a jump that
-- crosses tabs (e.g. gd/gr landing in another tab) leaves no breadcrumb in the
-- destination window. We record those hops here so <C-h>/<C-l> can walk them.
M._back = {}
M._forward = {}

-- Capture the current window, its buffer, and cursor as a restorable location.
local function snapshot()
  local win = vim.api.nvim_get_current_win()
  return {
    win = win,
    buf = vim.api.nvim_win_get_buf(win),
    pos = vim.api.nvim_win_get_cursor(win),
  }
end

-- True if we're currently sitting exactly where `snap` points (same win, buf, line).
local function loc_matches(snap)
  if not snap or not vim.api.nvim_win_is_valid(snap.win) then return false end
  if vim.api.nvim_get_current_win() ~= snap.win then return false end
  if vim.api.nvim_win_get_buf(snap.win) ~= snap.buf then return false end
  if snap.pos then
    local cur = vim.api.nvim_win_get_cursor(snap.win)
    if cur[1] ~= snap.pos[1] then return false end -- match by line; column may drift
  end
  return true
end

-- Move focus to `snap`: switch its tab, focus its window, restore buffer and cursor.
local function restore(snap)
  if not snap or not vim.api.nvim_win_is_valid(snap.win) then return false end
  local tab = vim.api.nvim_win_get_tabpage(snap.win)
  if vim.api.nvim_tabpage_is_valid(tab) then
    pcall(vim.api.nvim_set_current_tabpage, tab)
  end
  pcall(vim.api.nvim_set_current_win, snap.win)
  if snap.buf and vim.api.nvim_buf_is_valid(snap.buf)
    and vim.api.nvim_win_get_buf(snap.win) ~= snap.buf then
    pcall(vim.api.nvim_win_set_buf, snap.win, snap.buf)
  end
  if snap.pos then
    pcall(vim.api.nvim_win_set_cursor, snap.win, snap.pos)
  end
  return true
end

-- Run a navigation `fn`, recording the origin->destination hop if it crossed
-- windows/tabs so <C-h> can bring us back. Clears the redo (forward) stack.
function M.record(fn)
  local origin = snapshot()
  fn()
  local dest = snapshot()
  if dest.win ~= origin.win or dest.buf ~= origin.buf then
    M._back[#M._back + 1] = { origin = origin, dest = dest }
    if #M._back > 100 then table.remove(M._back, 1) end
    M._forward = {}
  end
end

-- Go back: if we're at a recorded cross-tab destination, return to its origin;
-- otherwise fall back to the normal (tab-aware) jumplist motion.
function M.back()
  local entry = M._back[#M._back]
  if entry and loc_matches(entry.dest) then
    M._back[#M._back] = nil
    entry.dest.pos = vim.api.nvim_win_get_cursor(0) -- remember spot for redo
    M._forward[#M._forward + 1] = entry
    restore(entry.origin)
    return
  end
  M.jump("<C-o>")
end

-- Go forward: redo the most recent cross-tab back, else normal jumplist forward.
function M.forward()
  local entry = M._forward[#M._forward]
  if entry and loc_matches(entry.origin) then
    M._forward[#M._forward] = nil
    entry.origin.pos = vim.api.nvim_win_get_cursor(0)
    M._back[#M._back + 1] = entry
    restore(entry.dest)
    return
  end
  M.jump("<C-i>")
end

return M
