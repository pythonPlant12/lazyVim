-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Cs = "\e[4:0m"]])
vim.g.autoformat = false
vim.g.lazyvim_python_lsp = "pyright"
-- vim.g.lazyvim_python_ruff = "ruff_lsp"

-- Cursor configuration with colors
vim.opt.guicursor = "n-v-c-sm:block-Cursor/lCursor,i-ci-ve:block-iCursor/lCursor,r-cr-o:block-rCursor/lCursor"
