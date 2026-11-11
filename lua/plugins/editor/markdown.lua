-- markdown-preview.nvim: live browser preview of the current markdown buffer.
return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = "bash app/install.sh",
  init = function()
    -- Browser preview CSS mirrors the editor theme and typography.
    vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/assets/markdown-preview.css"
  end,
  config = function()
    -- On BufHidden the plugin clears the group of the current buffer, which is
    -- not the hidden buffer during :tabonly (E216). Clear the hidden one.
    vim.cmd([[
      runtime autoload/mkdp/autocmd.vim
      function! mkdp#autocmd#clear_buf() abort
        let l:buf = empty(expand('<abuf>')) ? bufnr('%') : expand('<abuf>')
        silent! execute 'autocmd! MKDP_REFRESH_INIT' . l:buf
      endfunction
    ]])
  end,
  keys = {
    {
      "<leader>sp",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Preview markdown (browser)",
      ft = "markdown",
    },
  },
}
