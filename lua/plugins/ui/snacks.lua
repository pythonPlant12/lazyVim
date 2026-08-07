-- Snacks: file/grep pickers, lazygit window, inline image previews, statuscolumn.
-- Opening behavior (jump-to-existing-tab, exact line placement) lives in features/picker_open.
local picker_open = require("features.picker_open")

-- Some long-running picker callbacks may still resolve this as a Lua global until
-- Snacks is reloaded. Keep a compatibility alias for those stale closures.
_G.tab_jump = require("utils.tab_jump")

-- Keys shared by the grep and grep_word pickers (case/word/regex toggles).
local grep_input_keys = {
  ["<c-h>"]          = { "toggle_hidden",    mode = { "i", "n" } },
  ["<A-s>"]          = { "toggle_camel_case", mode = { "i", "n" }, nowait = true },
  ["<S-Up>"]         = { "history_back",     mode = { "i", "n" } },
  ["<S-Down>"]       = { "history_forward",  mode = { "i", "n" } },
  ["<localleader>r"] = { "toggle_regex",     mode = { "n" } },
  ["<localleader>c"] = { "toggle_case",      mode = { "n" } },
  ["<localleader>w"] = { "toggle_word",      mode = { "n" } },
  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" }, nowait = true },
}
local grep_list_keys = {
  ["<c-h>"]          = "toggle_hidden",
  ["c"]              = { "toggle_camel_case", mode = { "n" }, nowait = true },
  ["<A-s>"]          = { "toggle_camel_case", mode = { "n" }, nowait = true },
  ["<localleader>r"] = { "toggle_regex",     mode = { "n" } },
  ["<localleader>c"] = { "toggle_case",      mode = { "n" } },
  ["<localleader>w"] = { "toggle_word",      mode = { "n" } },
  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" }, nowait = true },
}

-- All LSP location pickers open tab-aware and show filename-first results.
local lsp_picker = {
  focus = "list",
  confirm = picker_open.confirm_lsp_location,
  format = function(item, picker)
    return require("snacks.picker.format").filename(item, picker)
  end,
}

