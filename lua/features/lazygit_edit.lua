-- LazyGit <-> Neovim integration: e/E in LazyGit open the file through the
-- entry point (open_file) in this tab or a new tab. Called by
-- scripts/lazygit-edit through nvim --remote.
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

-- LazyGit config for e/E inside Neovim. Snacks' YAML writer cannot hold a
-- list of custom commands, so they go to their own file, loaded after the
-- user's config.yml (its keys lose to these) and before Snacks' theme file.
-- LazyGit's edit keeps e where no custom e exists ("edit commit" in Commits)
-- and gets <f12>; "edit hunk" loses its key, E takes its place.
function M.configure_lazygit()
  local file = vim.fn.stdpath("cache") .. "/lazygit-edit.yml"
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

-- Second message: LazyGit's edit with the path and line. After a recent e/E
-- it opens through the entry point; otherwise (merge conflicts, the config
-- file) it opens the file in this tab as before.
function M.edit(path, line)
  local p = pending
  pending = nil
  if not p or vim.uv.now() - p.at > 5000 then
    return M.open_same_tab(path, line)
  end
  M.open_file({ path = path, line = line, commit = p.commit, source = p.source, new_tab = p.new_tab })
end

-- True if the current buffer is the LazyGit terminal.
function M.is_current_lazygit()
  return is_lazygit_buf(vim.api.nvim_get_current_buf())
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

-- Open a file in a new tab, optionally at a line.
function M.open(path, line)
  if not path or path == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then return end

  local escaped = vim.fn.fnameescape(abs)
  if line and tonumber(line) and tonumber(line) > 0 then
    vim.cmd(("tabedit +%d %s"):format(tonumber(line), escaped))
  else
    vim.cmd("tabedit " .. escaped)
  end
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

-- Clamp the cursor to a target column on the current line.
local function restore_cursor_col(col)
  if not col then return end
  local function restore()
    local ok_cursor, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
    if not ok_cursor then return end
    local line_len = #(vim.api.nvim_get_current_line() or "")
    pcall(vim.api.nvim_win_set_cursor, 0, { cursor[1], math.min(tonumber(col) or 0, line_len) })
  end

  restore()
  vim.schedule(restore)
end

-- Open a file in this tab, closing the LazyGit float.
function M.open_same_tab(path, line, col)
  if not path or path == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then return end

  local lazygit_win = current_lazygit_window()
  local target = normal_window_in_current_tab()

  local escaped = vim.fn.fnameescape(abs)
  local edit_cmd
  if line and tonumber(line) and tonumber(line) > 0 then
    edit_cmd = ("edit +%d %s"):format(tonumber(line), escaped)
  else
    edit_cmd = "edit " .. escaped
  end

  if target and vim.api.nvim_win_is_valid(target) then
    vim.api.nvim_set_current_win(target)
    vim.cmd(edit_cmd)
    restore_cursor_col(col)
  else
    close_lazygit_window(lazygit_win)
    vim.defer_fn(function()
      vim.cmd(edit_cmd)
      restore_cursor_col(col)
    end, 60)
    return
  end

  close_lazygit_window(lazygit_win)
end

-- Show a revision file alone (its working file is gone) as a read-only
-- scratch buffer, in this tab (closing the lazygit float) or a new tab.
local function open_revision(abs, lines, line, new_tab)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = vim.filetype.match({ filename = abs, buf = buf }) or ""
  local target = not new_tab and normal_window_in_current_tab()
  if target then
    close_lazygit_window(current_lazygit_window())
    vim.api.nvim_set_current_win(target)
    vim.api.nvim_win_set_buf(target, buf)
  else
    vim.cmd("tab sbuffer " .. buf)
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { tonumber(line) or 1, 0 })
end

-- The tab's label names the revision in the left pane: the tab line shows
-- `file @hash` and the statusline `hash (source)`. No ref drops the label.
local function set_label(tab, abs, ref, source)
  if not vim.api.nvim_tabpage_is_valid(tab) then return end
  vim.t[tab].revision = ref and { file = vim.fs.basename(abs), ref = ref:gsub("^(%x%x%x%x%x%x%x)%x*", "%1"), source = source } or nil
  vim.cmd.redrawtabline()
  local ok, lualine = pcall(require, "lualine")
  if ok then lualine.refresh({ place = { "statusline" } }) end
end

-- Entry point of lazygit's e/E. Opens the working file in this tab (closing
-- the lazygit float) or in a new tab. A file that differs from HEAD opens as
-- a diff against HEAD, with the file's commit list shrunk below it, HEAD
-- selected and the cursor in the working file. Another commit opens a
-- revision diff with that commit selected; when the working file is gone,
-- the revision file opens alone.
--   path     file to open
--   line     cursor line in the working file (default: top of the file)
--   commit   commit to compare against (default: HEAD)
--   source   branch, reflog or stash the commit came from (statusline label)
--   new_tab  open in a new tab; q then closes the tab
function M.open_file(opts)
  local abs = vim.fn.fnamemodify(opts.path, ":p")
  local live_diff = require("features.live_diff")
  local cwd = live_diff.git_root(abs)
  local head = (live_diff.git_lines({ "rev-parse", "HEAD" }, cwd) or {})[1]
  local commit = opts.commit and (live_diff.git_lines({ "rev-parse", opts.commit }, cwd) or {})[1]
  -- Without a working file even HEAD (e.g. the commit that deleted it) opens alone.
  if commit and not vim.uv.fs_stat(abs) then
    return live_diff.show_revision(commit, vim.fs.relpath(cwd, abs), cwd, function(lines, shown)
      if not lines then
        return vim.notify(("%s did not exist at %s"):format(opts.path, opts.commit), vim.log.levels.WARN)
      end
      open_revision(abs, lines, opts.line, opts.new_tab)
      local tab = vim.api.nvim_get_current_tabpage()
      set_label(tab, abs, shown, opts.source)
      -- The label goes with the revision file.
      vim.api.nvim_create_autocmd("BufWinLeave", { buffer = 0, once = true, callback = function() set_label(tab) end })
    end)
  end

  if commit == head then
    commit = nil
  end

  if opts.new_tab then M.open(abs, opts.line) else M.open_same_tab(abs, opts.line) end
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
    -- No label for HEAD or a closed diff. The source belongs to the commit
    -- lazygit gave, not to others in the list.
    on_ref = function(ref)
      if not ref or vim.startswith(head, ref) then return set_label(tab) end
      set_label(tab, abs, ref, commit and vim.startswith(commit, (ref:gsub("%^$", ""))) and opts.source or nil)
    end,
    on_quit = opts.new_tab and function()
      if vim.api.nvim_tabpage_is_valid(tab) and #vim.api.nvim_list_tabpages() > 1 then
        vim.cmd.tabclose(vim.api.nvim_tabpage_get_number(tab))
      end
    end or nil,
  })
end

return M
