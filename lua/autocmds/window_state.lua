-- Auto-restore equal split sizes when leaving a window that was zoomed/maximized.
vim.api.nvim_create_autocmd("WinLeave", {
  group = vim.api.nvim_create_augroup("AutoUnzoom", { clear = true }),
  callback = function()
    -- Leaving a maximized split restores layout before another window takes focus.
    if vim.t.maximized then
      vim.cmd("wincmd =")
      vim.t.maximized = false
    end
  end,
})
