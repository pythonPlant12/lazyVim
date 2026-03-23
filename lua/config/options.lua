-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.smoothscroll = false

vim.diagnostic.config({ signs = false })

vim.g.root_spec = { "cwd" }

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Cs = "\e[4:0m"]])

vim.o.cmdheight = 2

vim.g.autoformat = false
vim.g.eslint_autosave = false
vim.g.lazyvim_picker = "snacks"
