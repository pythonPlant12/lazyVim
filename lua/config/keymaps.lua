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
keymaps.set("n", "<C-i>", "<C-o>", opts)
keymaps.set("n", "<C-o>", "<C-i>", opts)
keymaps.set("n", "<D-i>", "<C-o>", opts)
keymaps.set("n", "<D-o>", "<C-i>", opts)
keymaps.set("n", "<leader>i", "<C-o>", opts)
keymaps.set("n", "<leader>o", "<C-i>", opts)

keymaps.set("n", "zc", "za", opts)

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

-- Swap j/k (j=up, k=down)
keymaps.set("n", "j", "k", opts)
keymaps.set("n", "k", "j", opts)
keymaps.set("v", "j", "k", opts)
keymaps.set("v", "k", "j", opts)

-- Delete without copying to clipboard (black hole register)
keymaps.set("n", "d", '"_d', opts)
keymaps.set("n", "D", '"_D', opts)
keymaps.set("n", "dd", '"_dd', opts)
keymaps.set("n", "dw", '"_dw', opts)
keymaps.set("n", "dW", '"_dW', opts)
keymaps.set("n", "db", '"_db', opts)
keymaps.set("n", "dB", '"_dB', opts)
keymaps.set("n", "c", '"_c', opts)
keymaps.set("n", "C", '"_C', opts)
keymaps.set("n", "cc", '"_cc', opts)
keymaps.set("n", "cw", '"_cw', opts)
keymaps.set("n", "cW", '"_cW', opts)
keymaps.set("n", "cb", '"_cb', opts)
keymaps.set("n", "cB", '"_cB', opts)
keymaps.set("n", "x", '"_x', opts)
keymaps.set("n", "X", '"_X', opts)
keymaps.set("n", "s", '"_s', opts)
keymaps.set("v", "d", '"_d', opts)
keymaps.set("v", "D", '"_D', opts)
keymaps.set("v", "c", '"_c', opts)
keymaps.set("v", "C", '"_C', opts)
keymaps.set("v", "x", '"_x', opts)
keymaps.set("v", "s", '"_s', opts)

-- Line navigation
keymaps.set("n", "B", "^", { desc = "Go to beginning of line" })
keymaps.set("n", "W", "$", { desc = "Go to end of line" })
keymaps.set("v", "B", "^", { desc = "Go to beginning of line" })
keymaps.set("v", "W", "$", { desc = "Go to end of line" })
keymaps.set("n", "zc", "za", opts)

-- Hover (show definition/error)
keymaps.set("n", "<leader>k", function()
  vim.lsp.buf.hover()
end, { desc = "Show hover information" })

-- Show diagnostic error message
keymaps.set("n", "<leader>K", function()
  vim.diagnostic.open_float()
end, { desc = "Show diagnostic message" })

-- Go to function definition
keymaps.set("n", "<C-S-CR>", vim.lsp.buf.definition, { desc = "Go to definition" })
keymaps.set("n", "<C-CR>", vim.lsp.buf.definition, { desc = "Go to definition" })

keymaps.set("n", "<leader>fp", function()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then root = vim.fn.getcwd() end
  local rel = vim.fn.expand("%:p"):sub(#root + 2)
  vim.fn.setreg("+", rel)
  vim.notify("Copied: " .. rel, vim.log.levels.INFO, { title = "Path" })
end, { desc = "Copy path relative to project root" })

keymaps.set("n", "<leader>fP", function()
  local abs = vim.fn.expand("%:p")
  vim.fn.setreg("+", abs)
  vim.notify("Copied: " .. abs, vim.log.levels.INFO, { title = "Path" })
end, { desc = "Copy absolute path" })
