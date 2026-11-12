-- Commit list with a live background diff, shared by <C-g>fD/<C-g>fR and the
-- lazygit edit feature, plus the helpers that build its items.
local M = {}

-- Return the git toplevel, falling back to cwd when not in a repo.
local function git_root_or_cwd()
  local ok, root = pcall(function() return LazyVim.root.git() end)
  return (ok and root and root ~= "") and root or vim.fn.getcwd()
end

-- Resolve from the file (default: current buffer) so nested repositories do
-- not fall back to cwd.
function M.git_root(path)
  path = path or vim.api.nvim_buf_get_name(0)
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
function M.git_lines(args, cwd)
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

-- "Nikita Petrov" -> "NP"; single-word names use their first two characters.
function M.author_initials(name)
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

-- Return recent commits for a ref (or a list of refs) as selectable items
-- (marking HEAD).
function M.list_commits(ref, limit, cwd, path)
  local function log(...)
    return vim.iter({ "log", ref, ("--max-count=%d"):format(limit or 150), ... }):flatten():totable()
  end
  local args = log("--pretty=format:%h\t%an\t%ad\t%s", "--date=format:%Y-%m-%d %H:%M")
  -- With a path only commits that touched that file are listed (following renames).
  -- --follow drops merge commits (a stash entry is one); -m keeps them, once per parent.
  local changed
  if path and path ~= "" then
    local base = cwd or git_root_or_cwd()
    local rel = (vim.fs.relpath and vim.fs.relpath(base, path)) or path
    vim.list_extend(args, { "-m", "--follow", "--", rel })
    -- A merge changed the file only against its first parent; the rest are
    -- dimmed. Stash entries stay enabled.
    changed = {}
    local first_parent = M.git_lines(log("--format=%h", "--diff-merges=first-parent", "--no-patch", "--follow", "--", rel), cwd) or {}
    for _, sha in ipairs(vim.list_extend(first_parent, M.git_lines({ "stash", "list", "--format=%h" }, cwd) or {})) do
      changed[sha] = true
    end
  end
  local lines, err = M.git_lines(args, cwd)
  if not lines then
    return nil, err
  end
  local items, seen = {}, {}
  for i, line in ipairs(lines) do
    local sha, author, date, subj = line:match("^([^\t]+)\t([^\t]*)\t([^\t]*)\t(.*)$")
    if sha and not seen[sha] then
      seen[sha] = true
      -- Path-filtered lists rarely start at HEAD, so the marker would lie.
      local head = (i == 1 and not path) and "HEAD" or "    "
      items[#items + 1] = {
        ref = sha,
        label = string.format("%s %-3s %s  %s  %s", head, M.author_initials(author), sha, date, subj or ""),
        dim = changed and not changed[sha] or nil,
      }
    end
  end
  return items, nil
end

-- Put the branch tip first, marked HEAD, so the branch itself is selectable
-- even when its last commit did not touch the file or line.
function M.with_branch_head(items, ref, cwd)
  local head = (M.list_commits(ref, 1, cwd) or {})[1]
  if not head then
    return items
  end
  -- Drop the tip wherever it is: a list of several refs may hold newer commits.
  items = vim.tbl_filter(function(it) return it.ref ~= head.ref end, items)
  table.insert(items, 1, head)
  return items
end

-- Fetch the file `rel` at `ref` in the background and call on_done(lines, shown)
-- on the main loop. A commit that deleted the file shows the version before
-- it: shown is then `ref^`. lines is nil when neither has the file.
function M.show_revision(ref, rel, cwd, on_done)
  local function show(shown)
    vim.system({ "git", "show", shown .. ":" .. rel }, { cwd = cwd, text = true }, vim.schedule_wrap(function(res)
      if res.code == 0 then
        on_done(vim.split((res.stdout or ""):gsub("\n$", ""), "\n", { plain = true }), shown)
      elseif shown == ref then
        show(ref .. "^")
      else
        on_done(nil, ref)
      end
    end))
  end
  show(ref)
end

-- Show changed chars inside a changed line in red on the old side and green
-- on the new side. A nil side clears the mapping.
function M.color_diff_side(win, side)
  vim.wo[win].winhighlight = side and ("DiffText:DiffText%s,DiffTextAdd:DiffText%s"):format(side, side) or ""
end

