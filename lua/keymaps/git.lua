-- Git keymaps under <C-g>: LazyGit, history/status/diff pickers, hunk actions,
-- and fullscreen file diffs (native gitsigns view, q to close).
local keymaps = vim.keymap
local opts = { noremap = true, silent = true }
local lazygit_edit = require("features.lazygit_edit")
local live_diff = require("features.live_diff")
local diff_bar = require("features.diff_bar")

-- Git (<C-g>): custom workflows around LazyGit, Snacks pickers, and gitsigns.
-- Guard bare <C-g> so it acts only as a prefix; without this, pausing after
-- <C-g> falls through to the native CTRL-G file-info ruler.
keymaps.set("n", "<C-g>", "<Nop>", opts)
keymaps.set("n", "<C-g>g", function()
  if not lazygit_edit.jump_to_lazygit() then
    lazygit_edit.open_lazygit()
  end
end, { desc = "Lazygit" })
-- A changed hunk in the inline preview keeps the red and green lines and
-- marks the changed chars in a slightly lighter red and green.
-- Added-only and deleted-only hunks keep the gitsigns colors.
local change_hunk_hl = table.concat({
  "GitSignsAddInline:LineDiffNewText",
  "GitSignsChangeInline:LineDiffNewText",
  "GitSignsDeleteVirtLnInLine:LineDiffOldText",
}, ",")

local function preview_line_diff()
  local win, buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  require("gitsigns").preview_hunk_inline(function()
    vim.schedule(function()
      local ns = vim.api.nvim_create_namespace("gitsigns_preview_inline")
      local has_old, has_new = false, false
      for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })) do
        has_old = has_old or mark[4].virt_lines ~= nil
        has_new = has_new or mark[4].hl_group == "GitSignsAddPreview"
      end
      if not (has_old and has_new and vim.api.nvim_win_is_valid(win)) then
        return
      end
      local prev_hl = vim.wo[win].winhighlight
      vim.wo[win].winhighlight = prev_hl == "" and change_hunk_hl or prev_hl .. "," .. change_hunk_hl
      -- gitsigns clears the preview on the same events.
      vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
        buffer = buf,
        once = true,
        callback = function()
          if vim.api.nvim_win_is_valid(win) then
            vim.wo[win].winhighlight = prev_hl
          end
        end,
      })
    end)
  end)
end

keymaps.set("n", "<C-g>l",  "<Nop>", opts) -- disable bare <C-g>l so it acts only as a prefix
keymaps.set("n", "<C-g>h",  function() Snacks.picker.git_log({ cwd = LazyVim.root.git() }) end, { desc = "Git history" })
keymaps.set("n", "<C-g>s",  function() Snacks.picker.git_status() end, { desc = "Git status" })
keymaps.set("n", "<C-g>d",  function() Snacks.picker.git_diff() end, { desc = "Git diff" })
keymaps.set("n", "<C-g>ld", preview_line_diff, { desc = "Line diff" })
keymaps.set("n", "<C-g>lh", function() Snacks.picker.git_log_line() end, { desc = "Line history" })
keymaps.set("n", "<C-g>lr", function() require("gitsigns").reset_hunk() end, { desc = "Revert line/hunk to HEAD" })
-- The file behind the current buffer.
local function current_real_file()
  return vim.api.nvim_buf_get_name(0)
end

-- Return the current branch name (or "HEAD" if detached/unknown).
local function current_branch(cwd)
  local lines = live_diff.git_lines({ "rev-parse", "--abbrev-ref", "HEAD" }, cwd)
  if type(lines) == "table" and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
  return "HEAD"
end

