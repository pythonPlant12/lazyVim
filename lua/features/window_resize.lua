-- Window resize mode (<C-w>r): h/l/j/k or arrows resize the current window in
-- steps, = equalizes, Esc/q exits. The statusline mode chip shows RESIZE WINDOW.
local M = {}

local active = false

-- Redraw lualine after toggling so the mode chip updates immediately.
local function refresh_statusline()
  vim.schedule(function()
    local ok, lualine = pcall(require, "lualine")
    if ok then lualine.refresh({ place = { "statusline" } }) end
  end)
end

-- Restore normal keys, including this config's inverted j/k movement.
function M.exit()
  if not active then return end
  active = false
  vim.g.window_resize_mode = false
  local resize_keys = { "h", "l", "j", "k", "<Left>", "<Right>", "<Up>", "<Down>", "<Esc>", "q", "=" }
  for _, k in ipairs(resize_keys) do
    pcall(vim.keymap.del, "n", k, { buffer = false })
  end
  vim.keymap.set("n", "j", "k", { silent = true })
  vim.keymap.set("n", "k", "j", { silent = true })
  vim.api.nvim_echo({}, false, {})
  refresh_statusline()
end

-- Temporarily rebind movement keys to window resizing.
function M.enter()
  if active then return end
  active = true
  vim.g.window_resize_mode = true
  local step = 3
  local map = vim.keymap.set
  local o = { nowait = true, silent = true }

  local function resize(cmd)
    return function()
      for _ = 1, step do vim.cmd("wincmd " .. cmd) end
    end
  end

  map("n", "h",       resize(">"), o)
  map("n", "l",       resize("<"), o)
  map("n", "j",       resize("+"), o)
  map("n", "k",       resize("-"), o)
  map("n", "<Left>",  resize(">"), o)
  map("n", "<Right>", resize("<"), o)
  map("n", "<Up>",    resize("+"), o)
  map("n", "<Down>",  resize("-"), o)
  map("n", "<Esc>",   M.exit, o)
  map("n", "q",       M.exit, o)
  map("n", "=",       function() vim.cmd("wincmd =") end, o)

  vim.api.nvim_echo({ { "-- RESIZE -- (h/l/j/k, <Esc> to exit)", "ModeMsg" } }, false, {})
  refresh_statusline()
end

return M