-- Commit picker with a live background diff: moving through the list diffs
-- the current buffer against the hovered commit without closing the list.
--   items       list_commits items ({ ref, label, dim }); dim rows are skipped
--   title       picker title
--   keep_diff   keep the diff open after <CR> (q closes it); otherwise the
--               preview closes and on_confirm handles the pick
--   on_confirm  called with the picked item after the picker closes
--   select      hash (full or short) of the commit to select at start
--   focus_diff  start with focus in the file and the list shrunk
--   line        cursor line in the file for the first diff (default: first hunk)
--   esc_keeps_diff  <Esc> closes only the list, like <CR> with keep_diff
--   on_quit     called after q closed the diff
--   on_ref      called with the ref each time the diff shows another commit
--               (`ref^` when that commit deleted the file), nil when it closes
--   live        false: no diff while moving, only on_confirm acts
function M.pick(picker_opts)
  local main_win = vim.api.nvim_get_current_win()
  local main_buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(main_buf)
  local cwd = M.git_root()
  local ft = vim.bo[main_buf].filetype
  -- The list belongs to this tab. Its windows stay here and show again on
  -- return; its window autocmds must not touch other tabs.
  local tab = vim.api.nvim_get_current_tabpage()
  local function in_tab() return vim.api.nvim_get_current_tabpage() == tab end

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
      if not in_tab() then
        return
      end
      -- The new window is current inside the event; also sweep on the next
      -- tick to catch windows created without entering (enter=false floats).
      strip_inherited(vim.api.nvim_get_current_win())
      vim.schedule(function()
        for _, w in ipairs(vim.api.nvim_tabpage_is_valid(tab) and vim.api.nvim_tabpage_list_wins(tab) or {}) do
          strip_inherited(w)
        end
      end)
    end,
  })

  local close_autocmd
  local function preview_close()
    -- Run once: a later WinClosed (e.g. on_quit closing the tab) would
    -- otherwise put the file into whatever window is current then.
    if preview.closed then
      return
    end
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
    if preview.list_autocmd then
      pcall(vim.api.nvim_del_autocmd, preview.list_autocmd)
      preview.list_autocmd = nil
    end
    pcall(vim.api.nvim_del_autocmd, close_autocmd)
    -- Tear down so the file window survives no matter which side was closed:
    -- if the file window is gone, the preview window becomes the file window.
    if preview.win and vim.api.nvim_win_is_valid(preview.win) then
      if vim.api.nvim_win_is_valid(main_win) then
        pcall(vim.api.nvim_win_close, preview.win, true)
      elseif vim.api.nvim_buf_is_valid(main_buf) then
        vim.api.nvim_win_set_buf(preview.win, main_buf)
        main_win = preview.win
      end
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
    if vim.api.nvim_win_is_valid(main_win) then
      M.color_diff_side(main_win, nil)
    end
    preview.win, preview.buf, preview.ref = nil, nil, nil
    pcall(vim.keymap.del, "n", "q", { buffer = main_buf })
    if picker_opts.on_ref then
      picker_opts.on_ref(nil)
    end
    -- Land back on the file.
    if vim.api.nvim_win_is_valid(main_win) then
      vim.api.nvim_set_current_win(main_win)
    elseif vim.api.nvim_buf_is_valid(main_buf) and vim.bo[vim.api.nvim_win_get_buf(0)].buftype ~= "prompt" then
      vim.api.nvim_win_set_buf(0, main_buf)
    end
  end

  -- Close the commit list and the diff. While the list is open this is a
  -- cancel that keeps the current position.
  local function close_diff()
    if preview.picker and not preview.picker.closed then
      if vim.api.nvim_win_is_valid(main_win) then
        orig_view = vim.api.nvim_win_call(main_win, vim.fn.winsaveview)
      end
      preview.picker:close()
    else
      preview_close()
    end
  end
  -- Closing either diff pane (:q, <C-w>q) closes the rest.
  close_autocmd = vim.api.nvim_create_autocmd("WinClosed", {
    callback = function(ev)
      local w = tonumber(ev.match)
      if w == main_win or (preview.win and w == preview.win) then
        vim.schedule(close_diff)
      end
    end,
  })

  -- q in either diff pane closes the commit list and the diff, like <C-g>fd.
  local function close_with_q()
    close_diff()
    if picker_opts.on_quit then
      vim.schedule(picker_opts.on_quit)
    end
  end

  local start_line = picker_opts.line
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
      for _, b in ipairs({ preview.buf, main_buf }) do
        vim.keymap.set("n", "q", close_with_q, { buffer = b, silent = true })
      end
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
      -- Replacing the preview lines opens all its folds, but the file pane
      -- keeps its closed folds and the panes lose alignment. Reset both.
      for _, w in ipairs({ preview.win, main_win }) do
        vim.api.nvim_win_call(w, function() vim.cmd("normal! zX") end)
      end
    end
    -- Land on the first hunk instead of the top of the file on every hover.
    -- The first diff lands on the caller's line instead, if given.
    vim.api.nvim_win_call(main_win, function()
      if start_line then
        vim.cmd(("normal! %dG"):format(start_line))
        start_line = nil
        return
      end
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
      M.show_revision(want, rel, cwd, function(lines, shown)
        if preview.want ~= want or preview.closed then
          return -- superseded by a newer hover or the picker closed
        end
        preview.ref = want
        apply_preview(lines or { "(file did not exist at " .. want .. ")" })
        if picker_opts.on_ref then
          picker_opts.on_ref(shown)
        end
      end)
    end))
  end

  local sitems = {}
  for i, it in ipairs(picker_opts.items) do
    sitems[#sitems + 1] = { idx = i, text = it.label, ref = it.ref, label = it.label, dim = it.dim }
  end

  -- Move to the next row in direction dir that is not dimmed; false if none.
  local function step(picker, dir)
    local list = picker.list
    for i = list.cursor + dir, dir > 0 and list:count() or 1, dir do
      if not list:get(i).dim then
        list:view(i)
        return true
      end
    end
    return false
  end

  local list_keys = {
    -- Previous/next tab, like the global normal-mode maps.
    ["<C-j>"] = { "tab_prev", mode = { "i", "n" } },
    ["<C-k>"] = { "tab_next", mode = { "i", "n" } },
  }
  for _, key in ipairs({ "<C-w>j", "<C-w><C-j>", "<C-w>k", "<C-w><C-k>" }) do
    list_keys[key] = { "focus_diff_file", mode = { "i", "n" } }
  end
  -- Leave the filter input first, or the other tab opens in insert mode.
  local function switch_tab(cmd)
    return function()
      vim.cmd.stopinsert()
      vim.schedule(vim.cmd[cmd])
    end
  end
  if picker_opts.esc_keeps_diff then
    list_keys["<Esc>"] = { "confirm", mode = "n" }
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
    enter = not picker_opts.focus_diff,
    -- Leaving the list upwards lands on the file (right pane). Without this
    -- nvim picks the window above by screen position, which is the preview.
    -- The list is the bottom window, so every vertical key goes up; this
    -- also covers the swapped <C-w>j/<C-w>k of keymaps/editing.lua.
    actions = {
      focus_diff_file = function()
        if vim.api.nvim_win_is_valid(main_win) then
          vim.api.nvim_set_current_win(main_win)
        end
      end,
      -- j/k and the arrows skip dimmed rows.
      list_down = function(picker) step(picker, 1) end,
      list_up = function(picker) step(picker, -1) end,
      tab_prev = switch_tab("tabprevious"),
      tab_next = switch_tab("tabnext"),
    },
    win = { list = { keys = list_keys }, input = { keys = list_keys } },
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
      return { { item.label, item.dim and "SnacksPickerDimmed" or nil } }
    end,
    -- Give the commit list its full height only while it has focus. Once focus
    -- moves to the diff windows it shrinks to a couple of rows, so the file
    -- gets the space back without losing the list.
    on_show = function(picker)
      preview.picker = picker
      local list_win = picker.list.win.win
      if not (list_win and vim.api.nvim_win_is_valid(list_win)) then
        return
      end
      local full_height = vim.api.nvim_win_get_height(list_win)
      local collapsed_height = 2

      local function picker_focused()
        local current = vim.api.nvim_get_current_win()
        for _, w in ipairs({ picker.input.win.win, picker.list.win.win, picker.preview.win.win }) do
          if w == current then
            return true
          end
        end
        return false
      end

      local function fit_list()
        if not vim.api.nvim_win_is_valid(list_win) then
          return
        end
        local target = picker_focused() and full_height or collapsed_height
        if vim.api.nvim_win_get_height(list_win) ~= target then
          pcall(vim.api.nvim_win_set_height, list_win, target)
        end
      end

      preview.list_autocmd = vim.api.nvim_create_autocmd("WinEnter", {
        callback = function()
          if in_tab() then vim.schedule(fit_list) end
        end,
      })
      -- A list opened without focus (focus_diff) shrinks at once.
      vim.schedule(fit_list)
      for i, it in ipairs(picker_opts.select and sitems or {}) do
        if vim.startswith(picker_opts.select, it.ref) or vim.startswith(it.ref, picker_opts.select) then
          picker.list:view(i)
          break
        end
      end
    end,
    on_change = function(picker, item)
      -- Any other way onto a dimmed row (start, mouse, gg) moves off it.
      if item and item.dim then
        return step(picker, 1) or step(picker, -1)
      end
      if item and picker_opts.live ~= false then
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
          -- Ensure the preview matches the picked commit; q still closes it.
          preview_show(item.ref)
        else
          preview_close()
        end
        if picker_opts.on_confirm then
          picker_opts.on_confirm({ ref = item.ref, label = item.label })
        end
      end)
    end,
    on_close = function()
      if confirmed then
        return
      end
      -- Snacks closes its split on the next tick; with splitkeep=screen that
      -- moves the file cursor, so restore the view one tick after it.
      vim.schedule(function()
        preview_close()
        vim.schedule(function()
          if vim.api.nvim_win_is_valid(main_win) then
            vim.api.nvim_win_call(main_win, function() vim.fn.winrestview(orig_view) end)
          end
        end)
      end)
    end,
  })
end

return M
