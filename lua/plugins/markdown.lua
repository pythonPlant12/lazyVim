return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = "bash app/install.sh",
  keys = {
    {
      "<leader>sp",
      "<cmd>MarkdownPreviewToggle<cr>",
      desc = "Preview markdown (browser)",
      ft = "markdown",
    },
  },
}
