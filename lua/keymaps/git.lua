-- Git keymaps under <C-g>: LazyGit, history/status/diff pickers, hunk actions,
-- and fullscreen file diffs (native gitsigns view, q to close).
local keymaps = vim.keymap
local opts = { noremap = true, silent = true }
local lazygit_edit = require("features.lazygit_edit")

-- Git (<C-g>): custom workflows around LazyGit, Snacks pickers, and gitsigns.
-- Guard bare <C-g> so it acts only as a prefix; without this, pausing after
-- <C-g> falls through to the native CTRL-G file-info ruler.
keymaps.set("n", "<C-g>", "<Nop>", opts)
keymaps.set("n", "<C-g>g", function()
  if lazygit_edit.jump_to_lazygit() then
    return
  end

  Snacks.lazygit({ cwd = LazyVim.root.git() })
end, { desc = "Lazygit" })
keymaps.set("n", "<C-g>l",  "<Nop>", opts) -- disable bare <C-g>l so it acts only as a prefix
keymaps.set("n", "<C-g>h",  function() Snacks.picker.git_log({ cwd = LazyVim.root.git() }) end, { desc = "Git history" })
keymaps.set("n", "<C-g>s",  function() Snacks.picker.git_status() end, { desc = "Git status" })
keymaps.set("n", "<C-g>d",  function() Snacks.picker.git_diff() end, { desc = "Git diff" })
keymaps.set("n", "<C-g>ld", function() require("gitsigns").preview_hunk_inline() end, { desc = "Line diff" })
keymaps.set("n", "<C-g>lh", function() Snacks.picker.git_log_line() end, { desc = "Line history" })
keymaps.set("n", "<C-g>lr", function() require("gitsigns").reset_hunk() end, { desc = "Revert line/hunk to HEAD" })
-- Return the git toplevel, falling back to cwd when not in a repo.
local function git_root_or_cwd()
  local ok, root = pcall(function() return LazyVim.root.git() end)
  return (ok and root and root ~= "") and root or vim.fn.getcwd()
end

-- The file behind the current buffer.
local function current_real_file()
  return vim.api.nvim_buf_get_name(0)
end

-- Resolve from the current file so nested repositories do not fall back to cwd.
local function current_file_git_root()
  local path = current_real_file()
  if path == "" then
    return git_root_or_cwd()
  end
  local dir = vim.fn.fnamemodify(path, ":p:h")
  local result = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if result.code ~= 0 then
    return git_root_or_cwd()
  end
  local root = vim.trim(result.stdout or "")
  return root ~= "" and root or git_root_or_cwd()
end

-- Run a git command and return its stdout split into lines, or nil + error.
local function git_lines(args, cwd)
  local cmd = { "git" }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { cwd = cwd or git_root_or_cwd(), text = true }):wait()
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

-- Return the current branch name (or "HEAD" if detached/unknown).
local function current_branch(cwd)
  local lines = git_lines({ "rev-parse", "--abbrev-ref", "HEAD" }, cwd)
  if type(lines) == "table" and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
  return "HEAD"
end

