local M = {}

function M.jump_to_lazygit()
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype == "snacks_terminal" then
        local meta = vim.b[buf].snacks_terminal
        local cmd = type(meta) == "table" and meta.cmd or nil
        local is_lazygit = (type(cmd) == "table" and cmd[1] == "lazygit")
          or (type(cmd) == "string" and cmd:find("lazygit", 1, true) ~= nil)

        if is_lazygit then
          vim.api.nvim_set_current_tabpage(tab)
          vim.api.nvim_set_current_win(win)
          return true
        end
      end
    end
  end

  return false
end

local function close_diff_tab()
  if #vim.api.nvim_list_tabpages() > 1 then
    vim.cmd("tabclose")
  else
    vim.cmd("diffoff!")
    vim.cmd("only")
  end
end

local function bind_q_in_tab()
  local tabpage = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
    local buf = vim.api.nvim_win_get_buf(win)
    vim.keymap.set("n", "q", close_diff_tab, { buffer = buf, silent = true })
  end
end

local function git_show(git_root, rev, relpath)
  local out = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(git_root)
    .. " show " .. vim.fn.shellescape(rev .. ":" .. relpath)
  )
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(out, "\n")
  end
  return out
end

local function git_root_for(path)
  local dir = vim.fn.fnamemodify(path, ":p:h")
  local result = vim.fn.systemlist("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel")
  if vim.v.shell_error ~= 0 then return nil end
  return result[1]
end

local function make_rev_buf(name, lines, ft)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype    = "nofile"
  vim.bo[buf].bufhidden  = "wipe"
  vim.bo[buf].swapfile   = false
  vim.bo[buf].modifiable = false
  if ft then vim.bo[buf].filetype = ft end
  return buf
end

function M.diff(path)
  if not path or path == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then return end

  vim.cmd("tabedit " .. vim.fn.fnameescape(abs))

  vim.defer_fn(function()
    require("gitsigns").diffthis()
    vim.defer_fn(bind_q_in_tab, 50)
  end, 50)
end

function M.diff_commit(path, hash)
  if not path or path == "" or not hash or hash == "" then return end

  local abs = vim.fn.fnamemodify(path, ":p")
  local root = git_root_for(abs)
  if not root then
    vim.notify("Not a git repo: " .. abs, vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end

  local relpath = abs:sub(#root + 2)
  local ft = vim.filetype.match({ filename = relpath })

  local before, err1 = git_show(root, hash .. "^", relpath)
  local after,  err2 = git_show(root, hash,         relpath)

  if not before then
    vim.notify("Cannot get " .. hash .. "^:" .. relpath .. "\n" .. (err1 or ""), vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end
  if not after then
    vim.notify("Cannot get " .. hash .. ":" .. relpath .. "\n" .. (err2 or ""), vim.log.levels.ERROR, { title = "Git Diff" })
    return
  end

  local short = hash:sub(1, 8)
  M._open_two_buf_diff(short .. "^:" .. relpath, before, short .. ":" .. relpath, after, ft)
end

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

return M
