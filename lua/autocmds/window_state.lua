vim.api.nvim_create_autocmd("WinLeave", {
  group = vim.api.nvim_create_augroup("AutoUnzoom", { clear = true }),
  callback = function()
    if vim.t.maximized then
      vim.cmd("wincmd =")
      vim.t.maximized = false
    end
  end,
})
