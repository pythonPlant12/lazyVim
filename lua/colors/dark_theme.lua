local M = {}
local colors = {
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

function M.setup()
    vim.cmd('highlight clear')
    
    local highlights = {
        -- Editor
        Normal = { fg = colors.fg, bg = colors.bg },
        LineNr = { fg = "#4b5059" },
        CursorLine = { bg = colors.selection_bg },
        CursorLineNr = { fg = "#a1a3ab" },
        Visual = { bg = "#373b39" },
        Search = { bg = "#2d543f" },
        IncSearch = { bg = "#114957" },
        
        -- Syntax
        Comment = { fg = colors.gray },
        String = { fg = colors.green },
        Number = { fg = colors.cyan },
        Function = { fg = colors.blue },
        Keyword = { fg = colors.orange },
        Type = { fg = colors.yellow },
        Constant = { fg = colors.purple },
        Special = { fg = colors.orange },
        Identifier = { fg = colors.white },
        Statement = { fg = colors.orange },
        PreProc = { fg = colors.orange },
        
        -- Class related
        ["@type"] = { fg = colors.yellow },           -- For class names in declarations
        ["@constructor"] = { fg = colors.yellow },    -- For constructor calls
        ["@type.builtin"] = { fg = colors.yellow },   -- For built-in classes
        ["@class"] = { fg = colors.yellow },          -- Class definitions
        ["@type.definition"] = { fg = colors.yellow }, -- Class definitions
        
        -- Variables
        ["@variable"] = { fg = colors.white },
        ["@variable.builtin"] = { fg = colors.white },
        ["@parameter"] = { fg = colors.light_purple },
        ["@field"] = { fg = colors.white },
        
        -- UI elements
        Pmenu = { fg = colors.fg, bg = "#2b2d30" },
        PmenuSel = { fg = colors.fg, bg = "#393b40" },
        VertSplit = { fg = "#393b40" },
        StatusLine = { fg = colors.fg, bg = "#2b2d30" },
        
        -- Git signs
        SignColumn = { bg = colors.bg },
        GitSignsAdd = { fg = "#549159" },
        GitSignsChange = { fg = "#375fad" },
        GitSignsDelete = { fg = "#868a91" },
    }

    for group, settings in pairs(highlights) do
        vim.api.nvim_set_hl(0, group, settings)
    end
end

return M
