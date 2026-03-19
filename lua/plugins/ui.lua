return {
  {
    "LazyVim/LazyVim",
    init = function()
      vim.o.winborder = "rounded"
    end,
  },
  -- neo-tree: always show hidden files
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      popup_border_style = "rounded",
      window = {
        position = "left",
        mappings = {
          ["<Left>"] = function(state)
            local node = state.tree:get_node()
            if node.type == "directory" and node:is_expanded() then
              node:collapse()
              require("neo-tree.ui.renderer").redraw(state)
            else
              local parent_id = node:get_parent_id()
              if parent_id then
                require("neo-tree.ui.renderer").focus_node(state, parent_id)
              end
            end
          end,
          ["<Right>"] = function(state)
            local node = state.tree:get_node()
            if node.type == "directory" and not node:is_expanded() then
              require("neo-tree.sources.filesystem").toggle_directory(state, node)
            end
          end,
        },
      },
      filesystem = {
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
    },
  },
  -- bufferline
  {
    "akinsho/bufferline.nvim",
    keys = {
    },
    opts = {
      options = {
        mode = "tabs",
        separator_style = "slant",
        show_buffer_close_icons = false,
        show_close_icon = false,
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      input = {
        win = {
          border = "rounded",
        },
      },
      picker = {
        win = {
          input = {
            border = "rounded",
          },
          list = {
            border = "rounded",
          },
          preview = {
            border = "rounded",
          },
        },
      },
      notifier = {
        style = "compact",
      },
    },
  },
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
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
    },
  },
  {
    "folke/trouble.nvim",
    opts = {
      win = {
        border = "rounded",
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
  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        theme = "solarized_dark",
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      })
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, {
        function()
          return "fmt"
        end,
        color = function()
          return (vim.g.autoformat == nil or vim.g.autoformat)
            and { fg = "#859900" }
            or { fg = "#586e75" }
        end,
      })
      table.insert(opts.sections.lualine_x, {
        function()
          return "eslint"
        end,
        color = function()
          return (vim.g.eslint_autosave == nil or vim.g.eslint_autosave)
            and { fg = "#859900" }
            or { fg = "#586e75" }
        end,
      })
      return opts
    end,
  },
}
