return {
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },
  {
    "tpope/vim-surround",
    event = "VeryLazy",
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      max_lines = 3,
      trim_scope = "outer",
    },
    keys = {
      {
        "[C",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        desc = "Jump to context",
      },
    },
  },
}
