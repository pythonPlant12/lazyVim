-- nvim-ufo: modern folding with Treesitter/indent providers and pretty fold previews.
-- Folds are useful in files, but noisy in plugin/tool windows.
local excluded_ft = {
  ["grug-far"]        = true,
  ["grug-far-history"] = true,
  ["grug-far-help"]   = true,
  ["lazy"]            = true,
  ["mason"]           = true,
  ["help"]            = true,
  ["noice"]           = true,
  ["Trouble"]         = true,
  ["dashboard"]       = true,
  ["neo-tree"]        = true,
}

return {
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    event = "BufReadPost",
    opts = {
      open_fold_hl_timeout = 0,
      provider_selector = function(_, filetype)
        -- Disable providers in UI buffers; use Treesitter first for real files.
        if excluded_ft[filetype] then return "" end
        return { "treesitter", "indent" }
      end,
    },
    init = function()
      -- Keep files fully expanded by default while preserving fold commands.
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
      -- No folds in a diff window: diff folds and ufo's function folds can
      -- both hide a change. diffoff brings the file's folds back.
      vim.api.nvim_create_autocmd("OptionSet", {
        group = vim.api.nvim_create_augroup("ufo_diff_folds", { clear = true }),
        pattern = "diff",
        callback = function()
          local win = vim.api.nvim_get_current_win()
          -- diffthis sets foldenable after diff.
          vim.schedule(function()
            if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
              vim.wo[win].foldenable = false
            end
          end)
        end,
      })
    end,
  },
}
