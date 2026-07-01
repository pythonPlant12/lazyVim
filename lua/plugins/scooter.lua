---@diagnostic disable: undefined-global

local function focus_window_for_location(grug_buf, filename)
  if not filename or filename == "" then
    return
  end

  local target = vim.fn.fnamemodify(filename, ":p")
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p")
    if buf ~= grug_buf and name == target then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

local function run_enter_fallback(fallback)
  if fallback and type(fallback.callback) == "function" then
    fallback.callback()
  end
end

local function open_grug_result_and_focus(buf, fallback)
  local grug_far = require("grug-far")
  local inst = grug_far.get_instance(buf)
  if not inst or not inst._context then
    run_enter_fallback(fallback)
    return
  end

  if vim.v.count and vim.v.count > 0 then
    pcall(function() inst:goto_match(vim.v.count) end)
  end

  local ok, results_list = pcall(require, "grug-far.render.resultsList")
  if not ok then
    run_enter_fallback(fallback)
    return
  end

  local location = results_list.getResultLocationAtCursor(buf, inst._context)
  if not location then
    run_enter_fallback(fallback)
    return
  end

  inst:open_location()
  focus_window_for_location(buf, location.filename)
end

return {
  {
    "MagicDuck/grug-far.nvim",
    opts = {
      windowCreationCommand = "botright vsplit",
      keymaps = {
        -- grug-far's default <enter> action is gotoLocation, which calls
        -- nvim_win_set_cursor without guarding against stale result line
        -- numbers. OpenLocation performs the same jump defensively.
        gotoLocation = false,
        openLocation = { n = "<enter>" },
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

          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
              local enter_fallback = nil
              for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(ev.buf, "n")) do
                if mapping.lhs == "<CR>" or mapping.lhs:lower() == "<enter>" then
                  enter_fallback = mapping
                  break
                end
              end
              vim.keymap.set("n", "<enter>", function()
                open_grug_result_and_focus(ev.buf, enter_fallback)
              end, { buffer = ev.buf, silent = true, desc = "Open result and focus file" })
            end
          end)

          map("<localleader>c", function() inst():toggle_flags({ "--smart-case" })    end, "Toggle camel/smart case")
          map("<localleader>w", function() inst():toggle_flags({ "--word-regexp" })   end, "Toggle whole word")
          map("<localleader>R", function() inst():toggle_flags({ "--fixed-strings" }) end, "Toggle regex")
        end,
      })
    end,
    keys = function()
      local grug_far_reuse = require("utils.grug_far_reuse")

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
