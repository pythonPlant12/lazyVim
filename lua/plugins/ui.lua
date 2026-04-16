local tab_reuse = require("config.tab_reuse")

local function remove_gl_key(_, keys)
  return vim.tbl_filter(function(k)
    local lhs = type(k) == "string" and k or k[1]
    return lhs ~= "<leader>gl"
  end, keys)
end

local picker_excludes = {
  "node_modules/**",
  "venv/**",
  ".venv/**",
  ".idea",
  ".idea/**",
  "**/.idea/**",
  ".vscode/**",
  ".zed/**",
  ".git/**",
  "shelved.patch",
  "**/shelved.patch",
}

local function grep_case_mode_args(args, camel_case)
  local filtered = {}
  for _, arg in ipairs(args or {}) do
    if arg ~= "--ignore-case" and arg ~= "--case-sensitive" and arg ~= "--smart-case" then
      filtered[#filtered + 1] = arg
    end
  end
  if not camel_case then
    filtered[#filtered + 1] = "--ignore-case"
  end
  return filtered
end

local function toggle_grep_camel_case(picker)
  local source = picker and picker.opts and picker.opts.source or nil
  if source ~= "grep" and source ~= "grep_word" then
    return
  end

  picker.opts.camel_case = not picker.opts.camel_case
  picker.opts.args = grep_case_mode_args(picker.opts.args, picker.opts.camel_case)
  picker.list:set_target()
  picker:find()

  vim.notify(
    picker.opts.camel_case and "Grep case mode: camel/smart" or "Grep case mode: insensitive",
    vim.log.levels.INFO,
    { title = "Grep" }
  )
end

local function apply_item_pos(item)
  if not item then
    return
  end

  require("snacks.picker.util").resolve_loc(item)

  local pos = item.pos
  if not (pos and pos[1]) and item.loc and item.loc.range and item.loc.range.start then
    local start = item.loc.range.start
    pos = { start.line + 1, start.character }
  end
  if not (pos and pos[1]) then
    return
  end

  local line_count = vim.api.nvim_buf_line_count(0)
  local row = math.max(1, math.min(pos[1], line_count))
  local col = math.max(0, pos[2] or 0)
  local ok = pcall(vim.cmd, ("keepjumps call cursor(%d, %d)"):format(row, col + 1))
  if not ok then
    pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
  end
  pcall(vim.cmd, "normal! zv")
end

local function confirm_lsp_location(picker, item)
  if not item then
    return
  end

  local function remember_jump_origin()
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()
    local is_empty = vim.bo[buf].buftype == ""
      and vim.bo[buf].filetype == ""
      and vim.api.nvim_buf_line_count(buf) == 1
      and vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1] == ""
      and vim.api.nvim_buf_get_name(buf) == ""
    if is_empty then
      return
    end

    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! m'")
    end)
  end

  remember_jump_origin()

  picker:close()
  require("snacks.picker.util").resolve_loc(item)

  local path = Snacks.picker.util.path(item) or item.file
  if not path or path == "" then
    return
  end

  if tab_reuse.jump_to_path(path, { prefer_other_tabs = true }) then
    apply_item_pos(item)
    return
  end

  local escaped = vim.fn.fnameescape(path)
  local ok = pcall(vim.cmd, "drop " .. escaped)
  if not ok then
    vim.cmd("edit " .. escaped)
  end
  apply_item_pos(item)
end

local uv = vim.uv or vim.loop

local video_ext = {
  mp4 = true,
  mov = true,
  avi = true,
  mkv = true,
  webm = true,
}

local function is_video_path(path)
  if not path or path == "" then
    return false
  end
  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  return video_ext[ext] == true
end

local function video_thumbnail_path(path)
  local dir = vim.fn.stdpath("cache") .. "/snacks/video"
  vim.fn.mkdir(dir, "p")
  return dir .. "/" .. vim.fn.sha256(path) .. ".png"
end

