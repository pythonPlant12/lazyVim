---@diagnostic disable: undefined-global

return {
  -- Inline rename command for LSP symbols.
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },
  -- Surround mappings are loaded lazily but keep visual `as` available.
  {
    "tpope/vim-surround",
    event = "VeryLazy",
    config = function()
      vim.keymap.set("x", "as", "<Plug>VSurround", { remap = true, silent = true, desc = "Add surround" })
    end,
  },
  -- Shows the containing function/class at the top while scrolling deep code.
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
          -- Treat interfaces like classes so completion icons use the desired highlight.
          if item.kind == 4 then
            item.kind = 7
          end
        end
        return items
      end

      opts.completion = opts.completion or {}
      opts.completion.menu = opts.completion.menu or {}
      opts.completion.menu.draw = opts.completion.menu.draw or {}
      opts.completion.menu.draw.columns = {
        { "kind_icon" },
        { "label", "label_description", gap = 1 },
        { "kind" },
      }
      opts.completion.menu.draw.components = opts.completion.menu.draw.components or {}
      opts.completion.menu.draw.components.kind = vim.tbl_deep_extend("force", opts.completion.menu.draw.components.kind or {}, {
        ellipsis = false,
        text = function(ctx) return ctx.kind end,
        highlight = function(ctx) return ctx.kind_hl end,
      })

      -- Tab moves through the completion menu first, then snippets/AI/fallback.
      opts.keymap["<Tab>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.select_next({ auto_insert = false })
          end
        end,
        LazyVim.cmp.map({ "snippet_forward", "ai_nes", "ai_accept" }),
        "fallback",
      }
      opts.keymap["<S-Tab>"] = {
        function(cmp)
          if cmp.is_menu_visible() then
            return cmp.select_prev({ auto_insert = false })
          end
        end,
        "snippet_backward",
        "fallback",
      }
    end,
  },
}
