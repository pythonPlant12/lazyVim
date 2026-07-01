local keymaps = vim.keymap
local opts = { noremap = true, silent = true }

keymaps.set("n", "<leader>rv", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { desc = "Rename variable", expr = true })

keymaps.set("n", "<leader>cdf", function() Snacks.picker.diagnostics_buffer() end, { desc = "File diagnostics" })
keymaps.set("n", "<leader>cdw", function() Snacks.picker.diagnostics() end, { desc = "Workspace diagnostics" })
keymaps.set("n", "<leader>se", function() Snacks.picker.diagnostics_buffer() end, { desc = "Buffer diagnostics" })
Snacks.toggle({
  name = "ESLint Auto-fix",
  get = function() return vim.g.eslint_autosave == nil or vim.g.eslint_autosave end,
  set = function(state) vim.g.eslint_autosave = state end,
}):map("<leader>cFe")
keymaps.set("n", "<C-b>", "<Nop>", opts)

local function toggle_bookmark_at_source()
  local source_win = vim.api.nvim_get_current_win()
  local source_buf = vim.api.nvim_win_get_buf(source_win)
  local source_cursor = vim.api.nvim_win_get_cursor(source_win)
  local source_path = vim.api.nvim_buf_get_name(source_buf)

  if source_path == "" or vim.bo[source_buf].buftype ~= "" or vim.bo[source_buf].filetype == "neo-tree" then
    vim.notify("Bookmarks can only be added from file buffers", vim.log.levels.WARN, { title = "Bookmarks" })
    return
  end

  local location = {
    path = source_path,
    line = source_cursor[1],
    col = source_cursor[2],
  }

  local service = require("bookmarks.domain.service")
  local sign = require("bookmarks.sign")
  local tree = require("bookmarks.tree.operate")
  local bookmark = service.find_bookmark_by_location(location)

  vim.ui.input({ prompt = "[Bookmarks Toggle]", default = bookmark and bookmark.name or "" }, function(input)
    if not input then return end

    if not vim.api.nvim_win_is_valid(source_win) or not vim.api.nvim_buf_is_valid(source_buf) then
      vim.notify("Bookmark source window is no longer available", vim.log.levels.WARN, { title = "Bookmarks" })
      return
    end

    if vim.api.nvim_win_get_buf(source_win) ~= source_buf then
      vim.notify("Bookmark source buffer changed", vim.log.levels.WARN, { title = "Bookmarks" })
      return
    end

    vim.api.nvim_set_current_win(source_win)
    vim.api.nvim_win_set_cursor(source_win, source_cursor)
    service.toggle_mark(input, location)
    sign.safe_refresh_signs()
    pcall(tree.refresh)
  end)
end

keymaps.set("n", "<C-b>b", function()
  if vim.bo.filetype == "neo-tree" then
    vim.notify("Cannot add bookmarks from neo-tree", vim.log.levels.WARN, { title = "Bookmarks" })
    return
  end
  vim.cmd("BookmarksMark")
end, { desc = "Toggle bookmark" })
keymaps.set("n", "<C-b>l", "<cmd>BookmarksGoto<cr>", { desc = "List bookmarks" })
keymaps.set("n", "<leader>cFc", function()
  local conform = require("conform")
  local formatters = conform.list_formatters(0)
  local available = vim.tbl_filter(function(f) return f.available end, formatters)
  if #available == 0 then
    vim.notify("No formatters available for " .. vim.bo.filetype, vim.log.levels.WARN, { title = "Format" })
    return
  end
  vim.ui.select(available, {
    prompt = "Format with:",
    format_item = function(f) return f.name end,
  }, function(choice)
    if choice then
      conform.format({ formatters = { choice.name }, async = false, lsp_fallback = false })
    end
  end)
end, { desc = "Choose formatter" })

vim.schedule(function()
  require("which-key").add({ { "<leader>cF", group = "format" } })
end)

vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    local to_del = {
      { "n", "<leader>gg" },
      { "n", "<leader>gG" },
      { "n", "<leader>gL" },
      { "n", "<leader>gb" },
      { "n", "<leader>gf" },
      { { "n", "x" }, "<leader>gB" },
      { { "n", "x" }, "<leader>gY" },
    }
    for _, m in ipairs(to_del) do
      local modes = type(m[1]) == "table" and m[1] or { m[1] }
      for _, mode in ipairs(modes) do
        pcall(vim.keymap.del, mode, m[2])
      end
    end
    keymaps.set("n", "<leader>gl", function()
      vim.ui.input({ prompt = "Go to line: " }, function(input)
        if input and input ~= "" then
          local line = tonumber(input)
          if line then
            vim.cmd(tostring(line))
          end
        end
      end)
    end, { desc = "Go to line" })
  end,
})

