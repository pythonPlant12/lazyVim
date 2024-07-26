return {
  -- bufferline
  {
    "akinsho/bufferline.nvim",
    keys = {
      { "<Tab>", "<Cmd>BuffeLineCycleNext<CR>", desc = "Next tab" },
      { "<S-Tab>", "<Cmd>BuffeLineCyclePrev<CR>", desc = "Prev tab" },
    },
    opts = {
      options = {
        mode = "tabs",
        show_buffer_close_icons = true,
        show_close_icon = true,
      },
    },
  },
  -- Preview markdown live in web browser
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
  },
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
  },
}
