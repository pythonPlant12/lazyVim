-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymaps = vim.keymap
local opts = { noremap = true, silent = true }

vim.keymap.set({ "n", "i", "x", "s" }, "<C-s>", "<Nop>", { noremap = true, silent = true })

-- Increment/decrement
keymaps.set("n", "+", "C-a")
keymaps.set("n", "-", "C-x")

-- Select all
keymaps.set("n", "<C-a>", "gg<S-v>G")

-- Jumplist
local function smart_jump(motion)
  local pre_buf = vim.api.nvim_get_current_buf()
  local pre_win = vim.api.nvim_get_current_win()
  vim.g._tab_reuse_suppress = true
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(motion, true, false, true), "n", false
  )
  vim.schedule(function()
    vim.g._tab_reuse_suppress = false
    local post_buf = vim.api.nvim_get_current_buf()
    if post_buf == pre_buf then return end
    local cur_tab = vim.api.nvim_get_current_tabpage()
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      if tab ~= cur_tab then
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
          if vim.api.nvim_win_get_buf(win) == post_buf then
            vim.api.nvim_win_set_buf(pre_win, pre_buf)
            vim.api.nvim_set_current_tabpage(tab)
            vim.api.nvim_set_current_win(win)
            return
          end
        end
      end
    end
  end)
end
keymaps.set("n", "<leader>i", function() smart_jump("<C-o>") end, opts)
keymaps.set("n", "<leader>o", function() smart_jump("<C-i>") end, opts)

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
keymaps.set("n", "dW", '"_dW', opts)
keymaps.set("n", "db", '"_db', opts)
keymaps.set("n", "dB", '"_dB', opts)
keymaps.set("n", "c", '"_c', opts)
keymaps.set("n", "C", '"_C', opts)
keymaps.set("n", "cc", '"_cc', opts)
keymaps.set("n", "cw", '"_cw', opts)
keymaps.set("n", "cW", '"_cW', opts)
keymaps.set("n", "cb", '"_cb', opts)
keymaps.set("n", "cB", '"_cB', opts)
keymaps.set("n", "x", '"+x', opts)
keymaps.set("n", "X", '"+X', opts)
keymaps.set("n", "s", '"_s', opts)
keymaps.set("v", "d", '"_d', opts)
keymaps.set("v", "D", '"_D', opts)
keymaps.set("v", "c", '"_c', opts)
keymaps.set("v", "C", '"_C', opts)
keymaps.set("v", "x", '"+x', opts)
keymaps.set("v", "s", '"_s', opts)

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
keymaps.set("n", "<leader><tab>q", ":tabclose<CR>", { desc = "Close tab" })

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

keymaps.set("n", "<C-h>", function() move_buf_to_win("h") end, { desc = "Move buffer to left window" })
keymaps.set("n", "<C-l>", function() move_buf_to_win("l") end, { desc = "Move buffer to right window" })

-- Smart buffer goto: if the buffer is already visible in another tab, jump there
local function smart_buf_goto(bufnr)
  if not bufnr or bufnr <= 0 then return end
  local cur_tab = vim.api.nvim_get_current_tabpage()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if tab ~= cur_tab then
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if vim.api.nvim_win_get_buf(win) == bufnr then
          vim.api.nvim_set_current_tabpage(tab)
          vim.api.nvim_set_current_win(win)
          return
        end
      end
    end
  end
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

-- Git (<C-g>)
keymaps.set("n", "<C-g>g",  function() Snacks.lazygit({ cwd = LazyVim.root.git() }) end, { desc = "Lazygit" })
keymaps.set("n", "<C-g>l",  "<Nop>", opts)
keymaps.set("n", "<C-g>h",  function() Snacks.picker.git_log({ cwd = LazyVim.root.git() }) end, { desc = "Git history" })
keymaps.set("n", "<C-g>s",  function() Snacks.picker.git_status() end, { desc = "Git status" })
keymaps.set("n", "<C-g>d",  function() Snacks.picker.git_diff() end, { desc = "Git diff" })
keymaps.set("n", "<C-g>ld", function() require("gitsigns").preview_hunk_inline() end, { desc = "Line diff" })
keymaps.set("n", "<C-g>lh", function() Snacks.picker.git_log_line() end, { desc = "Line history" })
keymaps.set("n", "<C-g>lr", function() require("gitsigns").reset_hunk() end, { desc = "Revert line/hunk to HEAD" })
local close_file_diff
local function open_file_diff_fullscreen(base)
  require("gitsigns").diffthis(base)
  if vim.wo.diff then
    vim.cmd("wincmd =")

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[win].diff then
        local buf = vim.api.nvim_win_get_buf(win)
        vim.b[buf].git_file_diff_mode = true
        vim.keymap.set("n", "q", close_file_diff, {
          buffer = buf,
          silent = true,
          desc = "Close file diff",
        })
      end
    end
  end
