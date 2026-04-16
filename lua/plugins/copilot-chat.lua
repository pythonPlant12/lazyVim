return {
  "CopilotC-Nvim/CopilotChat.nvim",
  branch = "main",
  dependencies = {
    { "nvim-lua/plenary.nvim", branch = "master" },
  },
  build = "make tiktoken",
  cmd = "CopilotChat",
  config = function(_, opts)
    require("CopilotChat").setup(opts)
  end,
  keys = {
    {
      "<leader>ac",
      function() require("CopilotChat").open() end,
      desc = "CopilotChat",
      mode = { "n", "x" },
    },
  },
}
