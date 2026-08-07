-- Undotree: browse and restore earlier undo states of the file (<leader>U).
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
}
