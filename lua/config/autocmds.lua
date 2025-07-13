-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Set cursor highlight colors for different modes
vim.api.nvim_create_autocmd("ModeChanged", {
  callback = function()
    local mode = vim.fn.mode()
    if mode == "i" then
      vim.cmd("highlight Cursor guifg=white guibg=#c77dbb")  -- purple
      vim.cmd("highlight iCursor guifg=white guibg=#c77dbb")
    elseif mode == "v" or mode == "V" or mode == "" then
      vim.cmd("highlight Cursor guifg=white guibg=#cf8e6d")  -- orange
      vim.cmd("highlight vCursor guifg=white guibg=#cf8e6d")
    elseif mode == "n" then
      vim.cmd("highlight Cursor guifg=white guibg=#56a8f5")  -- blue
      vim.cmd("highlight nCursor guifg=white guibg=#56a8f5")
    elseif mode == "R" then
      vim.cmd("highlight Cursor guifg=white guibg=#f75464")  -- red
      vim.cmd("highlight rCursor guifg=white guibg=#f75464")
    else
      vim.cmd("highlight Cursor guifg=white guibg=#56a8f5")  -- default blue
    end
  end,
})

-- Set initial cursor colors
vim.cmd("highlight Cursor guifg=white guibg=#56a8f5")
vim.cmd("highlight iCursor guifg=white guibg=#c77dbb")
vim.cmd("highlight vCursor guifg=white guibg=#cf8e6d")
vim.cmd("highlight rCursor guifg=white guibg=#f75464")