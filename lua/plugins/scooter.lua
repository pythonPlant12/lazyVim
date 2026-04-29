return {
  {
    "MagicDuck/grug-far.nvim",
    opts = {
      windowCreationCommand = "botright vsplit",
      keymaps = {
        syncNext    = { n = "<S-CR>", i = "<S-CR>" },
        historyOpen = { n = "<localleader>h" },
        refresh     = { n = "<localleader>r" },
        close       = { n = "<localleader>C" },
      },
      prefills = { flags = "--fixed-strings" },
      folding = { enabled = false },
    },
    config = function(_, opts)
      require("grug-far").setup(opts)

      -- Monkey-patch fix: grug-far's getLineWithoutCarriageReturn is a no-op on
      -- non-Windows, so \r from CRLF files leaks into the results buffer. When
      -- those lines are written back, they get an extra \r prepended to \r\n.
      -- Strip \r unconditionally on all platforms to prevent double-CR corruption.
      local utils = require("grug-far.utils")
      utils.getLineWithoutCarriageReturn = function(line)
        if string.sub(line, -1) == "\r" then
          return string.sub(line, 1, -2)
        end
        return line
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "grug-far",
        callback = function(ev)
          local width = math.max(40, math.floor(vim.o.columns * 0.25))
          pcall(vim.api.nvim_win_set_width, vim.fn.bufwinid(ev.buf), width)

          local map = function(lhs, fn, desc)
            vim.keymap.set({ "n", "i" }, lhs, fn, { buffer = ev.buf, silent = true, desc = desc })
          end
          local inst = function() return require("grug-far").get_instance(ev.buf) end

          map("<localleader>c", function() inst():toggle_flags({ "--smart-case" })    end, "Toggle camel/smart case")
          map("<localleader>w", function() inst():toggle_flags({ "--word-regexp" })   end, "Toggle whole word")
          map("<localleader>R", function() inst():toggle_flags({ "--fixed-strings" }) end, "Toggle regex")
        end,
      })
    end,
    keys = function()
      local grug_far_reuse = require("config.grug_far_reuse")

      local function escape_path(p)
        return p:gsub(" ", "\\ ")
      end

      local function open_grug(opts)
        return grug_far_reuse.open_for_buffer(vim.api.nvim_get_current_buf(), opts)
      end

      local function grug_visual(extra_prefills)
        local s = vim.fn.getpos("'<")
        local e = vim.fn.getpos("'>")
        local sr, er = s[2], e[2]
        local is_word = false
        if sr > 0 and er > 0 and sr == er then
          local line = vim.api.nvim_buf_get_lines(0, sr - 1, sr, false)[1] or ""
          local sc = s[3]
          local ec = math.min(e[3], #line)
          local text = line:sub(sc, ec)
          is_word = text ~= "" and not text:match("%s")
        end

        local prefills = vim.tbl_extend("force", {}, extra_prefills or {})
        prefills.search = require("grug-far").get_current_visual_selection(true)
        prefills.flags = prefills.flags or "--fixed-strings"
        prefills.paths = prefills.paths or ""
        if is_word then
          local flags = prefills.flags or "--fixed-strings"
          if not flags:find("--word%-regexp") then
            prefills.flags = flags .. " --word-regexp"
          end
        end

        open_grug(next(prefills) ~= nil and { prefills = prefills } or nil)
      end

      return {
        {
          "<leader>sr",
          function() open_grug() end,
          desc = "Search and Replace (grug-far)",
        },
        {
          "<leader>sr",
          function() grug_visual() end,
          mode = "v",
          desc = "Search selected text (grug-far)",
        },
        {
          "<leader>srw",
          function() open_grug() end,
          desc = "Search and Replace in Workspace (grug-far)",
        },
        {
          "<leader>srw",
          function() grug_visual() end,
          mode = "v",
          desc = "Search selected text in Workspace (grug-far)",
        },
        {
          "<C-s>g",
          function() open_grug() end,
          desc = "Search and Replace (grug-far)",
        },
        {
          "<C-s>g",
          function() grug_visual() end,
          mode = "v",
          desc = "Search and Replace selected text (grug-far)",
        },
        {
          "<C-s>r",
          function()
            open_grug({ prefills = { flags = "--fixed-strings --ignore-case" } })
          end,
          desc = "Search and Replace (grug-far)",
        },
        {
          "<C-s>r",
          function() grug_visual({ flags = "--fixed-strings --ignore-case" }) end,
          mode = "v",
          desc = "Search selected text (grug-far)",
        },
        {
          "<C-s>s",
          function()
            open_grug({ prefills = { search = vim.fn.expand("<cword>"), flags = "--fixed-strings --ignore-case", paths = "" } })
          end,
          desc = "Search and Replace word under cursor (grug-far)",
        },
        {
          "<C-s>s",
          function() grug_visual({ flags = "--fixed-strings --ignore-case" }) end,
          mode = "v",
          desc = "Search and Replace selected text (grug-far)",
        },
        {
          "<C-s>f",
          function()
            open_grug({ prefills = { paths = escape_path(vim.fn.expand("%")), flags = "--fixed-strings" } })
          end,
          desc = "Search in current file (grug-far)",
        },
        {
          "<C-s>f",
          function() grug_visual({ paths = escape_path(vim.fn.expand("%")) }) end,
          mode = "v",
          desc = "Search selected text in current file (grug-far)",
        },
        {
          "<C-s>d",
          function()
            open_grug({ prefills = { paths = escape_path(vim.fn.expand("%:h")), flags = "--fixed-strings --ignore-case" } })
          end,
          desc = "Search in current directory (grug-far)",
        },
        {
          "<C-s>d",
          function() grug_visual({ paths = escape_path(vim.fn.expand("%:h")), flags = "--fixed-strings --ignore-case" }) end,
          mode = "v",
          desc = "Search selected text in current directory (grug-far)",
        },
        {
          "<C-s>w",
          function()
            open_grug({
              prefills = {
                search = vim.fn.expand("<cword>"),
                flags  = "--fixed-strings --word-regexp --case-sensitive",
                paths = "",
              },
            })
          end,
          desc = "Search whole word under cursor (grug-far)",
        },
        {
          "<C-s>w",
          function()
            grug_visual({ flags = "--fixed-strings --word-regexp --case-sensitive", paths = "" })
          end,
          mode = "v",
          desc = "Search whole word (selected text) (grug-far)",
        },
      }
    end,
  },
}
