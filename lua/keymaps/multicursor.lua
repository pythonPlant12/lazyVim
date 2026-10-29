-- Built-in multicursor (Neovim 0.13, :h multicursor) on the keys the old
-- multicursor.nvim setup used. Q itself is macro recording here (see
-- keymaps/editing.lua), so every map below reaches the built-in commands
-- through a noremap RHS ("Q", "zq", "q=", "]C" ...), never through Q directly.
local M = {}

local ns = vim.api.nvim_create_namespace("nvim.multicursor")

--- Number of extra cursors in buffer `buf` (default: current).
function M.count(buf)
  return #vim.api.nvim_buf_get_extmarks(buf or 0, ns, 0, -1, {})
end

function M.active(buf) return M.count(buf) > 0 end

--- Remove every extra cursor in buffer `buf` (default: current).
function M.clear(buf) vim.api.nvim_buf_clear_namespace(buf or 0, ns, 0, -1) end

-- Search pattern that matches the Visual selection literally.
local function selection_pattern()
  local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  return "\\V" .. table.concat(vim.tbl_map(function(l) return vim.fn.escape(l, "\\") end, lines), "\\n")
end

-- Search pattern for the word under the cursor, like "*".
local function word_pattern()
  return "\\<" .. vim.fn.escape(vim.fn.expand("<cword>"), "\\") .. "\\>"
end

-- Expr maps keep the built-ins cascade-aware (Lua/<Cmd> maps do not replay).
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { expr = type(rhs) == "function", desc = desc })
end

-- <C-n>: place a cursor on the current match and move to the next one.
-- First press in Normal mode searches the word under the cursor.
map("n", "<C-n>", function()
  if not M.active() then vim.fn.setreg("/", word_pattern()) end
  return "1Qn"
end, "MC: Add next match")
map("x", "<C-n>", function()
  vim.fn.setreg("/", selection_pattern())
  return "<Esc>`<1Qn"
end, "MC: Add next match of selection")
map("n", "<leader>ms", "n", "MC: Skip match (move without adding)")
map("n", "<leader>mS", "N", "MC: Skip match backwards")

map("n", "<M-Up>", "1Qk", "MC: Add cursor above")
map("n", "<M-Down>", "1Qj", "MC: Add cursor below")

map("n", "<leader>mA", "zq*", "MC: Add cursor at every match of word")
map("x", "<leader>mA", function()
  vim.fn.setreg("/", selection_pattern())
  return "<Esc>zqgn"
end, "MC: Add cursor at every match of selection")

map("n", "<C-q>", "Q", "MC: Toggle cursor here")
map("x", "<C-q>", "Q", "MC: Cursor on each selected line")
map("x", "<leader>ml", "Q", "MC: Cursor on each selected line")
-- An Insert command inside the mapping RHS ("QA") edits only the primary
-- cursor, so I/A are fed as typed keys after Q has placed the cursors.
local function then_typed(keys)
  return function()
    vim.schedule(function() vim.api.nvim_feedkeys(keys, "nt", false) end)
    return "Q"
  end
end
map("x", "<leader>mi", then_typed("I"), "MC: Insert at each line start")
map("x", "<leader>mI", then_typed("A"), "MC: Append at each line end")
map("n", "<leader>mx", "2Q", "MC: Remove cursor here")
map("n", "<leader>mr", "gQ", "MC: Restore previous cursors")
map("n", "<leader>mf", "q=", "MC: Toggle follow mode")

-- Alt-Left/Right move by word (keymaps/ui.lua) unless cursors exist; then they
-- jump between cursors.
map({ "n", "x" }, "<M-Left>", function() return M.active() and "[C" or "b" end, "MC: Previous cursor / word back")
map({ "n", "x" }, "<M-Right>", function() return M.active() and "]C" or "w" end, "MC: Next cursor / word forward")

-- Keep the MCursor highlight visible across colorschemes.
local function set_hl() vim.api.nvim_set_hl(0, "MCursor", { reverse = true, default = true }) end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { group = vim.api.nvim_create_augroup("user_multicursor_hl", {}), callback = set_hl })

return M