keymaps.set("n", "<S-Up>",   "Vk", { desc = "Select line upward" })
keymaps.set("n", "<S-Down>", "Vj", { desc = "Select line downward" })
keymaps.set("v", "<S-Up>",   "k",  { desc = "Extend selection up" })
keymaps.set("v", "<S-Down>", "j",  { desc = "Extend selection down" })
keymaps.set("n", "J",        "Vk", { desc = "Select line upward" })
keymaps.set("n", "K",        "Vj", { desc = "Select line downward" })
keymaps.set("v", "J",        "k",  { desc = "Extend selection up" })
keymaps.set("v", "K",        "j",  { desc = "Extend selection down" })

-- Option+Left/Right: move word by word
-- <M-Right>/<M-Left>  = xterm sequence  (iTerm2 / most modern terminals)
-- <M-f>/<M-b>         = readline sequence (Terminal.app and some others)
keymaps.set({ "n", "v" }, "<M-Right>", "w",      { desc = "Move forward a word" })
keymaps.set("i",           "<M-Right>", "<C-o>w", { desc = "Move forward a word" })
keymaps.set({ "n", "v" }, "<M-f>",     "w",      { desc = "Move forward a word" })
keymaps.set("i",           "<M-f>",     "<C-o>w", { desc = "Move forward a word" })
keymaps.set({ "n", "v" }, "<M-Left>",  "b",      { desc = "Move backward a word" })
keymaps.set("i",           "<M-Left>",  "<C-o>b", { desc = "Move backward a word" })
keymaps.set({ "n", "v" }, "<M-b>",     "b",      { desc = "Move backward a word" })
keymaps.set("i",           "<M-b>",     "<C-o>b", { desc = "Move backward a word" })

keymaps.set("i", "<M-BS>", "<C-w>", { desc = "Delete previous word" })
keymaps.set("i", "<A-BS>", "<C-w>", { desc = "Delete previous word" })
keymaps.set("i", "<M-Del>", "<C-w>", { desc = "Delete previous word" })
keymaps.set("i", "<A-Del>", "<C-w>", { desc = "Delete previous word" })

local function comment_line()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gcc", true, false, true), "m", false)
end
local function comment_visual()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gc", true, false, true), "m", false)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gv", true, false, true), "m", false)
end
keymaps.set("n", "<C-/>", comment_line,   { desc = "Toggle comment" })
keymaps.set("v", "<C-/>", comment_visual, { desc = "Toggle comment" })
keymaps.set("n", "<C-_>", comment_line,   { desc = "Toggle comment" })
keymaps.set("v", "<C-_>", comment_visual, { desc = "Toggle comment" })

keymaps.set("n", "gl", function()
  local input = vim.fn.input(": ")
  if not input or input == "" then
    return
  end

  local line = tonumber(vim.trim(input))
  if not line then
    vim.notify("Invalid line number", vim.log.levels.WARN, { title = "Go to line" })
    return
  end

  local max_line = vim.api.nvim_buf_line_count(0)
  line = math.max(1, math.min(line, max_line))
  vim.cmd(tostring(line))
  pcall(vim.cmd, "normal! zv")
end, { desc = "Go to line" })

local theme_state_file = vim.fn.stdpath("state") .. "/theme"

local function save_theme(value)
  local f = io.open(theme_state_file, "w")
  if f then
    f:write(value)
    f:close()
  end
end

local lazygit_cfg_dir = vim.fn.expand("~/Library/Application Support/lazygit")
local function lazygit_theme_name(kind)
  if kind == "default-white" then
    return "light"
  end
  if kind == "default-dark" then
    return "dark"
  end
  if kind == "islands-white" then
    return "islands-light"
  end
  return kind
end

