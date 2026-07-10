---@diagnostic disable: undefined-global

-- vim-illuminate: highlights other occurrences of the word under the cursor.
return {
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    -- Highlight references under cursor, but delay/disable noisy filetypes to avoid movement lag.
    opts = {
      delay = 300,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = {},
      },
      filetype_overrides = {
        html = { providers = {} },
        htmldjango = { providers = {} },
        jinja = { providers = {} },
        jinja2 = { providers = {} },
        vue = { providers = {} },
      },
      modes_allowlist = { "n" },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)

      -- Reapply custom reference highlights after theme changes.
      local function set_illuminate_hl()
        local bg = vim.o.background == "light" and "#E6E6E6" or "#3A3A4A"
        vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = bg, underline = false })
        vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = bg, underline = false })
        vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = bg, underline = false })
      end

      set_illuminate_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_illuminate_hl })
    end,
  },
}
