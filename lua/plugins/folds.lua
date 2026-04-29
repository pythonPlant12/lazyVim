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
        if excluded_ft[filetype] then return "" end
        return { "treesitter", "indent" }
      end,
    },
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
  },
}