local function generate_video_thumbnail(path)
  local stat = uv.fs_stat(path)
  if not stat then
    return nil
  end

  local thumb = video_thumbnail_path(path)
  local thumb_stat = uv.fs_stat(thumb)
  if thumb_stat and thumb_stat.mtime and stat.mtime and thumb_stat.mtime.sec >= stat.mtime.sec then
    return thumb
  end

  if vim.fn.executable("ffmpeg") ~= 1 then
    return nil
  end

  local result = vim.system({
    "ffmpeg",
    "-hide_banner",
    "-loglevel",
    "error",
    "-y",
    "-i",
    path,
    "-vf",
    "thumbnail,scale=1920:-1",
    "-frames:v",
    "1",
    thumb,
  }, { text = true }):wait()

  if result.code == 0 and uv.fs_stat(thumb) then
    return thumb
  end

  return nil
end

local function snacks_file_preview_with_video(ctx)
  local path = Snacks.picker.util.path(ctx.item)
  if not is_video_path(path) then
    return require("snacks.picker.preview").file(ctx)
  end

  local thumb = generate_video_thumbnail(path)
  if not thumb then
    return require("snacks.picker.preview").file(ctx)
  end

  local buf = ctx.preview:scratch()
  local title = ctx.item.title or vim.fn.fnamemodify(path, ":t")
  ctx.preview:set_title(title)
  Snacks.image.buf.attach(buf, { src = thumb })
  return true
end

local function fzf_file_switch_or_edit(selected, opts)
  if not (selected and selected[1]) then
    return
  end
  local actions = require("fzf-lua.actions")
  if #selected > 1 then
    return actions.file_sel_to_qf(selected, opts)
  end

  local path_mod = require("fzf-lua.path")
  local entry = path_mod.entry_to_file(selected[1], opts)
  local target = entry.path or entry.bufname
  if target and tab_reuse.jump_to_path(target, { prefer_other_tabs = true }) then
    if (entry.line or 0) > 0 or (entry.col or 0) > 0 then
      local row = math.max(1, entry.line)
      local col = math.max(1, entry.col)
      local ok = pcall(vim.cmd, ("keepjumps call cursor(%d, %d)"):format(row, col))
      if not ok then
        pcall(vim.api.nvim_win_set_cursor, 0, { row, col - 1 })
      end
    end
    return
  end

  actions.file_edit(selected, opts)
end

