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


-- Override "d" and its combinations to delete without yanking in normal mode
keymaps.set("n", "d", '"_d')
keymaps.set("n", "dd", '"_dd')
keymaps.set("n", "dw", '"_dw')
keymaps.set("n", "db", '"_db')

-- Override "d" and its combinations to delete without yanking in visual mode
keymaps.set("x", "d", '"_d')
keymaps.set("x", "dd", '"_dd')
keymaps.set("x", "dw", '"_dw')
keymaps.set("x", "db", '"_db')

-- Override "d" and its combinations to delete without yanking in operator pending mode
keymaps.set("o", "d", '"_d')
keymaps.set("o", "dd", '"_dd')
keymaps.set("o", "dw", '"_dw')
keymaps.set("o", "db", '"_db')
