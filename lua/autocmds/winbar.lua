---@diagnostic disable: undefined-global

-- Show the window's filename in the top-left winbar, but ONLY when the tab is
-- split across 2+ real file windows. A single window (or an editor + tool pane
-- like the explorer) gets no winbar, so nothing changes in the common case.
-- Cheap: only reacts to window layout events, never to cursor movement/scroll.
local group = vim.api.nvim_create_augroup("SplitFilenameWinbar", { clear = true })

-- Left-aligned filename tail (%t), padded from the edge.
local WINBAR = " %t "

-- Non-floating windows only; floats can't carry a winbar.
local function is_normal_win(win)
  return vim.api.nvim_win_get_config(win).relative == ""
end

-- A "real file" window: normal buftype with an actual file name (excludes
-- explorer/help/terminal/quickfix and empty scratch buffers).
local function is_file_win(win)
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= ""
end

local function update()
  local wins = vim.tbl_filter(is_normal_win, vim.api.nvim_tabpage_list_wins(0))
  local file_wins = vim.tbl_filter(is_file_win, wins)
  local split = #file_wins > 1
  for _, win in ipairs(wins) do
    vim.wo[win].winbar = (split and is_file_win(win)) and WINBAR or ""
  end
end

vim.api.nvim_create_autocmd(
  { "WinEnter", "WinLeave", "WinNew", "WinClosed", "BufWinEnter", "TabEnter" },
  {
    group = group,
    -- Defer so the window list is settled (WinClosed fires pre-removal).
    callback = function() vim.schedule(update) end,
  }
)
