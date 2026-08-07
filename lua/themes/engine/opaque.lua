-- Opaque-theme support: some themes must keep plugin windows on solid
-- backgrounds (floats, pickers, treesitter-context) instead of transparency.
local M = {}

-- True for themes that should keep plugin windows fully opaque.
function M.is_default_theme()
  local cs = vim.g.colors_name or ""
  return cs == "default-dark"
    or cs == "default-light"
    or cs == "islands-rose-pine-light"
    or (cs == "rose-pine" and vim.o.background == "light")
    or cs == "rose-pine-dawn"
end

-- Default themes need explicit opaque UI backgrounds for floats, pickers, and context windows.
function M.apply_default_opaque_hl()
  if not M.is_default_theme() then return end

  local hl = vim.api.nvim_set_hl
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local normal_bg = (normal and normal.bg) and string.format("#%06x", normal.bg) or (vim.o.background == "light" and "#FFFFFF" or "#151619")
  local normal_fg = (normal and normal.fg) and string.format("#%06x", normal.fg) or (vim.o.background == "light" and "#4C4F69" or "#BCBEC4")
  local c = type(vim.g.theme_custom_hl) == "table" and vim.g.theme_custom_hl or {}
  local panel_bg = c.panel_bg or normal_bg
  local context_bg = c.treesitter_context_bg or c.context_bg or (vim.o.background == "light" and "#F3F3F3" or "#313244")
  local border = c.border or normal_fg
  -- Pickers can opt onto a different surface than the gray panel (default-light
  -- puts them on the editor background). Falls back to panel_bg otherwise.
  local picker_bg = c.picker_bg or panel_bg
  local picker_groups = {
    SnacksPickerBox = true, SnacksPickerInput = true, SnacksPickerList = true,
    SnacksPickerPreview = true, SnacksPickerTitle = true, SnacksPickerFooter = true,
    SnacksInputNormal = true, SnacksInputTitle = true,
    SnacksPickerBorder = true, SnacksInputBorder = true,
  }

  local function with_bg(group, group_bg, group_fg)
    local current = vim.api.nvim_get_hl(0, { name = group, link = false }) or {}
    current.bg = group_bg
    if group_fg == false then
      current.fg = nil
    elseif group_fg then
      current.fg = group_fg
    end
    current.link = nil
    hl(0, group, current)
  end

  for _, group in ipairs({
    "NormalFloat",
    "FloatTitle",
    "FloatFooter",
    "Pmenu",
    "NoicePopup",
    "NoicePopupmenu",
    "NoiceCmdlinePopup",
    "WhichKey",
    "WhichKeyNormal",
    "BlinkCmpMenu",
    "BlinkCmpDoc",
    "BlinkCmpSignatureHelp",
    "Terminal",
    "SnacksPickerBox",
    "SnacksPickerInput",
    "SnacksPickerList",
    "SnacksPickerPreview",
    "SnacksPickerTitle",
    "SnacksPickerFooter",
    "SnacksInputNormal",
    "SnacksInputTitle",
  }) do
    with_bg(group, picker_groups[group] and picker_bg or panel_bg, normal_fg)
  end

  for _, group in ipairs({
    "FloatBorder",
    "PmenuBorder",
    "NoicePopupBorder",
    "NoiceCmdlinePopupBorder",
    "NoiceCmdlinePopupTitle",
    "WhichKeyBorder",
    "BlinkCmpMenuBorder",
    "BlinkCmpDocBorder",
    "BlinkCmpDocSeparator",
    "BlinkCmpSignatureHelpBorder",
    "SnacksPickerBorder",
    "SnacksInputBorder",
    "TreesitterContextSeparator",
  }) do
    with_bg(group, picker_groups[group] and picker_bg or panel_bg, border)
  end

  for _, group in ipairs({
    "TreesitterContext",
    "TreesitterContextLineNumber",
    "TreesitterContextBottom",
    "TreesitterContextLineNumberBottom",
  }) do
    with_bg(group, context_bg, group:find("LineNumber") and normal_fg or false)
  end

  -- nvim-treesitter-context opens noautocmd floating windows and maps only
  -- NormalFloat by default, so normal window autocommands can miss them.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local ok_context, is_context = pcall(function() return vim.w[win].treesitter_context end)
      local ok_line_number, is_line_number = pcall(function() return vim.w[win].treesitter_context_line_number end)
      local ok_terminal, terminal = pcall(function()
        local buf = vim.api.nvim_win_get_buf(win)
        return vim.b[buf].snacks_terminal
      end)
      local is_lazygit = ok_terminal
        and type(terminal) == "table"
        and ((type(terminal.cmd) == "table" and terminal.cmd[1] == "lazygit")
          or (type(terminal.cmd) == "string" and terminal.cmd:find("lazygit", 1, true) ~= nil))
      if ok_context and is_context then
        pcall(function()
          vim.wo[win].winhl = table.concat({
            "Normal:TreesitterContext",
            "NormalNC:TreesitterContext",
            "NormalFloat:TreesitterContext",
            "FloatBorder:TreesitterContextSeparator",
            "EndOfBuffer:TreesitterContext",
          }, ",")
          vim.wo[win].winblend = vim.o.winblend
        end)
      elseif ok_line_number and is_line_number then
        pcall(function()
          vim.wo[win].winhl = table.concat({
            "Normal:TreesitterContextLineNumber",
            "NormalNC:TreesitterContextLineNumber",
            "NormalFloat:TreesitterContextLineNumber",
            "FloatBorder:TreesitterContextSeparator",
            "EndOfBuffer:TreesitterContextLineNumber",
          }, ",")
          vim.wo[win].winblend = vim.o.winblend
        end)
      elseif is_lazygit then
        pcall(function()
          vim.wo[win].winhl = table.concat({
            "Normal:NormalFloat",
            "NormalNC:NormalFloat",
            "NormalFloat:NormalFloat",
            "FloatBorder:FloatBorder",
            "EndOfBuffer:NormalFloat",
          }, ",")
          vim.wo[win].winblend = vim.o.winblend
        end)
      end
    end
  end
end

-- Reapply on startup/theme/window events, not cursor movement, to avoid motion lag.
function M.schedule_default_opaque_hl()
  if not M.is_default_theme() then return end

  M.apply_default_opaque_hl()
  vim.schedule(M.apply_default_opaque_hl)
  vim.defer_fn(M.apply_default_opaque_hl, 20)
  vim.defer_fn(M.apply_default_opaque_hl, 100)
end

return M
