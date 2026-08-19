-- vim-surround: add/change/delete quotes and brackets around text (ys/cs/ds).
return {
  {
    "tpope/vim-surround",
    event = "VeryLazy",
    config = function()
      -- Visual s + bracket/quote surrounds the selection (closing bracket = no
      -- inner spaces, opening = spaces; same for as, kept as the old binding).
      vim.keymap.set("x", "s", "<Plug>VSurround", { remap = true, silent = true, desc = "Surround selection" })
      vim.keymap.set("x", "as", "<Plug>VSurround", { remap = true, silent = true, desc = "Add surround" })
    end,
  },
  {
    -- Flash claims x-mode s by default; surround owns it now (n/o jumps keep working).
    "folke/flash.nvim",
    optional = true,
    keys = {
      { "s", mode = "x", false },
    },
  },
}
