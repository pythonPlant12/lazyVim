return {
  {
    "lewis6991/gitsigns.nvim",
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
