---@diagnostic disable: undefined-global

-- vim-matchup: highlights and jumps between matching words and tags
-- (<div>/</div>, if/end, function/return) in addition to brackets. It replaces
-- the built-in matchparen; brackets keep the MatchParen colors from
-- autocmds/matchpairs.lua.
return {
  {
    "andymass/vim-matchup",
    -- Not lazy-loaded: match-up loads little at startup and its README advises
    -- against event loading.
    lazy = false,
    init = function()
      -- No statusline/popup preview of an offscreen match.
      vim.g.matchup_matchparen_offscreen = {}
      -- No "◀ try" label after the closing bracket of a matched block.
      vim.g.matchup_treesitter_disable_virtual_text = true
      -- Highlight after a short pause, not on every cursor move.
      vim.g.matchup_matchparen_deferred = 1
    end,
    config = function()
      -- Matching words and tags: bold, in the active theme's blue, on the same
      -- gray background as the word-under-cursor matches (vim-illuminate).
      local function set_matchword_hl()
        local theme = vim.g.theme_custom_hl
        local blue = type(theme) == "table" and theme.name == vim.g.colors_name and theme.blue
        if not blue then
          local fn = vim.api.nvim_get_hl(0, { name = "Function", link = false }).fg
          blue = fn and string.format("#%06x", fn) or nil
        end
        local ref_bg = require("themes.engine.palette").get().ref_bg
          or (vim.o.background == "light" and "#E6E6E6" or "#3A3A4A")
        vim.api.nvim_set_hl(0, "MatchWord", { fg = blue, bg = ref_bg, bold = true })
        vim.api.nvim_set_hl(0, "MatchWordCur", { link = "MatchWord" })
      end

      set_matchword_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("MatchupWordHl", { clear = true }),
        callback = set_matchword_hl,
      })
    end,
  },
}
