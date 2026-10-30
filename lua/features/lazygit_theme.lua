-- LazyGit colors from the Neovim highlights. Snacks uses `theme` for the LazyGit float, and
-- `write` puts the same colors in config.yml, so LazyGit in a terminal looks the same.
local M = {}

-- Snacks merges this over its default theme. It has every key that Snacks sets, so config.yml
-- gets all of them.
M.theme = {
  activeBorderColor          = { fg = "LazyGitActiveBorder", bold = true },
  searchingActiveBorderColor = { fg = "LazyGitActiveBorder", bold = true },
  cherryPickedCommitBgColor  = { fg = "Identifier" },
  cherryPickedCommitFgColor  = { fg = "Function" },
  defaultFgColor             = { fg = "Normal" },
  inactiveBorderColor        = { fg = "FloatBorder" },
  optionsTextColor           = { fg = "Function" },
  -- The Snacks default maps the active row to Visual; use the cursorline color.
  selectedLineBgColor        = { bg = "CursorLine" },
  unstagedChangesColor       = { fg = "DiagnosticError" },
}

-- Same conversion as Snacks: highlight group colors to a LazyGit color list.
local function colors(spec)
  local out = {}
  for _, key in ipairs({ "fg", "bg" }) do
    local hl = spec[key] and vim.api.nvim_get_hl(0, { name = spec[key], link = false })
    if hl and hl[key] then
      table.insert(out, ("#%06x"):format(hl[key]))
    end
  end
  if spec.bold then
    table.insert(out, "bold")
  end
  return out
end

-- Replace the `gui.theme` entries of a LazyGit config with the colors of `M.theme`.
-- Entries that `M.theme` does not set stay as they are in `base`.
local function with_theme(base)
  local keys, entries = vim.tbl_keys(M.theme), {}
  table.sort(keys)
  for _, key in ipairs(keys) do
    local values = colors(M.theme[key])
    if #values > 0 then
      table.insert(entries, ("    %s:"):format(key))
      for _, value in ipairs(values) do
        table.insert(entries, ("      - '%s'"):format(value))
      end
    end
  end

  local out, in_theme, skip = {}, false, false
  for _, line in ipairs(vim.split(base, "\n", { plain = true })) do
    local indent = #line:match("^ *")
    if line:match("%S") and indent <= 2 then
      in_theme = false
    end
    if in_theme and indent == 4 then
      skip = M.theme[line:match("^ *([%w_]+):")] ~= nil
    end
    if not (in_theme and skip and indent >= 4) then
      table.insert(out, line)
    end
    if line == "  theme:" then
      in_theme, skip = true, false
      vim.list_extend(out, entries)
    end
  end
  return table.concat(out, "\n")
end

-- Write `base` with the theme colors to `path`. The theme engine changes highlights again up to
-- 100 ms after a colorscheme change (themes/engine/opaque.lua), so the write waits for that.
function M.write(path, base)
  vim.defer_fn(function()
    local f = io.open(path, "w")
    if f then
      f:write(with_theme(base))
      f:close()
    end
  end, 150)
end

return M
