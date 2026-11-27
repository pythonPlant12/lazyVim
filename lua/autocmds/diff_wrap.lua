-- Keep the two sides of a diff aligned when 'wrap' is on. Diff mode aligns by
-- buffer line, so a line that wraps to more rows on one side moves the rest of
-- that side down. Blank virtual lines under the shorter side fill the gap.
local ns = vim.api.nvim_create_namespace("diff_wrap")
local padded = {}
-- Per aligned window: the other window, and the screen row each line starts
-- on, counted from the top of the buffer.
local layout = {}

-- The buffer line of each diff row of `win` (false for a filler row).
local function diff_rows(win)
  return vim.api.nvim_win_call(win, function()
    local rows, last = {}, vim.api.nvim_buf_line_count(0)
    for lnum = 1, last + 1 do
      for _ = 1, vim.fn.diff_filler(lnum) do rows[#rows + 1] = false end
      if lnum <= last then rows[#rows + 1] = lnum end
    end
    return rows
  end)
end

local function height(win, lnum)
  if not lnum then return 1 end
  return vim.api.nvim_win_text_height(win, { start_row = lnum - 1, start_vcol = 0, end_row = lnum - 1 }).all
end

local function view_of(win)
  return vim.api.nvim_win_call(win, vim.fn.winsaveview)
end

local function set_view(win, view)
  vim.api.nvim_win_call(win, function() vim.fn.winrestview(view) end)
  view = view_of(win)
  if layout[win] then layout[win].set = view.topline .. ":" .. view.topfill end
end

-- Scroll the other side to the screen row `win` starts on. Neovim's own
-- scroll sync counts filler rows only, so the padding rows move the sides apart.
local function sync(win)
  local own = layout[win]
  local peer = own and layout[own.other]
  if not (peer and vim.api.nvim_win_is_valid(own.other)) then return end
  local view = view_of(win)
  if not own.starts[view.topline] then return end
  -- Neovim hides the rows above line 1 on a jump to the top.
  if view.topline == 1 and own.top ~= 1 then
    set_view(win, { topfill = own.starts[1] })
    view = view_of(win)
  end
  own.top = view.topline
  local row, topline = own.starts[view.topline] - view.topfill, #peer.starts
  for lnum, start in ipairs(peer.starts) do
    if start >= row then
      topline = lnum
      break
    end
  end
  set_view(own.other, { topline = topline, topfill = math.max(peer.starts[topline] - row, 0) })
  peer.top = topline
end

-- Put the rows each side lacks under the nearest line above them (above
-- line 1 when there is none).
local function align(wins)
  local rows = { diff_rows(wins[1]), diff_rows(wins[2]) }
  local pad, last, starts, offset = { {}, {} }, {}, { {}, {} }, 0
  for row = 1, math.max(#rows[1], #rows[2]) do
    local lnums = { rows[1][row] or false, rows[2][row] or false }
    local heights = { height(wins[1], lnums[1]), height(wins[2], lnums[2]) }
    for side = 1, 2 do
      if lnums[side] then starts[side][lnums[side]] = offset end
      last[side] = lnums[side] or last[side]
      local missing = heights[3 - side] - heights[side]
      if missing > 0 then
        local key = last[side] or 0
        pad[side][key] = (pad[side][key] or 0) + missing
      end
    end
    offset = offset + math.max(heights[1], heights[2])
  end
  for side = 1, 2 do
    local buf = vim.api.nvim_win_get_buf(wins[side])
    padded[buf] = true
    for lnum, count in pairs(pad[side]) do
      local lines = {}
      for i = 1, count do lines[i] = { { "" } } end
      vim.api.nvim_buf_set_extmark(buf, ns, math.max(lnum, 1) - 1, 0, { virt_lines = lines, virt_lines_above = lnum == 0 })
    end
    layout[wins[side]] = { other = wins[3 - side], starts = starts[side] }
  end
  local cur = vim.api.nvim_get_current_win()
  sync(layout[cur] and cur or wins[1])
end

local function refresh()
  for buf in pairs(padded) do
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1) end
  end
  local was_padded = padded
  padded, layout = {}, {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    local wins = vim.tbl_filter(function(w) return vim.wo[w].diff end, vim.api.nvim_tabpage_list_wins(tab))
    if #wins == 2 and vim.wo[wins[1]].wrap and vim.wo[wins[2]].wrap then
      align(wins)
    else
      for _, w in ipairs(wins) do
        -- The window keeps its count of rows above line 1 without the padding.
        if was_padded[vim.api.nvim_win_get_buf(w)] and view_of(w).topline == 1 then
          set_view(w, { topfill = vim.api.nvim_win_call(w, function() return vim.fn.diff_filler(1) end) })
        end
      end
    end
  end
end

local pending = false
local function schedule_refresh()
  if pending then return end
  pending = true
  vim.defer_fn(function()
    pending = false
    refresh()
  end, 30)
end

local group = vim.api.nvim_create_augroup("diff_wrap", { clear = true })

-- <leader>uw sets 'wrap' in one window; the other side of the diff follows.
vim.api.nvim_create_autocmd("OptionSet", {
  group = group,
  pattern = "wrap",
  callback = function()
    local win = vim.api.nvim_get_current_win()
    if not vim.wo[win].diff then return end
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[w].diff and vim.wo[w].wrap ~= vim.wo[win].wrap then vim.wo[w].wrap = vim.wo[win].wrap end
    end
    schedule_refresh()
  end,
})

vim.api.nvim_create_autocmd({ "DiffUpdated", "WinResized", "WinClosed", "TextChanged", "TextChangedI" }, {
  group = group,
  callback = schedule_refresh,
})
vim.api.nvim_create_autocmd("OptionSet", { group = group, pattern = "diff", callback = schedule_refresh })

-- Follow the window the user scrolled, not one that sync() moved.
vim.api.nvim_create_autocmd("WinScrolled", {
  group = group,
  callback = function()
    local function scrolled(win)
      local view = layout[win] and vim.v.event[tostring(win)] and view_of(win)
      return view and view.topline .. ":" .. view.topfill ~= layout[win].set
    end
    local cur = vim.api.nvim_get_current_win()
    if scrolled(cur) then return sync(cur) end
    for win in pairs(layout) do
      if scrolled(win) then return sync(win) end
    end
  end,
})
