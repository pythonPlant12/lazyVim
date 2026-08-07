-- fzf-lua: Enter jumps to an already-visible file instead of opening a duplicate.
local picker_open = require("features.picker_open")

return {
  {
    "ibhagwan/fzf-lua",
    keys = picker_open.remove_gl_key,
    opts = {
      fzf_colors = true,
      actions = {
        files = {
          ["enter"] = picker_open.fzf_file_switch_or_edit,
        },
      },
      files = {
        formatter = { "path.filename_first", 2 },
      },
      grep = {
        formatter = { "path.filename_first", 2 },
      },
    },
  },
}
