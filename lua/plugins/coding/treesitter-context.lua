-- treesitter-context: pin the current function/class name at the top while scrolling.
return {
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      max_lines = 6,
      trim_scope = "outer",
    },
    config = function(_, opts)
      require("treesitter-context").setup(opts)
      -- The context floats inherit the global winblend of transparent themes.
      -- Force winblend 0 after each render so the panel hides the text below.
      local render = require("treesitter-context.render")
      local open = render.open
      render.open = function(...)
        open(...)
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if (vim.w[win].treesitter_context or vim.w[win].treesitter_context_line_number)
            and vim.wo[win].winblend ~= 0 then
            vim.wo[win].winblend = 0
          end
        end
      end
    end,
    keys = {
      {
        "[C",
        function() require("treesitter-context").go_to_context(vim.v.count1) end,
        desc = "Jump to context",
      },
    },
  },
}
