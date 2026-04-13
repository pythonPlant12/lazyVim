return {
  {
    "MagicDuck/grug-far.nvim",
    opts = {
      keymaps = {
        syncNext    = { n = "<S-CR>", i = "<S-CR>" },
        historyOpen = { n = "<localleader>h" },
        refresh     = { n = "<localleader>r" },
        close       = { n = "<localleader>C" },
      },
      prefills = { flags = "--fixed-strings" },
    },
    config = function(_, opts)
      require("grug-far").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "grug-far",
        callback = function(ev)
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
      local function escape_path(p)
        return p:gsub(" ", "\\ ")
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
        if is_word then
          local flags = prefills.flags or "--fixed-strings"
          if not flags:find("--word%-regexp") then
            prefills.flags = flags .. " --word-regexp"
          end
        end

        require("grug-far").with_visual_selection(
          next(prefills) ~= nil and { prefills = prefills } or nil
        )
      end

      return {
        {
          "<leader>sr",
          function() require("grug-far").open() end,
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
          function() require("grug-far").open() end,
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
          function() require("grug-far").open() end,
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
          function() require("grug-far").open() end,
          desc = "Search and Replace (grug-far)",
        },
        {
          "<C-s>r",
          function() grug_visual() end,
          mode = "v",
          desc = "Search selected text (grug-far)",
        },
        {
          "<C-s>s",
          function()
            require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
          end,
          desc = "Search and Replace word under cursor (grug-far)",
        },
        {
          "<C-s>s",
          function() grug_visual() end,
          mode = "v",
          desc = "Search and Replace selected text (grug-far)",
        },
        {
          "<C-s>f",
          function()
            require("grug-far").open({ prefills = { paths = escape_path(vim.fn.expand("%")) } })
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
            require("grug-far").open({ prefills = { paths = escape_path(vim.fn.expand("%:h")) } })
          end,
          desc = "Search in current directory (grug-far)",
        },
        {
          "<C-s>d",
          function() grug_visual({ paths = escape_path(vim.fn.expand("%:h")) }) end,
          mode = "v",
          desc = "Search selected text in current directory (grug-far)",
        },
        {
          "<C-s>w",
          function()
            require("grug-far").open({
              prefills = {
                search = vim.fn.expand("<cword>"),
                flags  = "--fixed-strings --word-regexp",
              },
            })
          end,
          desc = "Search whole word under cursor (grug-far)",
        },
        {
          "<C-s>w",
          function()
            require("grug-far").with_visual_selection({
              prefills = { flags = "--fixed-strings --word-regexp" },
            })
          end,
          mode = "v",
          desc = "Search whole word (selected text) (grug-far)",
        },
      }
    end,
  },
}
