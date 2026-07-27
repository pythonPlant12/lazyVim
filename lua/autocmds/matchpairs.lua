-- Highlight the delimiter under the cursor together with its counterpart using
-- a distinct foreground + background. Brackets/parens/braces (and angle
-- brackets) are handled by the built-in matchparen plugin; quotes are matched
-- here because matchparen ignores them. Works for every filetype.

local group = vim.api.nvim_create_augroup("MatchPairsHighlight", { clear = true })

-- Let the built-in matchparen also pair angle brackets.
vim.opt.matchpairs:append("<:>")

-- Distinct highlights derived from the active theme so they always match it.
-- The foreground uses the theme's own accent color; the background is that
-- accent blended toward the editor background, giving a soft/opaque tint rather
-- than a harsh solid block. Re-applied on ColorScheme to survive theme switches.
local function hl_color(name, key)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if not ok then
    return nil
  end
  return hl[key]
end

-- Blend two 24-bit RGB colors; `alpha` is the weight of `fg` (0..1).
local function blend(fg, bg, alpha)
  local function chan(color, shift)
    return math.floor(color / shift) % 256
  end
  local r = chan(fg, 65536) * alpha + chan(bg, 65536) * (1 - alpha)
  local g = chan(fg, 256) * alpha + chan(bg, 256) * (1 - alpha)
  local b = chan(fg, 1) * alpha + chan(bg, 1) * (1 - alpha)
  return math.floor(r + 0.5) * 65536 + math.floor(g + 0.5) * 256 + math.floor(b + 0.5)
end

local function apply_highlights()
  -- Editor background (fall back sensibly for transparent themes).
  local bg = hl_color("Normal", "bg")
  if not bg then
    bg = vim.o.background == "light" and 0xffffff or 0x1a1b26
  end

  -- Theme accents: brackets follow punctuation/special, quotes follow strings.
  local bracket = hl_color("Special", "fg") or hl_color("Delimiter", "fg") or 0xe0af68
  local quote = hl_color("String", "fg") or 0x9ece6a

  -- ~0.4 keeps the tint soft yet clearly opaque against the background.
  local alpha = 0.4
  vim.api.nvim_set_hl(0, "MatchParen", { fg = bracket, bg = blend(bracket, bg, alpha), bold = true })
  vim.api.nvim_set_hl(0, "MatchQuote", { fg = quote, bg = blend(quote, bg, alpha), bold = true })
end

vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = apply_highlights })
apply_highlights()

-- Quote matching -----------------------------------------------------------
local ns = vim.api.nvim_create_namespace("MatchQuoteHighlight")
local quotes = { ['"'] = true, ["'"] = true, ["`"] = true }
local debounce -- pending timer from vim.defer_fn

local function clear()
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local function highlight_quote()
  clear()

  local col = vim.fn.col(".") - 1 -- 0-indexed cursor column
  local line = vim.api.nvim_get_current_line()
  local char = line:sub(col + 1, col + 1)
  if not quotes[char] then
    return
  end

  -- Collect unescaped occurrences of this quote char on the current line.
  local positions = {}
  for i = 1, #line do
    if line:sub(i, i) == char and (i == 1 or line:sub(i - 1, i - 1) ~= "\\") then
      positions[#positions + 1] = i - 1 -- 0-indexed
    end
  end

  -- Pair them sequentially; highlight the pair containing the cursor.
  local row = vim.fn.line(".") - 1
  for i = 1, #positions - 1, 2 do
    local open, close = positions[i], positions[i + 1]
    if col == open or col == close then
      vim.api.nvim_buf_set_extmark(0, ns, row, open, { end_col = open + 1, hl_group = "MatchQuote" })
      vim.api.nvim_buf_set_extmark(0, ns, row, close, { end_col = close + 1, hl_group = "MatchQuote" })
      return
    end
  end
end

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
  group = group,
  callback = function()
    clear()
    if debounce then
      debounce:stop()
    end
    debounce = vim.defer_fn(highlight_quote, 100)
  end,
})
vim.api.nvim_create_autocmd("BufLeave", { group = group, callback = clear })
