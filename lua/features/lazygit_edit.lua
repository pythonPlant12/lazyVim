-- LazyGit <-> Neovim integration: e/E in LazyGit open the file through the
-- entry point (open_file) in this tab or a new tab. Called by
-- scripts/lazygit-edit through nvim --remote. Also starts LazyGit (<C-g>g)
-- and shows a commit in it (L in a commit list).
local M = {}

-- LazyGit's own edit action, moved to <f12> (raw terminal bytes) by the
-- config below, so custom e/E can press it after they sent their message.
local EDIT_KEY = "\27[24~"

-- The commit, source and target from the last e/E, until LazyGit's edit
-- sends the path and line.
local pending

-- True if the buffer is a Snacks terminal running LazyGit.
local function is_lazygit_buf(buf)
  if vim.bo[buf].filetype ~= "snacks_terminal" then
    return false
  end

  local meta = vim.b[buf].snacks_terminal
  local cmd = type(meta) == "table" and meta.cmd or nil
  return (type(cmd) == "table" and cmd[1] == "lazygit")
    or (type(cmd) == "string" and cmd:find("lazygit", 1, true) ~= nil)
end

-- First message of e/E (args: commit, source, new_tab, folder): keep them, then
-- press LazyGit's edit (M.edit). The on-screen "Diff files (<hash>|stash@{N}"
-- title wins over SelectedCommit, which is wrong for a stash or in the patch view.
function M.expect(args)
  pending = nil
  if args.folder then
    return vim.notify("e/E open files, not folders", vim.log.levels.INFO, { title = "Lazygit" })
  end
  -- The focused LazyGit first: the key goes to the one that sent e/E.
  for _, buf in ipairs({ vim.api.nvim_get_current_buf(), unpack(vim.api.nvim_list_bufs()) }) do
    if is_lazygit_buf(buf) and vim.bo[buf].channel > 0 then
      local title = args.commit and table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):match("─Diff files %(([^%s:)]+)")
      pending = {
        commit = title or args.commit,
        source = (title or ""):match("^stash@") and "stash" or args.source,
        new_tab = args.new_tab ~= nil,
        at = vim.uv.now(),
      }
      return vim.api.nvim_chan_send(vim.bo[buf].channel, EDIT_KEY)
    end
  end
end

-- A file only this Neovim writes: a shared cache file lets another instance
-- (or a test run) swap the paths under a running LazyGit, which reloads it.
local instance_dir = vim.fn.fnamemodify(vim.fn.tempname(), ":h")
function M.instance_file(name)
  return instance_dir .. "/" .. name
end

-- LazyGit config for e/E, in its own file after the user's config.yml (Snacks'
-- YAML cannot hold custom commands). LazyGit's edit adds <f12>; E replaces "edit hunk".
function M.configure_lazygit()
  local file = M.instance_file("lazygit-edit.yml")
  local files = vim.env.LG_CONFIG_FILE or ""
  if files:find(file, 1, true) then return end

  local expect = ("python3 %s --expect"):format(vim.fn.shellescape(vim.fn.stdpath("config") .. "/scripts/lazygit-edit"))
  local commands = {}
  for _, c in ipairs({
    { context = "files, staging, stagingSecondary", args = "{{if not .SelectedFile}} folder=1{{end}}" },
    -- SelectedCommit is the very SelectedReflogCommit object when the view
    -- was opened from the reflog.
    { context = "commitFiles, patchBuilding", args = " commit={{.SelectedCommit.Hash}}{{if eq .SelectedCommit .SelectedReflogCommit}} source=reflog{{end}}{{if not .SelectedCommitFile}} folder=1{{end}}" },
  }) do
    table.insert(commands, { key = "e", context = c.context, command = expect .. c.args, description = "Open in Neovim" })
    table.insert(commands, { key = "E", context = c.context, command = expect .. c.args .. " new_tab=1", description = "Open in a new Neovim tab" })
  end
  -- JSON is YAML.
  vim.fn.writefile({ vim.json.encode({
    keybinding = { universal = { edit = { "e", "<f12>" } }, main = { editSelectHunk = "<disabled>" } },
    customCommands = commands,
  }) }, file)

  -- Snacks adds the user's config.yml only when LG_CONFIG_FILE is empty.
  if files == "" then
    local user = vim.split(vim.fn.system({ "lazygit", "-cd" }), "\n")[1] .. "/config.yml"
    files = vim.uv.fs_stat(user) and user or ""
  end
  vim.env.LG_CONFIG_FILE = (files == "" and "" or files .. ",") .. file
