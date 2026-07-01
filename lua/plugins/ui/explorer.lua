local grug_far_reuse = require("utils.grug_far_reuse")

return {
  -- neo-tree: always show hidden files
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      {
        "<leader>e",
        function()
          local manager = require("neo-tree.sources.manager")
          local state = manager.get_state("filesystem", nil, nil)
          if state then
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

      local detail_components = {
        file_size = true,
        type = true,
        last_modified = true,
        created = true,
      }

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

      opts.popup_border_style = "rounded"
      opts.window = opts.window or {}
      opts.window.position = "left"
      opts.window.border = "rounded"
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
      opts.window.mappings["<S-CR>"]    = "open_vsplit"
      opts.window.mappings["["]         = "prev_source"
      opts.window.mappings["]"]         = "next_source"
      opts.window.mappings["<"]         = false
      opts.window.mappings[">"]         = false
      opts.window.mappings["I"] = function(state)
        state.__show_all_details = not state.__show_all_details
        local show_all = state.__show_all_details
        for _, renderer in pairs(state.renderers or {}) do
          toggle_renderer_details(renderer, show_all)
        end
        require("neo-tree.ui.renderer").redraw(state)
      end
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
      opts.filesystem.filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      }
      opts.filesystem.follow_current_file = { enabled = true }
      opts.filesystem.bind_to_cwd = false
      opts.filesystem.window = opts.filesystem.window or {}
      opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}
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
      opts.filesystem.window.mappings["{"] = "navigate_up"
      opts.filesystem.window.mappings["}"] = "set_root"
      opts.filesystem.window.mappings["<C-s>d"] = "grug_far_search_node"

      return opts
    end,
  },
}
