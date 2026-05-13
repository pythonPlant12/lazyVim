---@diagnostic disable: undefined-global

local function current_git_root()
  local path = vim.api.nvim_buf_get_name(0)
  local start_dir = path ~= "" and vim.fn.fnamemodify(path, ":p:h") or vim.fn.getcwd()
  local root = vim.fn.systemlist({ "git", "-C", start_dir, "rev-parse", "--show-toplevel" })[1]

  if vim.v.shell_error ~= 0 or not root or root == "" then
    return nil
  end

  return vim.fs.normalize(vim.fn.fnamemodify(root, ":p"))
end

local function path_in_root(path, root)
  if type(path) ~= "string" or path == "" then
    return false
  end

  local normalized_path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  local root_prefix = root:sub(-1) == "/" and root or (root .. "/")

  return normalized_path == root or normalized_path:sub(1, #root_prefix) == root_prefix
end

local function delete_repo_bookmarks()
  local root = current_git_root()
  if not root then
    vim.notify("Not inside a git repository", vim.log.levels.WARN, { title = "Bookmarks" })
    return
  end

  local repo = require("bookmarks.domain.repo")
  local sign = require("bookmarks.sign")
  local tree = require("bookmarks.tree")

  local deleted = 0
  for _, bookmark in ipairs(repo.get_all_bookmarks()) do
    if bookmark.location and path_in_root(bookmark.location.path, root) then
      repo.delete_node(bookmark.id)
      deleted = deleted + 1
    end
  end

  sign.safe_refresh_signs()
  pcall(tree.refresh)

  local name = vim.fn.fnamemodify(root, ":t")
  local message = deleted == 1 and "Deleted 1 bookmark for " .. name
    or "Deleted " .. tostring(deleted) .. " bookmarks for " .. name
  vim.notify(message, vim.log.levels.INFO, { title = "Bookmarks" })
end

return {
  {
    "LintaoAmons/bookmarks.nvim",
    tag = "3.2.0",
    event = "VeryLazy",
    dependencies = {
      "kkharji/sqlite.lua",
      "nvim-telescope/telescope.nvim",
      "stevearc/dressing.nvim",
    },
    keys = {
      {
        "<C-b>d",
        function()
          local service = require("bookmarks.domain.service")
          local sign = require("bookmarks.sign")
          local tree = require("bookmarks.tree")

          local bookmark = service.find_bookmark_by_location()
          if not bookmark then
            vim.notify("No bookmark on current line", vim.log.levels.INFO, { title = "Bookmarks" })
            return
          end

          local ok, err = pcall(service.delete_node, bookmark.id)
          if not ok then
            vim.notify("Failed to delete bookmark: " .. tostring(err), vim.log.levels.ERROR, { title = "Bookmarks" })
            return
          end

          sign.safe_refresh_signs()
          pcall(tree.refresh)
          local title = (type(bookmark.name) == "string" and bookmark.name ~= "") and bookmark.name or "[Untitled]"
          vim.notify("Deleted bookmark: " .. title, vim.log.levels.INFO, {
            title = "Bookmarks",
          })
        end,
        desc = "Delete bookmark on line",
      },
      {
        "<C-b>D",
        delete_repo_bookmarks,
        desc = "Delete repository bookmarks",
      },
    },
    config = function()
      local function bookmark_title(bookmark)
        return (type(bookmark.name) == "string" and bookmark.name ~= "") and bookmark.name or "[Untitled]"
      end

      local function bookmark_entry_display(bookmark, bookmarks)
        local max_title = 20
        local max_file = 18
        local max_path = 24

        for _, bm in ipairs(bookmarks) do
          local title = bookmark_title(bm)
          local filename = vim.fn.fnamemodify(bm.location.path, ":t")
          local path = vim.fn.pathshorten(vim.fn.fnamemodify(bm.location.path, ":~:."))
          local line = tostring(bm.location.line)

          max_title = math.max(max_title, #title)
          max_file = math.max(max_file, #filename)
          max_path = math.max(max_path, #(path .. ":" .. line))
        end

        max_title = math.min(max_title, 28)
        max_file = math.min(max_file, 24)
        max_path = math.min(max_path, 44)

        local title = bookmark_title(bookmark)
        local filename = vim.fn.fnamemodify(bookmark.location.path, ":t")
        local path = vim.fn.pathshorten(vim.fn.fnamemodify(bookmark.location.path, ":~:."))
        local location = path .. ":" .. tostring(bookmark.location.line)

        local function fit(text, width)
          if #text > width then
            return text:sub(1, width - 2) .. ".."
          end
          return text .. string.rep(" ", width - #text)
        end

        return string.format(
          "%s │ %s │ %s",
          fit(title, max_title),
          fit(filename, max_file),
          fit(location, max_path)
        )
      end

      local is_light = vim.o.background == "light"
      require("bookmarks").setup({
        picker = {
          entry_display = bookmark_entry_display,
        },
        signs = {
          mark = {
            color = is_light and "#7B5EA7" or "#9D85C9",
            line_bg = is_light and "#EDE6F5" or "#2E2540",
          },
        },
      })
    end,
  },
}
