return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
      follow_current_file = true,
      use_libuv_file_watcher = true,
      -- Change the path here
      root_dir = "./",
    },
    default_component_configs = {
      git_status = {
        symbols = {
          added = "",
          deleted = "󰧧",
          modified = "",
          renamed = "",
          -- Status type
          untracked = "",
          ignored = "",
          unstaged = "",
          staged = "",
          conflict = "",
        },
      },
    },
  },
  lazy = false,
}
