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

function M.open(path, line)
  if not path or path == "" then
    return
  end

  local abs = vim.fn.fnamemodify(path, ":p")
  if abs == "" then
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