end

local function git_root_or_cwd()
  local ok, root = pcall(function() return LazyVim.root.git() end)
  return (ok and root and root ~= "") and root or vim.fn.getcwd()
end

local function git_lines(args)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { cwd = git_root_or_cwd(), text = true }):wait()
  if result.code ~= 0 then
    local err = vim.trim(result.stderr or "")
    return nil, err ~= "" and err or "git command failed"
  end
  local out = vim.trim(result.stdout or "")
  if out == "" then
    return {}, nil
  end
  return vim.split(out, "\n", { trimempty = true }), nil
end

local function current_branch()
  local lines = git_lines({ "rev-parse", "--abbrev-ref", "HEAD" })
  if type(lines) == "table" and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
  return "HEAD"
end

local function list_branches(active_branch)
  local lines, err = git_lines({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" })
  if not lines then
    return nil, err
  end
  local seen = {}
  local current = {}
  local local_refs = {}
  local remote_refs = {}
  for _, ref in ipairs(lines) do
    if ref ~= "origin/HEAD" and not seen[ref] then
      seen[ref] = true
      local is_remote = ref:find("/", 1, true) ~= nil
      local item = {
        ref = ref,
        label = is_remote and ("[remote] " .. ref) or ("[local]  " .. ref),
      }
      if (not is_remote) and active_branch and ref == active_branch then
        item.label = item.label .. " (current)"
        current[#current + 1] = item
      elseif is_remote then
        remote_refs[#remote_refs + 1] = item
      else
        local_refs[#local_refs + 1] = item
      end
    end
  end
  local items = {}
  vim.list_extend(items, current)
  vim.list_extend(items, local_refs)
  vim.list_extend(items, remote_refs)
  return items, nil
end

local function list_commits(ref, limit)
  local lines, err = git_lines({ "log", ref, "--pretty=format:%h\t%s", ("--max-count=%d"):format(limit or 150) })
  if not lines then
    return nil, err
  end
  local items = {}
  for i, line in ipairs(lines) do
    local sha, subj = line:match("^(%S+)%s+(.+)$")
    if sha then
      local head = i == 1 and "HEAD" or "    "
      items[#items + 1] = { ref = sha, label = string.format("%s %s  %s", head, sha, subj or "") }
    end
  end
  return items, nil
end

local function pick_diff_base_and_open()
  local active = current_branch()
  local branches, err = list_branches(active)
  if not branches then
    vim.notify("Could not list branches: " .. err, vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  if #branches == 0 then
    vim.notify("No branches found", vim.log.levels.WARN, { title = "Git Diff" })
    return
  end

  vim.ui.select(branches, {
    prompt = "Select branch:",
    format_item = function(item) return item.label end,
  }, function(branch_item)
    if not branch_item then
      return
    end

    local commits, commits_err = list_commits(branch_item.ref, 150)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Diff" })
      return
    end
    if #commits == 0 then
      vim.notify("No commits found for " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Diff" })
      return
    end

    vim.ui.select(commits, {
      prompt = "Select commit from " .. branch_item.ref .. ":",
      format_item = function(item) return item.label end,
    }, function(commit_item)
      if commit_item then
        open_file_diff_fullscreen(commit_item.ref)
      end
    end)
  end)
end

keymaps.set("n", "<C-g>fd", open_file_diff_fullscreen, { desc = "File diff" })
keymaps.set("n", "<C-g>fD", pick_diff_base_and_open, { desc = "File diff against ref" })

local function pick_line_diff_base_and_preview()
  local active = current_branch()
  local branches, err = list_branches(active)
  if not branches then
    vim.notify("Could not list branches: " .. err, vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  if #branches == 0 then
    vim.notify("No branches found", vim.log.levels.WARN, { title = "Git Diff" })
    return
  end

  vim.ui.select(branches, {
    prompt = "Select branch:",
    format_item = function(item) return item.label end,
  }, function(branch_item)
    if not branch_item then return end

    local commits, commits_err = list_commits(branch_item.ref, 150)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Diff" })
      return
    end
    if #commits == 0 then
      vim.notify("No commits found for " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Diff" })
      return
    end

    vim.ui.select(commits, {
      prompt = "Select commit from " .. branch_item.ref .. ":",
      format_item = function(item) return item.label end,
    }, function(commit_item)
      if not commit_item then return end
      local gs = require("gitsigns")
      gs.change_base(commit_item.ref, false)
      gs.preview_hunk_inline()
    end)
  end)
end

keymaps.set("n", "<C-g>lD", pick_line_diff_base_and_preview, { desc = "Line diff against ref" })
close_file_diff = function()
  if not vim.wo.diff then return end
  local cur_win = vim.api.nvim_get_current_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= cur_win and vim.wo[w].diff then
      local buf = vim.api.nvim_win_get_buf(w)
      pcall(vim.keymap.del, "n", "q", { buffer = buf })
      vim.b[buf].git_file_diff_mode = nil
      pcall(vim.api.nvim_win_close, w, false)
    end
  end
  local cur_buf = vim.api.nvim_win_get_buf(cur_win)
  pcall(vim.keymap.del, "n", "q", { buffer = cur_buf })
  vim.b[cur_buf].git_file_diff_mode = nil
  vim.cmd("diffoff!")
end

keymaps.set("n", "<C-g>fq", close_file_diff, { desc = "Close file diff" })
keymaps.set("n", "<C-g>fh", function() Snacks.picker.git_log_file() end, { desc = "File history" })
keymaps.set("n", "<C-g>fr", function() require("gitsigns").reset_buffer() end, { desc = "Revert file to HEAD" })

local ns_inline = vim.api.nvim_create_namespace("gitsigns_preview_inline")

local function has_inline_preview()
  local bufnr = vim.api.nvim_get_current_buf()
  return #vim.api.nvim_buf_get_extmarks(bufnr, ns_inline, 0, -1, { limit = 1 }) > 0
end

keymaps.set("n", "n", function()
  if vim.wo.diff then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("]c", true, false, true), "n", false)
  elseif has_inline_preview() then
    require("gitsigns").nav_hunk("next")
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "n", false)
  end
end, { desc = "Next hunk in diff, otherwise next search match" })

keymaps.set("n", "N", function()
  if vim.wo.diff then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("[c", true, false, true), "n", false)
  elseif has_inline_preview() then
    require("gitsigns").nav_hunk("prev")
  else
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("N", true, false, true), "n", false)
  end
end, { desc = "Prev hunk in diff, otherwise previous search match" })

local function set_exact_visual_search(text)
  if not text or text == "" then
    return false
  end
  text = vim.fn.escape(text, "/\\")
  text = text:gsub("\n", "\\n")
  vim.fn.setreg("/", "\\V" .. text)
  vim.cmd("set hlsearch")
  return true
end

local function parse_search_query(input)
  if not input or input == "" then
    return nil
  end

  local has_prefix = false
  local regex = false
  local case_sensitive = false
  local whole_word = false
  local search_text = input

  local colon = input:find(":", 1, true)
  if colon then
    local prefix = vim.trim(input:sub(1, colon - 1)):lower()
    local rest = input:sub(colon + 1)

    if prefix ~= "" then
      local i = 1
      local ok_prefix = true
      while i <= #prefix do
        local two = prefix:sub(i, i + 1)
        local one = prefix:sub(i, i)
        if two == "re" then
          regex = true
          has_prefix = true
          i = i + 2
        elseif one == "c" then
          case_sensitive = true
          has_prefix = true
          i = i + 1
        elseif one == "w" then
          whole_word = true
          has_prefix = true
          i = i + 1
        elseif one == " " then
          i = i + 1
        else
          ok_prefix = false
          break
        end
      end

      if ok_prefix and has_prefix then
        search_text = rest
      end
    end
  end

  search_text = vim.trim(search_text)
  if search_text == "" then
    return nil
  end

  local case_flag = case_sensitive and "\\C" or "\\c"
  local pattern

  if regex then
    pattern = case_flag .. search_text
    if whole_word then
      pattern = case_flag .. "\\<" .. search_text .. "\\>"
    end
  else
    local escaped = vim.fn.escape(search_text, "/\\")
    if whole_word then
      pattern = case_flag .. "\\V\\<" .. escaped .. "\\>"
    else
      pattern = case_flag .. "\\V" .. escaped
    end
  end

  return {
    pattern = pattern,
  }
end

local function set_prefixed_search(input)
  local parsed = parse_search_query(input)
  if not parsed then
    return false
  end

  vim.fn.setreg("/", parsed.pattern)
  vim.fn.histadd("search", parsed.pattern)
  vim.cmd("set hlsearch")
  return true
end

keymaps.set("n", "/", function()
  local input = vim.fn.input("/ ")
  if not set_prefixed_search(input) then
    return
  end

  local pattern = vim.fn.getreg("/")
  if pattern == "" then
    vim.notify("No search pattern set", vim.log.levels.INFO, { title = "Search" })
    return
  end

  local ok, match_line = pcall(vim.fn.search, pattern, "sw")
  if not ok then
    vim.notify("Invalid search pattern", vim.log.levels.WARN, { title = "Search" })
    return
  end

  if not match_line or match_line == 0 then
    vim.notify("No matches found", vim.log.levels.INFO, { title = "Search" })
    return
  end

  pcall(vim.cmd, "normal! zv")
end, { desc = "Search (prefix flags before ':' e.g. re:, c:, w:, cw:, wcre:)" })

local function visual_search_set()
  local saved = vim.fn.getreg('"')
  local saved_type = vim.fn.getregtype('"')
  vim.cmd("normal! y")
  local text = vim.fn.getreg('"')
  vim.fn.setreg('"', saved, saved_type)
  set_exact_visual_search(text)
end

keymaps.set("v", "n", function()
  visual_search_set()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "n", false)
end, { desc = "Search selected text forward" })
keymaps.set("v", "/", function()
  visual_search_set()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "n", false)
end, { desc = "Search selected text" })
keymaps.set("v", "N", function()
  visual_search_set()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("N", true, false, true), "n", false)
end, { desc = "Search selected text backward" })



keymaps.set("n", "<leader>rv", function()
  return ":IncRename " .. vim.fn.expand("<cword>")
end, { desc = "Rename variable", expr = true })

keymaps.set("n", "<leader>se", function() Snacks.picker.diagnostics_buffer() end, { desc = "Buffer diagnostics" })
Snacks.toggle({
  name = "ESLint Auto-fix",
  get = function() return vim.g.eslint_autosave == nil or vim.g.eslint_autosave end,
  set = function(state) vim.g.eslint_autosave = state end,
}):map("<leader>cFe")
keymaps.set("n", "<C-b>", "<Nop>", opts)
keymaps.set("n", "<C-b>b", "<cmd>BookmarksMark<cr>", { desc = "Toggle bookmark" })
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
local function update_lazygit_theme(kind)
  local src
  if kind == "dark" or kind == "light" then
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
git:
  paging:
    colorArg: always
    pager: "delta --color-only --syntax-theme=none --paging=never --hunk-header-decoration-style=none"
]])
    wf:close()
  end
