---@diagnostic disable: undefined-global, trailing-space

-- Register window, formatting, highlight, integration, and buffer autocmds.
-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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
