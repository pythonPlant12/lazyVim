return {
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    init = function()
      -- Layout 3 keeps the tree and diff preview side-by-side.
      vim.g.undotree_WindowLayout = 3
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_SplitWidth = 36

      vim.cmd([[
        function! g:Undotree_CustomMap() abort
          augroup UserUndotreeAutoPreview
            autocmd! * <buffer>
            " Preview the selected undo state while moving inside Undotree.
            autocmd CursorMoved <buffer> if exists('t:undotree') | silent! call t:undotree.ActionEnter() | endif
          augroup END
        endfunction
      ]])
    end,
    keys = {
      { "<leader>U", "<cmd>UndotreeToggle<cr>", desc = "Toggle Undotree" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    init = function()
      -- Keep blame/inlay hint colors aligned with the active theme palette.
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
          -- Remove LazyVim's default hunk maps; custom git maps live under <C-g>.
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
