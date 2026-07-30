local grug_far_reuse = require("utils.grug_far_reuse")

-- Neo-tree explorer tweaks: navigation, path yanking, bookmark cleanup, grug-far/Finder integration.
return {
  -- Neo-tree is tab-aware and reveals the current file with hidden files visible.
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<leader>e",
        function()
          local manager = require("neo-tree.sources.manager")
          local state = manager.get_state("filesystem", nil, nil)
          if state then
            -- Neo-tree keeps one state object; clear stale windows from other tabs first.
            local cur_tab_wins = vim.api.nvim_tabpage_list_wins(0)
            if state.winid and not vim.tbl_contains(cur_tab_wins, state.winid) then
              state.winid = nil
              state.bufnr = nil
            end
          end
          require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (reveal current file)",
      },
      {
        "<leader>fe",
        function()
          local manager = require("neo-tree.sources.manager")
          local state = manager.get_state("filesystem", nil, nil)
          if state then
            -- Same stale-state guard as <leader>e for the alternate explorer key.
            local cur_tab_wins = vim.api.nvim_tabpage_list_wins(0)
            if state.winid and not vim.tbl_contains(cur_tab_wins, state.winid) then
              state.winid = nil
              state.bufnr = nil
            end
          end
          require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
        end,
        desc = "Explorer NeoTree (reveal current file)",
      },
    },
    opts = function(_, opts)

      -- Detail toggle temporarily lowers renderer width thresholds, then restores originals.
      local detail_components = {
        file_size = true,
        type = true,
        last_modified = true,
        created = true,
      }

      -- Recursively force-show (or restore) the detail columns across nested renderers.
      local function toggle_renderer_details(components, show_all)
        for _, component in ipairs(components or {}) do
          local name = component[1]
          if detail_components[name] then
            if component.__orig_required_width == nil then
              component.__orig_required_width = component.required_width
            end
            if component.__orig_enabled == nil then
              component.__orig_enabled = component.enabled
            end
            if show_all then
              component.required_width = 0
              if name == "created" then
                component.enabled = true
              end
            else
              component.required_width = component.__orig_required_width
              component.enabled = component.__orig_enabled
            end
          end
          if name == "container" and component.content then
            toggle_renderer_details(component.content, show_all)
          end
        end
      end

      -- While a `/` search is active, order matches by how shallow they are: a
      -- node that itself matches (or whose nearest matching descendant is
      -- closest) sorts first, then alphabetically. So a root-level `.serena`
      -- beats a match buried in `other/deep/`. Normal browsing keeps neo-tree's
      -- default folders-first ordering untouched.
      local ok_mgr, fs_manager = pcall(require, "neo-tree.sources.manager")
      local ok_fzy, fzy = pcall(require, "neo-tree.sources.common.filters.filter_fzy")

      local function name_matches(name, pattern)
        if not name or not pattern or pattern == "" then
          return false
        end
        if ok_fzy then
          local ok, res = pcall(fzy.has_match, pattern, name)
          if ok then
            return res
          end
        end
        return name:lower():find(pattern:lower(), 1, true) ~= nil
      end

      -- Shallowest depth (0 = this node) at which `pattern` matches a name in
      -- this subtree; math.huge if nothing matches. Memoised on the node — the
      -- item tree is rebuilt on every navigate, so the cache never goes stale.
      local function match_depth(node, pattern)
        if node.__match_depth ~= nil then
          return node.__match_depth
        end
        local depth = math.huge
        if name_matches(node.name, pattern) then
          depth = 0
        elseif type(node.children) == "table" then
          for _, child in ipairs(node.children) do
            local d = match_depth(child, pattern) + 1
            if d < depth then
              depth = d
            end
          end
        end
        node.__match_depth = depth
        return depth
      end

      opts.sort_function = function(a, b)
        local pattern
        if ok_mgr then
          local st = fs_manager.get_state("filesystem")
          if st and st.search_pattern ~= nil and st.search_pattern ~= "" then
            pattern = st.search_pattern
          end
        end
        -- Depth ordering needs real item nodes (with .name/.children). neo-tree
        -- probes this function with bare {type,path} stubs to check validity,
        -- and normal browsing wants the default order — both fall through to
        -- the folders-first comparison below.
        if pattern and a.name ~= nil and b.name ~= nil then
          local da, db = match_depth(a, pattern), match_depth(b, pattern)
          if da ~= db then
            return da < db
          end
          return a.name:lower() < b.name:lower()
        end
        if a.type ~= b.type then
          return a.type < b.type
        end
        return a.path < b.path
      end

      opts.popup_border_style = "rounded"
      opts.window = opts.window or {}
      opts.window.position = "left"
      opts.window.border = "rounded"
      opts.window.mappings = opts.window.mappings or {}
      -- Left collapses an expanded dir or jumps to the parent node.
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
      -- Right expands a collapsed directory.
      opts.window.mappings["<Right>"] = function(state)
        local node = state.tree:get_node()
        if node.type == "directory" and not node:is_expanded() then
          require("neo-tree.sources.filesystem").toggle_directory(state, node)
        end
      end
      opts.window.mappings["<S-CR>"]    = "open_vsplit"
      opts.window.mappings["["]         = "prev_source"
      opts.window.mappings["]"]         = "next_source"
      opts.window.mappings["<"]         = false
      opts.window.mappings[">"]         = false
      -- I toggles the extra detail columns for the whole tree.
      opts.window.mappings["I"] = function(state)
        state.__show_all_details = not state.__show_all_details
        local show_all = state.__show_all_details
        for _, renderer in pairs(state.renderers or {}) do
          toggle_renderer_details(renderer, show_all)
        end
        require("neo-tree.ui.renderer").redraw(state)
      end
      -- y/p/P yank the node's absolute, relative, or absolute path to the clipboard.
      opts.window.mappings["y"] = function(state)
        local node = state.tree:get_node()
        if not node then
          return
        end
        local path = node:get_id()
        if not path or path == "" then
          return
        end
        vim.fn.setreg('"', path)
        vim.fn.setreg("+", path)
        vim.notify(path, vim.log.levels.INFO, { title = "Yanked path" })
      end
      opts.window.mappings["p"] = function(state)
        local node = state.tree:get_node()
        if not node then return end
        local abs = node:get_id()
        if not abs or abs == "" then return end
        local rel = vim.fn.fnamemodify(abs, ":~:.")
        vim.fn.setreg('"', rel)
        vim.fn.setreg("+", rel)
        vim.notify(rel, vim.log.levels.INFO, { title = "Yanked relative path" })
      end
      opts.window.mappings["P"] = function(state)
        local node = state.tree:get_node()
        if not node then return end
        local abs = node:get_id()
        if not abs or abs == "" then return end
        vim.fn.setreg('"', abs)
        vim.fn.setreg("+", abs)
        vim.notify(abs, vim.log.levels.INFO, { title = "Yanked absolute path" })
      end
      -- Delete bookmarks for selected file or every file under selected directory.
      opts.window.mappings["<C-b>d"] = function(state)
        local node = state.tree:get_node()
        if not node then return end
        local path = vim.fs.normalize(vim.fn.fnamemodify(node:get_id(), ":p"))
        if path == "" then return end

        local repo = require("bookmarks.domain.repo")
        local sign = require("bookmarks.sign")
        local bm_tree = require("bookmarks.tree")

        local deleted = 0
        for _, bookmark in ipairs(repo.get_all_bookmarks()) do
          if bookmark.location and bookmark.location.path then
            local bpath = vim.fs.normalize(vim.fn.fnamemodify(bookmark.location.path, ":p"))
            -- match exact file OR anything under a directory
            if bpath == path or bpath:sub(1, #path + 1) == path .. "/" then
              repo.delete_node(bookmark.id)
              deleted = deleted + 1
            end
          end
        end

        sign.safe_refresh_signs()
        pcall(bm_tree.refresh)

        local name = vim.fn.fnamemodify(path, ":t")
        if deleted > 0 then
          local msg = deleted == 1 and "Deleted 1 bookmark for " .. name
            or "Deleted " .. deleted .. " bookmarks for " .. name
          vim.notify(msg, vim.log.levels.INFO, { title = "Bookmarks" })
        else
          vim.notify("No bookmarks found for " .. name, vim.log.levels.WARN, { title = "Bookmarks" })
        end
      end

      opts.default_component_configs = opts.default_component_configs or {}
      -- Render file icons through mini.icons so Neo-tree matches the picker
      -- (<leader><leader>). A real nvim-web-devicons dependency elsewhere can
      -- defeat LazyVim's mini.icons mock, leaving Neo-tree on a different
      -- palette; this provider pins files to mini.icons directly. Directories
      -- fall through so Neo-tree keeps its own folder glyphs.
      opts.default_component_configs.icon = opts.default_component_configs.icon or {}
      opts.default_component_configs.icon.provider = function(icon, node)
        if node.type == "file" or node.type == "terminal" then
          local ok, mini_icon, mini_hl = pcall(require("mini.icons").get, "file", node.name)
          if ok then
            icon.text = mini_icon
            icon.highlight = mini_hl
          end
        end
      end
      opts.default_component_configs.git_status = {
        symbols = {
          added     = "a",
          modified  = "m",
          deleted   = "d",
          renamed   = "r",
          untracked = "?",
          ignored   = "",
          unstaged  = "",
          staged    = "s",
          conflict  = "!",
        },
      }

      opts.filesystem = opts.filesystem or {}
      opts.filesystem.commands = opts.filesystem.commands or {}
      -- Keep hidden/gitignored files visible; searching/filtering is handled elsewhere.
      opts.filesystem.filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      }
      opts.filesystem.follow_current_file = { enabled = true }
      opts.filesystem.bind_to_cwd = false
      opts.filesystem.window = opts.filesystem.window or {}
      opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}
      -- Run grug-far scoped to the selected file/directory from Neo-tree.
      opts.filesystem.commands.grug_far_search_node = function(state)
        local node = state.tree:get_node()
        if not node or node.type == "message" then
          return
        end

        local path = node:get_id()
        if not path or path == "" then
          return
        end

        grug_far_reuse.open_for_buffer(vim.api.nvim_get_current_buf(), {
          prefills = {
            paths = path:gsub(" ", "\\ "),
            flags = "--fixed-strings --ignore-case",
          },
        })
      end
      -- Search for the selected node's bare filename across the project.
      opts.filesystem.commands.grug_far_search_node_filename = function(state)
        local node = state.tree:get_node()
        if not node or node.type == "message" then
          return
        end

        local path = node:get_id()
        local filename = path and vim.fn.fnamemodify(path, ":t") or ""
        if filename == "" then
          vim.notify("No selected file name", vim.log.levels.WARN, { title = "grug-far" })
          return
        end

        grug_far_reuse.open_for_buffer(vim.api.nvim_get_current_buf(), {
          prefills = {
            search = filename,
            paths = "",
            flags = "--fixed-strings --ignore-case",
          },
        })
      end
      -- Reveal the selected node in macOS Finder.
      opts.filesystem.commands.reveal_node_in_finder = function(state)
        local node = state.tree:get_node()
        if not node or node.type == "message" then
          return
        end

        local path = node:get_id()
        if not path or path == "" then
          vim.notify("No selected path", vim.log.levels.WARN, { title = "Reveal File" })
          return
        end

        path = vim.fn.fnamemodify(path, ":p")
        if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
          vim.notify("File not found: " .. path, vim.log.levels.WARN, { title = "Reveal File" })
          return
        end

        if vim.fn.has("macunix") ~= 1 then
          vim.notify("Finder reveal is only available on macOS", vim.log.levels.WARN, { title = "Reveal File" })
          return
        end

        local ok = pcall(vim.system, { "open", "-R", path }, { detach = true })
        if not ok then
          vim.notify("Failed to reveal: " .. path, vim.log.levels.ERROR, { title = "Reveal File" })
        end
      end
      opts.filesystem.window.mappings["{"] = "navigate_up"
      opts.filesystem.window.mappings["}"] = "set_root"
      opts.filesystem.window.mappings["F"] = "reveal_node_in_finder"
      opts.filesystem.window.mappings["<C-s>f"] = "grug_far_search_node"
      opts.filesystem.window.mappings["<C-s>F"] = "grug_far_search_node_filename"
      opts.filesystem.window.mappings["<C-s>d"] = "grug_far_search_node"

      return opts
    end,
  },
  -- Bridge Neo-tree file operations to LSP so servers can rewrite moved imports.
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim",
    },
    opts = {
      operations = {
        willRenameFiles = true,
        didRenameFiles = true,
        willCreateFiles = true,
        didCreateFiles = true,
        willDeleteFiles = true,
        didDeleteFiles = true,
      },
    },
    config = function(_, opts)
      require("lsp-file-operations").setup(opts)
    end,
  },
}
