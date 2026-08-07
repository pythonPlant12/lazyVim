-- vim-surround: add/change/delete quotes and brackets around text (ys/cs/ds).
return {
  {
    "tpope/vim-surround",
    event = "VeryLazy",
    config = function()
      vim.keymap.set("x", "as", "<Plug>VSurround", { remap = true, silent = true, desc = "Add surround" })
    end,
  },
}