return {
  {
    "folke/snacks.nvim",
    -- Patch Snacks statuscolumn to pad the current line number so it aligns with the gutter.
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          local ok, statuscolumn = pcall(require, "snacks.statuscolumn")
          if not ok or statuscolumn._current_lnum_left_offset then
            return
          end

          statuscolumn._current_lnum_left_offset = true
          local original_get = statuscolumn.get
          statuscolumn.get = function()
            local ret = original_get()
            if vim.v.virtnum ~= 0 or vim.v.relnum ~= 0 then
              return ret
            end

            local win = vim.g.statusline_winid
            local nu = vim.wo[win].number
            local rnu = vim.wo[win].relativenumber
            if not (nu or rnu) then
              return ret
            end

            local num = rnu and nu and vim.v.lnum or rnu and vim.v.relnum or vim.v.lnum
            local needle = "%=" .. num .. " "
            local start_col, end_col = ret:find(needle, 1, true)
            if not start_col then
              return ret
            end

            return ret:sub(1, end_col) .. "  " .. ret:sub(end_col + 1)
          end
        end,
      })
    end,
    keys = {
      {
        "<leader>,",
        function()
          Snacks.picker.buffers({
            confirm = function(picker, item)
              if not item then return end
              picker:close()
              if item.buf then
                vim.api.nvim_set_current_buf(item.buf)
              end
            end,
          })
        end,
        desc = "Buffers",
      },
      { "<leader>sG", false },
      {
        "<leader>sG",
        function()
          require("utils.search_grep").cwd_with_filter_mode()
        end,
        desc = "Grep (cwd, path filters)",
      },
      {
        "<leader>sE",
        function()
          Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics (project)",
      },
      {
        "<leader>sf",
        function()
          Snacks.picker.grep({ dirs = { vim.fn.expand("%:p") } })
        end,
        desc = "Search in current file (snacks)",
      },
      {
        "<leader>sw",
        function()
          Snacks.picker.grep_word()
        end,
        desc = "Search word under cursor (snacks)",
        mode = { "n", "x" },
      },
      {
        "<leader>sd",
        function()
          Snacks.picker.grep({ cwd = vim.fn.expand("%:p:h") })
        end,
        desc = "Search in current directory (snacks)",
      },
    },
    opts = {
      words = { enabled = false },
      -- LazyGit edit actions route through scripts/lazygit-edit to open files in Neovim.
      lazygit = {
        win = {
          width = 0,
          height = 0,
          row = 2,
          col = 0,
          border = "none",
        },
        config = {
          os = {
            editPreset = "",
            edit = ("python3 %s \"{{filename}}\""):format(vim.fn.shellescape(vim.fn.stdpath("config") .. "/scripts/lazygit-edit")),
            editAtLine = ("python3 %s \"{{filename}}\" \"{{line}}\""):format(vim.fn.shellescape(vim.fn.stdpath("config") .. "/scripts/lazygit-edit")),
            editAtLineAndWait = ("python3 %s \"{{filename}}\" \"{{line}}\""):format(vim.fn.shellescape(vim.fn.stdpath("config") .. "/scripts/lazygit-edit")),
            editInTerminal = false,
          },
        },
      },
      -- Inline image/PDF previews for docs and picker preview panes.
      image = {
        enabled = true,
        formats = {
          "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff", "heic", "avif", "pdf", "icns",
        },
        doc = {
          enabled = true,
          inline = true,
          float = true,
          max_width = 80,
          max_height = 40,
        },
      },
      input = {
        win = {
          border = "rounded",
        },
      },
      picker = {
        sources = {
          buffers = {
            confirm = function(picker, item)
              if not item then return end
              picker:close()
              if item.buf then
                vim.api.nvim_set_current_buf(item.buf)
              end
            end,
          },
          files = {
            cmd = "fd",
            hidden = true,
            ignored = true,
            exclude = picker_open.excludes,
            win = {
              input = {
                keys = {
                  ["<c-h>"] = { "toggle_hidden", mode = { "i", "n" } },
                },
              },
              list = {
                keys = {
                  ["<c-h>"] = "toggle_hidden",
                },
              },
            },
          },
          -- Grep starts literal and case-insensitive; local toggles opt into regex/case/word.
          grep = {
            hidden = false,
            ignored = true,
            regex = false,
            camel_case = false,
            toggles = { regex = false },
            exclude = picker_open.excludes,
            args = { "--ignore-case" },
            win = {
              input = { keys = grep_input_keys },
              list = { keys = grep_list_keys },
            },
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
          grep_word = {
            hidden = false,
            ignored = true,
            regex = false,
            camel_case = false,
            toggles = { regex = false },
            exclude = picker_open.excludes,
            args = { "--word-regexp", "--ignore-case" },
            win = {
              input = { keys = grep_input_keys },
              list = { keys = grep_list_keys },
            },
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
          lsp_references = lsp_picker,
          lsp_definitions = lsp_picker,
          lsp_implementations = lsp_picker,
          lsp_type_definitions = lsp_picker,
        },
        actions = {
          toggle_camel_case = picker_open.toggle_grep_camel_case,
          toggle_case = function(picker)
            require("utils.search_grep").toggle_case(picker)
          end,
          toggle_word = function(picker)
            require("utils.search_grep").toggle_word(picker)
          end,
          tab_open = picker_open.open_in_tab,
          confirm = picker_open.confirm_tab_aware,
        },
        -- Shift-Enter opens picker results in a new tab; j/k follow inverted navigation.
        win = {
          input = {
            keys = {
              ["j"] = { "list_up", mode = { "n" } },
              ["k"] = { "list_down", mode = { "n" } },
              ["<S-CR>"] = { "tab_open", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["j"] = "list_up",
              ["k"] = "list_down",
              ["<S-CR>"] = "tab_open",
            },
          },
        },
        formatters = {
          file = {
            filename_first = true,
          },
        },
      },
      notifier = {
        style = "compact",
      },
      statuscolumn = {
        left = { "sign" },
        right = { "fold", "git" },
      },
    },
  },
}
