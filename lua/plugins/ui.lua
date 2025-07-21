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
  -- lualine with custom mode colors
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = {
          normal = {
            a = { fg = "#ffffff", bg = "#56a8f5", gui = "bold" }, -- blue for normal mode
            b = { fg = "#bcbec4", bg = "#2b2d30" },
            c = { fg = "#bcbec4", bg = "#1e1f22" },
          },
          insert = {
            a = { fg = "#ffffff", bg = "#c77dbb", gui = "bold" }, -- purple for insert mode
            b = { fg = "#bcbec4", bg = "#2b2d30" },
            c = { fg = "#bcbec4", bg = "#1e1f22" },
          },
          visual = {
            a = { fg = "#ffffff", bg = "#cf8e6d", gui = "bold" }, -- orange for visual/select mode
            b = { fg = "#bcbec4", bg = "#2b2d30" },
            c = { fg = "#bcbec4", bg = "#1e1f22" },
          },
          replace = {
            a = { fg = "#ffffff", bg = "#f75464", gui = "bold" }, -- red for replace mode
            b = { fg = "#bcbec4", bg = "#2b2d30" },
            c = { fg = "#bcbec4", bg = "#1e1f22" },
          },
          command = {
            a = { fg = "#ffffff", bg = "#6aab73", gui = "bold" }, -- green for command mode
            b = { fg = "#bcbec4", bg = "#2b2d30" },
            c = { fg = "#bcbec4", bg = "#1e1f22" },
          },
        },
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
  -- Disable neoscroll plugin if it exists
  {
    "karb94/neoscroll.nvim",
    enabled = false,
  },
}
