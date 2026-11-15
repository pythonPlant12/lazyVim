-- Imported names get the LSP color of the same name elsewhere in the buffer.
-- Language servers (tsserver, vue_ls, ...) send no semantic tokens for import
-- specifiers, so `import { ref, Dialog }` would otherwise keep the plain
-- syntax color (blue `javaScript`/Special in .vue <script>).
local M = {}

local ns = vim.api.nvim_create_namespace("import_hl")
local kinds = {} -- buf -> { [name] = hl_group }
local pending = {}

local skip = {
  import = true, from = true, as = true, type = true, typeof = true, default = true,
}

-- Identifiers on the import statements of a buffer: { { row, col, name }, ... }.
local function import_names(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local out, open = {}, false
  for row, line in ipairs(lines) do
    local starts = line:match("^%s*import[%s{*]") or line:match("^%s*from%s+[%w_.]+%s+import%s")
    if starts or open then
      -- Blank out strings so module paths are never matched.
      local code = line:gsub("(['\"`])(.-)%1", function(q, s) return q .. (" "):rep(#s) .. q end)
      local head = code
      if starts and code:match("^%s*from%s") then
        head = code:gsub("^(%s*from%s+)([%w_.]+)", function(a, m) return a .. (" "):rep(#m) end)
      end
      local cut = head:find("%sfrom%s") -- JS: names end before `from '...'`
      local scan = cut and head:sub(1, cut) or head
      for col, name in scan:gmatch("()([%a_$][%w_$]*)") do
        if not skip[name] then out[#out + 1] = { row - 1, col - 1, name } end
      end
      -- Multi-line `import {` / `from x import (` blocks stay open until closed.
      if starts then
        open = (code:find("[{(]") ~= nil) and not code:find("[})]")
      elseif code:find("[})]") then
        open = false
      end
    end
  end
  return out
end

local function apply(buf)
  pending[buf] = nil
  if not vim.api.nvim_buf_is_valid(buf) then return end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local map = kinds[buf]
  if not map then return end
  for _, item in ipairs(import_names(buf)) do
    local group = map[item[3]]
    if group then
      vim.api.nvim_buf_set_extmark(buf, ns, item[1], item[2], {
        end_col = item[2] + #item[3],
        hl_group = group,
        priority = 126,
      })
    end
  end
end

local function schedule(buf)
  if pending[buf] then return end
  pending[buf] = true
  vim.defer_fn(function() apply(buf) end, 150)
end

-- Most specific group the theme defines for a token, e.g. @lsp.typemod.function.async.
local function token_group(token, ft)
  local defined = function(name)
    return next(vim.api.nvim_get_hl(0, { name = name, create = false })) ~= nil
  end
  local mods = vim.tbl_keys(token.modifiers or {})
  table.sort(mods)
  for _, mod in ipairs(mods) do
    local g = "@lsp.typemod." .. token.type .. "." .. mod
    if defined(g .. "." .. ft) then return g .. "." .. ft end
    if defined(g) then return g end
  end
  local g = "@lsp.type." .. token.type
  if defined(g .. "." .. ft) then return g .. "." .. ft end
  if defined(g) then return g end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ImportTokenHl", { clear = true })
  vim.api.nvim_create_autocmd("LspTokenUpdate", {
    group = group,
    callback = function(args)
      local token = args.data.token
      if token.line ~= token.end_line then return end
      local buf = args.buf
      local line = vim.api.nvim_buf_get_lines(buf, token.line, token.line + 1, false)[1] or ""
      local name = line:sub(token.start_col + 1, token.end_col)
      if name == "" then return end
      kinds[buf] = kinds[buf] or {}
      -- Keep the first color seen; declarations and uses agree on the type.
      if not kinds[buf][name] then
        kinds[buf][name] = token_group(token, vim.bo[buf].filetype)
      end
      schedule(buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = group,
    callback = function(args)
      if kinds[args.buf] then schedule(args.buf) end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    callback = function(args) kinds[args.buf] = nil end,
  })
  -- Re-pick colors after a theme change (group names stay, colors follow).
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      for buf in pairs(kinds) do schedule(buf) end
    end,
  })
end

return M
