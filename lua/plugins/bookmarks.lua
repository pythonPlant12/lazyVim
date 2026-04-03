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

        return string.format("%s │ %s │ %s", fit(title, max_title), fit(filename, max_file), fit(location, max_path))
      end

      require("bookmarks").setup({
        picker = {
          entry_display = bookmark_entry_display,
        },
      })
    end,
  },
}
