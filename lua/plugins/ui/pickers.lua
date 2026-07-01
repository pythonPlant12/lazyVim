---@diagnostic disable: undefined-global

-- Configure UI-facing plugins: pickers, explorer, statusline, notifications, and borders.
local tab_jump = require("utils.tab_jump")

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

  -- Wait for buffer to be loaded before applying position
  vim.schedule(function()
    local line_count = vim.api.nvim_buf_line_count(0)
    local row = math.max(1, math.min(pos[1], line_count))
    local col = math.max(0, pos[2] or 0)
    local ok = pcall(vim.cmd, ("keepjumps call cursor(%d, %d)"):format(row, col + 1))
    if not ok then
      pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
    end
    pcall(vim.cmd, "normal! zv")
    pcall(vim.cmd, "normal! zz")  -- Center cursor on screen
  end)
end

local function open_in_tab(picker, item)
  if not item then
    return
  end

  require("snacks.picker.util").resolve_loc(item)

  local path = Snacks.picker.util.path(item) or item.file
  if not path or path == "" then
    local bufnr = item.buf
    if not bufnr then return end
    picker.opts.auto_close = false
    vim.api.nvim_win_call(picker.main, function()
      vim.cmd("tabnew")
      vim.api.nvim_set_current_buf(bufnr)
    end)
    picker:focus()
    picker.opts.auto_close = nil
    return
  end

  local buf = vim.fn.bufadd(path)
  vim.bo[buf].buflisted = true

  picker.opts.auto_close = false
  vim.api.nvim_win_call(picker.main, function()
    vim.cmd(("tab sbuffer %d"):format(buf))
  end)
  apply_item_pos(item)
  picker:focus()
  picker.opts.auto_close = nil
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

  -- File not open in any tab, open it in current window
  local ok, err = tab_jump.edit_or_goto_path(path)
  if not ok then
    vim.notify("Failed to open file: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
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
  if not target then
    return actions.file_edit(selected, opts)
  end

  local ok, err = tab_jump.edit_or_goto_path(target)
  if not ok then
    vim.notify("Failed to open file: " .. (err or "unknown error"), vim.log.levels.ERROR)
    return
  end

  if (entry.line or 0) > 0 or (entry.col or 0) > 0 then
    local row = math.max(1, entry.line or 1)
    local col = math.max(1, entry.col or 1)
    local set_ok = pcall(vim.cmd, ("keepjumps call cursor(%d, %d)"):format(row, col))
    if not set_ok then
      pcall(vim.api.nvim_win_set_cursor, 0, { row, col - 1 })
    end
    pcall(vim.cmd, "normal! zv")
    pcall(vim.cmd, "normal! zz")
  end
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
}
