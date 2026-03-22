return {
  {
    "MagicDuck/grug-far.nvim",
    opts = {},
    keys = {
      {
        "<leader>sr",
        function()
          require("grug-far").open()
        end,
        desc = "Search and Replace (grug-far)",
      },
      {
        "<leader>sr",
        function()
          require("grug-far").with_visual_selection()
        end,
        mode = "v",
        desc = "Search selected text (grug-far)",
      },
      {
        "<leader>sf",
        function()
          require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } })
        end,
        desc = "Search and Replace in File (grug-far)",
      },
      {
        "<leader>sf",
        function()
          require("grug-far").with_visual_selection({ prefills = { paths = vim.fn.expand("%") } })
        end,
        mode = "v",
        desc = "Search selected text in File (grug-far)",
      },
    },
  },
}
