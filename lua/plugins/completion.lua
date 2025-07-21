return {
  -- Use <tab> for completion and snippets (supertab)
  -- first: disable default <tab> and <s-tab> behavior in LuaSnip
  {
    "L3MON4D3/LuaSnip",
    opts = {
      history = true,
      region_check_events = "InsertEnter",
      delete_check_events = "TextChanged,InsertLeave",
    },
    keys = function()
      return {}
    end,
  },
  -- then: setup supertab in cmp
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")

      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, { { name = "emoji" } }))
      opts.mapping = vim.tbl_extend("force", opts.mapping, {
        -- Enter creates new line, Shift+Enter accepts suggestion
        ["<CR>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.abort()
          end
          fallback()
        end, { "i", "s" }),
        ["<S-CR>"] = cmp.mapping.confirm({ select = true }),
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            -- Default tab behavior for indentation
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-t>", true, false, true), "n", false)
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            -- Force unindentation behavior
            local keys = vim.api.nvim_replace_termcodes("<C-d>", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", false)
          end
        end, { "i", "s" }),
      })
    end,
  },
}
