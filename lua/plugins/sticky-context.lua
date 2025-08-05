return {
  -- Option 1: nvim-treesitter-context (Most popular)
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPre",
    opts = {
      enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
      min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
      line_numbers = true,
      multiline_threshold = 20, -- Maximum number of lines to show for a single context
      trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      mode = 'cursor',  -- Line used to calculate context. Choices: 'cursor', 'topline'
      -- Separator between context and content. Should be a single character string, like '-'.
      -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
      separator = nil,
      zindex = 20, -- The Z-index of the context window
      on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching to a buffer
    },
    keys = {
      {
        "<leader>tc",
        "<cmd>TSContextToggle<cr>",
        desc = "Toggle Treesitter Context (Sticky Headers)",
      },
    },
  },
  
  -- Option 2: Alternative - barbecue.nvim (Breadcrumbs style)
  -- {
  --   "utilyre/barbecue.nvim",
  --   name = "barbecue",
  --   version = "*",
  --   dependencies = {
  --     "SmiteshP/nvim-navic",
  --     "nvim-tree/nvim-web-devicons", -- optional dependency
  --   },
  --   opts = {
  --     -- configurations go here
  --     theme = "auto",
  --     include_buftypes = { "" },
  --     exclude_filetypes = { "netrw", "toggleterm" },
  --     show_modified = false,
  --     symbols = {
  --       modified = "●",
  --       ellipsis = "…",
  --       separator = "",
  --     },
  --     kinds = {
  --       File = "",
  --       Module = "",
  --       Namespace = "",
  --       Package = "",
  --       Class = "",
  --       Method = "",
  --       Property = "",
  --       Field = "",
  --       Constructor = "",
  --       Enum = "練",
  --       Interface = "練",
  --       Function = "",
  --       Variable = "",
  --       Constant = "",
  --       String = "",
  --       Number = "",
  --       Boolean = "◩",
  --       Array = "",
  --       Object = "",
  --       Key = "",
  --       Null = "ﳠ",
  --       EnumMember = "",
  --       Struct = "",
  --       Event = "",
  --       Operator = "",
  --       TypeParameter = "",
  --     },
  --   },
  --   keys = {
  --     {
  --       "<leader>tb",
  --       "<cmd>lua require('barbecue.ui').toggle()<cr>",
  --       desc = "Toggle Barbecue (Breadcrumbs)",
  --     },
  --   },
  -- },
}