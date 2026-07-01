---@diagnostic disable: undefined-global, unused-local, unused-function, param-type-mismatch

-- Register the custom editing, navigation, Git, search, theme, and language keymaps.
-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymaps = vim.keymap
local opts = { noremap = true, silent = true }
local lazygit_edit = require("git.lazygit_edit")
local tab_jump = require("utils.tab_jump")
local python_lsp_settings = require("lsp.python_settings")
local typescript_lsp_settings = require("lsp.typescript_settings")

vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Nop>", { noremap = true, silent = true })

-- Increment/decrement
keymaps.set("n", "+", "C-a")
keymaps.set("n", "-", "C-x")

-- Select all
keymaps.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist
local function smart_jump(motion)
  tab_jump.jump(motion)
end
keymaps.set("n", "<leader>i", function() smart_jump("<C-o>") end, opts)
keymaps.set("n", "<leader>o", function() smart_jump("<C-i>") end, opts)
keymaps.set("n", "<C-o>", function() smart_jump("<C-o>") end, opts)

keymaps.set("n", "zc", "za", opts)

-- New tab
keymaps.set("n", "te", "tabedit")
vim.api.nvim_set_keymap("n", "te", ":tabedit<CR>", opts)
vim.api.nvim_set_keymap("n", "tq", ":tabclose<CR>", opts)

-- Split window
keymaps.set("n", "ss", ":split<Return>", opts)
keymaps.set("n", "sv", ":vsplit<Return>", opts)

local resize_mode_active = false

local function exit_resize_mode()
  if not resize_mode_active then return end
  resize_mode_active = false
  local resize_keys = { "h", "l", "j", "k", "<Left>", "<Right>", "<Up>", "<Down>", "<Esc>", "q", "=" }
  for _, k in ipairs(resize_keys) do
    pcall(vim.keymap.del, "n", k, { buffer = false })
  end
  vim.keymap.set("n", "j", "k", { silent = true })
  vim.keymap.set("n", "k", "j", { silent = true })
  vim.api.nvim_echo({}, false, {})
end

local function enter_resize_mode()
  if resize_mode_active then return end
  resize_mode_active = true
  local step = 3
  local map = vim.keymap.set
  local o = { nowait = true, silent = true }

  local function resize(cmd)
    return function()
      for _ = 1, step do vim.cmd("wincmd " .. cmd) end
    end
  end

  map("n", "h",       resize(">"), o)
  map("n", "l",       resize("<"), o)
  map("n", "j",       resize("+"), o)
  map("n", "k",       resize("-"), o)
  map("n", "<Left>",  resize(">"), o)
  map("n", "<Right>", resize("<"), o)
  map("n", "<Up>",    resize("+"), o)
  map("n", "<Down>",  resize("-"), o)
  map("n", "<Esc>",   exit_resize_mode, o)
  map("n", "q",       exit_resize_mode, o)
  map("n", "=",       function() vim.cmd("wincmd =") end, o)

  vim.api.nvim_echo({ { "-- RESIZE -- (h/l/j/k, <Esc> to exit)", "ModeMsg" } }, false, {})
end

keymaps.set("n", "<C-w>r", enter_resize_mode, { desc = "Enter resize mode" })

-- Diagnostics

-- Swap j/k (j=up, k=down)
keymaps.set("n", "j", "k", opts)
keymaps.set("n", "k", "j", opts)
keymaps.set("v", "j", "k", opts)
keymaps.set("v", "k", "j", opts)

-- Delete without copying to clipboard (black hole register)
keymaps.set("n", "d", '"_d', opts)
keymaps.set("n", "D", '"_D', opts)
keymaps.set("n", "dd", '"_dd', opts)
keymaps.set("n", "dw", '"_dw', opts)
keymaps.set("n", "db", '"_db', opts)
keymaps.set("n", "c", '"_c', opts)
keymaps.set("n", "C", '"_C', opts)
keymaps.set("n", "cc", '"_cc', opts)
keymaps.set("n", "cw", '"_cw', opts)
keymaps.set("n", "cb", '"_cb', opts)
keymaps.set("n", "x", '"+x', opts)
keymaps.set("n", "X", '"+X', opts)
keymaps.set("n", "s", '"_s', opts)
keymaps.set("v", "d", '"_d', opts)
keymaps.set("v", "D", '"_D', opts)
keymaps.set("v", "c", '"_c', opts)
keymaps.set("v", "C", '"_C', opts)
keymaps.set("v", "x", '"+x', opts)
keymaps.set("v", "s", '"_s', opts)
-- Paste over selection without yanking the replaced text
keymaps.set("v", "p", '"_dP', opts)
keymaps.set("v", "P", '"_dP', opts)

