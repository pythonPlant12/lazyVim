-- Path forms shared by the statusline, the tabs and the window bars.
local M = {}

-- The folder Neovim was opened in; a later :cd (lazygit's worktree switch)
-- does not move it.
local root = vim.env.PWD or vim.fn.getcwd()

-- path relative to the folder Neovim was opened in, else to the current
-- one, else from ~. A relative path stays as it is.
function M.relative(path)
  if not vim.startswith(path, "/") then
    return path
  end
  return vim.fs.relpath(root, path) or vim.fs.relpath(vim.fn.getcwd(), path) or vim.fn.fnamemodify(path, ":~")
end

-- The file name of path with its last n folders: `src/common/file.js`.
function M.tail(path, n)
  local parts = vim.split(path, "/", { trimempty = true })
  return table.concat(parts, "/", math.max(1, #parts - n))
end

-- The tab name of path among others: the file name, or with two or more
-- folders (as many as tell them apart) when another path has the same name.
function M.unique(path, others)
  path = M.relative(path)
  local rels = vim.tbl_map(M.relative, others)
  local function clash(n)
    return vim.iter(rels):any(function(o) return o ~= path and M.tail(o, n) == M.tail(path, n) end)
  end
  if not clash(0) then
    return M.tail(path, 0)
  end
  local n = 2
  while clash(n) and n < #vim.split(path, "/") do
    n = n + 1
  end
  return M.tail(path, n)
end

-- path in at most width cells; a longer one loses its start: `...common/file.js`.
function M.fit(path, width)
  if vim.api.nvim_strwidth(path) <= width then
    return path
  end
  if width <= 3 then
    return ""
  end
  local chars = vim.fn.strchars(path)
  local keep = width - 3
  local tail = vim.fn.strcharpart(path, chars - keep)
  while vim.api.nvim_strwidth(tail) > keep do
    keep = keep - 1
    tail = vim.fn.strcharpart(path, chars - keep)
  end
  return "..." .. tail
end

return M
