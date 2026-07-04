return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  ft = { "markdown" },
  build = "bash app/install.sh",
  init = function()
    vim.g.mkdp_markdown_css = vim.fn.stdpath("config") .. "/assets/markdown-preview.css"
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
