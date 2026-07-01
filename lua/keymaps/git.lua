local keymaps = vim.keymap
local opts = { noremap = true, silent = true }
local lazygit_edit = require("git.lazygit_edit")

-- Git (<C-g>)
keymaps.set("n", "<C-g>g", function()
  if lazygit_edit.jump_to_lazygit() then
    return
  end

  Snacks.lazygit({ cwd = LazyVim.root.git() })
end, { desc = "Lazygit" })
keymaps.set("n", "<C-g>l",  "<Nop>", opts)
keymaps.set("n", "<C-g>h",  function() Snacks.picker.git_log({ cwd = LazyVim.root.git() }) end, { desc = "Git history" })
keymaps.set("n", "<C-g>s",  function() Snacks.picker.git_status() end, { desc = "Git status" })
keymaps.set("n", "<C-g>d",  function() Snacks.picker.git_diff() end, { desc = "Git diff" })
keymaps.set("n", "<C-g>ld", function() require("gitsigns").preview_hunk_inline() end, { desc = "Line diff" })
keymaps.set("n", "<C-g>lh", function() Snacks.picker.git_log_line() end, { desc = "Line history" })
keymaps.set("n", "<C-g>lr", function() require("gitsigns").reset_hunk() end, { desc = "Revert line/hunk to HEAD" })
local function git_root_or_cwd()
  local ok, root = pcall(function() return LazyVim.root.git() end)
  return (ok and root and root ~= "") and root or vim.fn.getcwd()
end

local function current_file_git_root()
  local path = vim.api.nvim_buf_get_name(0)
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

local function current_branch(cwd)
  local lines = git_lines({ "rev-parse", "--abbrev-ref", "HEAD" }, cwd)
  if type(lines) == "table" and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
  return "HEAD"
end

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

local function list_commits(ref, limit, cwd)
  local lines, err = git_lines({ "log", ref, "--pretty=format:%h\t%s", ("--max-count=%d"):format(limit or 150) }, cwd)
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

local function pick_line_diff_base_and_preview()
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

    local commits, commits_err = list_commits(branch_item.ref, 150, cwd)
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

local function open_file_diff_fullscreen(base)
  local orig_win = vim.api.nvim_get_current_win()
  require("gitsigns").diffthis(base)

  vim.defer_fn(function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      vim.keymap.set("n", "q", function()
        vim.cmd("diffoff!")
        vim.api.nvim_set_current_win(orig_win)
        vim.cmd("only")
      end, { buffer = buf, silent = true })
    end
  end, 50)
end

local function pick_diff_base_and_open()
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

    local commits, commits_err = list_commits(branch_item.ref, 150, cwd)
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

keymaps.set("n", "<C-g>fd", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  lazygit_edit.diff(path)
end, { desc = "File diff" })
keymaps.set("n", "<C-g>fD", pick_diff_base_and_open, { desc = "File diff against ref" })

local function pick_ref_and_restore_file()
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

    local commits, commits_err = list_commits(branch_item.ref, 150, cwd)
    if not commits then
      vim.notify("Could not list commits: " .. commits_err, vim.log.levels.ERROR, { title = "Git Restore" })
      return
    end
    if #commits == 0 then
      vim.notify("No commits found for " .. branch_item.ref, vim.log.levels.WARN, { title = "Git Restore" })
      return
    end

    vim.ui.select(commits, {
      prompt = "Select commit from " .. branch_item.ref .. ":",
      format_item = function(item) return item.label end,
    }, function(commit_item)
      if not commit_item then return end

      local filepath = vim.api.nvim_buf_get_name(0)
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
    end)
  end)
end

keymaps.set("n", "<C-g>fR", pick_ref_and_restore_file, { desc = "Restore file to ref" })

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