return {
  {
    "stevearc/aerial.nvim",
    opts = {
      -- Per-filetype allow-list. "_" is the default for all other filetypes.
      -- Vue/HTML exclude Struct: template elements and custom component tags
      -- are reported as Struct by the LSP and add noise to the breadcrumb.
      filter_kind = {
        _ = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method", "Struct" },
        vue  = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method" },
        html = { "Class", "Constructor", "Enum", "Function", "Interface", "Module", "Method" },
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = remove_gl_key,
  },
  {
    "ibhagwan/fzf-lua",
    keys = remove_gl_key,
    opts = {
      fzf_colors = true,
      actions = {
        files = {
          ["enter"] = fzf_file_switch_or_edit,
        },
      },
      files = {
        formatter = { "path.filename_first", 2 },
      },
      grep = {
        formatter = { "path.filename_first", 2 },
      },
    },
  },
  {
    "LazyVim/LazyVim",
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
      opts.filesystem.follow_current_file = { enabled = true }
      opts.filesystem.bind_to_cwd = false
      opts.filesystem.window = opts.filesystem.window or {}
      opts.filesystem.window.mappings = opts.filesystem.window.mappings or {}
      opts.filesystem.window.mappings["{"] = "navigate_up"
      opts.filesystem.window.mappings["}"] = "set_root"

      return opts
    end,
  },
  -- bufferline
  {
    "akinsho/bufferline.nvim",
    keys = {
    },
    opts = function(_, opts)
      local _appearance = vim.fn.system("defaults read -g AppleInterfaceStyle 2>/dev/null"):gsub("%s+", "")
      local is_light = _appearance ~= "Dark"
      opts = opts or {}
      opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
        mode = "tabs",
        separator_style = { "", "" },
        show_buffer_close_icons = false,
        show_close_icon = false,
        indicator = { style = "none" },
        diagnostics = false,
      })
      opts.highlights = is_light and {
        fill                    = { bg = "#D8D4CE" },
        background              = { fg = "#52505A", bg = "#C8C2B8" },
        tab                     = { fg = "#52505A", bg = "#C8C2B8" },
        tab_selected            = { fg = "#ffffff", bg = "#5B9CF6", bold = true },
        tab_separator           = { fg = "#C8C2B8", bg = "#D8D4CE" },
        tab_separator_selected  = { fg = "#5B9CF6", bg = "#D8D4CE" },
        tab_close               = { fg = "#52505A", bg = "#D8D4CE" },
        buffer_selected         = { fg = "#ffffff", bg = "#5B9CF6", bold = true, italic = false },
        buffer_visible          = { fg = "#52505A", bg = "#C8C2B8", italic = false },
        numbers_selected        = { fg = "#ffffff", bg = "#5B9CF6", bold = true },
        numbers_visible         = { fg = "#52505A", bg = "#C8C2B8" },
        close_button            = { fg = "#52505A", bg = "#C8C2B8" },
        close_button_visible    = { fg = "#52505A", bg = "#C8C2B8" },
        close_button_selected   = { fg = "#ffffff", bg = "#5B9CF6" },
        indicator_selected      = { fg = "#5B9CF6", bg = "#5B9CF6" },
        indicator_visible       = { fg = "#C8C2B8", bg = "#C8C2B8" },
        separator               = { fg = "#B8B2A8", bg = "#D8D4CE" },
        separator_selected      = { fg = "#5B9CF6", bg = "#D8D4CE" },
        separator_visible       = { fg = "#B8B2A8", bg = "#D8D4CE" },
        duplicate_selected      = { fg = "#ffffff", bg = "#5B9CF6", bold = true, italic = false },
        duplicate               = { fg = "#52505A", bg = "#C8C2B8", italic = false },
        duplicate_visible       = { fg = "#52505A", bg = "#C8C2B8", italic = false },
        modified_selected       = { fg = "#ffffff", bg = "#5B9CF6", italic = false },
        modified                = { fg = "#52505A", bg = "#C8C2B8", italic = false },
        modified_visible        = { fg = "#52505A", bg = "#C8C2B8", italic = false },
      } or {
        fill                    = { bg = "#1e1e2e" },
        background              = { fg = "#6c7086", bg = "#181825" },
        tab                     = { fg = "#6c7086", bg = "#181825" },
        tab_selected            = { fg = "#1e1e2e", bg = "#89b4fa", bold = true },
        tab_separator           = { fg = "#181825", bg = "#1e1e2e" },
        tab_separator_selected  = { fg = "#89b4fa", bg = "#1e1e2e" },
        tab_close               = { fg = "#6c7086", bg = "#1e1e2e" },
        buffer_selected         = { fg = "#1e1e2e", bg = "#89b4fa", bold = true, italic = false },
        buffer_visible          = { fg = "#6c7086", bg = "#181825", italic = false },
        numbers_selected        = { fg = "#1e1e2e", bg = "#89b4fa", bold = true },
        numbers_visible         = { fg = "#6c7086", bg = "#181825" },
        close_button            = { fg = "#6c7086", bg = "#181825" },
        close_button_visible    = { fg = "#6c7086", bg = "#181825" },
        close_button_selected   = { fg = "#1e1e2e", bg = "#89b4fa" },
        indicator_selected      = { fg = "#89b4fa", bg = "#89b4fa" },
        indicator_visible       = { fg = "#181825", bg = "#181825" },
        separator               = { fg = "#181825", bg = "#1e1e2e" },
        separator_selected      = { fg = "#89b4fa", bg = "#1e1e2e" },
        separator_visible       = { fg = "#181825", bg = "#1e1e2e" },
        duplicate_selected      = { fg = "#1e1e2e", bg = "#89b4fa", bold = true, italic = false },
        duplicate               = { fg = "#6c7086", bg = "#181825", italic = false },
        duplicate_visible       = { fg = "#6c7086", bg = "#181825", italic = false },
        modified_selected       = { fg = "#1e1e2e", bg = "#89b4fa", italic = false },
        modified                = { fg = "#6c7086", bg = "#181825", italic = false },
        modified_visible        = { fg = "#6c7086", bg = "#181825", italic = false },
      }
      return opts
    end,
  },
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>,",
        function()
          Snacks.picker.buffers({
            confirm = function(picker, item)
              if not item then return end
              picker:close()
              if item.buf and tab_reuse.jump_to_buf(item.buf, { prefer_other_tabs = true }) then
                return
              end
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
          require("config.search_grep").cwd_with_filter_mode()
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
              if item.buf and tab_reuse.jump_to_buf(item.buf, { prefer_other_tabs = true }) then
                return
              end
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
            require("config.search_grep").toggle_case(picker)
          end,
          toggle_word = function(picker)
            require("config.search_grep").toggle_word(picker)
          end,
          confirm = function(picker, item)
            if not item then return end
            picker:close()

            local path = Snacks.picker.util.path(item)
            if path and is_video_path(path) then
              local thumb = generate_video_thumbnail(path)
              if thumb then
                local bufnr = vim.fn.bufnr(path)
                if bufnr ~= -1 and tab_reuse.jump_to_buf(bufnr, { prefer_other_tabs = true }) then
                  Snacks.image.buf.attach(bufnr, { src = thumb })
                  return
                end

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

            if path and tab_reuse.jump_to_path(path, { prefer_other_tabs = true }) then
              apply_item_pos(item)
              return
            end

            local bufnr = item.buf
            if not bufnr and path then
              bufnr = vim.fn.bufnr(path)
              if bufnr == -1 then
                vim.cmd("edit " .. vim.fn.fnameescape(path))
                apply_item_pos(item)
                return
              end
            end

            if bufnr and tab_reuse.jump_to_buf(bufnr, { prefer_other_tabs = true }) then
              apply_item_pos(item)
              return
            end

            if not bufnr then return end
            vim.bo[bufnr].buflisted = true
            vim.api.nvim_set_current_buf(bufnr)
            apply_item_pos(item)
          end,
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
      local lualine_light = {
        normal   = { a = { fg = "#F0EDE8", bg = "#5A8FD4", gui = "bold" }, b = { fg = "#4C4F69", bg = "#D5D0CA", gui = "bold" }, c = { fg = "#4C4F69", bg = "#E2DFDB" } },
        insert   = { a = { fg = "#F0EDE8", bg = "#7CA686", gui = "bold" }, b = { fg = "#4C4F69", bg = "#D5D0CA", gui = "bold" } },
        visual   = { a = { fg = "#F0EDE8", bg = "#9B87C4", gui = "bold" }, b = { fg = "#4C4F69", bg = "#D5D0CA", gui = "bold" } },
        replace  = { a = { fg = "#F0EDE8", bg = "#B85C5C", gui = "bold" }, b = { fg = "#4C4F69", bg = "#D5D0CA", gui = "bold" } },
        command  = { a = { fg = "#F0EDE8", bg = "#C87A3A", gui = "bold" }, b = { fg = "#4C4F69", bg = "#D5D0CA", gui = "bold" } },
        inactive = { a = { fg = "#7A7880", bg = "#E2DFDB" }, b = { fg = "#7A7880", bg = "#E2DFDB" }, c = { fg = "#7A7880", bg = "#E2DFDB" } },
      }
      local lualine_dark = {
        normal   = { a = { fg = "#191A1C", bg = "#89b4fa", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" }, c = { fg = "#BCBEC4", bg = "#2B2D30" } },
        insert   = { a = { fg = "#191A1C", bg = "#a6e3a1", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        visual   = { a = { fg = "#191A1C", bg = "#B189F5", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        replace  = { a = { fg = "#191A1C", bg = "#F75464", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        command  = { a = { fg = "#191A1C", bg = "#D5B778", gui = "bold" }, b = { fg = "#BCBEC4", bg = "#3B3F45", gui = "bold" } },
        inactive = { a = { fg = "#6F737A", bg = "#191A1C" }, b = { fg = "#6F737A", bg = "#191A1C" }, c = { fg = "#6F737A", bg = "#191A1C" } },
      }
      local _hint = vim.g._lualine_theme_hint or ""
      local mode_theme = _hint == "islands-light" and lualine_light or _hint == "islands-dark" and lualine_dark or (vim.o.background == "light" and lualine_light or lualine_dark)
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        theme = mode_theme,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
      })
      opts.sections = opts.sections or {}
      opts.sections.lualine_a = {
        { "mode", separator = { left = "\u{E0B6}", right = "\u{E0B4}" }, padding = { left = 1, right = 1 } },
      }
      opts.sections.lualine_x = {}
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

      local function setup_breadcrumb_hl()
        local chip_bgs_hl = vim.o.background == "light"
          and { "#D5D0CA", "#D5D0CA", "#D5D0CA" }
          or  { "#3A3D41", "#42464D", "#4A4F57" }
        local breadcrumb_bg = chip_bgs_hl[2] or chip_bgs_hl[1]
        local breadcrumb_fg = vim.o.background == "light" and "#4C4F69" or "#CED0D6"
        local arrow_fg = vim.o.background == "light" and "#2F3147" or "#DCE0E8"
        for i, bg in ipairs(chip_bgs_hl) do
          vim.api.nvim_set_hl(0, "LualineBreadcrumbSep" .. i, { fg = arrow_fg, bg = bg })
        end
        vim.api.nvim_set_hl(0, "LualineBreadcrumbStatus", { fg = breadcrumb_fg, bg = breadcrumb_bg })
      end
      setup_breadcrumb_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_breadcrumb_hl })

      local function setup_git_hl()
        if vim.o.background == "light" then
          vim.api.nvim_set_hl(0, "LualineGitBase",   { fg = "#7A7880", bg = "#D5D0CA", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitBranch", { fg = "#6B3CC8", bg = "#D5D0CA", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitGreen",  { fg = "#7CA686", bg = "#D5D0CA", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = "#A8983A", bg = "#D5D0CA", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitPeach",  { fg = "#C87A3A", bg = "#D5D0CA", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitRed",    { fg = "#B85C5C", bg = "#D5D0CA", bold = true })
        else
          vim.api.nvim_set_hl(0, "LualineGitBase",   { fg = "#BCBEC4", bg = "#3B3F45", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitBranch", { fg = "#cba6f7", bg = "#3B3F45", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitGreen",  { fg = "#a6e3a1", bg = "#3B3F45", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = "#f9e2af", bg = "#3B3F45", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitPeach",  { fg = "#fab387", bg = "#3B3F45", bold = true })
          vim.api.nvim_set_hl(0, "LualineGitRed",    { fg = "#f38ba8", bg = "#3B3F45", bold = true })
        end
      end
      setup_git_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_git_hl })

      local function setup_lualine_theme_hl()
        local hint = vim.g._lualine_theme_hint or ""
        local theme
        if hint == "islands-light" then
          theme = lualine_light
        elseif hint == "islands-dark" then
          theme = lualine_dark
        else
          theme = "auto"
        end
        local ok, lualine = pcall(require, "lualine")
        if not ok then return end
        local cfg = lualine.get_config()
        cfg.options = cfg.options or {}
        cfg.options.theme = theme
        lualine.setup(cfg)
      end
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_lualine_theme_hl })

      opts.sections.lualine_b = {
        {
          function()
            local branch = vim.b.gitsigns_head or vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
            if branch == "" or branch:find("fatal") then return "" end
            local parts = { "%#LualineGitBranch#󰘬 " .. branch }
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
          padding = { left = 1, right = 0 },
          separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        },
        {
          function() return "|" end,
          padding = { left = 1, right = 1 },
          separator = "",
          color = function()
            return { fg = vim.o.background == "light" and "#9B9792" or "#6B6F75" }
          end,
          cond = function()
            if vim.b.gitsigns_head and vim.b.gitsigns_head ~= "" then return true end
            local b = vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "")
            return b ~= "" and not b:find("fatal")
          end,
        },
      }

      local function setup_diag_hl()
        if vim.o.background == "light" then
          vim.api.nvim_set_hl(0, "DiagPillCap",   { fg = "#D5D0CA", bg = "#E2DFDB" })
          vim.api.nvim_set_hl(0, "DiagPillBase",  { fg = "#7A7880", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillError", { fg = "#B85C5C", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillWarn",  { fg = "#A8983A", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillInfo",  { fg = "#5A8FD4", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillHint",  { fg = "#7CA686", bg = "#D5D0CA" })
        else
          vim.api.nvim_set_hl(0, "DiagPillCap",   { fg = "#313438", bg = "#2B2D30" })
          vim.api.nvim_set_hl(0, "DiagPillBase",  { fg = "#BCBEC4", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillError", { fg = "#f38ba8", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillWarn",  { fg = "#f9e2af", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillInfo",  { fg = "#89b4fa", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillHint",  { fg = "#a6e3a1", bg = "#313438" })
        end
      end
      setup_diag_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_diag_hl })

      local new_c = {}
      for i, comp in ipairs(opts.sections.lualine_c or {}) do
        if i == 1 then goto skip end
        if type(comp) == "table" and comp[1] == "diagnostics" then goto skip end
        if type(comp) == "table" and comp[1] == "filetype" and comp.icon_only then goto skip end
        table.insert(new_c, comp)
        ::skip::
      end
      opts.sections.lualine_c = new_c

      -- Replace LazyVim's Trouble symbols component with a kind-filtered version.
      -- The component is identified by: table with function at [1] and a cond function.
      -- For Vue/HTML files, Struct kind items (template elements, custom component tags)
      -- are excluded so they don't pollute the statusline breadcrumb.
      local breadcrumb_symbols = nil
      do
        local ok_t, trouble_api = pcall(require, "trouble")
        if ok_t then
          for i, comp in ipairs(opts.sections.lualine_c) do
            if type(comp) == "table" and type(comp[1]) == "function" and type(comp.cond) == "function" then
              local symbols = trouble_api.statusline({
                mode = "symbols",
                groups = {},
                title = false,
                filter = { range = true, no_vue_struct = true },
                filters = {
                  no_vue_struct = function(item)
                    local ft = vim.bo.filetype
                    if ft ~= "vue" and ft ~= "html" then return true end
                    return not (item.item and item.item.kind == "Struct")
                  end,
                },
                format = "{kind_icon}{symbol.name:Normal}",
                hl_group = "LualineBreadcrumbStatus",
              })
              breadcrumb_symbols = symbols
              opts.sections.lualine_c[i] = {
                symbols and symbols.get,
                cond = function()
                  return vim.b.trouble_lualine ~= false and symbols.has()
                end,
              }
              break
            end
          end
        end
      end

      table.insert(opts.sections.lualine_x, 1, {
        function()
          local d = vim.diagnostic.count(0)
          local e = d[vim.diagnostic.severity.ERROR] or 0
          local w = d[vim.diagnostic.severity.WARN] or 0
          local inf = d[vim.diagnostic.severity.INFO] or 0
          local h = d[vim.diagnostic.severity.HINT] or 0
          if e + w + inf + h == 0 then return "" end
          local parts = {}
          if e > 0 then table.insert(parts, "%#DiagPillError#E " .. e) end
          if w > 0 then table.insert(parts, "%#DiagPillWarn#W " .. w) end
          if inf > 0 then table.insert(parts, "%#DiagPillInfo#I " .. inf) end
          if h > 0 then table.insert(parts, "%#DiagPillHint#H " .. h) end
          return table.concat(parts, " ")
        end,
        cond = function()
          local d = vim.diagnostic.count(0)
          local e = d[vim.diagnostic.severity.ERROR] or 0
          local w = d[vim.diagnostic.severity.WARN] or 0
          local inf = d[vim.diagnostic.severity.INFO] or 0
          local h = d[vim.diagnostic.severity.HINT] or 0
          return e + w + inf + h > 0
        end,
        separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        color = function()
          local light = vim.o.background == "light"
          return { fg = light and "#7A7880" or "#7A7E85", bg = light and "#D5D0CA" or "#2B2D30" }
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
        basedpyright   = "󰌠 ",
        pylsp          = "󰌠 ",
        jsonls         = "󰘦 ",
        html           = "󰌝 ",
        cssls          = "󰌜 ",
        emmet_ls       = "󰯸 ",
        bashls         = " ",
        dockerls       = "󰡨 ",
        yamlls         = "󰘦 ",
        copilot        = " ",
        ["null-ls"]    = "󱏿 ",
      }

      local lsp_colors = {
        vtsls          = "#89b4fa",
        ts_ls          = "#89b4fa",
        tsserver       = "#89b4fa",
        vue_ls         = "#a6e3a1",
        volar          = "#a6e3a1",
        tailwindcss    = "#94e2d5",
        lua_ls         = "#89b4fa",
        pyright        = "#fab387",
        basedpyright   = "#fab387",
        pylsp          = "#fab387",
        jsonls         = "#f9e2af",
        html           = "#fab387",
        cssls          = "#74c7ec",
        emmet_ls       = "#fab387",
        bashls         = "#a6e3a1",
        dockerls       = "#89dceb",
        yamlls         = "#f9e2af",
        copilot        = "#cba6f7",
        ["null-ls"]    = "#94e2d5",
      }

      local lsp_colors_light = {
        vtsls          = "#0B74D6",
        ts_ls          = "#0B74D6",
        tsserver       = "#0B74D6",
        vue_ls         = "#2E7D4F",
        volar          = "#2E7D4F",
        tailwindcss    = "#1A8894",
        lua_ls         = "#0B74D6",
        pyright        = "#A04B10",
        basedpyright   = "#A04B10",
        pylsp          = "#A04B10",
        jsonls         = "#7A5C00",
        html           = "#A04B10",
        cssls          = "#1A8894",
        emmet_ls       = "#A04B10",
        bashls         = "#2E7D4F",
        dockerls       = "#1A8894",
        yamlls         = "#7A5C00",
        copilot        = "#6B3CC8",
        ["null-ls"]    = "#1A8894",
      }

      local function setup_lsp_hl()
        local light = vim.o.background == "light"
        local lsp_bg = light and "#D5D0CA" or "#45475a"
        local colors = light and lsp_colors_light or lsp_colors
        vim.api.nvim_set_hl(0, "LualineLspBase",        { fg = light and "#7A7880" or "#93a1a1",  bg = lsp_bg })
        vim.api.nvim_set_hl(0, "LualineCopilotOn",      { fg = light and "#7B72C9" or "#cba6f7",  bg = lsp_bg })
        vim.api.nvim_set_hl(0, "LualineCopilotSpinner", { fg = light and "#A8983A" or "#f9e2af",  bg = lsp_bg })
        vim.api.nvim_set_hl(0, "LualineCopilotOff",     { fg = light and "#7A7880" or "#6c7086",  bg = lsp_bg })
        for name, fg in pairs(colors) do
          local hl = "LualineLsp_" .. name:gsub("[%-%.]", "_")
          vim.api.nvim_set_hl(0, hl, { fg = fg, bg = lsp_bg })
        end
      end
      setup_lsp_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_lsp_hl })

      table.insert(opts.sections.lualine_x, {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then return "" end
          local parts = {}
          local seen = {}
          for _, c in ipairs(clients) do
            if c.name == "eslint" or c.name == "copilot" then goto continue end
            if not seen[c.name] then
              seen[c.name] = true
              local icon = lsp_icons[c.name] or "󰒋 "
              local hl = "LualineLsp_" .. c.name:gsub("[%-%.]", "_")
              if lsp_colors[c.name] then
                parts[#parts + 1] = "%#" .. hl .. "#" .. icon .. c.name .. "%#LualineLspBase#"
              else
                parts[#parts + 1] = icon .. c.name
              end
            end
            ::continue::
          end
          return table.concat(parts, "  ")
        end,
        separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        color = function()
          local light = vim.o.background == "light"
          return { fg = light and "#7A7880" or "#93a1a1", bg = light and "#D5D0CA" or "#45475a" }
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          local icon = " "
          local ok, status = pcall(require, "copilot.status")
          if not ok then
            return "%#LualineCopilotOff#" .. icon .. "copilot%#LualineLspBase#"
          end
          local s = status.data and status.data.status or ""
          if s == "InProgress" then
            return "%#LualineCopilotSpinner#" .. icon .. "copilot%#LualineLspBase#"
          elseif s == "Normal" then
            return "%#LualineCopilotOn#" .. icon .. "copilot%#LualineLspBase#"
          else
            return "%#LualineCopilotOff#" .. icon .. "copilot%#LualineLspBase#"
          end
        end,
        separator = { left = "", right = "" },
        color = function()
          local light = vim.o.background == "light"
          return { fg = light and "#9BA5B0" or "#6c7086", bg = light and "#C8CCD1" or "#45475a" }
        end,
        cond = function()
          return LazyVim.has("copilot.lua")
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          local fmt_active = vim.g.autoformat == nil or vim.g.autoformat
          return "󰉼 fmt" .. (fmt_active and " (A)" or "")
        end,
        separator = { left = "", right = "" },
        color = function()
          local light = vim.o.background == "light"
          local lsp_bg = light and "#C8CCD1" or "#45475a"
          return (vim.g.autoformat == nil or vim.g.autoformat)
            and { fg = light and "#7CA686" or "#a6e3a1", bg = lsp_bg }
            or  { fg = light and "#7A7880" or "#586e75", bg = lsp_bg }
        end,
      })

      table.insert(opts.sections.lualine_x, {
        function()
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return "󰅪 eslint" end
          return "󰅪 eslint" .. (autosave_on and " (A)" or "")
        end,
        separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        color = function()
          local light = vim.o.background == "light"
          local lsp_bg = light and "#D5D0CA" or "#45475a"
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return { fg = light and "#7A7880" or "#586e75", bg = lsp_bg } end
          return autosave_on
            and { fg = light and "#A8983A" or "#f9e2af", bg = lsp_bg }
            or  { fg = light and "#7A7880" or "#93a1a1", bg = lsp_bg }
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
          color.fg = color.fg or (vim.o.background == "light" and "#4C4F69" or "#CED0D6")
          color.bg = bg
          return color
        end

        return comp
      end

      opts.sections.lualine_c = opts.sections.lualine_c or {}
      local chip_bgs = vim.o.background == "light"
        and { "#D5D0CA", "#D5D0CA", "#D5D0CA" }
        or  { "#3A3D41", "#42464D", "#4A4F57" }
      local chip_index = 1
      local styled_c = {}
      for _, comp in ipairs(opts.sections.lualine_c) do
        local head = type(comp) == "table" and comp[1] or comp
        local is_path_like = type(head) == "function" or head == "filename"
        if is_path_like then
          local bg = chip_bgs[((chip_index - 1) % #chip_bgs) + 1]
          local styled_comp = style_chip(comp, bg)
          if chip_index == 1 then
            styled_comp.padding = { left = 1, right = 0 }
            local path_fn = LazyVim.lualine.pretty_path({ filename_hl = "", directory_hl = "" })
            styled_comp[1] = function(self)
              local icon = require("mini.icons").get("file", vim.fn.expand("%:t"))
              local path = type(path_fn) == "function" and path_fn(self) or ""
              if icon and icon ~= "" then return icon .. " " .. path end
              return path
            end
            local existing_color_fn = styled_comp.color
            styled_comp.color = function()
              local c = type(existing_color_fn) == "function" and existing_color_fn() or {}
              c.gui = (c.gui and c.gui .. ",bold" or "bold")
              return c
            end
          end
          if chip_index > 1 then
            local sep_hl = "LualineBreadcrumbSep" .. (((chip_index - 1) % 3) + 1)
            styled_comp.padding = { left = 0, right = 0 }
            local original = styled_comp[1]
            if type(original) == "function" then
              styled_comp[1] = function(self)
                local str = (original(self) or ""):gsub("^%s+", ""):gsub("%s+$", "")
                return str:gsub(" %%#", "%%#" .. sep_hl .. "# %%#")
              end
            end
            styled_comp.fmt = function(str)
              local max = math.max(0, vim.o.columns - 100)
              local visible = str:gsub("%%#[^#]*#", "")
              if #visible <= max then return str end
              if max < 5 then return "" end
              local out, count, i = {}, 0, 1
              while i <= #str and count < max - 1 do
                if str:sub(i, i) == "%" and str:sub(i + 1, i + 1) == "#" then
                  local j = str:find("#", i + 2)
                  if j then table.insert(out, str:sub(i, j)); i = j + 1
                  else i = i + 1 end
                else
                  local b = str:byte(i)
                  local char_len = (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
                  table.insert(out, str:sub(i, i + char_len - 1)); count = count + 1; i = i + char_len
                end
              end
              return table.concat(out) .. "…"
            end
          end
          table.insert(styled_c, styled_comp)
          if chip_index == 1 then
            local sep_bg = chip_bgs[1]
            local sep_comp = style_chip({ function() return "|" end }, sep_bg)
            sep_comp.padding = { left = 1, right = 1 }
            sep_comp.color = function()
              return { fg = vim.o.background == "light" and "#9B9792" or "#6B6F75", bg = sep_bg }
            end
            sep_comp.cond = function()
              return breadcrumb_symbols ~= nil
                and vim.b.trouble_lualine ~= false
                and breadcrumb_symbols.has()
            end
            table.insert(styled_c, sep_comp)
          end
          chip_index = chip_index + 1
        else
          table.insert(styled_c, comp)
        end
      end
      opts.sections.lualine_c = styled_c

      return opts
    end,
  },
}