end

local function apply_theme_mode(mode)
  local background = mode == "light" and "light" or "dark"
  vim.o.background = background

  local schemes = background == "dark"
      and { "islands-dark", "solarized-osaka", "habamax" }
    or { "islands-light", "solarized-osaka", "morning", "habamax" }

  for _, scheme in ipairs(schemes) do
    vim.g._lualine_theme_hint = scheme:find("^islands") and ("islands-" .. background) or "auto"
    if pcall(vim.cmd.colorscheme, scheme) then
      vim.g.theme_mode = background
      save_theme(scheme)
      update_lazygit_theme(background)
      return
    end
  end

  vim.notify("No colorscheme available for " .. background .. " mode", vim.log.levels.ERROR, { title = "Theme" })
end

local function apply_catppuccin(flavour)
  local bg = (flavour == "latte") and "light" or "dark"
  vim.o.background = bg
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
  vim.g._lualine_theme_hint = "auto"
  vim.cmd.colorscheme(cs)
  vim.g.theme_mode = bg
  save_theme(cs)
  update_lazygit_theme(nil)
end

local function apply_islands_rose_pine(variant)
  local cs = "islands-rose-pine-" .. variant
  local bg = variant == "light" and "light" or "dark"
  vim.o.background = bg
  vim.g._lualine_theme_hint = "islands-" .. variant
  vim.cmd.colorscheme(cs)
  vim.g.theme_mode = bg
  save_theme(cs)
  update_lazygit_theme(bg)
