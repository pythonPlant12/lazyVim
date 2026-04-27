-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.o.smoothscroll = false
vim.o.cursorline = true
vim.opt.guicursor = "n-v-c-sm:block,i-ci-ve:ver25,r-cr-o:hor20,a:blinkwait0-blinkon0-blinkoff0"

vim.o.winborder = "rounded"
vim.o.switchbuf = "useopen"

vim.diagnostic.config({ signs = false })

vim.g.root_spec = { "cwd" }

-- Undercurl
vim.cmd([[let &t_Cs = "\e[4:3m"]])
vim.cmd([[let &t_Ce = "\e[4:0m"]])

vim.o.cmdheight = 2

vim.g.autoformat = false
vim.g.eslint_autosave = false
vim.g.lazyvim_picker = "snacks"

local function normalize_template_path(path)
  if not path or path == "" then
    return ""
  end

  return path:gsub("\\", "/")
end

local function jinja_template_filetype(path)
  local normalized = normalize_template_path(path)
  if normalized:match(".*%.html%.j2$") or normalized:match(".*%.html%.jinja$") or normalized:match(".*%.html%.jinja2$") then
    return "htmldjango"
  end

  return "jinja"
end

local function buffer_has_template_markers(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local chunk_size = 200

  for start_line = 0, math.max(line_count - 1, 0), chunk_size do
    local end_line = math.min(start_line + chunk_size, line_count)
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
    for _, line in ipairs(lines) do
      if line:find("{%", 1, true) or line:find("{{", 1, true) or line:find("{#", 1, true) then
        return true
      end
    end
  end

  return false
end

vim.filetype.add({
  extension = {
    j2 = jinja_template_filetype,
    jinja = jinja_template_filetype,
    jinja2 = jinja_template_filetype,
    html = function(path, bufnr)
      local normalized = normalize_template_path(path)
      if normalized:match("/templates/.*%.html$") then
        return "htmldjango"
      end

      if buffer_has_template_markers(bufnr) then
        return "htmldjango"
      end

      return "html"
    end,
  },
  pattern = {
    [".*%.html%.j2$"] = "htmldjango",
    [".*%.html%.jinja$"] = "htmldjango",
    [".*%.html%.jinja2$"] = "htmldjango",
    [".*/templates/.*%.html$"] = "htmldjango",
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TemplateSyntax", { clear = true }),
  pattern = { "jinja", "jinja2", "htmldjango" },
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    vim.bo[ev.buf].syntax = ft == "htmldjango" and "htmldjango" or "jinja"
  end,
})
