-- Multiple-cursor editing helpers and an active-cursor keymap layer.
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
      { "<leader>mc", desc = "Multicursor build mode", mode = "n" },
      { "<leader>ms", desc = "Multicursor skip next match", mode = { "n", "x" } },
      { "<leader>mi", desc = "Multicursor insert at each line start", mode = "x" },
      { "<leader>mI", desc = "Multicursor append at each line end", mode = "x" },
    },
    config = function()
      local mc = require("multicursor-nvim")
      mc.setup()

      local set = vim.keymap.set
      local build_mode = { active = false, bufnr = nil }

      local function sync_multicursor_status()
        local has_cursors = false
        if not build_mode.active then
          local ok, value = pcall(mc.hasCursors)
          has_cursors = ok and value or false
        end
        vim.g.multicursor_mode_active = has_cursors
      end

      local function refresh_statusline()
        vim.schedule(function()
          sync_multicursor_status()
          local ok, lualine = pcall(require, "lualine")
          if ok then lualine.refresh({ place = { "statusline" } }) end
        end)
        vim.defer_fn(function()
          sync_multicursor_status()
          local ok, lualine = pcall(require, "lualine")
          if ok then lualine.refresh({ place = { "statusline" } }) end
        end, 25)
      end

      local function match_toggle_cursor(direction)
        mc.matchSkipCursor(direction)
        vim.schedule(function()
          mc.toggleCursor()
          refresh_statusline()
        end)
      end

      local function stop_build_mode()
        if not build_mode.active then
          return
        end

        local bufnr = build_mode.bufnr
        build_mode.active = false
        build_mode.bufnr = nil
        vim.g.multicursor_build_mode = false

        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          for _, lhs in ipairs({ "c", "n", "N", "q", "<Esc>" }) do
            pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })
          end
        end

        if not mc.cursorsEnabled() then
          mc.enableCursors()
        end

        refresh_statusline()
        vim.notify("Multicursor build mode off", vim.log.levels.INFO, { title = "Multicursor" })
      end

      local function start_build_mode()
        if build_mode.active then
          stop_build_mode()
          return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        build_mode.active = true
        build_mode.bufnr = bufnr
        vim.g.multicursor_build_mode = true
        vim.g.multicursor_mode_active = false

        local opts = { buffer = bufnr, nowait = true, silent = true }
        set("n", "c", function()
          mc.toggleCursor()
          refresh_statusline()
        end, vim.tbl_extend("force", opts, { desc = "MC build: Toggle cursor here" }))
        set("n", "n", function() match_toggle_cursor(1) end, vim.tbl_extend("force", opts, { desc = "MC build: Toggle next match" }))
        set("n", "N", function() match_toggle_cursor(-1) end, vim.tbl_extend("force", opts, { desc = "MC build: Toggle previous match" }))
        set("n", "q", stop_build_mode, vim.tbl_extend("force", opts, { desc = "MC build: Finish" }))
        set("n", "<Esc>", stop_build_mode, vim.tbl_extend("force", opts, { desc = "MC build: Finish" }))

        refresh_statusline()
        vim.notify("Multicursor build mode: c toggle, n/N next/prev toggle, q/<Esc> finish", vim.log.levels.INFO, {
          title = "Multicursor",
        })
      end

      local function clear_or_enable_cursors()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
          vim.g.multicursor_build_mode = false
          vim.g.multicursor_mode_active = false
        end
        refresh_statusline()
      end

      set({ "n", "x" }, "<C-n>", function() mc.matchAddCursor(1) end, { desc = "MC: Add next match" })
      set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "MC: Skip next match" })
      set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "MC: Skip previous match" })
      set({ "n", "x" }, "<M-Up>", function() mc.lineAddCursor(-1) end, { desc = "MC: Add cursor above" })
      set({ "n", "x" }, "<M-Down>", function() mc.lineAddCursor(1) end, { desc = "MC: Add cursor below" })
      set({ "n", "x" }, "<leader>mA", mc.matchAllAddCursors, { desc = "MC: Add all matches" })
      set("n", "<leader>mc", start_build_mode, { desc = "MC: Build cursors" })
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

      -- Layer mappings only apply while multicursor mode owns the keys.
      mc.addKeymapLayer(function(layer_set)
        layer_set({ "n", "x" }, "<M-Left>", mc.prevCursor, { desc = "MC: Previous cursor" })
        layer_set({ "n", "x" }, "<M-Right>", mc.nextCursor, { desc = "MC: Next cursor" })
        layer_set({ "n", "x" }, "<leader>mx", mc.deleteCursor, { desc = "MC: Delete current cursor" })
        layer_set("n", "q", clear_or_enable_cursors, { desc = "MC: Clear cursors" })
        layer_set("n", "<Esc>", clear_or_enable_cursors, { desc = "MC: Clear cursors" })
      end)

      -- Keep cursor/match visuals readable across colorschemes.
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
