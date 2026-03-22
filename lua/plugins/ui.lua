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
    opts = {
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
  -- neo-tree: always show hidden files
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (reveal current file)",
      },
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (reveal current file)",
      },
    },
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
      opts.window.mappings["<S-CR>"]    = "open_vsplit"

      opts.default_component_configs = opts.default_component_configs or {}
      opts.default_component_configs.git_status = {
        symbols = {
          added     = "●",
          modified  = "●",
          deleted   = "●",
          renamed   = "●",
          untracked = "●",
          ignored   = "",
          unstaged  = "●",
          staged    = "●",
          conflict  = "●",
        },
      }

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
        separator_style = { "", "" },
        show_buffer_close_icons = false,
        show_close_icon = false,
        indicator = { style = "none" },
        diagnostics = false,
      },
      highlights = {
        fill                   = { bg = "#1e1e2e" },
        background             = { fg = "#6c7086", bg = "#181825" },
        tab                    = { fg = "#6c7086", bg = "#181825" },
        tab_selected           = { fg = "#1e1e2e", bg = "#89b4fa", bold = true },
        tab_separator          = { fg = "#181825", bg = "#1e1e2e" },
        tab_separator_selected = { fg = "#89b4fa", bg = "#1e1e2e" },
        tab_close              = { fg = "#6c7086", bg = "#1e1e2e" },
        buffer_selected        = { fg = "#1e1e2e", bg = "#89b4fa", bold = true, italic = false },
        numbers_selected       = { fg = "#1e1e2e", bg = "#89b4fa", bold = true },
        separator              = { fg = "#181825", bg = "#1e1e2e" },
        separator_selected     = { fg = "#89b4fa", bg = "#1e1e2e" },
        separator_visible      = { fg = "#181825", bg = "#1e1e2e" },
        -- directory prefix shown when two tabs share the same filename
        duplicate_selected     = { fg = "#1e1e2e", bg = "#89b4fa", bold = true,  italic = false },
        duplicate              = { fg = "#6c7086", bg = "#181825",               italic = false },
        duplicate_visible      = { fg = "#6c7086", bg = "#181825",               italic = false },
        -- modified indicator (unsaved file): keep the blue background on the active tab
        modified_selected      = { fg = "#1e1e2e", bg = "#89b4fa", italic = false },
        modified               = { fg = "#6c7086", bg = "#181825", italic = false },
        modified_visible       = { fg = "#6c7086", bg = "#181825", italic = false },
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
  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local mode_theme = {
        normal   = { a = { fg = "#191A1C", bg = "#89b4fa", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" }, c = { fg = "#BCBEC4", bg = "#2B2D30" } },
        insert   = { a = { fg = "#191A1C", bg = "#a6e3a1", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        visual   = { a = { fg = "#191A1C", bg = "#B189F5", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        replace  = { a = { fg = "#191A1C", bg = "#F75464", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        command  = { a = { fg = "#191A1C", bg = "#D5B778", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        inactive = { a = { fg = "#6F737A", bg = "#191A1C" }, b = { fg = "#6F737A", bg = "#191A1C" }, c = { fg = "#6F737A", bg = "#191A1C" } },
      }
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        theme = mode_theme,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      })
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      -- Git ahead/behind async refresh
      vim.g._git_ahead = vim.g._git_ahead or 0
      vim.g._git_behind = vim.g._git_behind or 0
      vim.g._git_untracked = vim.g._git_untracked or 0
      vim.g._git_modified = vim.g._git_modified or 0
      vim.g._git_deleted = vim.g._git_deleted or 0
      vim.g._git_conflicted = vim.g._git_conflicted or 0
      local function refresh_git_ab()
        vim.fn.jobstart({ "git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}" }, {
          cwd = vim.fn.getcwd(),
          stdout_buffered = true,
          on_stdout = function(_, data)
            if data and data[1] and data[1] ~= "" then
              local a, b = data[1]:match("(%d+)%s+(%d+)")
              vim.g._git_ahead = tonumber(a) or 0
              vim.g._git_behind = tonumber(b) or 0
            end
          end,
          on_exit = function(_, code)
            if code ~= 0 then
              vim.g._git_ahead = 0
              vim.g._git_behind = 0
            end
          end,
        })
      end
      local function refresh_git_status()
        vim.fn.jobstart({ "git", "status", "--porcelain" }, {
          cwd = vim.fn.getcwd(),
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data then return end
            local untracked, modified, deleted, conflicted = 0, 0, 0, 0
            for _, line in ipairs(data) do
              if line ~= "" then
                local x, y = line:sub(1, 1), line:sub(2, 2)
                if x == "?" then
                  untracked = untracked + 1
                elseif x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
                  conflicted = conflicted + 1
                else
                  if y == "M" or x == "M" then modified = modified + 1 end
                  if y == "D" or x == "D" then deleted = deleted + 1 end
                end
              end
            end
            vim.g._git_untracked = untracked
            vim.g._git_modified = modified
            vim.g._git_deleted = deleted
            vim.g._git_conflicted = conflicted
          end,
          on_exit = function(_, code)
            if code ~= 0 then
              vim.g._git_untracked = 0
              vim.g._git_modified = 0
              vim.g._git_deleted = 0
              vim.g._git_conflicted = 0
            end
          end,
        })
      end
      local function refresh_git_all()
        refresh_git_ab()
        refresh_git_status()
      end
      local grp = vim.api.nvim_create_augroup("lualine_git_ab", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, { group = grp, callback = refresh_git_all })
      refresh_git_all()

      local function setup_git_hl()
        vim.api.nvim_set_hl(0, "LualineGitBase", { fg = "#BCBEC4", bg = "#3B3F45", bold = true })
        vim.api.nvim_set_hl(0, "LualineGitGreen", { fg = "#a6e3a1", bg = "#3B3F45", bold = true })
        vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = "#f9e2af", bg = "#3B3F45", bold = true })
        vim.api.nvim_set_hl(0, "LualineGitPeach", { fg = "#fab387", bg = "#3B3F45", bold = true })
        vim.api.nvim_set_hl(0, "LualineGitRed", { fg = "#f38ba8", bg = "#3B3F45", bold = true })
      end
      setup_git_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_git_hl })

      opts.sections.lualine_b = {
        {
          function()
            local branch = vim.b.gitsigns_head or vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
            if branch == "" or branch:find("fatal") then return "" end
            local parts = { " " .. branch }
            local a, b = vim.g._git_ahead or 0, vim.g._git_behind or 0
            local u, m, d, c = vim.g._git_untracked or 0, vim.g._git_modified or 0, vim.g._git_deleted or 0, vim.g._git_conflicted or 0
            local indicators = {}
            if a > 0 and b > 0 then table.insert(indicators, "%#LualineGitYellow#▲▼") end
            if a > 0 and b == 0 then table.insert(indicators, "%#LualineGitGreen#▲") end
            if b > 0 and a == 0 then table.insert(indicators, "%#LualineGitPeach#▼") end
            if c > 0 then table.insert(indicators, "%#LualineGitRed#●") end
            if u > 0 then table.insert(indicators, "%#LualineGitGreen#●") end
            if m > 0 then table.insert(indicators, "%#LualineGitYellow#●") end
            if d > 0 then table.insert(indicators, "%#LualineGitRed#●") end
            if #indicators > 0 then
              table.insert(parts, " " .. table.concat(indicators, "") .. "%#LualineGitBase#")
            end
            return table.concat(parts, "")
          end,
          cond = function()
            if vim.b.gitsigns_head and vim.b.gitsigns_head ~= "" then return true end
            local b = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
            return b ~= "" and not b:find("fatal")
          end,
          padding = { left = 1, right = 1 },
        },
      }

      local function setup_diag_hl()
        vim.api.nvim_set_hl(0, "DiagPillCap", { fg = "#313438", bg = "#2B2D30" })
        vim.api.nvim_set_hl(0, "DiagPillBase", { fg = "#BCBEC4", bg = "#313438" })
        vim.api.nvim_set_hl(0, "DiagPillError", { fg = "#f38ba8", bg = "#313438" })
        vim.api.nvim_set_hl(0, "DiagPillWarn", { fg = "#f9e2af", bg = "#313438" })
        vim.api.nvim_set_hl(0, "DiagPillInfo", { fg = "#89b4fa", bg = "#313438" })
        vim.api.nvim_set_hl(0, "DiagPillHint", { fg = "#a6e3a1", bg = "#313438" })
      end
      setup_diag_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_diag_hl })

      local new_c = {}
      for i, comp in ipairs(opts.sections.lualine_c or {}) do
        if i == 1 then goto skip end
        if type(comp) == "table" and comp[1] == "diagnostics" then goto skip end
        table.insert(new_c, comp)
        ::skip::
      end
      opts.sections.lualine_c = new_c

      table.insert(opts.sections.lualine_x, 1, {
        function()
          local d = vim.diagnostic.count(0)
          local e = d[vim.diagnostic.severity.ERROR] or 0
          local w = d[vim.diagnostic.severity.WARN] or 0
          local inf = d[vim.diagnostic.severity.INFO] or 0
          local h = d[vim.diagnostic.severity.HINT] or 0
          if e + w + inf + h == 0 then return "" end
          local parts = {}
          if e > 0 then table.insert(parts, "%#DiagPillError#✕ " .. e) end
          if w > 0 then table.insert(parts, "%#DiagPillWarn#△ " .. w) end
          if inf > 0 then table.insert(parts, "%#DiagPillInfo#○ " .. inf) end
          if h > 0 then table.insert(parts, "%#DiagPillHint#◇ " .. h) end
          return table.concat(parts, " ")
        end,
        padding = { left = 1, right = 1 },
      })

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
        separator = { left = "", right = "" },
        color = { fg = "#93a1a1", bg = "#45475a" },
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
        separator = { left = "", right = "" },
        color = function()
          return (vim.g.autoformat == nil or vim.g.autoformat)
            and { fg = "#a6e3a1", bg = "#45475a" }
            or  { fg = "#586e75", bg = "#45475a" }
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return "󰅪 eslint" end
          return "󰅪 eslint" .. (autosave_on and " (A)" or "")
        end,
        separator = { left = "", right = "" },
        color = function()
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return { fg = "#586e75", bg = "#45475a" } end
          return autosave_on and { fg = "#f9e2af", bg = "#45475a" } or { fg = "#93a1a1", bg = "#45475a" }
        end,
      })

      opts.sections.lualine_z = {}
      opts.sections.lualine_y = {}

      local function style_chip(component, bg)
        local comp = component
        if type(comp) == "function" then
          comp = { comp }
        end
        if type(comp) == "string" then
          comp = { comp }
        end
        if type(comp) ~= "table" then
          return comp
        end

        local existing_color = comp.color
        comp.separator = { left = "", right = "" }
        comp.padding = comp.padding or { left = 1, right = 1 }
        comp.color = function()
          local color
          if type(existing_color) == "function" then
            color = existing_color() or {}
          else
            color = existing_color or {}
          end
          color.fg = color.fg or "#CED0D6"
          color.bg = bg
          return color
        end

        return comp
      end

      opts.sections.lualine_c = opts.sections.lualine_c or {}
      local chip_bgs = { "#3A3D41", "#42464D", "#4A4F57" }
      local chip_index = 1
      for i, comp in ipairs(opts.sections.lualine_c) do
        local head = type(comp) == "table" and comp[1] or comp
        local is_path_like = type(head) == "function" or head == "filename"
        if is_path_like then
          local bg = chip_bgs[((chip_index - 1) % #chip_bgs) + 1]
          opts.sections.lualine_c[i] = style_chip(comp, bg)
          chip_index = chip_index + 1
        end
      end

      -- Prettier path separator: ❯ instead of /
      for _, comp in ipairs(opts.sections.lualine_c) do
        if type(comp) == "table" and type(comp[1]) == "function" then
          local original = comp[1]
          comp[1] = function(self)
            return (original(self) or ""):gsub("/", " ❯ ")
          end
        end
      end

      return opts
    end,
  },
}