end

-- Focus the LazyGit terminal window across any tab; false if not open.
function M.jump_to_lazygit()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if is_lazygit_buf(buf) then
        vim.api.nvim_set_current_tabpage(tab)
        vim.api.nvim_set_current_win(win)
        return true
      end
    end
  end

  return false
end

-- Lazygit writes its directory here on every worktree/repo switch and on
-- quit, so the next open can start in the worktree you switched to instead
-- of the main tree Neovim's root points at. The path is unique per Neovim
-- instance, so two editors on the same repository do not follow each other.
local lazygit_dir_file = vim.fn.tempname()

local function git_common_dir(dir)
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--path-format=absolute", "--git-common-dir" })
  return vim.v.shell_error == 0 and out[1] or nil
end

-- The last lazygit directory when it is a worktree of the same repository.
local function lazygit_cwd(root)
  local ok, lines = pcall(vim.fn.readfile, lazygit_dir_file)
  local last = ok and lines[1] or nil
  if not last or last == "" or vim.fn.isdirectory(last) ~= 1 or last == root then
    return root
  end
  local common = git_common_dir(last)
  if common and common == git_common_dir(root) then
    return last
  end
  return root
end

-- Listed file buffers (no terminals, pickers, or scratch buffers).
local function file_buffers()
  return vim.tbl_filter(function(buf)
    return vim.bo[buf].buflisted and vim.bo[buf].buftype == ""
  end, vim.api.nvim_list_bufs())
end

