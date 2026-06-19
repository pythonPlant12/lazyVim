---@diagnostic disable: undefined-global

local uv = vim.uv

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return uv.fs_realpath(path) or path
end

local function stat(path)
  if not path then
    return nil
  end
  return uv.fs_stat(path)
end

local function is_dir(path)
  local s = stat(path)
  return s and s.type == "directory"
end

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function venv_bin_dir()
  return is_windows() and "Scripts" or "bin"
end

local function venv_exec(venv_dir, executable)
  if not venv_dir then
    return nil
  end
  local exec_name = executable
  if is_windows() and not executable:match("%.exe$") then
    exec_name = executable .. ".exe"
  end
  local path = normalize(string.format("%s/%s/%s", venv_dir, venv_bin_dir(), exec_name))
  if path and vim.fn.executable(path) == 1 then
    return path
  end
  return nil
end

local function root_venv(root)
  local nroot = normalize(root)
  if not nroot then
    return nil
  end
  for _, name in ipairs({ ".venv", "venv", ".env" }) do
    local candidate = normalize(string.format("%s/%s", nroot, name))
    if candidate and is_dir(candidate) and stat(string.format("%s/pyvenv.cfg", candidate)) then
      return candidate
    end
  end
  return nil
end

local function active_venv()
  local venv = normalize(vim.env.VIRTUAL_ENV)
  if venv and is_dir(venv) then
    return venv
  end
  local conda = normalize(vim.env.CONDA_PREFIX)
  if conda and is_dir(conda) then
    return conda
  end
  return nil
end

local function ruff_command(_, ctx)
  local root = vim.fs.root(ctx.dirname, {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    "pyrightconfig.json",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
  })

  local from_root_venv = venv_exec(root_venv(root), "ruff")
  if from_root_venv then
    return from_root_venv
  end

  local from_active_venv = venv_exec(active_venv(), "ruff")
  if from_active_venv then
    return from_active_venv
  end

  return "ruff"
end

local function formatter_list(opts, ft)
  opts.formatters_by_ft = opts.formatters_by_ft or {}
  opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
  return opts.formatters_by_ft[ft]
end