-- Keep the current branch first, then local refs, then remote refs.
local function list_branches(active_branch, cwd)
  local lines, err = git_lines({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/remotes" }, cwd)
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

-- "Nikita Petrov" -> "NP"; single-word names use their first two characters.
local function author_initials(name)
  local words = {}
  for w in (name or ""):gmatch("%S+") do
    words[#words + 1] = w
  end
  if #words == 0 then
    return "??"
  end
  if #words == 1 then
    return vim.fn.strcharpart(words[1], 0, 2):upper()
  end
  return (vim.fn.strcharpart(words[1], 0, 1) .. vim.fn.strcharpart(words[#words], 0, 1)):upper()
end

-- Return recent commits for a ref as selectable items (marking HEAD).
local function list_commits(ref, limit, cwd, path)
  local args = { "log", ref, "--pretty=format:%h\t%an\t%s", ("--max-count=%d"):format(limit or 150) }
  -- With a path only commits that touched that file are listed (following renames).
  if path and path ~= "" then
    local base = cwd or git_root_or_cwd()
    local rel = (vim.fs.relpath and vim.fs.relpath(base, path)) or path
    vim.list_extend(args, { "--follow", "--", rel })
  end
  local lines, err = git_lines(args, cwd)
  if not lines then
    return nil, err
  end
  local items = {}
  for i, line in ipairs(lines) do
    local sha, author, subj = line:match("^([^\t]+)\t([^\t]*)\t(.*)$")
    if sha then
      -- Path-filtered lists rarely start at HEAD, so the marker would lie.
      local head = (i == 1 and not path) and "HEAD" or "    "
      items[#items + 1] = {
        ref = sha,
        label = string.format("%s %-3s %s  %s", head, author_initials(author), sha, subj or ""),
      }
    end
  end
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
  local cmd = { "git", "log", "--no-color", "--format=%x01%h%x09%an%x09%s" }
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
      local sha, author, subj = header:match("^([^\t]+)\t([^\t]*)\t(.*)$")
      if sha then
        cur = {
          ref = sha,
          label = string.format("%-3s %s  %s", author_initials(author), sha, subj or ""),
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
  local cwd = current_file_git_root()
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
    if #commits == 0 then
      vim.notify("No commits changed this line on " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Diff" })
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
          end
        end
      end
      pcall(vim.keymap.del, "n", "q", { buffer = orig_buf })
      if vim.api.nvim_win_is_valid(orig_win) then
        vim.api.nvim_set_current_win(orig_win)
      end
    end

    for _, win in ipairs(diff_wins) do
      vim.keymap.set("n", "q", close_diff, { buffer = vim.api.nvim_win_get_buf(win), silent = true })
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

-- Commit picker with a live background diff: moving through the list diffs
-- the current buffer against the hovered commit without closing the list.
--   items       list_commits items ({ ref, label })
--   title       picker title
--   keep_diff   keep the diff open after <CR> (q closes it); otherwise the
--               preview closes and on_confirm handles the pick
--   on_confirm  called with the picked item after the picker closes
local function pick_commit_with_live_diff(picker_opts)
  local main_win = vim.api.nvim_get_current_win()
  local main_buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(main_buf)
  local cwd = current_file_git_root()
  local ft = vim.bo[main_buf].filetype

  local preview = { win = nil, buf = nil, ref = nil }
  -- Debounce timer for the async preview fetch (see preview_show below).
  local show_timer = assert(vim.uv.new_timer())
  -- Original view of the file window, restored when the picker is cancelled.
  local orig_view = vim.api.nvim_win_call(main_win, vim.fn.winsaveview)

  -- Windows already in diff mode before the preview (unrelated diffs stay
  -- untouched by the close-time cleanup below).
  local preexisting_diff = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.wo[w].diff then
      preexisting_diff[w] = true
    end
  end

  -- New windows copy the current window's local options. Any window born
  -- while the diff binds are active (snacks list floats, neo-tree, splits)
  -- would inherit diff/scrollbind/cursorbind: the commit list then scrolls
  -- with the diff, and small buffers hit E19 via cursorbind. Strip the
  -- inherited options the moment such a window appears.
  local function strip_inherited(w)
    if not vim.api.nvim_win_is_valid(w) or w == main_win or w == preview.win or preexisting_diff[w] then
      return
    end
    if vim.wo[w].diff then
      vim.api.nvim_win_call(w, function() vim.cmd("diffoff") end)
    end
    if vim.wo[w].scrollbind then vim.wo[w].scrollbind = false end
    if vim.wo[w].cursorbind then vim.wo[w].cursorbind = false end
  end
  local winnew_autocmd = vim.api.nvim_create_autocmd("WinNew", {
    callback = function()
      -- The new window is current inside the event; also sweep on the next
      -- tick to catch windows created without entering (enter=false floats).
      strip_inherited(vim.api.nvim_get_current_win())
      vim.schedule(function()
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          strip_inherited(w)
        end
      end)
    end,
  })

  local function preview_close()
    preview.closed = true
    if show_timer and not show_timer:is_closing() then
      show_timer:stop()
      show_timer:close()
    end
    if winnew_autocmd then
      pcall(vim.api.nvim_del_autocmd, winnew_autocmd)
      winnew_autocmd = nil
    end
    if preview.scroll_autocmd then
      pcall(vim.api.nvim_del_autocmd, preview.scroll_autocmd)
      preview.scroll_autocmd = nil
    end
    if preview.win and vim.api.nvim_win_is_valid(preview.win) then
      pcall(vim.api.nvim_win_close, preview.win, true)
    end
    if preview.buf and vim.api.nvim_buf_is_valid(preview.buf) then
      pcall(vim.api.nvim_buf_delete, preview.buf, { force = true })
    end
    -- Splits made while the diff was active (neo-tree, vsplits...) inherit the
    -- window-local diff/scrollbind/cursorbind options. Turn diff mode off in
    -- every window our preview put (or leaked) it into, then drop stray binds.
    -- Diffs that existed before the preview opened are left alone.
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_is_valid(w) then
        if vim.wo[w].diff and not preexisting_diff[w] then
          vim.api.nvim_win_call(w, function() vim.cmd("diffoff") end)
        end
        if not vim.wo[w].diff then
          if vim.wo[w].scrollbind then vim.wo[w].scrollbind = false end
          if vim.wo[w].cursorbind then vim.wo[w].cursorbind = false end
        end
      end
    end
    preview.win, preview.buf, preview.ref = nil, nil, nil
    pcall(vim.keymap.del, "n", "q", { buffer = main_buf })
  end

  -- Put `lines` (the file at some ref) into the preview pane and refresh the diff.
  local function apply_preview(lines)
    if not (preview.buf and vim.api.nvim_buf_is_valid(preview.buf)) then
      preview.buf = vim.api.nvim_create_buf(false, true)
      vim.bo[preview.buf].buftype = "nofile"
      vim.bo[preview.buf].swapfile = false
      vim.bo[preview.buf].filetype = ft
    end
    vim.bo[preview.buf].modifiable = true
    vim.api.nvim_buf_set_lines(preview.buf, 0, -1, false, lines)
    vim.bo[preview.buf].modifiable = false
    if not (preview.win and vim.api.nvim_win_is_valid(preview.win)) then
      preview.win = vim.api.nvim_open_win(preview.buf, false, { split = "left", win = main_win })
      vim.api.nvim_win_call(preview.win, function() vim.cmd("diffthis") end)
      vim.api.nvim_win_call(main_win, function() vim.cmd("diffthis") end)
      -- Both panes scroll together, same as the plain <C-g>fd diff.
      for _, w in ipairs({ preview.win, main_win }) do
        vim.wo[w].scrollbind = true
        vim.wo[w].cursorbind = true
      end
      -- While the picker has focus, scrollbind doesn't act on mouse scrolls
      -- of the (unfocused) file pane; mirror them to the preview manually.
      preview.scroll_autocmd = vim.api.nvim_create_autocmd("WinScrolled", {
        pattern = tostring(main_win),
        callback = function()
          if vim.api.nvim_win_is_valid(main_win) and vim.api.nvim_get_current_win() ~= main_win then
            vim.api.nvim_win_call(main_win, function() vim.cmd("syncbind") end)
          end
        end,
      })
    else
      -- Content changed under an existing diff; recompute it.
      vim.api.nvim_win_call(main_win, function() vim.cmd("diffupdate") end)
    end
    -- Land on the first hunk instead of the top of the file on every hover.
    vim.api.nvim_win_call(main_win, function()
      vim.cmd("normal! gg")
      local first_main = vim.api.nvim_buf_get_lines(main_buf, 0, 1, false)[1]
      local first_prev = vim.api.nvim_buf_get_lines(preview.buf, 0, 1, false)[1]
      -- If line 1 already differs it IS the first hunk; ]c would skip past it.
      if first_main == first_prev then
        pcall(vim.cmd, "normal! ]c")
      end
    end)
  end

  -- Debounced async preview: a synchronous git show (:wait) pumps the event
  -- loop, so held-down j/k got processed re-entrantly mid-render and made the
  -- list cursor jump around. Fetch the hovered ref's content in the
  -- background and only apply the newest request.
  local function preview_show(ref)
    if ref == preview.ref or preview.closed then
      return
    end
    preview.want = ref
    show_timer:stop()
    show_timer:start(90, 0, vim.schedule_wrap(function()
      local want = preview.want
      if not want or want == preview.ref or preview.closed then
        return
      end
      local rel = (vim.fs.relpath and vim.fs.relpath(cwd, path)) or path
      vim.system(
        { "git", "show", want .. ":" .. rel },
        { cwd = cwd, text = true },
        vim.schedule_wrap(function(res)
          if preview.want ~= want or preview.closed then
            return -- superseded by a newer hover or the picker closed
          end
          local lines
          if res.code == 0 then
            lines = vim.split((res.stdout or ""):gsub("\n$", ""), "\n", { plain = true })
          else
            lines = { "(file did not exist at " .. want .. ")" }
          end
          preview.ref = want
          apply_preview(lines)
        end)
      )
    end))
  end

  local sitems = {}
  for i, it in ipairs(picker_opts.items) do
    sitems[#sitems + 1] = { idx = i, text = it.label, ref = it.ref, label = it.label }
  end

  local confirmed = false
  Snacks.picker.pick({
    title = picker_opts.title,
    items = sitems,
    -- Keep the list open while inspecting the diff windows; it closes only on
    -- q/<Esc> (cancel) or <CR> (confirm), never by losing focus.
    auto_close = false,
    -- Start focused on the list in normal mode (j/k navigate immediately);
    -- press i or / to reach the filter input.
    focus = "list",
    -- The global snacks config swaps j/k for its reversed pickers; this list
    -- is top-down, so restore natural direction here.
    win = {
      input = {
        keys = {
          ["j"] = { "list_down", mode = { "n" } },
          ["k"] = { "list_up", mode = { "n" } },
        },
      },
      list = {
        keys = {
          ["j"] = "list_down",
          ["k"] = "list_up",
        },
      },
    },
    -- Full-width strip as a real BOTTOM SPLIT (not a float), so it never
    -- covers the diff windows — the file stays fully visible above it.
    layout = {
      -- snacks reads cycle from the resolved layout: j/k stop at the
      -- first/last commit instead of wrapping around.
      cycle = false,
      layout = {
        box = "vertical",
        position = "bottom",
        backdrop = false,
        width = 0,
        height = 0.3,
        border = "top",
        title = " {title} ",
        title_pos = "left",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
    format = function(item)
      return { { item.label } }
    end,
    on_change = function(_, item)
      if item then
        vim.schedule(function() preview_show(item.ref) end)
      end
    end,
    confirm = function(picker, item)
      confirmed = true
      picker:close()
      vim.schedule(function()
        if not item then
          preview_close()
          if vim.api.nvim_win_is_valid(main_win) then
            vim.api.nvim_win_call(main_win, function() vim.fn.winrestview(orig_view) end)
          end
          return
        end
        if picker_opts.keep_diff then
          -- Ensure the preview matches the picked commit, then hand q the close.
          preview_show(item.ref)
          for _, b in ipairs({ main_buf, preview.buf }) do
            if b and vim.api.nvim_buf_is_valid(b) then
              vim.keymap.set("n", "q", preview_close, { buffer = b, silent = true })
            end
          end
          if preview.win then
            vim.api.nvim_create_autocmd("WinClosed", {
              pattern = tostring(preview.win),
              once = true,
              callback = function() vim.schedule(preview_close) end,
            })
          end
        else
          preview_close()
        end
        if picker_opts.on_confirm then
          picker_opts.on_confirm({ ref = item.ref, label = item.label })
        end
      end)
    end,
    on_close = function()
      vim.schedule(function()
        if not confirmed then
          preview_close()
          if vim.api.nvim_win_is_valid(main_win) then
            vim.api.nvim_win_call(main_win, function() vim.fn.winrestview(orig_view) end)
          end
        end
      end)
    end,
  })
end

-- Pick a branch then commit and open that ref's diff in fullscreen.
-- Only commits that touched the current file are offered.
local function pick_diff_base_and_open()
  local fpath = current_real_file()
  if fpath == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  local cwd = current_file_git_root()
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

    local commits, commits_err = list_commits(branch_item.ref, 150, cwd, fpath)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Diff" })
      return
    end
    if #commits == 0 then
      vim.notify("No commits changed this file on " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Diff" })
      return
    end

    -- Hovering a commit shows the diff live in the background; <CR> keeps it
    -- open (q closes), <Esc> restores the previous layout.
    pick_commit_with_live_diff({
      items = commits,
      title = "Diff against commit (" .. branch_item.ref .. ")",
      keep_diff = true,
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
  local cwd = current_file_git_root()
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

    local commits, commits_err = list_commits(branch_item.ref, 150, cwd, fpath)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Restore" })
      return
    end
    if #commits == 0 then
      vim.notify("No commits changed this file on " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Restore" })
      return
    end

    -- Hovering a commit previews the diff live; <CR> closes the preview and
    -- actually restores the file, <Esc> cancels without touching anything.
    pick_commit_with_live_diff({
      items = commits,
      title = "Restore file from (" .. branch_item.ref .. ")",
      keep_diff = false,
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
  local cwd = current_file_git_root()

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
