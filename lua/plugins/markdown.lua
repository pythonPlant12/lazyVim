return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = function() vim.fn["mkdp#util#install"]() end,
  keys = {
    {
      "<leader>sp",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Preview markdown (browser)",
      ft = "markdown",
    },
  },
}
