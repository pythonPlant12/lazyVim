return {
  {
    "okuuva/auto-save.nvim",
    cmd = "ASToggle", -- optional for lazy loading on command
    event = { "InsertLeave", "TextChanged" }, -- optional for lazy loading on trigger events
    keys = {
      {
        "<leader>as",
        function()
          require("auto-save").toggle()
        end,
        desc = "Toggle auto-save",
      },
    },
    opts = {
      enabled = false, -- start auto-save when the plugin is loaded (i.e. when your package manager loads it)
      execution_message = {
        enabled = true,
        message = function() -- message to print on save
          return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
        end,
        dim = 0.18, -- dim the color of `message`
        cleaning_interval = 1250, -- (milliseconds) automatically clean MsgArea after displaying `message`. See :h MsgArea
      },
      trigger_events = { -- See :h events
        immediate_save = { "BufLeave", "FocusLost" }, -- vim events that trigger an immediate save
        defer_save = { "InsertLeave", "TextChanged" }, -- vim events that trigger a deferred save (saves after `debounce_delay`)
        cancel_defered_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
      },
      -- function that takes the buffer handle and determines whether to save the current buffer or not
      -- return true: if buffer is ok to be saved
      -- return false: if it's not ok to be saved
      -- if set to `nil` then no specific condition is applied
      condition = function(buf)
        local fn = vim.fn
        local utils = require("auto-save.utils.data")

        -- don't save for special-buffers whose buftype is not empty
        if utils.not_in(fn.getbufvar(buf, "&buftype"), { "", "acwrite" }) then
          return false
        end
        -- don't save for `sql` file types
        if utils.not_in(fn.getbufvar(buf, "&filetype"), { "sql" }) then
          return false
        end
        return true
      end,
      write_all_buffers = false, -- write all buffers when the current one meets `condition`
      debounce_delay = 1000, -- delay after which a pending save is executed (in milliseconds)
    },
  },
}