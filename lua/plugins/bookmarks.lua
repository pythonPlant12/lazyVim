return {
  {
    "LintaoAmons/bookmarks.nvim",
    tag = "3.2.0",
    event = "VeryLazy",
    dependencies = {
      "kkharji/sqlite.lua",
      "nvim-telescope/telescope.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("bookmarks").setup({})
    end,
  },
}
