return {
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
    event = "VeryLazy",
    keys = {
      { "<C-n>", desc = "Multicursor add next match", mode = { "n", "x" } },
      { "<M-Up>", desc = "Multicursor add cursor above", mode = { "n", "x" } },
      { "<M-Down>", desc = "Multicursor add cursor below", mode = { "n", "x" } },
      { "<leader>mA", desc = "Multicursor add all matches", mode = { "n", "x" } },
      { "<leader>ms", desc = "Multicursor skip next match", mode = { "n", "x" } },
      { "<leader>mi", desc = "Multicursor insert at each line start", mode = "x" },
      { "<leader>mI", desc = "Multicursor append at each line end", mode = "x" },
    },
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local set = vim.keymap.set

      set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "MC: Add next match" })
      set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "MC: Skip next match" })
      set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "MC: Skip previous match" })
      set({ "n", "x" }, "<M-Up>", function() mc.lineAddCursor(-1) end, { desc = "MC: Add cursor above" })
      set({ "n", "x" }, "<M-Down>", function() mc.lineAddCursor(1) end, { desc = "MC: Add cursor below" })
      set({ "n", "x" }, "<leader>mA", mc.matchAllAddCursors, { desc = "MC: Add all matches" })
      set({ "n", "x" }, "<leader>mo", mc.operator, { desc = "MC: Match with operator" })
      set({ "n", "x" }, "<leader>ml", mc.addCursorOperator, { desc = "MC: Add cursor per line (operator)" })
      set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "MC: Toggle current cursor" })
      set("n", "<leader>mr", mc.restoreCursors, { desc = "MC: Restore cursors" })
      set({ "n", "x" }, "g<C-a>", mc.sequenceIncrement, { desc = "MC: Sequence increment" })
      set({ "n", "x" }, "g<C-x>", mc.sequenceDecrement, { desc = "MC: Sequence decrement" })
      set("x", "<leader>mi", mc.insertVisual, { desc = "MC: Insert at each line start" })
      set("x", "<leader>mI", mc.appendVisual, { desc = "MC: Append at each line end" })
      set("x", "<leader>mm", mc.matchCursors, { desc = "MC: Match within selection" })
      set("x", "<leader>m/", mc.splitCursors, { desc = "MC: Split selection by regex" })

      mc.addKeymapLayer(function(layer_set)
        layer_set({ "n", "x" }, "<M-Left>", mc.prevCursor, { desc = "MC: Previous cursor" })
        layer_set({ "n", "x" }, "<M-Right>", mc.nextCursor, { desc = "MC: Next cursor" })
        layer_set({ "n", "x" }, "<leader>mx", mc.deleteCursor, { desc = "MC: Delete current cursor" })
        layer_set("n", "<Esc>", function()
          if not mc.cursorsEnabled() then
            mc.enableCursors()
          else
            mc.clearCursors()
          end
        end, { desc = "MC: Clear cursors" })
      end)

      vim.api.nvim_set_hl(0, "MultiCursorCursor", { reverse = true })
      vim.api.nvim_set_hl(0, "MultiCursorVisual", { link = "Visual" })
      vim.api.nvim_set_hl(0, "MultiCursorSign", { link = "SignColumn" })
      vim.api.nvim_set_hl(0, "MultiCursorMatchPreview", { link = "Search" })
      vim.api.nvim_set_hl(0, "MultiCursorDisabledCursor", { reverse = true })
      vim.api.nvim_set_hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
      vim.api.nvim_set_hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
    end,
  },
}
