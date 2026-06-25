return {
  {
    "lewis6991/gitsigns.nvim",
    init = function()
      local function apply_blame_hl()
        local theme = type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl.name == vim.g.colors_name and vim.g.theme_custom_hl or {}
        local blame_fg = theme.blame_fg
        if not blame_fg then return end
        vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = blame_fg, bg = "NONE" })
        vim.api.nvim_set_hl(0, "LspInlayHint", { fg = blame_fg, bg = "NONE" })
      end
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_blame_hl })
      apply_blame_hl()
    end,
    opts = {
      current_line_blame = true,
      on_attach = function(bufnr)
        vim.schedule(function()
          local leader_g_maps = {
            "<leader>ghs", "<leader>ghr", "<leader>ghS", "<leader>ghu",
            "<leader>ghR", "<leader>ghp", "<leader>ghb", "<leader>ghB",
            "<leader>ghd", "<leader>ghD",
          }
          for _, lhs in ipairs(leader_g_maps) do
            pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })
            pcall(vim.keymap.del, "v", lhs, { buffer = bufnr })
            pcall(vim.keymap.del, "x", lhs, { buffer = bufnr })
          end
        end)
      end,
    },
  },
}
