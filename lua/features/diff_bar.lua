-- Top bars of a split diff: `<file icon> dir/dir/file | <branch icon> branch | @hash`
-- on the revision pane, `... | working` on the working file. A window keeps
-- its bar in w:diff_bar; autocmds/winbar.lua draws it in place of the split bar.
local M = {}

-- Current branch and full HEAD hash; a detached HEAD names its short hash.
local function head(cwd)
  local out = require("features.live_diff").git_lines({ "rev-parse", "HEAD", "--abbrev-ref", "HEAD" }, cwd) or {}
  local sha = out[1] or ""
  return out[2] ~= "HEAD" and out[2] or sha:sub(1, 7), sha
end

-- from: the file's name in the other pane when it differs (a rename), shown
-- as `dir/dir/old -> new`; the new name keeps its folders after a move.
local function bar(path, branch, rev, from)
  local paths = require("utils.path_display")
  local name = paths.tail(paths.relative(path), 2)
  if from then
    local moved = vim.fs.dirname(from) ~= vim.fs.dirname(path)
    name = ("%s -> %s"):format(paths.tail(paths.relative(from), 2), moved and name or vim.fs.basename(path))
  end
  local text = ("%s %s | \u{F062C} %s | %s"):format(
    require("mini.icons").get("file", vim.fs.basename(path)), name, branch, rev)
  return " " .. text:gsub("%%", "%%%%") .. " "
end

local function put(win, text)
  if win and vim.api.nvim_win_is_valid(win) then vim.w[win].diff_bar = text end
end

local function redraw() vim.api.nvim_exec_autocmds("User", { pattern = "DiffBar" }) end

-- Bars of a diff (cwd: its repository). rev, the revision pane: { path, ref,
-- branch }, ref read as HEAD when it is HEAD, branch defaults to the current
-- one. work, the other pane if any: { path } for the working file of the
-- current branch, or another revision like rev (a diff of two revisions).
-- path is the file's name in that pane (full, or relative to cwd). After a
-- rename the other pane's bar reads `old -> new`.
function M.show(rev_win, work_win, cwd, rev, work)
  local current, sha = head(cwd)
  local function full(side) return vim.fs.normalize(vim.fs.joinpath(side.path:sub(1, 1) == "/" and "" or cwd, side.path)) end
  local function text(side, from)
    local r = side.ref and "@" .. (vim.startswith(sha, side.ref) and "HEAD" or side.ref:gsub("^(%x%x%x%x%x%x%x)%x*", "%1")) or "working"
    return bar(full(side), side.ref and side.branch or current, r, from and full(from) ~= full(side) and full(from) or nil)
  end
  put(rev_win, text(rev))
  put(work_win, work and text(work, rev))
  redraw()
end

-- Drop the bars of both panes; the split bar takes over again.
function M.clear(a, b)
  put(a, nil)
  put(b, nil)
  redraw()
end

return M