local function delete_range(start_row, start_col, end_row, end_col, enter_insert)
  vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { "" })
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  if enter_insert then vim.cmd("startinsert") end
end

local function change_to_custom_line_motion(side, enter_insert)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local row0 = row - 1

  if side == "right" then
    if col >= #line - 1 then
      if enter_insert then vim.cmd("startinsert!") end
      return
    end
    delete_range(row0, col, row0, #line, false)
    if enter_insert then vim.cmd("startinsert!") end
    return
  end

  local first_nonblank = vim.fn.indent(row) + 1
  local target_col = col == first_nonblank - 1 and 0 or first_nonblank - 1
  if target_col == col then
    if enter_insert then vim.cmd("startinsert") end
    return
  end
  delete_range(row0, target_col, row0, col, enter_insert)
end

keymaps.set("n", "dW", function() change_to_custom_line_motion("right", false) end, { desc = "Delete to custom W target" })
keymaps.set("n", "dB", function() change_to_custom_line_motion("left", false) end, { desc = "Delete to custom B target" })
keymaps.set("n", "cW", function() change_to_custom_line_motion("right", true) end, { desc = "Change to custom W target" })
keymaps.set("n", "cB", function() change_to_custom_line_motion("left", true) end, { desc = "Change to custom B target" })

local function node_contains_cursor(node, row, col)
  local start_row, start_col, end_row, end_col = node:range()
  if row < start_row or row > end_row then return false end
  if row == start_row and col < start_col then return false end
  if row == end_row and col > end_col then return false end
  return true
end

local function node_type_matches(kind, node_type)
  local function_types = {
    function_declaration = true,
    function_definition = true,
    function_item = true,
    function_statement = true,
    function_expression = true,
    arrow_function = true,
    method_declaration = true,
    method_definition = true,
    method = true,
    closure_expression = true,
  }
  local class_types = {
    class_declaration = true,
    class_definition = true,
    class = true,
    struct_item = true,
    enum_item = true,
    trait_item = true,
    impl_item = true,
    interface_declaration = true,
    type_alias_declaration = true,
  }
  return kind == "function" and function_types[node_type] or kind == "class" and class_types[node_type]
end

local function treesitter_containing_range(kind)
  local ok, node = pcall(vim.treesitter.get_node)
  if not ok or not node then return nil end

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  while node do
    if node_type_matches(kind, node:type()) and node_contains_cursor(node, row, col) then
      local start_row, _, end_row = node:range()
      return start_row, end_row
    end
    node = node:parent()
  end
  return nil
end

local function lsp_symbol_kind_matches(kind, symbol_kind)
  local lsp_kind = vim.lsp.protocol.SymbolKind
  if kind == "function" then
    return symbol_kind == lsp_kind.Function or symbol_kind == lsp_kind.Method or symbol_kind == lsp_kind.Constructor
  end
  return symbol_kind == lsp_kind.Class
    or symbol_kind == lsp_kind.Interface
    or symbol_kind == lsp_kind.Struct
    or symbol_kind == lsp_kind.Enum
end

local function lsp_containing_range(kind)
  local params = { textDocument = vim.lsp.util.make_text_document_params(0) }
  local responses = vim.lsp.buf_request_sync(0, "textDocument/documentSymbol", params, 1000)
  if not responses then return nil end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local best_start
  local best_end
  local best_size

  local function visit(symbols)
    for _, symbol in ipairs(symbols or {}) do
      local range = symbol.range or symbol.location and symbol.location.range
      if range then
        local start_row = range.start.line
        local end_row = range["end"].line
        if cursor_row >= start_row and cursor_row <= end_row and lsp_symbol_kind_matches(kind, symbol.kind) then
          local size = end_row - start_row
          if not best_size or size < best_size then
            best_start = start_row
            best_end = end_row
            best_size = size
          end
        end
      end
      visit(symbol.children)
    end
  end

  for _, response in pairs(responses) do
    if response.result then visit(response.result) end
  end

  return best_start, best_end
end

local function delete_code_object(kind, enter_insert)
  local start_row, end_row = treesitter_containing_range(kind)
  if not start_row then
    start_row, end_row = lsp_containing_range(kind)
  end

  if not start_row then
    vim.notify("No containing " .. kind .. " found", vim.log.levels.WARN, { title = "Code Object" })
    if enter_insert then vim.cmd("startinsert") end
    return
  end

  local line_count = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_buf_set_lines(0, start_row, math.min(end_row + 1, line_count), false, {})
  local target_row = math.min(start_row + 1, vim.api.nvim_buf_line_count(0))
  vim.api.nvim_win_set_cursor(0, { target_row, 0 })
  if enter_insert then vim.cmd("startinsert") end
end

keymaps.set("n", "dF", function() delete_code_object("function", false) end, { desc = "Delete containing function" })
keymaps.set("n", "dC", function() delete_code_object("class", false) end, { desc = "Delete containing class" })
keymaps.set("n", "cF", function() delete_code_object("function", true) end, { desc = "Change containing function" })
keymaps.set("n", "cC", function() delete_code_object("class", true) end, { desc = "Change containing class" })

-- Line navigation
keymaps.set({ "n", "v" }, "B", function()
  local col = vim.fn.col(".")
  local first_nonblank = vim.fn.indent(".") + 1
  if col == first_nonblank then
    vim.cmd("normal! 0")
  else
    vim.cmd("normal! ^")
  end
end, { desc = "Go to beginning of line (toggle ^/0)" })
keymaps.set("n", "W", "$", { desc = "Go to end of line" })
keymaps.set("v", "W", "$", { desc = "Go to end of line" })
keymaps.set("n", "zc", "za", opts)

-- Hover (show definition/error)
keymaps.set("n", "<leader>k", function()
  vim.lsp.buf.hover()
end, { desc = "Show hover information" })

-- Show diagnostic error message
keymaps.set("n", "<leader>K", function()
  vim.diagnostic.open_float()
end, { desc = "Show diagnostic message" })

-- Go to function definition
keymaps.set("n", "<C-S-CR>", function() Snacks.picker.lsp_definitions() end, { desc = "Go to definition" })
keymaps.set("n", "<C-CR>", function() Snacks.picker.lsp_definitions() end, { desc = "Go to definition" })
keymaps.set("n", "gd", function() Snacks.picker.lsp_definitions() end, { desc = "Go to definition" })
keymaps.set("n", "gr", function() Snacks.picker.lsp_references() end, { desc = "Go to references" })

keymaps.set("n", "<leader>fp", function()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then root = vim.fn.getcwd() end
  local rel = vim.fn.expand("%:p"):sub(#root + 2)
  vim.fn.setreg("+", rel)
  vim.notify("Copied: " .. rel, vim.log.levels.INFO, { title = "Path" })
end, { desc = "Copy path relative to project root" })

keymaps.set("n", "<leader>fP", function()
  local abs = vim.fn.expand("%:p")
  vim.fn.setreg("+", abs)
  vim.notify("Copied: " .. abs, vim.log.levels.INFO, { title = "Path" })
end, { desc = "Copy absolute path" })

local function path_under_cursor_or_buffer()
  if vim.bo.filetype == "neo-tree" then
    local ok, state = pcall(function()
      return require("neo-tree.sources.manager").get_state("filesystem")
    end)

    if ok and state and state.tree then
      local node = state.tree:get_node()
      if node then
        local path = node:get_id()
        if path and path ~= "" then return path end
      end
    end
  end

  return vim.api.nvim_buf_get_name(0)
end

local function file_manager_reveal_command(path)
  if vim.fn.has("macunix") == 1 then
    return { "open", "-R", path }
  end

  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return { "explorer", "/select," .. path:gsub("/", "\\") }
  end

  local target = path
  if vim.fn.filereadable(path) == 1 then
    target = vim.fn.fnamemodify(path, ":h")
  end

  return { "xdg-open", target }
end

keymaps.set("n", "<leader>fd", function()
  local path = path_under_cursor_or_buffer()
  if path == "" then
    vim.notify("Current buffer has no file path", vim.log.levels.WARN, { title = "Reveal File" })
    return
  end

  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    vim.notify("File not found: " .. path, vim.log.levels.WARN, { title = "Reveal File" })
    return
  end

  local cmd = file_manager_reveal_command(path)
  if vim.fn.executable(cmd[1]) ~= 1 then
    vim.notify("File manager command not found: " .. cmd[1], vim.log.levels.ERROR, { title = "Reveal File" })
    return
  end

  local ok = pcall(vim.system, cmd, { detach = true })
  if not ok then
    vim.notify("Failed to reveal: " .. path, vim.log.levels.ERROR, { title = "Reveal File" })
    return
  end

  vim.notify("Revealed externally: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO, { title = "Reveal File" })
end, { desc = "Reveal file in file manager" })

keymaps.set("n", "<leader>fo", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Current buffer has no file path", vim.log.levels.WARN, { title = "Open File" })
    return
  end

  path = vim.fn.fnamemodify(path, ":p")
  if vim.fn.filereadable(path) ~= 1 and vim.fn.isdirectory(path) ~= 1 then
    vim.notify("File not found: " .. path, vim.log.levels.WARN, { title = "Open File" })
    return
  end

  local cmd
  if vim.fn.has("macunix") == 1 then
    cmd = { "open", path }
  elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    cmd = { "cmd", "/c", "start", "", path }
  else
    cmd = { "xdg-open", path }
  end

  if vim.fn.executable(cmd[1]) ~= 1 then
    vim.notify("Open command not found: " .. cmd[1], vim.log.levels.ERROR, { title = "Open File" })
    return
  end

  local ok = pcall(vim.system, cmd, { detach = true })
  if not ok then
    vim.notify("Failed to open: " .. path, vim.log.levels.ERROR, { title = "Open File" })
    return
  end

  vim.notify("Opened externally: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.INFO, { title = "Open File" })
end, { desc = "Open file externally" })

keymaps.set("n", "<C-m>", vim.lsp.buf.hover, { desc = "Show hover information" })
keymaps.set("i", "<C-n>", function() require("blink.cmp").show() end, { desc = "Show suggestions" })

keymaps.set("n", "<leader>ce", function()
  vim.lsp.buf.code_action({
    apply = true,
    context = { only = { "source.fixAll.eslint" }, diagnostics = {} },
  })
end, { desc = "ESLint fix file" })

keymaps.set("n", "<C-j>", ":tabprev<CR>", { desc = "Previous tab" })
keymaps.set("n", "<C-k>", ":tabnext<CR>", { desc = "Next tab" })
keymaps.set("n", "<C-S-j>", function()
  if vim.fn.tabpagenr() > 1 then vim.cmd("tabmove -1") end
end, { desc = "Move tab left" })
keymaps.set("n", "<C-S-k>", function()
  if vim.fn.tabpagenr() < vim.fn.tabpagenr("$") then vim.cmd("tabmove +1") end
end, { desc = "Move tab right" })
keymaps.set("n", "<leader><tab>q", ":tabclose<CR>", { desc = "Close tab" })
pcall(vim.keymap.del, "n", "<leader><tab>]")
pcall(vim.keymap.del, "n", "<leader><tab>[")

local function move_buf_to_win(dir)
  local buf = vim.api.nvim_get_current_buf()
  local cur_win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. dir)
  local target_win = vim.api.nvim_get_current_win()
  if target_win == cur_win then
    vim.cmd(dir == "h" and "leftabove vsplit" or "rightbelow vsplit")
    vim.cmd("wincmd " .. dir)
    target_win = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_win_set_buf(target_win, buf)
  vim.api.nvim_set_current_win(cur_win)
  local ok = pcall(vim.cmd, "bprevious")
  if not ok or vim.api.nvim_get_current_buf() == buf then
    vim.cmd("enew")
  end
  vim.api.nvim_set_current_win(target_win)
end

keymaps.set("n", "<C-h>", function() smart_jump("<C-o>") end, { desc = "Jump back" })
keymaps.set("n", "<C-l>", function() smart_jump("<C-i>") end, { desc = "Jump forward" })

-- Smart buffer goto: if the buffer is already visible in another tab, jump there
local function smart_buf_goto(bufnr)
  if not bufnr or bufnr <= 0 then return end
  if tab_jump.goto_visible_buf(bufnr) then return end
  vim.api.nvim_set_current_buf(bufnr)
end

local function goto_alt_buf()
  local cur = vim.api.nvim_get_current_buf()

  local function usable(bufnr)
    if not bufnr or bufnr <= 0 or bufnr == cur then return false end
    if not vim.api.nvim_buf_is_valid(bufnr) then return false end
    if vim.fn.buflisted(bufnr) ~= 1 then return false end
    if vim.bo[bufnr].buftype ~= "" then return false end
    if vim.api.nvim_buf_get_name(bufnr) == "" then return false end
    return true
  end

  local h = vim.g.buf_history or {}
  for i = #h, 1, -1 do
    if usable(h[i]) then
      smart_buf_goto(h[i])
      return
    end
  end
end
keymaps.set("n", "<C-^>",      goto_alt_buf, { desc = "Alternate buffer (tab-aware)" })
keymaps.set("n", "<leader>bb", goto_alt_buf, { desc = "Switch to Other Buffer" })

keymaps.set("n", "<C-w>z", function()
  if vim.t.maximized then
    vim.cmd("wincmd =")
    vim.t.maximized = false
  else
    vim.cmd("wincmd _")
    vim.cmd("wincmd |")
    vim.t.maximized = true
  end
end, { desc = "Toggle maximize window" })

keymaps.set("n", "<C-w>_", "<cmd>vsplit<CR>", { desc = "Split window vertically" })
keymaps.set("n", "<C-w>-", "<cmd>split<CR>",  { desc = "Split window horizontally" })

local function toggle_terminal_split()
  Snacks.terminal.toggle(nil, {
    count = 1,
    win = {
      position = "bottom",
    },
  })
end

keymaps.set("n", "<C-w>t", toggle_terminal_split, { desc = "Toggle terminal split" })

keymaps.set("n", "<C-w>=", function()
  vim.cmd("wincmd =")
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      local ok, state = pcall(function()
        return require("neo-tree.sources.manager").get_state("filesystem")
      end)
      local width = (ok and state and state.window and state.window.width) or 30
      vim.api.nvim_win_set_width(win, width)
      break
    end
  end
end, { desc = "Equalize windows (preserve neo-tree width)" })

local function pick_buffers_smart()
  Snacks.picker.buffers({
    confirm = function(picker, item)
      local buf = item and item.buf
      picker:close()
      vim.schedule(function()
        if buf then smart_buf_goto(buf) end
      end)
    end,
  })
end
keymaps.set("n", "<C-Tab>",    pick_buffers_smart, { desc = "Find buffers" })
keymaps.set("n", "<leader>bl", pick_buffers_smart, { desc = "List buffers" })

keymaps.set("n", "<Tab>", ">>", { desc = "Indent line" })
keymaps.set("n", "<S-Tab>", "<<", { desc = "Unindent line" })
keymaps.set("v", "<Tab>", ">gv", { desc = "Indent selection" })
keymaps.set("v", "<S-Tab>", "<gv", { desc = "Unindent selection" })
keymaps.set("i", "<Tab>", "<C-t>", { desc = "Indent" })
keymaps.set("i", "<S-Tab>", "<C-d>", { desc = "Unindent" })

local function move_current_line(delta)
  vim.cmd(delta < 0 and "move .-2" or "move .+1")
  vim.cmd("normal! ==")
end

local function move_selected_lines(delta)
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line == 0 or end_line == 0 then
    return
  end
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local line_count = vim.api.nvim_buf_line_count(0)
  if delta < 0 and start_line == 1 then
    return
  end
  if delta > 0 and end_line == line_count then
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, {})

  local target = delta < 0 and (start_line - 2) or start_line
  vim.api.nvim_buf_set_lines(0, target, target, false, lines)

  local new_start = start_line + delta
  local new_end = end_line + delta
  vim.fn.setpos("'<", { 0, new_start, 1, 0 })
  vim.fn.setpos("'>", { 0, new_end, 1, 0 })
  vim.api.nvim_win_set_cursor(0, { new_end, 0 })
  vim.cmd("normal! gv=gv")
end

keymaps.set("n", "<C-S-Up>", function() move_current_line(-1) end, { desc = "Move line up" })
keymaps.set("n", "<C-S-Down>", function() move_current_line(1) end, { desc = "Move line down" })
keymaps.set("v", "<C-S-Up>", function() move_selected_lines(-1) end, { desc = "Move selection up" })
keymaps.set("v", "<C-S-Down>", function() move_selected_lines(1) end, { desc = "Move selection down" })

keymaps.set("n", "<C-e>", vim.diagnostic.open_float, { desc = "Show line diagnostics" })



keymaps.set("n", "<C-w>j", "<C-w>k", opts)
keymaps.set("n", "<C-w>k", "<C-w>j", opts)