local function update_lazygit_theme(kind)
  kind = lazygit_theme_name(kind)
  local src
  if type(kind) == "string" and kind ~= "" then
    src = lazygit_cfg_dir .. "/config-" .. kind .. ".yml"
  end
  local dst = lazygit_cfg_dir .. "/config.yml"
  if src then
    local rf = io.open(src, "r")
    if rf then
      local content = rf:read("*a")
      rf:close()
      local wf = io.open(dst, "w")
      if wf then
        wf:write(content)
        wf:close()
      end
      return
    end
  end
  local wf = io.open(dst, "w")
  if wf then
    wf:write([[
gui:
  theme:
    activeBorderColor:
      - default
      - bold
    inactiveBorderColor:
      - default
    selectedLineBgColor:
      - default
    inactiveViewSelectedLineBgColor:
      - default
    selectedRangeBgColor:
      - default
    unstagedChangesColor:
      - default
    cherryPickedCommitBgColor:
      - default
    cherryPickedCommitFgColor:
      - default
    defaultFgColor:
      - default
keybinding:
  universal:
    prevItem: j
    nextItem: k
    prevItem-alt: <up>
    nextItem-alt: <down>
customCommands:
  - key: E
    context: files
    description: Open file in new tab
    command: "python3 /Users/nikita/.config/nvim/scripts/lazygit-edit --tab {{if .SelectedFile}}{{.SelectedFile.Name | quote}}{{else}}{{.SelectedPath | quote}}{{end}}"
git:
  paging:
    colorArg: always
    pager: "delta --color-only --syntax-theme=none --paging=never --hunk-header-decoration-style=none"
]])
    wf:close()
  end
end

local function lualine_theme_hint(scheme, background)
  if scheme == "default-white" or scheme == "islands-white" or scheme == "islands-light" then
    return "islands-light"
  end
  if scheme == "default-dark" or scheme == "islands-dark" then
    return "islands-dark"
  end
  return scheme:find("^islands") and ("islands-" .. background) or "auto"
end

local function apply_scheme(scheme, background)
  vim.o.background = background
  local transparent = scheme == "islands-dark"
    or scheme == "islands-white"
    or scheme == "islands-light"
    or scheme:find("^islands%-rose%-pine") ~= nil
  local blend = transparent and 10 or 0
  vim.o.winblend = blend
  vim.o.pumblend = blend
  vim.g._lualine_theme_hint = lualine_theme_hint(scheme, background)
  vim.cmd.colorscheme(scheme)
  vim.g.theme_mode = background
  save_theme(scheme)
  update_lazygit_theme(scheme)
end

local function apply_theme_mode(mode)
  local background = mode == "light" and "light" or "dark"
  vim.o.background = background
  vim.o.winblend = 0
  vim.o.pumblend = 0

  local schemes = background == "dark"
      and { "default-dark", "solarized-osaka", "habamax" }
    or { "default-white", "solarized-osaka", "morning", "habamax" }

  for _, scheme in ipairs(schemes) do
    vim.g._lualine_theme_hint = lualine_theme_hint(scheme, background)
    if pcall(vim.cmd.colorscheme, scheme) then
      vim.g.theme_mode = background
      save_theme(scheme)
      update_lazygit_theme(scheme)
      return
    end
  end

  vim.notify("No colorscheme available for " .. background .. " mode", vim.log.levels.ERROR, { title = "Theme" })
end

local function apply_islands_theme(variant)
  local bg = variant == "white" and "light" or "dark"
  apply_scheme("islands-" .. variant, bg)
end

local function apply_catppuccin(flavour)
  local bg = (flavour == "latte") and "light" or "dark"
  vim.o.background = bg
  vim.o.winblend = 0
  vim.o.pumblend = 0
  require("catppuccin").setup({ flavour = flavour })
  vim.g._lualine_theme_hint = "auto"
  vim.cmd.colorscheme("catppuccin")
  vim.g.theme_mode = bg
  save_theme("catppuccin:" .. flavour)
  update_lazygit_theme(bg)
end

local function apply_rose_pine(variant)
  local cs = variant == "main" and "rose-pine" or ("rose-pine-" .. variant)
  local bg = variant == "dawn" and "light" or "dark"
  vim.o.background = bg
  vim.o.winblend = 0
  vim.o.pumblend = 0
  vim.g._lualine_theme_hint = "auto"
  vim.cmd.colorscheme(cs)
  vim.g.theme_mode = bg
  save_theme(cs)
  update_lazygit_theme(bg == "light" and "rose-pine-light" or "rose-pine-dark")
end

local function apply_rose_pine_dark_dimmed()
  vim.o.background = "dark"
  vim.o.winblend = 0
  vim.o.pumblend = 0
  vim.g._lualine_theme_hint = "auto"
  vim.cmd.colorscheme("rose-pine-dark-dimmed")
  vim.g.theme_mode = "dark"
  save_theme("rose-pine-dark-dimmed")
  update_lazygit_theme("rose-pine-dark-dimmed")
end

