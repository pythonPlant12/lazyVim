-- Blame of every line as end-of-line text, in the look of the gitsigns
-- current-line blame. On per buffer; a closed buffer loses it.
local M = {}

local ns = vim.api.nvim_create_namespace("blame_all")
local uncommitted = { ["Not Committed Yet"] = true, ["External file (--contents)"] = true }

-- vim.b[buf].blame_all holds the git user name of the buffer's repository
-- while the blame is on: that author reads "You".
local function render(buf)
  local path = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- The buffer text goes in on stdin, so unsaved lines keep their place.
  vim.system({ "git", "blame", "--line-porcelain", "--contents", "-", "--", path }, {
    cwd = vim.fs.dirname(path),
    text = true,
    stdin = table.concat(lines, "\n") .. "\n",
  }, vim.schedule_wrap(function(res)
    local me = vim.api.nvim_buf_is_valid(buf) and vim.b[buf].blame_all
    if not me then return end
    if res.code ~= 0 then
      vim.notify(vim.trim(res.stderr or ""), vim.log.levels.ERROR, { title = "Git Blame" })
      return M.toggle(buf)
    end
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local relative_time = require("gitsigns.util").get_relative_time
    local row, info = 0, {}
    for _, line in ipairs(vim.split(res.stdout, "\n")) do
      local key, value = line:match("^(%S+) (.*)$")
      if line:sub(1, 1) == "\t" then
        local text = uncommitted[info.author] and "Not committed yet"
          or ("%s, %s - %s"):format(info.author == me and "You" or info.author, relative_time(tonumber(info["author-time"])), info.summary)
        vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
          virt_text = { { "   " .. text .. " ", "GitSignsCurrentLineBlame" } },
          virt_text_pos = "eol",
          hl_mode = "combine",
          priority = 100,
          strict = false,
        })
        row, info = row + 1, {}
      elseif key then
        info[key] = value
      end
    end
  end))
end

-- The gitsigns blame of the cursor line would repeat the text on that line.
local function sync_line_blame()
  local gitsigns = package.loaded.gitsigns
  if gitsigns then gitsigns.toggle_current_line_blame(not vim.b.blame_all) end
end

function M.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.b[buf].blame_all then
    vim.b[buf].blame_all = nil
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  else
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" or vim.bo[buf].buftype ~= "" then
      return vim.notify("No file in current buffer", vim.log.levels.ERROR, { title = "Git Blame" })
    end
    local name = vim.system({ "git", "config", "user.name" }, { cwd = vim.fs.dirname(path), text = true }):wait()
    vim.b[buf].blame_all = vim.trim(name.stdout or "")
    render(buf)
  end
  sync_line_blame()
end

local group = vim.api.nvim_create_augroup("blame_all", { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "BufWritePost" }, {
  group = group,
  callback = function(ev)
    if vim.b[ev.buf].blame_all then render(ev.buf) end
  end,
})
vim.api.nvim_create_autocmd("BufUnload", {
  group = group,
  callback = function(ev)
    if vim.b[ev.buf].blame_all then M.toggle(ev.buf) end
  end,
})
vim.api.nvim_create_autocmd("BufEnter", { group = group, callback = sync_line_blame })

return M
