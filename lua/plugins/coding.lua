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
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.appearance = opts.appearance or {}
      opts.appearance.kind_icons = vim.tbl_extend("force", opts.appearance.kind_icons or {}, {
        Text          = "󰉿 ",
        Method        = "󰆧 ",
        Function      = "󰊕 ",
        Constructor   = " ",
        Field         = "󰜢 ",
        Variable      = "󰀫 ",
        Class         = "󰠱 ",
        Interface     = " ",
        Module        = " ",
        Property      = "󰜢 ",
        Unit          = "󰑭 ",
        Value         = "󰎠 ",
        Enum          = " ",
        Keyword       = "󰌋 ",
        Snippet       = " ",
        Color         = "󰏘 ",
        File          = "󰈙 ",
        Reference     = "󰈇 ",
        Folder        = "󰉋 ",
        EnumMember    = " ",
        Constant      = "󰏿 ",
        Struct        = "󰙅 ",
        Event         = " ",
        Operator      = "󰆕 ",
        TypeParameter = "󰬛 ",
      })
    end,
  },
}
