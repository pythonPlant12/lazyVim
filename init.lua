-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.api.nvim_set_keymap('n', 'dw', 'dw', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'db', 'db', { noremap = true, silent = true })



