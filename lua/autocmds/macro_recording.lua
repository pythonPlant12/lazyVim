-- Surface macro recording state: blink.cmp hard-disables ALL completion
-- (insert mode, `/` search and `:` cmdline) while a macro is being recorded
-- or executed (reg_recording()/reg_executing() check in its enabled()).
-- A stray `q<letter>` in normal mode silently starts recording, which looks
-- like "completion randomly stopped working". Notify and refresh the
-- statusline (the mode chip shows RECORDING @x) so the state is obvious.
local group = vim.api.nvim_create_augroup("macro_recording_notify", { clear = true })

local function refresh_statusline()
  local ok, lualine = pcall(require, "lualine")
  if ok then lualine.refresh({ place = { "statusline" } }) end
end

vim.api.nvim_create_autocmd("RecordingEnter", {
  group = group,
  callback = function()
    refresh_statusline()
    vim.notify(
      ("Recording macro @%s — completion is disabled while recording (press q to stop)"):format(vim.fn.reg_recording()),
      vim.log.levels.WARN,
      { title = "Macro" }
    )
  end,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  group = group,
  callback = function()
    -- reg_recording() is still set inside RecordingLeave; refresh just after.
    vim.schedule(refresh_statusline)
    vim.notify("Macro recording stopped — completion re-enabled", vim.log.levels.INFO, { title = "Macro" })
  end,
})
