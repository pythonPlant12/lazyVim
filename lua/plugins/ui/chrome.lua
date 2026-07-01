return {
  -- bufferline
  {
    "akinsho/bufferline.nvim",
    keys = {
    },
    opts = function(_, opts)
      opts = opts or {}
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        mode = "tabs",
        separator_style = { "│", "│" },
        show_buffer_close_icons = false,
        show_close_icon = false,
        indicator = { style = "none" },
        diagnostics = false,
      })
      local function palette()
        local name = vim.g.colors_name or ""
        if name == "rose-pine-dark-dimmed" then
          return { fg = "#b0acbc", muted = "#7a7686", border = "#524f67", active_bg = "#26233a", active_fg = "#c7c3d1", bg = "NONE" }
        elseif name:find("rose%-pine") and vim.o.background == "dark" then
          return { fg = "#e0def4", muted = "#908caa", border = "#524f67", active_bg = "#26233a", active_fg = "#e0def4", bg = "NONE" }
        elseif vim.o.background == "light" then
          return { fg = "#4C4F69", muted = "#7A7880", border = "#B8B2A8", active_bg = "#D2E4F5", active_fg = "#2F496F", bg = "NONE" }
        end
        return { fg = "#BCBEC4", muted = "#6F737A", border = "#4A4F57", active_bg = "#2F496F", active_fg = "#E8F0FA", bg = "NONE" }
      end

      local function tab_highlights()
        local c = palette()
        return {
          fill                    = { bg = c.bg },
          background              = { fg = c.muted, bg = c.bg },
          tab                     = { fg = c.muted, bg = c.bg },
          tab_selected            = { fg = c.active_fg, bg = c.active_bg, bold = true },
          tab_separator           = { fg = c.border, bg = c.bg },
          tab_separator_selected  = { fg = c.active_bg, bg = c.bg },
          tab_close               = { fg = c.muted, bg = c.bg },
          buffer_selected         = { fg = c.active_fg, bg = c.active_bg, bold = true, italic = false },
          buffer_visible          = { fg = c.fg, bg = c.bg, italic = false },
          numbers_selected        = { fg = c.active_fg, bg = c.active_bg, bold = true },
          numbers_visible         = { fg = c.fg, bg = c.bg },
          close_button            = { fg = c.muted, bg = c.bg },
          close_button_visible    = { fg = c.muted, bg = c.bg },
          close_button_selected   = { fg = c.active_fg, bg = c.active_bg },
          indicator_selected      = { fg = c.active_bg, bg = c.active_bg },
          indicator_visible       = { fg = c.bg, bg = c.bg },
          separator               = { fg = c.border, bg = c.bg },
          separator_selected      = { fg = c.active_bg, bg = c.bg },
          separator_visible       = { fg = c.border, bg = c.bg },
          duplicate_selected      = { fg = c.active_fg, bg = c.active_bg, bold = true, italic = false },
          duplicate               = { fg = c.muted, bg = c.bg, italic = false },
          duplicate_visible       = { fg = c.muted, bg = c.bg, italic = false },
          modified_selected       = { fg = c.active_fg, bg = c.active_bg, italic = false },
          modified                = { fg = c.muted, bg = c.bg, italic = false },
          modified_visible        = { fg = c.muted, bg = c.bg, italic = false },
        }
      end

      opts.highlights = tab_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          local ok, bufferline = pcall(require, "bufferline")
          if ok then
            opts.highlights = tab_highlights()
            bufferline.setup(opts)
          end
        end,
      })
      return opts
    end,
  },
  {
    "folke/snacks.nvim",
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

            return ret:sub(1, end_col) .. " " .. ret:sub(end_col + 1)
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
      image = {
        enabled = true,
        formats = {
          "png",
          "jpg",
          "jpeg",
          "gif",
          "bmp",
          "webp",
          "tiff",
          "heic",
          "avif",
          "pdf",
          "icns",
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
            exclude = picker_excludes,
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
            preview = snacks_file_preview_with_video,
          },
          git_files = {
            preview = snacks_file_preview_with_video,
          },
          recent = {
            preview = snacks_file_preview_with_video,
          },
          explorer = {
            preview = snacks_file_preview_with_video,
          },
          grep = {
            hidden = false,
            ignored = true,
            regex = false,
            camel_case = false,
            toggles = {
              regex = false,
            },
            exclude = picker_excludes,
            args = {
              "--ignore-case",
            },
            win = {
              input = {
                keys = {
                  ["<c-h>"]          = { "toggle_hidden",    mode = { "i", "n" } },
                  ["<A-s>"]          = { "toggle_camel_case", mode = { "i", "n" }, nowait = true },
                  ["<S-Up>"]         = { "history_back",     mode = { "i", "n" } },
                  ["<S-Down>"]       = { "history_forward",  mode = { "i", "n" } },
                  ["<localleader>r"] = { "toggle_regex",     mode = { "n" } },
                  ["<localleader>c"] = { "toggle_case",      mode = { "n" } },
                  ["<localleader>w"] = { "toggle_word",      mode = { "n" } },
                  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" }, nowait = true },
                },
              },
              list = {
                keys = {
                  ["<c-h>"]          = "toggle_hidden",
                  ["c"]              = { "toggle_camel_case", mode = { "n" }, nowait = true },
                  ["<A-s>"]          = { "toggle_camel_case", mode = { "n" }, nowait = true },
                  ["<localleader>r"] = { "toggle_regex",     mode = { "n" } },
                  ["<localleader>c"] = { "toggle_case",      mode = { "n" } },
                  ["<localleader>w"] = { "toggle_word",      mode = { "n" } },
                  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" }, nowait = true },
                },
              },
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
            toggles = {
              regex = false,
            },
            exclude = picker_excludes,
            args = {
              "--word-regexp",
              "--ignore-case",
            },
            win = {
              input = {
                keys = {
                  ["<c-h>"]          = { "toggle_hidden",    mode = { "i", "n" } },
                  ["<A-s>"]          = { "toggle_camel_case", mode = { "i", "n" }, nowait = true },
                  ["<S-Up>"]         = { "history_back",     mode = { "i", "n" } },
                  ["<S-Down>"]       = { "history_forward",  mode = { "i", "n" } },
                  ["<localleader>r"] = { "toggle_regex",     mode = { "n" } },
                  ["<localleader>c"] = { "toggle_case",      mode = { "n" } },
                  ["<localleader>w"] = { "toggle_word",      mode = { "n" } },
                  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" }, nowait = true },
                },
              },
              list = {
                keys = {
                  ["<c-h>"]          = "toggle_hidden",
                  ["c"]              = { "toggle_camel_case", mode = { "n" }, nowait = true },
                  ["<A-s>"]          = { "toggle_camel_case", mode = { "n" }, nowait = true },
                  ["<localleader>r"] = { "toggle_regex",     mode = { "n" } },
                  ["<localleader>c"] = { "toggle_case",      mode = { "n" } },
                  ["<localleader>w"] = { "toggle_word",      mode = { "n" } },
                  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" }, nowait = true },
                },
              },
            },
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
          lsp_references = {
            confirm = confirm_lsp_location,
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
          lsp_definitions = {
            confirm = confirm_lsp_location,
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
          lsp_implementations = {
            confirm = confirm_lsp_location,
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
          lsp_type_definitions = {
            confirm = confirm_lsp_location,
            format = function(item, picker)
              return require("snacks.picker.format").filename(item, picker)
            end,
          },
        },
        actions = {
          toggle_camel_case = toggle_grep_camel_case,
          toggle_case = function(picker)
            require("utils.search_grep").toggle_case(picker)
          end,
          toggle_word = function(picker)
            require("utils.search_grep").toggle_word(picker)
          end,
          tab_open = open_in_tab,
          confirm = function(picker, item)
            if not item then return end
            picker:close()

            local path = Snacks.picker.util.path(item)
            if path and is_video_path(path) then
              local thumb = generate_video_thumbnail(path)
              if thumb then
                local bufnr = vim.fn.bufnr(path)
                if bufnr == -1 then
                  bufnr = vim.api.nvim_create_buf(true, false)
                  vim.api.nvim_buf_set_name(bufnr, path)
                end
                vim.bo[bufnr].buflisted = true
                vim.api.nvim_set_current_buf(bufnr)
                Snacks.image.buf.attach(bufnr, { src = thumb })
                return
              end
            end

            if path then
              local ok, err = tab_jump.edit_or_goto_path(path)
              if not ok then
                vim.notify("Failed to open file: " .. (err or "unknown error"), vim.log.levels.ERROR)
                return
              end
              apply_item_pos(item)
              return
            end

            local bufnr = item.buf
            if not bufnr then return end
            vim.bo[bufnr].buflisted = true
            vim.api.nvim_set_current_buf(bufnr)
            apply_item_pos(item)
          end,
        },
        win = {
          input = {
            keys = {
              ["<S-CR>"] = { "tab_open", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
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
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      -- Throttle UI updates to reduce error frequency and avoid the panic/auto-disable threshold
      throttle = 1000 / 30,
      views = {
        cmdline_popup = {
          border = {
            style = "rounded",
          },
        },
        popupmenu = {
          border = {
            style = "rounded",
          },
        },
        hover = {
          border = {
            style = "rounded",
          },
        },
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      win = {
        border = "rounded",
      },
      spec = {
        { "<leader>g",   group = nil },
        { "<leader>gh",  group = nil },
        { "<leader>gg",  hidden = true },
        { "<leader>gG",  hidden = true },
        { "<leader>gL",  hidden = true },
        { "<leader>gb",  hidden = true },
        { "<leader>gf",  hidden = true },
        { "<leader>gB",  hidden = true },
        { "<leader>gY",  hidden = true },
        { "<leader>gl",  desc = "Go to line" },
      },
    },
  },
  {
    "folke/trouble.nvim",
    opts = {
      win = {
        border = "rounded",
      },
      icons = {
        kinds = {
          Text          = "󰉿 ",
          Method        = "󰆧 ",
          Function      = "󰊕 ",
          Constructor   = "󰊓 ",
          Field         = "󰆧 ",
          Variable      = "󰆦 ",
          Class         = "󰠱 ",
          Interface     = "󰜰 ",
          Module        = "󰅩 ",
          Property      = "󰆧 ",
          Unit          = "󰑭 ",
          Value         = "󰎠 ",
          Enum          = "󰍜 ",
          Keyword       = "󰌋 ",
          Snippet       = "󰅧 ",
          Color         = "󰏘 ",
          File          = "󰈙 ",
          Reference     = "󰈇 ",
          Folder        = "󰉋 ",
          EnumMember    = "󰲣 ",
          Constant      = "󰏿 ",
          Struct        = "󰙅 ",
          Event         = "󰑧 ",
          Operator      = "󰆕 ",
          TypeParameter = "󰬛 ",
          Array         = " ",
          Boolean       = "󰨙 ",
          Key           = " ",
          Namespace     = "󰦮 ",
          Null          = " ",
          Number        = "󰎠 ",
          Object        = " ",
          Package       = " ",
          String        = " ",
        },
      },
    },
  },
  {
    "folke/lazy.nvim",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
      },
    },
  },
}
