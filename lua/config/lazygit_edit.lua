local tab_reuse = require("config.tab_reuse")

local M = {}

function M.open(path, line)
  if not path or path == "" then
    return
  end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then
    return
  end

  if tab_reuse.jump_to_path(abs, { prefer_other_tabs = true }) then
    if line and tonumber(line) and tonumber(line) > 0 then
      local target = math.min(tonumber(line), vim.api.nvim_buf_line_count(0))
      vim.api.nvim_win_set_cursor(0, { math.max(target, 1), 0 })
      pcall(vim.cmd, "normal! zv")
    end
    return
  end

  local escaped = vim.fn.fnameescape(abs)
  if line and tonumber(line) and tonumber(line) > 0 then
    vim.cmd(("tabedit +%d %s"):format(tonumber(line), escaped))
  else
    vim.cmd("tabedit " .. escaped)
  end
end

return M
