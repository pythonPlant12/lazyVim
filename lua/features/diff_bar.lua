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

local function bar(path, branch, rev)
  local paths = require("utils.path_display")
  local text = ("%s %s | \u{F062C} %s | %s"):format(
    require("mini.icons").get("file", vim.fs.basename(path)), paths.tail(paths.relative(path), 2), branch, rev)
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
-- path is the file's name in that pane.
function M.show(rev_win, work_win, cwd, rev, work)
  local current, sha = head(cwd)
  local function text(side)
    local r = side.ref and "@" .. (vim.startswith(sha, side.ref) and "HEAD" or side.ref:gsub("^(%x%x%x%x%x%x%x)%x*", "%1")) or "working"
    return bar(side.path, side.ref and side.branch or current, r)
  end
  put(rev_win, text(rev))
  put(work_win, work and text(work))
  redraw()
end

-- Drop the bars of both panes; the split bar takes over again.
function M.clear(a, b)
  put(a, nil)
  put(b, nil)
  redraw()
end

return M