end

keymaps.set("n", "<leader>ut", function()
  local items = {
    { label = "Default Dark Theme",        action = function() apply_theme_mode("dark") end },
    { label = "Default Light Theme",       action = function() apply_theme_mode("light") end },
    { label = "Catppuccin Mocha (dark)",   action = function() apply_catppuccin("mocha") end },
    { label = "Catppuccin Macchiato",      action = function() apply_catppuccin("macchiato") end },
    { label = "Catppuccin Frappé",         action = function() apply_catppuccin("frappe") end },
    { label = "Catppuccin Latte (light)",  action = function() apply_catppuccin("latte") end },
    { label = "Rose Pine (dark)",              action = function() apply_rose_pine("main") end },
    { label = "Rose Pine Moon (dark)",         action = function() apply_rose_pine("moon") end },
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
    return vim.diagnostic.config().virtual_text ~= false
  end,
  set = function(enabled)
    vim.diagnostic.config({ virtual_text = enabled })
  end,
}):map("<leader>ui")

Snacks.toggle({
  name = "Inlay Hints",
  get = function()
    return vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  end,
  set = function(enabled)
    vim.lsp.inlay_hint.enable(enabled, { bufnr = 0 })
  end,
}):map("<leader>up")

vim.keymap.set("n", "<leader>ue", function()
  require("neo-tree.command").execute({ toggle = true, reveal = true, dir = LazyVim.root() })
end, { desc = "Reveal file in tree" })