-- After lazygit closes: when it switched to another worktree of the same
-- repository, close every file buffer and move Neovim there, so nothing on
-- screen still belongs to the old worktree.
local function follow_lazygit_worktree()
  local cwd = vim.fn.getcwd()
  local target = lazygit_cwd(cwd)
  if target == cwd then
    return
  end

  local modified = vim.tbl_filter(function(buf) return vim.bo[buf].modified end, file_buffers())
  if #modified > 0 then
    local choice = vim.fn.confirm(
      ("%d buffer(s) have unsaved changes. Save all and switch to %s?"):format(#modified, vim.fn.fnamemodify(target, ":~")),
      "&Save and switch\n&Stay here",
      2
    )
    if choice ~= 1 then
      return
    end
    vim.cmd("wall")
  end

  for _, buf in ipairs(file_buffers()) do
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end

  vim.cmd.cd(vim.fn.fnameescape(target))
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      require("neo-tree.command").execute({ source = "filesystem", dir = target, action = "show" })
      break
    end
  end
  vim.notify("Switched to worktree " .. vim.fn.fnamemodify(target, ":~"), vim.log.levels.INFO, { title = "Lazygit" })
end

-- Start LazyGit (<C-g>g) with the config for e/E, in the last worktree it
-- switched to.
function M.open_lazygit()
  M.configure_lazygit()
  return Snacks.lazygit({
    cwd = lazygit_cwd(LazyVim.root.git()),
    env = { LAZYGIT_NEW_DIR_FILE = lazygit_dir_file },
    win = {
      on_close = function()
        vim.schedule(follow_lazygit_worktree)
      end,
    },
  })
end

-- Send keys to a terminal one by one, 150 ms apart: an <Esc> followed at
-- once by a key reads as Alt+key. A function in keys runs at its turn.
local function send_keys(chan, keys)
  local key = table.remove(keys, 1)
  if key then
    if type(key) == "function" then key() else vim.api.nvim_chan_send(chan, key) end
    vim.defer_fn(function() send_keys(chan, keys) end, 150)
  end
end

-- L in a commit list: LazyGit in a new tab (the running one, or a new one)
-- on its Commits panel, the commit selected by a search for its hash.
function M.show_commit(hash, cwd)
  vim.cmd.tabnew()
  local term = vim.iter(Snacks.terminal.list()):find(function(t) return is_lazygit_buf(t.buf) end)
  -- A new LazyGit draws its panels at once but loads them for a while; a
  -- selection made before that is lost.
  local settle = term and 0 or 1000
  if term then
    -- A window in another tab would stay there.
    if term:valid() then term:hide() end
    term:show():focus()
  else
    term = M.open_lazygit()
  end
  local buf = term.buf
  local function shows(text)
    return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find(text, 1, true) ~= nil
  end
  -- <Esc> leaves a sub-view, a popup or a search; 4 is the Commits panel,
  -- and [ goes from its Reflog tab back to Commits.
  local keys = { "\27", "\27", "\27", "4", function()
    if shows("─Reflog Entry") then vim.api.nvim_chan_send(vim.bo[buf].channel, "[") end
  end }
  if vim.system({ "git", "merge-base", "--is-ancestor", hash, "HEAD" }, { cwd = cwd }):wait().code == 0 then
    keys[#keys + 1] = "/" .. hash:sub(1, 7) .. "\r" -- LazyGit shows 8 hash characters
  else
    vim.notify(hash .. " is not on the current branch", vim.log.levels.INFO, { title = "Lazygit" })
  end
  local tries = 0
  local function start()
    if not shows("Commits") and tries < 50 then
      tries = tries + 1
      return vim.defer_fn(start, 100)
    end
    vim.defer_fn(function() send_keys(vim.bo[buf].channel, keys) end, settle)
  end
  start()
end

-- `<cmd> +line path` for an Ex edit command; nil without a path.
local function edit_cmd(cmd, path, line)
  if not path or path == "" then return end
  local escaped = vim.fn.fnameescape(vim.fn.fnamemodify(path, ":p"))
  line = tonumber(line)
  return line and line > 0 and ("%s +%d %s"):format(cmd, line, escaped) or ("%s %s"):format(cmd, escaped)
end

-- Open a file in a new tab, optionally at a line.
local function open_new_tab(path, line)
  local cmd = edit_cmd("tabedit", path, line)
  if cmd then vim.cmd(cmd) end
end

-- Same-tab opens reuse a real editing window and avoid terminal/float windows.
local function normal_window_in_current_tab()
  local function usable(win)
    if vim.api.nvim_win_get_config(win).relative ~= "" then return false end
    local buf = vim.api.nvim_win_get_buf(win)
    return vim.bo[buf].filetype ~= "snacks_terminal"
  end

  -- Prefer the current window so the file reopens exactly where it was launched from.
  local cur = vim.api.nvim_get_current_win()
  if usable(cur) then return cur end

  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if usable(win) then return win end
  end
end

-- The LazyGit window in the current tab, if focused.
local function current_lazygit_window()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  return is_lazygit_buf(buf) and win or nil
end

-- Close the LazyGit window after a short delay.
local function close_lazygit_window(win)
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end

  vim.defer_fn(function()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end, 50)
end

-- Run open() in a normal window of this tab, then close the LazyGit float.
-- Without one, the float closes first and open() runs in the window below it.
local function in_this_tab(open)
  local lazygit_win = current_lazygit_window()
  local target = normal_window_in_current_tab()
  if target then
    vim.api.nvim_set_current_win(target)
    open()
    close_lazygit_window(lazygit_win)
  else
    close_lazygit_window(lazygit_win)
    vim.defer_fn(open, 60)
  end
end

-- Open a file in this tab, optionally at a line, closing the LazyGit float.
local function open_this_tab(path, line)
  local cmd = edit_cmd("edit", path, line)
  if cmd then in_this_tab(function() vim.cmd(cmd) end) end
end

-- Show a revision file alone (its working file is gone) as a read-only
-- scratch buffer, in this tab or a new tab; q closes it (the tab for E).
-- on_show gets the window that shows it.
local function open_revision(abs, lines, line, new_tab, on_show)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = vim.filetype.match({ filename = abs, buf = buf }) or ""
  vim.keymap.set("n", "q", function()
    if new_tab and #vim.api.nvim_list_tabpages() > 1 then vim.cmd.tabclose() end
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, nowait = true })
  local function show()
    if new_tab then vim.cmd("tab sbuffer " .. buf) else vim.api.nvim_win_set_buf(0, buf) end
    pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line) or 1, 0 })
    on_show(vim.api.nvim_get_current_win())
  end
  if new_tab then show() else in_this_tab(show) end
  return buf
