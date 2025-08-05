return {
  {
    "rcarriga/nvim-notify",
    opts = {
      background_colour = "#000000",
      render = "compact",
      timeout = 2000,
    },
    config = function(_, opts)
      local notify = require("notify")
      notify.setup(opts)
      
      -- Override vim.notify to use nvim-notify
      vim.notify = notify
      
      -- Custom notification function for format toggles
      _G.format_notify = function(message, level)
        notify(message, level or "info", {
          title = "Format Toggle",
          icon = "🎛️",
          timeout = 3000,
        })
      end
    end,
  },
  {
    "folke/noice.nvim",
    optional = true,
    opts = {
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
      },
    },
  },
}