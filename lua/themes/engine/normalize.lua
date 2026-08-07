-- Cross-theme normalization: flat keyword colors, calm LSP semantic tokens,
-- and per-mode cursor colors — the same treatment for every theme.
local M = {}

-- Keep keywords visually plain across Treesitter and LSP semantic token groups.
local plain_keyword_groups = {
  "@conditional",
  "@keyword",
  "@keyword.conditional",
  "@keyword.conditional.ternary",
  "@keyword.coroutine",
  "@keyword.debug",
  "@keyword.directive",
  "@keyword.directive.define",
  "@keyword.exception",
  "@keyword.function",
  "@keyword.import",
  "@keyword.modifier",
  "@keyword.operator",
  "@keyword.repeat",
  "@keyword.return",
  "@repeat",
  "@lsp.type.keyword",
}

-- Filetypes whose keywords should be flattened to a single plain color.
local plain_keyword_langs = {
  "lua",
  "python",
  "javascript",
  "javascriptreact",
  "jsx",
  "typescript",
  "typescriptreact",
  "tsx",
  "rust",
  "vue",
  "html",
  "css",
  "scss",
  "jinja",
  "jinja2",
  "htmldjango",
}

-- Recolor all keyword-related groups to match the base Keyword foreground.
function M.apply_plain_keyword_hl()
  local keyword = vim.api.nvim_get_hl(0, { name = "Keyword", link = false })
  if not keyword or not keyword.fg then
    return
  end
  local keyword_fg = string.format("#%06x", keyword.fg)
  local hl = vim.api.nvim_set_hl

  for _, group in ipairs({ "Statement", "Keyword", "Conditional", "Repeat", "Label", "Exception" }) do
    hl(0, group, { fg = keyword_fg })
  end
  for _, group in ipairs(plain_keyword_groups) do
    hl(0, group, { fg = keyword_fg })
    for _, lang in ipairs(plain_keyword_langs) do
      hl(0, group .. "." .. lang, { fg = keyword_fg })
    end
  end
end

-- Apply plain keyword colors now and after delays so late plugins are covered.
function M.schedule_plain_keyword_hl()
  M.apply_plain_keyword_hl()
  for _, delay in ipairs({ 50, 200, 1000 }) do
    vim.defer_fn(M.apply_plain_keyword_hl, delay)
  end
end

-- Normalize semantic token colors so LSP overlays do not fight Treesitter colors.
function M.apply_semantic_token_hl()
  local function fg(name)
    local group = vim.api.nvim_get_hl(0, { name = name, link = false })
    return group and group.fg and string.format("#%06x", group.fg) or nil
  end
  local normal_fg = fg("Normal")
  local function_fg = fg("@function") or fg("Function") or normal_fg
  local type_fg = fg("@type") or fg("Type") or normal_fg
  local variable_fg = fg("@variable") or fg("Identifier") or normal_fg
  local hl = vim.api.nvim_set_hl

  local function_groups = {
    "@lsp.type.function",
    "@lsp.type.method",
    "@lsp.typemod.function.async",
    "@lsp.typemod.function.async.typescript",
    "@lsp.typemod.function.async.javascript",
    "@lsp.typemod.function.declaration",
    "@lsp.typemod.function.declaration.typescript",
    "@lsp.typemod.function.declaration.javascript",
    "@lsp.typemod.method.declaration",
    "@lsp.typemod.method.declaration.typescript",
    "@lsp.typemod.method.declaration.javascript",
  }
  for _, group in ipairs(function_groups) do
    hl(0, group, { fg = function_fg })
  end

  local type_groups = {
    "@interface",
    "@lsp.type.interface",
    "@lsp.type.interface.rust",
    "@lsp.typemod.interface.declaration",
    "@lsp.typemod.interface.declaration.rust",
    "@lsp.typemod.interface.macro",
    "@lsp.typemod.interface.macro.rust",
    "@lsp.typemod.interface.procMacro",
    "@lsp.typemod.interface.procMacro.rust",
    "@lsp.typemod.interface.public",
    "@lsp.typemod.interface.public.rust",
  }
  for _, group in ipairs(type_groups) do
    hl(0, group, { fg = type_fg })
  end

  local variable_groups = {
    "@lsp.type.variable",
    "@lsp.type.variable.typescript",
    "@lsp.type.variable.javascript",
    "@lsp.typemod.variable.readonly",
    "@lsp.typemod.variable.readonly.typescript",
    "@lsp.typemod.variable.readonly.javascript",
    "@lsp.typemod.variable.declaration",
    "@lsp.typemod.variable.declaration.typescript",
    "@lsp.typemod.variable.declaration.javascript",
  }
  for _, group in ipairs(variable_groups) do
    hl(0, group, { fg = variable_fg })
  end
end

-- Apply semantic token colors now and after delays so late LSP tokens are covered.
function M.schedule_semantic_token_hl()
  M.apply_semantic_token_hl()
  for _, delay in ipairs({ 50, 200, 1000 }) do
    vim.defer_fn(M.apply_semantic_token_hl, delay)
  end
end

-- Set cursor block colors per mode (normal/insert/replace) for light and dark.
function M.apply_cursor_hl()
  local is_light = vim.o.background == "light"
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local bg = normal and normal.bg and string.format("#%06x", normal.bg) or (is_light and "#FFFFFF" or "#151619")
  local cursor_text = is_light and "#FFFFFF" or bg
  local cursor = is_light and "#2A3038" or "#E8F0FA"
  local insert = is_light and "#2D6DB8" or "#56A8F5"
  local replace = is_light and "#A8631A" or "#CF8E6D"
  local hl = vim.api.nvim_set_hl

  hl(0, "Cursor",        { fg = cursor_text, bg = cursor })
  hl(0, "CursorInsert",  { fg = cursor_text, bg = insert })
  hl(0, "CursorReplace", { fg = cursor_text, bg = replace })
  hl(0, "lCursor",       { link = "CursorInsert" })
  hl(0, "CursorIM",      { link = "CursorInsert" })
  hl(0, "TermCursor",    { link = "Cursor" })
end

return M
