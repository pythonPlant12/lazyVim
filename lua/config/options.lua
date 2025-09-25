-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Cs = "\e[4:0m"]])
vim.g.autoformat = false
vim.g.lazyvim_python_lsp = "pyright"
-- vim.g.lazyvim_python_ruff = "ruff_lsp"

-- Disable all UI animations
vim.g.snacks_animate = false

-- Cursor configuration with colors
vim.opt.guicursor = "n-v-c-sm:block-Cursor/lCursor,i-ci-ve:block-iCursor/lCursor,r-cr-o:block-rCursor/lCursor"

-- Disable animations by default (same as <leader>ua)
vim.g.minianimate_disable = true

-- Disable smooth scrolling completely
vim.opt.smoothscroll = false
vim.g.neovide_scroll_animation_length = 0
vim.g.neovide_scroll_animation_far_lines = 0

-- Disable any neoscroll plugin if it exists
vim.g.neoscroll_disable = true

-- Disable LazyVim smooth scrolling (equivalent to <leader>uS)
-- Try multiple possible variable names
vim.g.lazyvim_smooth_scroll = false
vim.g.lazyvim_scroll_animation = false
vim.g.minianimate_scroll = false
vim.g.snacks_scroll = false

-- Terminal font configuration for GUI Neovim clients
if vim.g.neovide then
  vim.o.guifont = "JetBrainsMono NF Light:h15.5"
  vim.g.neovide_font_size = 15.5
  vim.g.neovide_letter_spacing = -0.7
  vim.g.neovide_line_height = 1.0
elseif vim.g.fvim_loaded then
  vim.o.guifont = "JetBrainsMono NF Light:h15.5"
end

-- Force disable smooth scrolling in LazyVim
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    -- Try to disable any loaded scroll animations
    if vim.g.loaded_smooth_scroll then
      vim.g.loaded_smooth_scroll = false
    end
    -- Disable snacks scroll if it exists
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.scroll then
      snacks.scroll.disable()
    end
  end,
})