local function apply_islands_rose_pine(variant)
  local cs = "islands-rose-pine-" .. variant
  local bg = variant == "light" and "light" or "dark"
  vim.o.background = bg
  vim.o.winblend = 10
  vim.o.pumblend = 10
  vim.g._lualine_theme_hint = "islands-" .. variant
  vim.cmd.colorscheme(cs)
  vim.g.theme_mode = bg
  save_theme(cs)
  update_lazygit_theme(cs)
end

keymaps.set("n", "<leader>ut", function()
  local items = {
    { label = "Default Dark Theme",        action = function() apply_theme_mode("dark") end },
    { label = "Default White Theme",       action = function() apply_theme_mode("light") end },
    { label = "Islands Dark Theme",        action = function() apply_islands_theme("dark") end },
    { label = "Islands White Theme",       action = function() apply_islands_theme("white") end },
    { label = "Catppuccin Mocha (dark)",   action = function() apply_catppuccin("mocha") end },
    { label = "Catppuccin Macchiato",      action = function() apply_catppuccin("macchiato") end },
    { label = "Catppuccin Frappé",         action = function() apply_catppuccin("frappe") end },
    { label = "Catppuccin Latte (light)",  action = function() apply_catppuccin("latte") end },
    { label = "Rose Pine (dark)",              action = function() apply_rose_pine("main") end },
    { label = "Rose Pine Moon (dark)",         action = function() apply_rose_pine("moon") end },
    { label = "Rose Pine Dark Dimmed",         action = apply_rose_pine_dark_dimmed },
    { label = "Rose Pine Dawn (light)",        action = function() apply_rose_pine("dawn") end },
    { label = "Islands × Rose Pine (dark)",   action = function() apply_islands_rose_pine("dark") end },
    { label = "Islands × Rose Pine (light)",  action = function() apply_islands_rose_pine("light") end },
  }

  vim.ui.select(items, {
    prompt = "Select theme",
    kind = "theme",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    choice.action()
  end)
end, { desc = "Select default theme" })

Snacks.toggle({
  name = "Inline Diagnostics",
  get = function()
    if vim.g.inline_diagnostics_enabled == nil then
      vim.g.inline_diagnostics_enabled = vim.diagnostic.config().virtual_text ~= false
    end
    return vim.g.inline_diagnostics_enabled
  end,
  set = function(enabled)
    vim.g.inline_diagnostics_enabled = enabled
    vim.diagnostic.config({ virtual_text = enabled })
  end,
}):map("<leader>ui")

local function apply_inlay_hints(enabled, bufnr)
  if not vim.lsp.inlay_hint then
    return
  end

  local function apply(buf)
    if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_buf_is_loaded(buf) then
      return
    end
    if #vim.lsp.get_clients({ bufnr = buf }) == 0 then
      return
    end
    vim.lsp.inlay_hint.enable(enabled, { bufnr = buf })
  end

  if bufnr then
    apply(bufnr)
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    apply(buf)
  end
end

vim.g.inlay_hints_enabled = vim.g.inlay_hints_enabled
if vim.g.inlay_hints_enabled == nil then
  vim.g.inlay_hints_enabled = true
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("PersistentInlayHints", { clear = true }),
  callback = function(ev)
    apply_inlay_hints(vim.g.inlay_hints_enabled, ev.buf)
  end,
})

Snacks.toggle({
  name = "Inlay Hints",
  get = function()
    return vim.g.inlay_hints_enabled
  end,
  set = function(enabled)
    vim.g.inlay_hints_enabled = enabled
    apply_inlay_hints(enabled)
  end,
}):map("<leader>up")

Snacks.toggle({
  id = "persistent_inlay_hints_alias",
  name = "Inlay Hints",
  get = function()
    return vim.g.inlay_hints_enabled
  end,
  set = function(enabled)
    vim.g.inlay_hints_enabled = enabled
    apply_inlay_hints(enabled)
  end,
}):map("<leader>uh")

vim.keymap.set("n", "<leader>ue", function()
  require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
end, { desc = "Reveal file in tree" })

vim.keymap.set("n", "<leader>e", function()
  local cur_win = vim.api.nvim_get_current_win()
  local neotree_win = nil
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
    local cfg = vim.api.nvim_win_get_config(win)
    if ft == "neo-tree" and cfg.relative == "" then
      neotree_win = win
      break
    end
  end
  if neotree_win == nil then
    require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
  elseif neotree_win == cur_win then
    require("neo-tree.command").execute({ action = "close" })
  else
    vim.api.nvim_set_current_win(neotree_win)
  end
end, { desc = "Toggle Neo-tree" })
