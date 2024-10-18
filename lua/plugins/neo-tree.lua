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
  },
}