local function append_formatter(opts, ft, name)
  local list = formatter_list(opts, ft)
  if not vim.tbl_contains(list, name) then
    list[#list + 1] = name
  end
end

local function class_wrap_width(bufnr)
  local textwidth = vim.bo[bufnr].textwidth
  if textwidth and textwidth > 0 then
    return textwidth
  end
  return 100
end

local function indent_unit(bufnr)
  local width = vim.bo[bufnr].shiftwidth
  if not width or width <= 0 then
    width = vim.bo[bufnr].tabstop
  end
  return string.rep(" ", width > 0 and width or 2)
end

local function split_class_tokens(value)
  local tokens = {}
  for token in value:gmatch("%S+") do
    tokens[#tokens + 1] = token
  end
  return tokens
end

local function wrap_class_tokens(tokens, indent, width)
  local wrapped = {}
  local current = ""

  for _, token in ipairs(tokens) do
    if current == "" then
      current = token
    elseif #indent + #current + 1 + #token <= width then
      current = current .. " " .. token
    else
      wrapped[#wrapped + 1] = indent .. current
      current = token
    end
  end

  if current ~= "" then
    wrapped[#wrapped + 1] = indent .. current
  end

  return wrapped
end

local function static_class_attr(line, start)
  local attr_start, eq_end = line:find("class%s*=", start)
  while attr_start do
    local prev = attr_start > 1 and line:sub(attr_start - 1, attr_start - 1) or ""
    if not prev:match("[%w_:%-@%.]") then
      local quote_start = line:find("[\"']", eq_end + 1)
      if quote_start and line:sub(eq_end + 1, quote_start - 1):match("^%s*$") then
        local quote = line:sub(quote_start, quote_start)
        local quote_end = line:find(quote, quote_start + 1, true)
        if quote_end then
          return attr_start, quote_start, quote_end, quote
        end
      end
    end
    attr_start, eq_end = line:find("class%s*=", attr_start + 1)
  end
end

local function has_template_markers(value)
  return value:find("{{", 1, true) or value:find("{%", 1, true) or value:find("{#", 1, true)
end

local function line_enters_vue_template(line)
  return line:find("<template[%s>]", 1) ~= nil
end

local function line_starts_block(line, name)
  return line:find("<" .. name .. "[%s>]", 1) ~= nil and line:find("</" .. name .. "%s*>", 1) == nil
end

local function line_ends_block(line, name)
  return line:find("</" .. name .. "%s*>", 1) ~= nil
end

local function line_has_tag_before_class(line)
  local attr_start = line:find("class%s*=")
  if not attr_start then
    return false
  end

  local before = line:sub(1, attr_start - 1)
  if before:find("<!%-%-[^>]*$", 1) or before:find("<script[%s>]", 1) or before:find("<style[%s>]", 1) then
    return false
  end
  return before:match("<[%a][%w:._-]*[^<>]*$") ~= nil
end

local function class_line_is_allowed(line, state, ft)
  if state.in_script or state.in_style then
    return false
  end

  if ft == "vue" and not (state.in_vue_template or line_enters_vue_template(line)) then
    return false
  end

  return state.in_tag or line_has_tag_before_class(line)
end

local function update_class_wrap_state(line, state, ft)
  if ft == "vue" and line_enters_vue_template(line) then
    state.in_vue_template = true
  end

  if line_starts_block(line, "script") then
    state.in_script = true
  end
  if line_starts_block(line, "style") then
    state.in_style = true
  end

  local in_tag = state.in_tag
  if line:find("<[%a][%w:._-]*[^<>]*$", 1) then
    in_tag = true
  end
  if in_tag and line:find(">", 1, true) then
    in_tag = false
  end
  state.in_tag = in_tag

  if line_ends_block(line, "script") then
    state.in_script = false
  end
  if line_ends_block(line, "style") then
    state.in_style = false
  end
  if ft == "vue" and line:find("</template%s*>", 1) then
    state.in_vue_template = false
  end
end

local function wrap_static_class_line(line, ctx, state, ft)
  if not class_line_is_allowed(line, state, ft) then
    return nil
  end

  local attr_start, quote_start, quote_end, quote = static_class_attr(line, 1)
  if not attr_start then
    return nil
  end

  local value = line:sub(quote_start + 1, quote_end - 1)
  if ft == "htmldjango" and has_template_markers(value) then
    return nil
  end

  local tokens = split_class_tokens(value)
  local width = class_wrap_width(ctx.buf)
  if #tokens <= 1 or (#line <= width and #value <= width) then
    return nil
  end

  local leading = line:match("^%s*") or ""
  local value_indent = leading .. indent_unit(ctx.buf)
  local wrapped_value = wrap_class_tokens(tokens, value_indent, width)
  if #wrapped_value <= 1 and #wrapped_value[1] <= width then
    return nil
  end

  local lines = { line:sub(1, quote_start) }
  vim.list_extend(lines, wrapped_value)
  lines[#lines + 1] = leading .. quote .. line:sub(quote_end + 1)
  return lines
end

local function format_static_html_vue_classes(_, ctx, lines, callback)
  local formatted = {}
  local changed = false
  local ft = vim.bo[ctx.buf].filetype
  local state = {
    in_tag = false,
    in_script = false,
    in_style = false,
    in_vue_template = ft ~= "vue",
  }

  for _, line in ipairs(lines) do
    local wrapped = wrap_static_class_line(line, ctx, state, ft)
    if wrapped then
      changed = true
      vim.list_extend(formatted, wrapped)
    else
      formatted[#formatted + 1] = line
    end
    update_class_wrap_state(line, state, ft)
  end

  callback(nil, changed and formatted or lines)
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "ruff" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.python = { "ruff_fix", "ruff_format" }
      append_formatter(opts, "html", "html_vue_class_wrap")
      append_formatter(opts, "htmldjango", "html_vue_class_wrap")
      opts.formatters_by_ft.htmldjango.lsp_format = "first"
      append_formatter(opts, "vue", "html_vue_class_wrap")

      opts.formatters = opts.formatters or {}
      opts.formatters.ruff_fix = vim.tbl_deep_extend("force", opts.formatters.ruff_fix or {}, {
        command = ruff_command,
      })
      opts.formatters.ruff_format = vim.tbl_deep_extend("force", opts.formatters.ruff_format or {}, {
        command = ruff_command,
      })
      opts.formatters.html_vue_class_wrap = {
        meta = {
          description = "Wrap long static class attributes in HTML and Vue templates.",
        },
        format = format_static_html_vue_classes,
      }
    end,
  },
}