end

-- Entry point of lazygit's e/E: a revision diff, a diff against HEAD, the plain
-- file or the revision file alone. opts: path, line, commit, source, new_tab.
function M.open_file(opts)
  local abs = vim.fn.fnamemodify(opts.path, ":p")
  local live_diff = require("features.live_diff")
  local label = require("features.revision_label")
  local diff_bar = require("features.diff_bar")
  local cwd = live_diff.git_root(abs)
  local function rev_parse(rev) return (live_diff.git_lines({ "rev-parse", rev }, cwd) or {})[1] end
  local head = rev_parse("HEAD")
  local commit = opts.commit and rev_parse(opts.commit)
  -- Without a working file the revision file opens alone, even for HEAD (the
  -- Files panel, or the commit that deleted it).
  if (commit or head) and not vim.uv.fs_stat(abs) then
    return live_diff.show_revision(commit or head, vim.fs.relpath(cwd, abs), cwd, function(lines, shown)
      if not lines then
        return vim.notify(("%s did not exist at %s"):format(opts.path, opts.commit or "HEAD"), vim.log.levels.WARN)
      end
      local win
      local buf = open_revision(abs, lines, opts.line, opts.new_tab, function(w)
        win = w
        diff_bar.show(win, nil, cwd, { path = abs, ref = shown, branch = opts.source })
      end)
      local tab = vim.api.nvim_get_current_tabpage()
      label.set(tab, abs, shown, opts.source)
      -- The label and the bar go with the revision file.
      vim.api.nvim_create_autocmd("BufWinLeave", { buffer = buf, once = true, callback = function()
        label.set(tab)
        diff_bar.clear(win)
      end })
    end)
  end

  if commit == head then
    commit = nil
  end
  -- The source belongs to the commit lazygit gave, not to others in the list.
  local function source_of(ref)
    return commit and vim.startswith(commit, (ref:gsub("%^$", ""))) and opts.source or nil
  end

  if opts.new_tab then open_new_tab(abs, opts.line) else open_this_tab(abs, opts.line) end
  local tab = vim.api.nvim_get_current_tabpage()
  -- Untracked and unchanged files have nothing to diff against HEAD.
  if not commit and (not head or vim.system({ "git", "diff", "--quiet", "HEAD", "--", abs }, { cwd = cwd }):wait().code == 0) then
    return
  end
  live_diff.pick({
    -- Commits of the file reachable from HEAD or from the commit, HEAD first.
    items = live_diff.with_branch_head(live_diff.list_commits({ "HEAD", commit }, 150, cwd, abs) or {}, "HEAD", cwd),
    title = "Diff against commit",
    keep_diff = true,
    select = commit or head,
    focus_diff = true,
    line = tonumber(opts.line) or 1,
    esc_keeps_diff = true,
    -- No label for HEAD or a closed diff.
    on_ref = function(ref)
      if not ref or vim.startswith(head, ref) then return label.set(tab) end
      label.set(tab, abs, ref, source_of(ref))
    end,
    branch = source_of,
    on_quit = opts.new_tab and function()
      if vim.api.nvim_tabpage_is_valid(tab) and #vim.api.nvim_list_tabpages() > 1 then
        vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
      end
    end or nil,
  })
end

-- Second message: LazyGit's edit with the path and line. After a recent e/E
-- it opens through the entry point; otherwise (merge conflicts, the config
-- file) it opens the file in this tab as before.
function M.edit(path, line)
  local p = pending
  pending = nil
  if not p or vim.uv.now() - p.at > 5000 then
    return open_this_tab(path, line)
  end
  M.open_file({ path = path, line = line, commit = p.commit, source = p.source, new_tab = p.new_tab })
end

return M
