-- Trouble: project-wide list of diagnostics/references with readable symbol icons.
return {
  {
    "folke/trouble.nvim",
    opts = {
      -- Inverted j/k to match this config's vertical navigation direction.
      keys = {
        j = "prev",
        k = "next",
      },
      win = {
        border = "rounded",
      },
      icons = {
        kinds = {
          Text          = "󰉿 ",
          Method        = "󰆧 ",
          Function      = "󰊕 ",
          Constructor   = "󰊓 ",
          Field         = "󰆧 ",
          Variable      = "󰆦 ",
          Class         = "󰠱 ",
          Interface     = "󰜰 ",
          Module        = "󰅩 ",
          Property      = "󰆧 ",
          Unit          = "󰑭 ",
          Value         = "󰎠 ",
          Enum          = "󰍜 ",
          Keyword       = "󰌋 ",
          Snippet       = "󰅧 ",
          Color         = "󰏘 ",
          File          = "󰈙 ",
          Reference     = "󰈇 ",
          Folder        = "󰉋 ",
          EnumMember    = "󰲣 ",
          Constant      = "󰏿 ",
          Struct        = "󰙅 ",
          Event         = "󰑧 ",
          Operator      = "󰆕 ",
          TypeParameter = "󰬛 ",
          Array         = " ",
          Boolean       = "󰨙 ",
          Key           = " ",
          Namespace     = "󰦮 ",
          Null          = " ",
          Number        = "󰎠 ",
          Object        = " ",
          Package       = " ",
          String        = " ",
        },
      },
    },
  },
}