vim.keymap.set("n", "<leader>e", function()
  local cur_win = vim.api.nvim_get_current_win()
  local neotree_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
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

-- Language > Python keymaps

local function get_pyright_client()
  for _, name in ipairs({ "basedpyright", "pyright" }) do
    local clients = vim.lsp.get_clients({ bufnr = 0, name = name })
    if #clients > 0 then return clients[1], name end
  end
  return nil, nil
end

local function read_config_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function escape_lua_pattern(s)
  return s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function toml_get(content, section, key)
  local key_pat = escape_lua_pattern(key)
  local in_target = (section == nil)
  for line in content:gmatch("[^\r\n]+") do
    local hdr = line:match("^%[([^%]]+)%]")
    if hdr then
      in_target = (section ~= nil and hdr == section)
    elseif in_target then
      local sval = line:match("^%s*" .. key_pat .. "%s*=%s*\"([^\"]+)\"")
      if sval then return sval end
      local nval = line:match("^%s*" .. key_pat .. "%s*=%s*(%d+)")
      if nval then return tonumber(nval) end
    end
  end
  return nil
end

local function walk_ancestors(callback)
  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath == "" then return nil end
  local dir = vim.fn.fnamemodify(bufpath, ":h")
  local stop = vim.fn.getcwd()
  local checked_stop = false
  while dir do
    local result = callback(dir)
    if result then return result end
    if dir == stop then checked_stop = true; break end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  if not checked_stop then
    return callback(stop)
  end
  return nil
end

local function read_project_type_checking_mode(server_name)
  return walk_ancestors(function(dir)
    local content = read_config_file(dir .. "/pyrightconfig.json")
    if content then
      local mode = content:match('"typeCheckingMode"%s*:%s*"([^"]+)"')
      if mode then return mode end
    end
    content = read_config_file(dir .. "/pyproject.toml")
    if content then
      local section = server_name == "basedpyright" and "tool.basedpyright" or "tool.pyright"
      local mode = toml_get(content, section, "typeCheckingMode")
      if mode then return mode end
    end
  end) or "standard"
end

local function read_python_indent_config(dir)
  for _, name in ipairs({ "ruff.toml", ".ruff.toml" }) do
    local content = read_config_file(dir .. "/" .. name)
    if content then
      local val = toml_get(content, "format", "indent-width")
        or toml_get(content, nil, "indent-width")
      if val then return val end
    end
  end
  local content = read_config_file(dir .. "/pyproject.toml")
  if content then
    local val = toml_get(content, "tool.ruff.format", "indent-width")
      or toml_get(content, "tool.ruff", "indent-width")
    if val then return val end
  end
end

local function json_decode_safe(content)
  if not content then return nil end
  local ok, data = pcall(vim.json.decode, content)
  if ok and type(data) == "table" then return data end
  return nil
end

local function json_get(data, ...)
  local val = data
  for _, key in ipairs({ ... }) do
    if type(val) ~= "table" then return nil end
    val = val[key]
  end
  return (type(val) == "number") and val or nil
end

local function strip_json_comments(text)
  text = text:gsub("//[^\r\n]*", "")
  text = text:gsub("/%*.-%*/", "")
  return text
end

local function read_js_indent_config(dir)
  for _, name in ipairs({ "biome.json", "biome.jsonc" }) do
    local raw = read_config_file(dir .. "/" .. name)
    if raw then
      if name:find("jsonc$") then raw = strip_json_comments(raw) end
      local data = json_decode_safe(raw)
      if data then
        local val = json_get(data, "javascript", "formatter", "indentWidth")
          or json_get(data, "formatter", "indentWidth")
        if val then return val end
      end
    end
  end
  for _, name in ipairs({ ".prettierrc", ".prettierrc.json" }) do
    local raw = read_config_file(dir .. "/" .. name)
    if raw then
      local data = json_decode_safe(raw)
      if data then
        local val = json_get(data, "tabWidth")
        if val then return val end
      else
        local val = raw:match("tabWidth%s*:%s*(%d+)")
        if val then return tonumber(val) end
      end
    end
  end
  local raw = read_config_file(dir .. "/package.json")
  if raw then
    local data = json_decode_safe(raw)
    if data then
      local val = json_get(data, "prettier", "tabWidth")
      if val then return val end
    end
  end
end

local js_filetypes = {
  javascript = true, javascriptreact = true,
  typescript = true, typescriptreact = true,
  vue = true,
}

local auto_indent_filetypes = vim.tbl_extend("force", { python = true }, js_filetypes)

local function read_project_indent()
  local ft = vim.bo.filetype
  local reader
  if ft == "python" then
    reader = read_python_indent_config
  elseif js_filetypes[ft] then
    reader = read_js_indent_config
  end
  if reader then return walk_ancestors(reader) end
  return nil
end

local function detect_indent()
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(200, vim.api.nvim_buf_line_count(0)), false)
  local counts = {}
  local prev_indent = 0
  for _, line in ipairs(lines) do
    if line:match("%S") then
      local indent = #(line:match("^(%s*)") or "")
      local diff = math.abs(indent - prev_indent)
      if diff > 0 and diff <= 8 then
        counts[diff] = (counts[diff] or 0) + 1
      end
      prev_indent = indent
    end
  end
  local best, best_count = 2, 0
  for width, count in pairs(counts) do
    if count > best_count then
      best, best_count = width, count
    end
  end
  return best
