---@diagnostic disable: undefined-global, trailing-space

-- Register window, formatting, highlight, integration, and buffer autocmds.
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- New windows inherit the current window's local options, so a float opened
-- from a window still carrying diff-mode options (cursorbind/scrollbind) gets
-- bound to it. The float's buffer is short, so its cursor at line 1 drags the
-- file's cursor to line 1 as well — the file appears to jump and come back
-- (seen with the code-action list). No float ever wants these, so clear them.
local function unbind_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative ~= "" then
      if vim.wo[win].cursorbind then vim.wo[win].cursorbind = false end
      if vim.wo[win].scrollbind then vim.wo[win].scrollbind = false end
      if vim.wo[win].diff then
        vim.api.nvim_win_call(win, function() vim.cmd("diffoff") end)
      end
    end
  end
end

vim.api.nvim_create_autocmd({ "WinNew", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("FloatUnbindScroll", { clear = true }),
  callback = function()
    unbind_floats()
    -- Floats created without being entered land on the next tick.
    vim.schedule(unbind_floats)
  end,
})

-- Enable cursorline in normal edit windows, disable it in floats and tool panes.
vim.api.nvim_create_autocmd("WinEnter", {
  group = vim.api.nvim_create_augroup("FloatNoCursorLine", { clear = true }),
  callback = function()
    -- Cursorline is useful in edit windows but noisy inside floats/tool panes.
    local cfg = vim.api.nvim_win_get_config(0)
    if cfg.relative ~= "" then
      vim.wo.cursorline = false
    else
      local ft = vim.bo.filetype
      local excluded = { ["grug-far"] = true, ["neo-tree"] = true, ["lazy"] = true, ["mason"] = true, ["Trouble"] = true, ["noice"] = true }
      if not excluded[ft] then
        vim.wo.cursorline = true
      end
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
