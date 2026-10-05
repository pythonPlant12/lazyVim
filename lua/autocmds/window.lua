---@diagnostic disable: undefined-global, trailing-space

-- Register window, formatting, highlight, integration, and buffer autocmds.
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Window-local options that must never reach a float or a tool pane.
local function unbind_diff(win)
  if vim.wo[win].cursorbind then vim.wo[win].cursorbind = false end
  if vim.wo[win].scrollbind then vim.wo[win].scrollbind = false end
  if vim.wo[win].diff then
    vim.api.nvim_win_call(win, function() vim.cmd("diffoff") end)
  end
end

-- Filetypes shown in tool panes: no cursorline, never bound to a diff.
local tool_pane_ft = { ["grug-far"] = true, ["neo-tree"] = true, ["lazy"] = true, ["mason"] = true, ["Trouble"] = true, ["noice"] = true }

-- New windows inherit the current window's local options, so a float or tool
-- pane opened from a window still carrying diff-mode options (cursorbind/
-- scrollbind) gets bound to it. The pane's buffer is short, so its cursor
-- drags the file's cursor and the file's cursor drags the pane's (seen with
-- the code-action list and with neo-tree opened from a diff tab). No float or
-- tool pane ever wants these, so clear them.
local function unbind_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local is_float = vim.api.nvim_win_get_config(win).relative ~= ""
      if is_float or tool_pane_ft[vim.bo[vim.api.nvim_win_get_buf(win)].filetype] then
        unbind_diff(win)
      end
    end
  end
end

vim.api.nvim_create_autocmd({ "WinNew", "WinEnter", "BufWinEnter", "FileType" }, {
  group = vim.api.nvim_create_augroup("FloatUnbindScroll", { clear = true }),
  callback = function()
    unbind_floats()
    -- Floats created without being entered land on the next tick.
    vim.schedule(unbind_floats)
  end,
})

-- Enable cursorline in every non-floating window so active rows stay consistent.
vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("FloatNoCursorLine", { clear = true }),
  callback = function()
    -- Floating windows do not have persistent rows to navigate.
    local cfg = vim.api.nvim_win_get_config(0)
    if cfg.relative ~= "" then
      vim.wo.cursorline = false
    else
      vim.wo.cursorline = true
    end
  end,
})

-- In the quickfix list, swap j/k so navigation matches its inverted ordering.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("InvertedListNavigation", { clear = true }),
  pattern = "qf",
  callback = function(event)
    vim.keymap.set("n", "j", "k", { buffer = event.buf, silent = true, desc = "List up" })
    vim.keymap.set("n", "k", "j", { buffer = event.buf, silent = true, desc = "List down" })
  end,
})
