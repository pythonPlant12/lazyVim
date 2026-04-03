return {
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "VeryLazy",
    init = function()
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = "rainbow-delimiters.strategy.global",
          vim = "rainbow-delimiters.strategy.local",
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
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
