-- blink.cmp completion tweaks: Enter-only accept, custom menu layout, Tab navigation.
return {
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
      -- Only commit a completion on <CR>. Highlight the top item (preselect) but
      -- never insert its text while navigating/typing (auto_insert = false).
      opts.completion.list = opts.completion.list or {}
      opts.completion.list.selection = vim.tbl_deep_extend("force", opts.completion.list.selection or {}, {
        preselect = true,
        auto_insert = false,
      })
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

      -- Escape always drops straight to normal mode, even with the menu open.
      opts.keymap["<Esc>"] = {
        function(cmp)
          if cmp.is_menu_visible() then cmp.hide() end
        end,
        "fallback",
      }
    end,
  },
}
