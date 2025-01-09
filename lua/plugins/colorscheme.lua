return {
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {
      style = "night",
      styles = {
        -- Disable italics everywhere
        comments = {},
        keywords = {},
        functions = {},
        variables = {},
        sidebars = {},
        floats = {},
      },
      on_colors = function(colors)
        colors.bg = "#1e1f22"
        colors.fg = "#bcbec4"
      end,
      on_highlights = function(highlights, colors)
        local custom_colors = {
          bg = "#1e1f22",
          fg = "#bcbec4",
          gray = "#7a7e85",
          blue = "#56a8f5",
          purple = "#c77dbb",
          green = "#6aab73", 
          orange = "#cf8e6d",
          yellow = "#eeba6c",
          red = "#f75464",
          cyan = "#2aacb8",
          light_purple = "#c8b0fb",
          white = "#ffffff",
          comment_gray = "#5f826b",
        }

        -- Your previous highlights
        -- Editor
        highlights.Normal = { fg = custom_colors.fg, bg = custom_colors.bg }
        highlights.LineNr = { fg = "#4b5059" }
        highlights.CursorLineNr = { fg = "#a1a3ab" }
        highlights.Visual = { bg = "#373b39" }
        highlights.Search = { bg = "#2d543f" }
        
        -- Class related (your previous settings)
        highlights["@type"] = { fg = custom_colors.yellow }
        highlights["@constructor"] = { fg = custom_colors.yellow }
        highlights["@type.builtin"] = { fg = custom_colors.yellow }
        highlights["@class"] = { fg = custom_colors.yellow }
        highlights["@type.definition"] = { fg = custom_colors.yellow }
        
        -- Variables (your previous settings)
        highlights["@variable"] = { fg = custom_colors.white }
        highlights["@variable.builtin"] = { fg = custom_colors.white }
        highlights["@parameter"] = { fg = custom_colors.white }
        
        -- New additions for better language support
        highlights["@field"] = { fg = custom_colors.blue }
        highlights["@property"] = { fg = custom_colors.blue }
        highlights["@function"] = { fg = custom_colors.blue }
        highlights["@function.call"] = { fg = custom_colors.blue }
        highlights["@method"] = { fg = custom_colors.blue }
        highlights["@method.call"] = { fg = custom_colors.blue }
        highlights["@variable.member"] = { fg = custom_colors.blue }
        highlights["@property.definition"] = { fg = custom_colors.blue }
        highlights["@attribute"] = { fg = custom_colors.blue }
        highlights["@keyword.operator"] = { fg = custom_colors.orange }
        highlights["@punctuation.delimiter"] = { fg = custom_colors.fg }
        highlights["@punctuation.bracket"] = { fg = custom_colors.fg }
        highlights["@constant"] = { fg = custom_colors.purple }
        highlights["@constant.builtin"] = { fg = custom_colors.purple }
        highlights["@string"] = { fg = custom_colors.green }
        highlights["@number"] = { fg = custom_colors.cyan }
        highlights["@boolean"] = { fg = custom_colors.purple }
        highlights["@operator"] = { fg = custom_colors.orange }

        -- Keep your existing UI elements
        highlights.Pmenu = { fg = custom_colors.fg, bg = "#2b2d30" }
        highlights.PmenuSel = { fg = custom_colors.fg, bg = "#393b40" }
        highlights.VertSplit = { fg = "#393b40" }
        highlights.StatusLine = { fg = custom_colors.fg, bg = "#2b2d30" }
        
        -- Git signs
        highlights.SignColumn = { bg = custom_colors.bg }
        highlights.GitSignsAdd = { fg = "#549159" }
        highlights.GitSignsChange = { fg = "#375fad" }
        highlights.GitSignsDelete = { fg = "#868a91" }
        highlights["@type"] = { fg = custom_colors.yellow, italic = false }
        highlights["@class"] = { fg = custom_colors.yellow, italic = false }
        highlights["@constructor"] = { fg = custom_colors.yellow, italic = false }
        highlights["@type.builtin"] = { fg = custom_colors.yellow, italic = false }
        highlights["@type.definition"] = { fg = custom_colors.yellow, italic = false }
        highlights["@type.identifier"] = { fg = custom_colors.yellow, italic = false }
        highlights["@class.typescript"] = { fg = custom_colors.yellow, italic = false }
        highlights["@class.tsx"] = { fg = custom_colors.yellow, italic = false }
        highlights["@type.typescript"] = { fg = custom_colors.yellow, italic = false }
        highlights["@type.tsx"] = { fg = custom_colors.yellow, italic = false }
        
        -- Explicitly remove italics from all relevant groups
        highlights["@variable"] = { fg = custom_colors.white, italic = false }
        highlights["@parameter"] = { fg = custom_colors.white, italic = false }
        highlights["@field"] = { fg = custom_colors.blue, italic = false }
        highlights["@property"] = { fg = custom_colors.blue, italic = false }
        highlights["@function"] = { fg = custom_colors.blue, italic = false }
        highlights["@function.call"] = { fg = custom_colors.blue, italic = false }
        highlights["@method"] = { fg = custom_colors.blue, italic = false }
        highlights["@method.call"] = { fg = custom_colors.blue, italic = false }
        highlights["@variable.member"] = { fg = custom_colors.blue, italic = false }
        highlights["@keyword"] = { fg = custom_colors.orange, italic = false }
        highlights["@constant"] = { fg = custom_colors.purple, italic = false }
        highlights["@constant.builtin"] = { fg = custom_colors.purple, italic = false }

        -- Additional TypeScript/React specific highlights
        highlights["@class.declaration"] = { fg = custom_colors.yellow, italic = false }
        highlights["@class.name"] = { fg = custom_colors.yellow, italic = false }
        highlights["@class.reference"] = { fg = custom_colors.yellow, italic = false }
      end,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  }
}
