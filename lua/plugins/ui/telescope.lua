-- Telescope: inverted j/k, no default LazyGit key, and opaque floats.
local picker_open = require("features.picker_open")

return {
  {
    "nvim-telescope/telescope.nvim",
    keys = picker_open.remove_gl_key,
    opts = function(_, opts)
      local actions = require("telescope.actions")
      opts.defaults = opts.defaults or {}
      -- Telescope reads the global winblend by default, so transparent themes
      -- (winblend 10) show buffer text through the picker. 0 hides that text.
      opts.defaults.winblend = 0
      opts.defaults.mappings = opts.defaults.mappings or {}
      -- Normal-mode j/k follow this config's inverted vertical movement.
      opts.defaults.mappings.n = vim.tbl_extend("force", opts.defaults.mappings.n or {}, {
        j = actions.move_selection_previous,
        k = actions.move_selection_next,
      })
    end,
  },
}
