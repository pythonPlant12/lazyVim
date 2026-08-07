---@diagnostic disable: undefined-global

-- rainbow-delimiters.nvim: color-codes matching brackets/parens by nesting depth.
return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "VeryLazy",
    init = function()
      -- Muted delimiter colors help nesting without overpowering the theme.
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = "rainbow-delimiters.strategy.global",
          vim = "rainbow-delimiters.strategy.local",
        },
        query = {
          [""] = "rainbow-delimiters",
        },
        -- HTML/Vue templates already have dense syntax colors, so skip rainbow there.
        blacklist = { "html", "vue" },
        highlight = {
          "RainbowDelimiterBlueMuted",
          "RainbowDelimiterGoldMuted",
          "RainbowDelimiterCyanMuted",
          "RainbowDelimiterPurpleMuted",
          "RainbowDelimiterGreenMuted",
          "RainbowDelimiterAmberMuted",
        },
      }
    end,
  },
}
