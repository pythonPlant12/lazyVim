vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("NeoTreeBookmarkToggle", { clear = true }),
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= "neo-tree" then return end
    vim.keymap.set("n", "<C-b>b", function()
      vim.notify("Bookmarks cannot be added from neo-tree", vim.log.levels.WARN, { title = "Bookmarks" })
    end, { buffer = ev.buf, desc = "Bookmark not available in neo-tree" })
  end,
})

local function bind_lazygit_tab_nav(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= "snacks_terminal" then
    return false
  end

  local meta = vim.b[buf].snacks_terminal
  if type(meta) ~= "table" then
    return false
  end

  local cmd = meta.cmd
  local is_lazygit = (type(cmd) == "table" and cmd[1] == "lazygit")
    or (type(cmd) == "string" and cmd:find("lazygit", 1, true) ~= nil)

  if not is_lazygit then
    return false
  end

  vim.keymap.set("t", "<C-j>", function()
    vim.cmd.stopinsert()
    vim.schedule(function() vim.cmd.tabprev() end)
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Previous tab from LazyGit",
  })
  vim.keymap.set("t", "<C-k>", function()
    vim.cmd.stopinsert()
    vim.schedule(function() vim.cmd.tabnext() end)
  end, {
    buffer = buf,
    nowait = true,
    silent = true,
    desc = "Next tab from LazyGit",
  })
  vim.keymap.set("n", "<C-j>", ":tabprev<CR>", {
    buffer = buf,
    silent = true,
    desc = "Previous tab from LazyGit",
  })
  vim.keymap.set("n", "<C-k>", ":tabnext<CR>", {
    buffer = buf,
    silent = true,
    desc = "Next tab from LazyGit",
  })

  return true
end

local function bind_lazygit_tab_nav_deferred(buf)
  if bind_lazygit_tab_nav(buf) then
    return
  end

  vim.defer_fn(function()
    if bind_lazygit_tab_nav(buf) then
      return
    end

    vim.defer_fn(function()
      bind_lazygit_tab_nav(buf)
    end, 150)
  end, 25)
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "TermOpen" }, {
  group = vim.api.nvim_create_augroup("LazyGitTerminalTabNav", { clear = true }),
  callback = function(ev)
    bind_lazygit_tab_nav_deferred(ev.buf)
  end,
})
