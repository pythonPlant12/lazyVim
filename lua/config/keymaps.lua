-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymaps = vim.keymap
local opts = { noremap = true, silent = true }

-- Increment/decrement
keymaps.set("n", "+", "C-a")
keymaps.set("n", "-", "C-x")

-- Select all
keymaps.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist
keymaps.set("n", "<C-m>", "<C-i>", opts)

-- New tab
keymaps.set("n", "te", "tabedit")
vim.api.nvim_set_keymap("n", "te", ":tabedit<CR>", opts)
vim.api.nvim_set_keymap("n", "tq", ":tabclose<CR>", opts)
keymaps.set("n", "<Tab>", ":tabnext<CR>", opts)
keymaps.set("n", "<s-Tab>", ":tabprev<CR>", opts)

-- Split window
keymaps.set("n", "ss", ":split<Return>", opts)
keymaps.set("n", "sv", ":vsplit<Return>", opts)

-- Resize window
keymaps.set("n", "<C-w><left>", "<C-w><")
keymaps.set("n", "<C-w><right>", "<C-w>>")
keymaps.set("n", "<C-w><up>", "<C-w>+")
keymaps.set("n", "<C-w><up>", "<C-w>-")

-- Diagnostics
keymaps.set("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)
