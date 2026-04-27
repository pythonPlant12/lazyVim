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
      max_lines = 6,
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
      opts.sources = opts.sources or {}
      opts.sources.transform_items = function(_, items)
        for _, item in ipairs(items) do
          -- Icons are now shown and will use BlinkCmpKind* highlights
          if item.kind == 4 then
            item.kind = 7
          end
        end
        return items
      end

      opts.completion = opts.completion or {}
      opts.completion.documentation = { auto_show = false }

      opts.keymap = opts.keymap or {}
      opts.keymap["<Tab>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.select_next()
          end
        end,
        LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" }),
        "fallback",
      }
      opts.keymap["<S-Tab>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.select_prev()
          end
        end,
        "snippet_backward",
        "fallback",
      }
    end,
  },
}
