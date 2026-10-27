-- Neovim defers diagnostic display while in insert mode (update_in_insert =
-- false) and checks the mode globally: diagnostics published for buffer A
-- while typing in buffer B wait for an InsertLeave in A, which may never come.
-- Seen with ESLint: editing eslint.config.mjs re-lints every open file, the
-- float showed the error, the underline never appeared. Redraw the other
-- buffers' diagnostics when leaving insert mode anywhere.
vim.api.nvim_create_autocmd("InsertLeave", {
  group = vim.api.nvim_create_augroup("DiagnosticsDeferredShow", { clear = true }),
  callback = function(ev)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= ev.buf and vim.api.nvim_buf_is_loaded(buf) and #vim.diagnostic.get(buf) > 0 then
        vim.diagnostic.show(nil, buf)
      end
    end
  end,
})
