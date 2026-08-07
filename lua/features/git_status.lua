-- Async git counters for the statusline branch chip: commits ahead/behind the
-- upstream plus untracked/modified/deleted/conflicted file counts.
-- Runs `git` in the background so the statusline never blocks.
local M = {}

vim.g._git_ahead = vim.g._git_ahead or 0
vim.g._git_behind = vim.g._git_behind or 0
vim.g._git_untracked = vim.g._git_untracked or 0
vim.g._git_modified = vim.g._git_modified or 0
vim.g._git_deleted = vim.g._git_deleted or 0
vim.g._git_conflicted = vim.g._git_conflicted or 0

-- Count of commits ahead/behind upstream for the branch chip.
local function refresh_ahead_behind()
  vim.fn.jobstart({ "git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}" }, {
    cwd = vim.fn.getcwd(),
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and data[1] and data[1] ~= "" then
        local a, b = data[1]:match("(%d+)%s+(%d+)")
        vim.g._git_ahead = tonumber(a) or 0
        vim.g._git_behind = tonumber(b) or 0
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.g._git_ahead = 0
        vim.g._git_behind = 0
      end
    end,
  })
end

-- Tally of untracked/modified/deleted/conflicted files from git status.
local function refresh_status()
  vim.fn.jobstart({ "git", "status", "--porcelain" }, {
    cwd = vim.fn.getcwd(),
    stdout_buffered = true,
    on_stdout = function(_, data)
      if not data then return end
      local untracked, modified, deleted, conflicted = 0, 0, 0, 0
      for _, line in ipairs(data) do
        if line ~= "" then
          local x, y = line:sub(1, 1), line:sub(2, 2)
          if x == "?" then
            untracked = untracked + 1
          elseif x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
            conflicted = conflicted + 1
          else
            if y == "M" or x == "M" then modified = modified + 1 end
            if y == "D" or x == "D" then deleted = deleted + 1 end
          end
        end
      end
      vim.g._git_untracked = untracked
      vim.g._git_modified = modified
      vim.g._git_deleted = deleted
      vim.g._git_conflicted = conflicted
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.g._git_untracked = 0
        vim.g._git_modified = 0
        vim.g._git_deleted = 0
        vim.g._git_conflicted = 0
      end
    end,
  })
end

function M.refresh()
  refresh_ahead_behind()
  refresh_status()
end

-- Refresh when entering buffers, regaining focus, or after writes.
function M.setup()
  local grp = vim.api.nvim_create_augroup("lualine_git_ab", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, {
    group = grp,
    callback = M.refresh,
  })
  M.refresh()
end

return M
