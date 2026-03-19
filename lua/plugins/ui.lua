local function remove_gl_key(_, keys)
  return vim.tbl_filter(function(k)
    local lhs = type(k) == "string" and k or k[1]
    return lhs ~= "<leader>gl"
  end, keys)
end

return {
  {
    "nvim-telescope/telescope.nvim",
    keys = remove_gl_key,
  },
  {
    "ibhagwan/fzf-lua",
    keys = remove_gl_key,
  },
  {
    "LazyVim/LazyVim",
    init = function()
      vim.o.winborder = "rounded"
    end,
  },
  -- neo-tree: always show hidden files
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      local highlights = require("neo-tree.ui.highlights")

      local folder_hl_map = {
        [highlights.GIT_ADDED]     = "NeoTreeGitAddedFolderName",
        [highlights.GIT_UNTRACKED] = "NeoTreeGitUntrackedFolderName",
        [highlights.GIT_MODIFIED]  = "NeoTreeGitModifiedFolderName",
        [highlights.GIT_CONFLICT]  = "NeoTreeGitConflictFolderName",
        [highlights.GIT_DELETED]   = "NeoTreeGitDeletedFolderName",
        [highlights.GIT_IGNORED]   = "NeoTreeGitIgnoredFolderName",
        [highlights.GIT_RENAMED]   = "NeoTreeGitRenamedFolderName",
        [highlights.GIT_STAGED]    = "NeoTreeGitAddedFolderName",
        NeoTreeGitAdded            = "NeoTreeGitAddedFolderName",
        NeoTreeGitUntracked        = "NeoTreeGitUntrackedFolderName",
        NeoTreeGitModified         = "NeoTreeGitModifiedFolderName",
        NeoTreeGitConflict         = "NeoTreeGitConflictFolderName",
        NeoTreeGitDeleted          = "NeoTreeGitDeletedFolderName",
        NeoTreeGitIgnored          = "NeoTreeGitIgnoredFolderName",
        NeoTreeGitRenamed          = "NeoTreeGitRenamedFolderName",
        NeoTreeGitStaged           = "NeoTreeGitAddedFolderName",
      }

      opts.popup_border_style = "rounded"
      opts.window = opts.window or {}
      opts.window.position = "left"
      opts.window.mappings = opts.window.mappings or {}
      opts.window.mappings["<Left>"] = function(state)
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
      end
      opts.window.mappings["<Right>"] = function(state)
        local node = state.tree:get_node()
        if node.type == "directory" and not node:is_expanded() then
          require("neo-tree.sources.filesystem").toggle_directory(state, node)
        end
      end
      opts.window.mappings["<S-Left>"]  = "navigate_up"
      opts.window.mappings["<S-Right>"] = "set_root"

      opts.filesystem = opts.filesystem or {}
      opts.filesystem.filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      }
      opts.filesystem.follow_current_file = { enabled = false }
      opts.filesystem.bind_to_cwd = false

      opts.components = opts.components or {}
      opts.components.name = function(config, node, state)
        local result = require("neo-tree.sources.common.components").name(config, node, state)
        if node.type == "directory" and result.highlight then
          result.highlight = folder_hl_map[result.highlight] or result.highlight
        end
        return result
      end

      return opts
    end,
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

      local lsp_icons = {
        vtsls          = "󰛦 ",
        ts_ls          = "󰛦 ",
        tsserver       = "󰛦 ",
        vue_ls         = "󰡄 ",
        volar          = "󰡄 ",
        eslint         = "󰅪 ",
        tailwindcss    = "󱏿 ",
        lua_ls         = "󰢱 ",
        pyright        = "󰌠 ",
        pylsp          = "󰌠 ",
        jsonls         = "󰘦 ",
        html           = "󰌝 ",
        cssls          = "󰌜 ",
        emmet_ls       = "󰯸 ",
        bashls         = " ",
        dockerls       = "󰡨 ",
        yamlls         = "󰘦 ",
        copilot        = " ",
        ["null-ls"]    = "󱏿 ",
      }

      table.insert(opts.sections.lualine_x, {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then return "" end
          local parts = {}
          local seen = {}
          for _, c in ipairs(clients) do
            if c.name == "eslint" then goto continue end
            if not seen[c.name] then
              seen[c.name] = true
              local icon = lsp_icons[c.name] or "󰒋 "
              parts[#parts + 1] = icon .. c.name
            end
            ::continue::
          end
          return table.concat(parts, "  ")
        end,
        color = { fg = "#93a1a1" },
        cond = function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          for _, c in ipairs(clients) do
            if c.name ~= "eslint" then return true end
          end
          return false
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          local fmt_active = vim.g.autoformat == nil or vim.g.autoformat
          return "󰉼 fmt" .. (fmt_active and " (A)" or "")
        end,
        color = function()
          return (vim.g.autoformat == nil or vim.g.autoformat)
            and { fg = "#859900" }
            or { fg = "#586e75" }
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return "󰅪 eslint" end
          return "󰅪 eslint" .. (autosave_on and " (A)" or "")
        end,
        color = function()
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return { fg = "#586e75" } end
          return autosave_on and { fg = "#859900" } or { fg = "#93a1a1" }
        end,
      })

      return opts
    end,
  },
}
