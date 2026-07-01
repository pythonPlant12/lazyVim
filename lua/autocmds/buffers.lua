do
  vim.g.buf_history = vim.g.buf_history or {}

  local function push_buf_history(bufnr)
    local h = vim.g.buf_history
    if h[#h] == bufnr then return end
    table.insert(h, bufnr)
    if #h > 50 then table.remove(h, 1) end
    vim.g.buf_history = h
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("BufHistory", { clear = true }),
    callback = function(ev)
      if vim.bo[ev.buf].buftype ~= "" then return end
      if vim.api.nvim_buf_get_name(ev.buf) == "" then return end
      push_buf_history(ev.buf)
    end,
  })
end

-- Prevent conceal-related cursor blink in JSON files.
-- Treesitter JSON has @conceal captures for " chars; with conceallevel>=1 this
-- causes a redraw (and visible cursor flicker) on every vertical cursor movement.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("JsonNoConceallevel", { clear = true }),
  pattern = { "json", "jsonc", "json5" },
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.concealcursor = "nvic"
  end,
})

-- Treesitter markdown highlights use (#set! conceal_lines "") to fully hide
-- fenced code block delimiters (```) when conceallevel >= 1. This makes code
-- blocks appear to collapse/vanish. Disable conceal for markdown files.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("MarkdownNoConceallevel", { clear = true }),
  pattern = { "markdown" },
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})