end

keymaps.set("n", "<leader>Lpt", function()
  if vim.bo.filetype ~= "python" then
    vim.notify("Not a Python buffer", vim.log.levels.WARN, { title = "Python" })
    return
  end
  local client, name = get_pyright_client()
  if not client then
    vim.notify("No pyright/basedpyright attached", vim.log.levels.WARN, { title = "Python" })
    return
  end
  local modes = { "off", "basic", "standard", "strict" }
  if name == "basedpyright" then
    table.insert(modes, "recommended")
    table.insert(modes, "all")
  end
  local current = vim.g.pyright_type_checking_mode or read_project_type_checking_mode(name)
  local items = {}
  for _, m in ipairs(modes) do
    local marker = m == current and " \u{25cf}" or ""
    table.insert(items, { label = m .. marker, value = m })
  end
  vim.ui.select(items, {
    prompt = "Type checking mode (" .. name .. "):",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    vim.g.pyright_type_checking_mode = choice.value
    client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
      python = { analysis = { typeCheckingMode = choice.value } },
    })
    client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    vim.notify("typeCheckingMode = " .. choice.value, vim.log.levels.INFO, { title = name })
  end)
end, { desc = "Type check level" })

keymaps.set("n", "<leader>Lsi", function()
  local ft = vim.bo.filetype
  if not auto_indent_filetypes[ft] then
    vim.notify("Not a supported filetype: " .. ft, vim.log.levels.WARN, { title = "Indent" })
    return
  end
  local project_indent = read_project_indent()
  local current = vim.b.indent_width_override or project_indent
  local widths = { 1, 2, 3, 4 }
  local items = {}
  for _, w in ipairs(widths) do
    local marker = (current == w) and " \u{25cf}" or ""
    table.insert(items, { label = tostring(w) .. marker, value = w })
  end
  local auto_marker = (current == nil) and " \u{25cf}" or ""
  table.insert(items, { label = "auto" .. auto_marker, value = "auto" })
  vim.ui.select(items, {
    prompt = "Indentation width:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local width = choice.value
    if width == "auto" then
      width = detect_indent()
      vim.b.indent_width_override = nil
      vim.notify("Detected indent: " .. width, vim.log.levels.INFO, { title = "Indent" })
    else
      vim.b.indent_width_override = width
    end
    vim.bo.shiftwidth = width
    vim.bo.tabstop = width
    vim.bo.softtabstop = width
    vim.notify("Indentation = " .. width, vim.log.levels.INFO, { title = "Indent" })
  end)
end, { desc = "Indentation width" })

keymaps.set("n", "<leader>LI", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo.filetype
  local lines = {}

  lines[#lines + 1] = "file: " .. (file ~= "" and file or "(no file)")
  lines[#lines + 1] = "filetype: " .. (ft ~= "" and ft or "(none)")
  lines[#lines + 1] = ""

  lines[#lines + 1] = "attached clients:"
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    lines[#lines + 1] = "  (none)"
  else
    for _, client in ipairs(clients) do
      local root = client.root_dir
      if (not root or root == "") and type(client.config) == "table" then
        root = client.config.root_dir
      end
      lines[#lines + 1] = string.format("  %s -> %s", client.name, root or "(none)")
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "indentation:"
  local source = "default"
  local width = vim.bo.shiftwidth
  if vim.b.indent_width_override then
    source = "manual override"
    width = vim.b.indent_width_override
  elseif auto_indent_filetypes[ft] then
    local proj = read_project_indent()
    if proj then
      source = "project config"
      width = proj
    else
      local detected = detect_indent()
      source = "file detection"
      width = detected
    end
  end
  lines[#lines + 1] = string.format("  width: %d (%s)", width, source)
  lines[#lines + 1] = string.format("  shiftwidth=%d tabstop=%d softtabstop=%d",
    vim.bo.shiftwidth, vim.bo.tabstop, vim.bo.softtabstop)

  if ft == "python" then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "type checking:"
    local client, name = get_pyright_client()
    if client then
      local mode = vim.g.pyright_type_checking_mode or read_project_type_checking_mode(name)
      local mode_source = vim.g.pyright_type_checking_mode and "manual override" or "project/default"
      lines[#lines + 1] = string.format("  %s: %s (%s)", name, mode, mode_source)
    else
      lines[#lines + 1] = "  (no pyright/basedpyright attached)"
    end
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Language Info" })
end, { desc = "Language info" })

local function apply_auto_indent()
  if not auto_indent_filetypes[vim.bo.filetype] then return end
  if vim.b.indent_width_override then return end
  local width = read_project_indent() or detect_indent()
  vim.bo.shiftwidth = width
  vim.bo.tabstop = width
  vim.bo.softtabstop = width
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("AutoIndent", { clear = true }),
  pattern = { "python", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  callback = apply_auto_indent,
})
if auto_indent_filetypes[vim.bo.filetype] then apply_auto_indent() end

pcall(vim.keymap.del, "n", "<leader>L")

vim.keymap.set("n", "<leader>If", function()
  require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } })
end, { desc = "File diagnostics" })

vim.keymap.set("n", "<leader>Iw", function()
  require("trouble").toggle("diagnostics")
end, { desc = "Workspace diagnostics" })

vim.keymap.set("n", "<leader>Ef", function()
  require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } })
end, { desc = "File errors (LSP)" })

vim.keymap.set("n", "<leader>Ew", function()
  require("trouble").toggle({ mode = "diagnostics" })
end, { desc = "Workspace errors (LSP)" })

vim.keymap.set("n", "<leader>Ee", function()
  require("trouble").toggle({ mode = "diagnostics", filter = { source = "eslint" } })
end, { desc = "ESLint errors" })

vim.schedule(function()
  require("which-key").add({
    { "<leader>I", group = "Inspect" },
    { "<leader>L", group = "Language" },
    { "<leader>Lp", group = "Python" },
    { "<leader>Ls", group = "Shared" },
    { "<leader>E",  group = "Errors" },
  })
end)
