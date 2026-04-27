return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "stevearc/dressing.nvim",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
  },
  opts = {
    provider = "openai",
    providers = {
      openai = {
        endpoint = "https://api.openai.com/v1",
        model = "gpt-4o",
        timeout = 30000,
        extra_request_body = {
          temperature = 0,
          max_tokens = 4096,
        },
      },
    },
    selector = { provider = "snacks" },
    input = { provider = "snacks" },
    hints = { enabled = true },
    windows = {
      position = "right",
      width = 35,
      sidebar_header = { align = "center", rounded = true },
    },
  },
}
