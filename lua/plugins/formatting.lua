return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "ruff" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
      },
    },
  },
}
