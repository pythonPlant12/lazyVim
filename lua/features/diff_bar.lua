-- Top bars of a split diff: `<file icon> file | <branch icon> branch | @hash`
-- on the revision pane, `... | working` on the working file. A window keeps
-- its bar in w:diff_bar; autocmds/winbar.lua draws it in place of the split bar.
local M = {}

-- Current branch and full HEAD hash; a detached HEAD names its short hash.
local function head(cwd)
  local out = require("features.live_diff").git_lines({ "rev-parse", "HEAD", "--abbrev-ref", "HEAD" }, cwd) or {}
  local sha = out[1] or ""
  return out[2] ~= "HEAD" and out[2] or sha:sub(1, 7), sha
end

local function bar(path, branch, rev)
  local file = vim.fs.basename(path)
  local text = ("%s %s | \u{F062C} %s | %s"):format(require("mini.icons").get("file", file), file, branch, rev)
  return " " .. text:gsub("%%", "%%%%") .. " "
end

local function put(win, text)
  if win and vim.api.nvim_win_is_valid(win) then vim.w[win].diff_bar = text end
end

local function redraw() vim.api.nvim_exec_autocmds("User", { pattern = "DiffBar" }) end

-- Bars of a diff of path (cwd: its repository): the revision pane shows ref
-- (HEAD when it is HEAD) of branch (default: the current branch); the
-- working pane, if any, the current branch, or with work_ref that revision
-- of work_branch (a diff of two revisions).
function M.show(rev_win, work_win, path, cwd, ref, branch, work_ref, work_branch)
  local current, sha = head(cwd)
  local function rev(r) return "@" .. (vim.startswith(sha, r) and "HEAD" or r:gsub("^(%x%x%x%x%x%x%x)%x*", "%1")) end
  put(rev_win, bar(path, branch or current, rev(ref)))
  put(work_win, work_ref and bar(path, work_branch or current, rev(work_ref)) or bar(path, current, "working"))
  redraw()
end

-- Drop the bars of both panes; the split bar takes over again.
function M.clear(a, b)
  put(a, nil)
  put(b, nil)
  redraw()
end

return M