-- Keep the current branch first, then local refs, then remote refs.
local function list_branches(active_branch, cwd)
  local lines, err = live_diff.git_lines({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" }, cwd)
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

-- Map a buffer line to its line number in the gitsigns base (usually HEAD) by
-- undoing the line-count shifts of the hunks above it. Inside a changed block
-- the base block start is used.
local function buf_line_to_base(lnum)
  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    return lnum
  end
  local hunks = gs.get_hunks(0) or {}
  local delta = 0
  for _, h in ipairs(hunks) do
    local a, r = h.added, h.removed
    local a_end = a.start + math.max(a.count, 1) - 1
    if a.count > 0 and lnum >= a.start and lnum <= a_end then
      return math.max(r.start, 1)
    end
    if a_end < lnum then
      delta = delta + (a.count - r.count)
    end
  end
  return math.max(lnum - delta, 1)
end

-- Commits that changed one specific line (git log -L follows the line as it
-- moves through history). Each item carries the line's content as of that
-- commit (post-image of the -L hunk), used to restore it.
local function list_line_commits(path, lnum, cwd, ref)
  local rel = (vim.fs.relpath and vim.fs.relpath(cwd, path)) or path
  local cmd = { "git", "log", "--no-color", "--format=%x01%h%x09%an%x09%ad%x09%s", "--date=format:%Y-%m-%d %H:%M" }
  if ref then
    cmd[#cmd + 1] = ref
  end
  cmd[#cmd + 1] = ("-L%d,%d:%s"):format(lnum, lnum, rel)
  local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    local err = vim.trim(result.stderr or "")
    return nil, err ~= "" and err or "git log -L failed"
  end

  local items = {}
  local cur, in_hunk
  for _, line in ipairs(vim.split(result.stdout or "", "\n")) do
    local header = line:match("^\1(.*)$")
    if header then
      local sha, author, date, subj = header:match("^([^\t]+)\t([^\t]*)\t([^\t]*)\t(.*)$")
      if sha then
        cur = {
          ref = sha,
          label = string.format("     %-3s %s  %s  %s", live_diff.author_initials(author), sha, date, subj or ""),
          lines = {},
        }
        items[#items + 1] = cur
      end
      in_hunk = false
    elseif cur then
      if line:match("^@@") then
        in_hunk = true
      elseif line:match("^diff %-%-git") then
        in_hunk = false
      elseif in_hunk then
        local first = line:sub(1, 1)
        if first == "+" or first == " " then
          cur.lines[#cur.lines + 1] = line:sub(2)
        end
      end
    end
  end
  return items, nil
end

-- Pick a ref, set gitsigns' diff base, and preview the current hunk inline.
-- Only commits that changed the current line are offered.
local function pick_line_diff_base_and_preview()
  local path = current_real_file()
  if path == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  local base_lnum = buf_line_to_base(vim.api.nvim_win_get_cursor(0)[1])
  local cwd = live_diff.git_root()
  local active = current_branch(cwd)
  local branches, err = list_branches(active, cwd)
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

    local commits, commits_err = list_line_commits(path, base_lnum, cwd, branch_item.ref)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Diff" })
      return
    end
    commits = live_diff.with_branch_head(commits, branch_item.ref, cwd)
    if #commits == 0 then
      vim.notify("No commits changed this line on " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Diff" })
      return
    end

    -- The commit list of fD without the live diff; <CR> previews inline.
    live_diff.pick({
      items = commits,
      title = "Line diff against commit (" .. branch_item.ref .. ")",
      live = false,
      on_confirm = function(commit_item)
        local gs = require("gitsigns")
        local buf = vim.api.nvim_get_current_buf()
        gs.change_base(commit_item.ref, false)
        preview_line_diff()
        -- The changed base is only for this preview. The same events that
        -- dismiss the inline preview also restore the default base (index),
        -- so gutter signs and <C-g>fd don't keep diffing against the commit.
        vim.defer_fn(function()
          vim.api.nvim_create_autocmd({ "CursorMoved", "InsertEnter", "BufLeave" }, {
            buffer = buf,
            once = true,
            desc = "Restore gitsigns base after line diff preview",
            callback = function()
              vim.schedule(function()
                pcall(function() require("gitsigns").change_base(nil, false) end)
              end)
            end,
          })
        end, 150)
      end,
    })
  end)
end

keymaps.set("n", "<C-g>lD", pick_line_diff_base_and_preview, { desc = "Line diff against ref" })

-- Every diff view gets the side colors. A revision pane (gitsigns://, scratch)
-- is the old side; with only real files, the first pane is the old side.
local function color_diff_sides()
  local wins = vim.tbl_filter(function(w) return vim.wo[w].diff end, vim.api.nvim_tabpage_list_wins(0))
  local function is_revision(w)
    local buf = vim.api.nvim_win_get_buf(w)
    return vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf):find("://") ~= nil
  end
  local has_revision = vim.iter(wins):any(is_revision)
  for i, w in ipairs(wins) do
    local is_old = has_revision and is_revision(w) or (not has_revision and i == 1)
    live_diff.color_diff_side(w, is_old and "Old" or "New")
  end
end
vim.api.nvim_create_autocmd("DiffUpdated", {
  group = vim.api.nvim_create_augroup("diff_side_colors", { clear = true }),
  callback = color_diff_sides,
})
-- `nvim -d` (git difftool) diffs before this module loads.
color_diff_sides()

-- Native gitsigns diff; q closes only the diff (scratch pane + diff mode),
-- leaving every other split untouched. The right pane is the real buffer, so
-- closing the diff leaves the cursor exactly where it was.
local function open_file_diff_fullscreen(base)
  local orig_win = vim.api.nvim_get_current_win()
  local orig_buf = vim.api.nvim_get_current_buf()
  require("gitsigns").diffthis(base)

  vim.defer_fn(function()
    -- Only the two windows gitsigns put into diff mode take part.
    local diff_wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[win].diff then
        diff_wins[#diff_wins + 1] = win
      end
    end
    if #diff_wins == 0 then return end

    local function close_diff()
      for _, win in ipairs(diff_wins) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.api.nvim_buf_get_name(buf):match("^gitsigns://") then
            pcall(vim.api.nvim_win_close, win, true)
          else
            vim.api.nvim_win_call(win, function() vim.cmd("diffoff") end)
            live_diff.color_diff_side(win, nil)
          end
        end
      end
      diff_bar.clear(diff_wins[1], diff_wins[2])
      pcall(vim.keymap.del, "n", "q", { buffer = orig_buf })
      if vim.api.nvim_win_is_valid(orig_win) then
        vim.api.nvim_set_current_win(orig_win)
      end
    end

    for _, win in ipairs(diff_wins) do
      vim.keymap.set("n", "q", close_diff, { buffer = vim.api.nvim_win_get_buf(win), silent = true })
    end

    -- The gitsigns pane is named `gitsigns://<gitdir>//<base>:<path>`; the
    -- index base (`:0`) is HEAD.
    local gs_win = vim.iter(diff_wins):find(function(w) return vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w)):match("^gitsigns://") end)
    if gs_win then
      local path = vim.api.nvim_buf_get_name(orig_buf)
      local base = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(gs_win)):match("^gitsigns://.*//(:?[^:]*):")
      diff_bar.show(gs_win, orig_win, path, live_diff.git_root(path), base:find("^:") and "HEAD" or base)
    end

    -- If the scratch pane is closed by other means (:q, :close), still clean up.
    for _, win in ipairs(diff_wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_name(buf):match("^gitsigns://") then
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(win),
          once = true,
          callback = function() vim.schedule(close_diff) end,
        })
      end
    end
  end, 50)
end

-- Pick a branch then commit and open that ref's diff in fullscreen.
-- Only commits that touched the current file are offered.
local function pick_diff_base_and_open()
  local fpath = current_real_file()
  if fpath == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  local cwd = live_diff.git_root()
  local active = current_branch(cwd)
  local branches, err = list_branches(active, cwd)
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

    local commits, commits_err = live_diff.list_commits(branch_item.ref, 150, cwd, fpath)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Diff" })
      return
    end
    commits = live_diff.with_branch_head(commits, branch_item.ref, cwd)
    if #commits == 0 then
      vim.notify("No commits changed this file on " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Diff" })
      return
    end

    -- Hovering a commit shows the diff live in the background; <CR> keeps it
    -- open (q closes), <Esc> restores the previous layout.
    live_diff.pick({
      items = commits,
      title = "Diff against commit (" .. branch_item.ref .. ")",
      keep_diff = true,
      branch = branch_item.ref,
    })
  end)
end

keymaps.set("n", "<C-g>fd", function()
  local path = current_real_file()
  if path == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  -- Same native diff view as fD; respects the gitsigns base (<C-g>lD).
  open_file_diff_fullscreen()
end, { desc = "File diff" })
keymaps.set("n", "<C-g>fD", pick_diff_base_and_open, { desc = "File diff against ref" })

-- Restore only the current file from the selected commit/ref.
-- Only commits that touched the current file are offered.
local function pick_ref_and_restore_file()
  local fpath = current_real_file()
  if fpath == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Restore" })
    return
  end
  local cwd = live_diff.git_root()
  local active = current_branch(cwd)
  local branches, err = list_branches(active, cwd)
  if not branches then
    vim.notify("Could not list branches: " .. err, vim.log.levels.ERROR, { title = "Git Restore" })
    return
  end
  if #branches == 0 then
    vim.notify("No branches found", vim.log.levels.WARN, { title = "Git Restore" })
    return
  end

  vim.ui.select(branches, {
    prompt = "Select branch:",
    format_item = function(item) return item.label end,
  }, function(branch_item)
    if not branch_item then return end

    local commits, commits_err = live_diff.list_commits(branch_item.ref, 150, cwd, fpath)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Restore" })
      return
    end
    commits = live_diff.with_branch_head(commits, branch_item.ref, cwd)
    if #commits == 0 then
      vim.notify("No commits changed this file on " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Restore" })
      return
    end

    -- Hovering a commit previews the diff live; <CR> closes the preview and
    -- actually restores the file, <Esc> cancels without touching anything.
    live_diff.pick({
      items = commits,
      title = "Restore file from (" .. branch_item.ref .. ")",
      keep_diff = false,
      branch = branch_item.ref,
      on_confirm = function(commit_item)
        local filepath = current_real_file()
        if not filepath or filepath == "" then
          vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Restore" })
          return
        end

        local git_root = LazyVim.root.git()
        local lock = git_root .. "/.git/index.lock"
        if vim.uv.fs_stat(lock) then
          vim.uv.fs_unlink(lock)
        end
        local result = vim.system({ "git", "checkout", commit_item.ref, "--", filepath }, { cwd = git_root }):wait()
        if result.code ~= 0 then
          vim.notify("git checkout failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR, { title = "Git Restore" })
          return
        end

        vim.cmd("edit!")
        vim.notify("Restored to " .. commit_item.ref, vim.log.levels.INFO, { title = "Git Restore" })
      end,
    })
  end)
end

keymaps.set("n", "<C-g>fR", pick_ref_and_restore_file, { desc = "Restore file to ref" })

-- Pick from the commits that touched the current line and restore the line's
-- content from the chosen commit (buffer edit only; nothing is written).
local function pick_line_commit_and_restore()
  local path = current_real_file()
  if path == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Restore Line" })
    return
  end

  local buf_lnum = vim.api.nvim_win_get_cursor(0)[1]
  local base_lnum = buf_line_to_base(buf_lnum)
  local cwd = live_diff.git_root()

  local items, err = list_line_commits(path, base_lnum, cwd)
  if not items then
    vim.notify("Could not get line history: " .. err, vim.log.levels.ERROR, { title = "Git Restore Line" })
    return
  end
  if #items == 0 then
    vim.notify("No commits changed this line", vim.log.levels.WARN, { title = "Git Restore Line" })
    return
  end

  vim.ui.select(items, {
    prompt = ("Restore line %d from:"):format(buf_lnum),
    format_item = function(item) return item.label end,
  }, function(item)
    if not item then return end
    vim.api.nvim_buf_set_lines(0, buf_lnum - 1, buf_lnum, false, item.lines)
    local what = #item.lines == 1 and "line" or (#item.lines .. " lines")
    vim.notify(("Restored %s from %s"):format(what, item.ref), vim.log.levels.INFO, { title = "Git Restore Line" })
  end)
end

keymaps.set("n", "<C-g>lR", pick_line_commit_and_restore, { desc = "Restore line from commit" })

keymaps.set("n", "<C-g>fh", function() Snacks.picker.git_log_file() end, { desc = "File history" })
keymaps.set("n", "<C-g>fr", function() require("gitsigns").reset_buffer() end, { desc = "Revert file to HEAD" })

local ns_inline = vim.api.nvim_create_namespace("gitsigns_preview_inline")

-- n/N switch to hunk navigation only while a diff/inline preview is active.
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
