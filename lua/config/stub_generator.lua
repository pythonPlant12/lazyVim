local M = {}

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function append_to_file(path, lines)
  local f = io.open(path, "a")
  if not f then return false end
  f:write("\n" .. table.concat(lines, "\n") .. "\n")
  f:close()
  return true
end

function M.extract_missing_attr(message)
  local attr = message:match('"([%w_]+)" is not a known attribute of module')
  if attr then return attr end
  attr = message:match('"([%w_]+)" is not a known attribute of class')
  if attr then return attr end
  attr = message:match('Cannot access attribute "([%w_]+)"')
  return attr
end

local function extract_module_from_import(bufnr, attr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
  for _, line in ipairs(lines) do
    local mod = line:match("from%s+([%w%.]+)%s+import.*" .. attr)
    if mod then return mod, attr end
    mod = line:match("import%s+([%w%.]+)%s+as%s+" .. attr)
    if mod then return mod, nil end
    if line:match("import%s+([%w%.]+%." .. attr .. ")") then
      local full = line:match("import%s+([%w%.]+%." .. attr .. ")")
      local parts = vim.split(full, "%.")
      local sym = table.remove(parts)
      return table.concat(parts, "."), sym
    end
  end
  return nil, nil
end

local function find_stub_file(module_path)
  local stub_root = vim.fn.stdpath("config") .. "/stubs"
  local rel = module_path:gsub("%.", "/")
  local candidates = {
    stub_root .. "/" .. rel .. ".pyi",
    stub_root .. "/" .. rel .. "/__init__.pyi",
  }
  for _, p in ipairs(candidates) do
    if vim.fn.filereadable(p) == 1 then return p end
  end
  return candidates[1]
end

local function module_to_import(module_path)
  return module_path:gsub("/", ".")
end

local function introspect_symbol(module_path, attr, venv_python)
  local script = string.format([[
import sys, inspect, typing
try:
  mod = __import__('%s', fromlist=['%s'])
  sym = getattr(mod, '%s')
  if callable(sym):
    try:
      sig = inspect.signature(sym)
      params = []
      PK = inspect.Parameter
      seen_kw_only = False
      has_var_positional = any(p.kind == PK.VAR_POSITIONAL for p in sig.parameters.values())
      for name, p in sig.parameters.items():
        ann = ''
        if p.annotation is not PK.empty:
          ann = ': ' + getattr(p.annotation, '__name__', str(p.annotation))
        default = ''
        if p.default is not PK.empty:
          default = ' = ...'
        if p.kind == PK.VAR_POSITIONAL:
          params.append('*' + name + ann)
        elif p.kind == PK.VAR_KEYWORD:
          params.append('**' + name + ann)
        elif p.kind == PK.KEYWORD_ONLY:
          if not seen_kw_only and not has_var_positional:
            params.append('*')
            seen_kw_only = True
          params.append(name + ann + default)
        else:
          params.append(name + ann + default)
      ret = ''
      if sig.return_annotation is not PK.empty:
        ret = ' -> ' + getattr(sig.return_annotation, '__name__', str(sig.return_annotation))
      print('callable|' + ', '.join(params) + '|' + ret)
    except (ValueError, TypeError):
      print('callable|*args: Any, **kwargs: Any|')
  else:
    t = type(sym).__name__
    print('value|' + t)
except Exception as e:
  print('error|' + str(e))
]], module_path, attr, attr)

  local python = venv_python or "python3"
  local result = vim.fn.system(python .. " -c " .. vim.fn.shellescape(script))
  return vim.trim(result)
end

local function build_stub_lines(attr, introspect_result)
  local kind, rest = introspect_result:match("^([^|]+)|(.*)$")
  if kind == "callable" then
    local params_str, ret = rest:match("^(.*)|([^|]*)$")
    local params = params_str ~= "" and params_str or "*args: Any, **kwargs: Any"
    local return_type = ret ~= "" and ret or " -> Any"
    if not return_type:match("^%s*%->") then
      return_type = " -> Any"
    end
    return {
      "from typing import Any, Callable, TypeVar",
      "def " .. attr .. "(" .. params .. ")" .. return_type .. ": ...",
    }
  elseif kind == "value" then
    local typ = rest ~= "" and rest or "Any"
    return {
      "from typing import Any",
      attr .. ": " .. typ,
    }
  else
    return {
      "from typing import Any",
      attr .. ": Any",
    }
  end
end

local function resolve_import_alias(bufnr, alias)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
  for _, line in ipairs(lines) do
    local from_mod = line:match("from%s+([%w%.]+)%s+import%s+" .. alias .. "%s*$")
      or line:match("from%s+([%w%.]+)%s+import%s+" .. alias .. "%s*,")
      or line:match("from%s+([%w%.]+)%s+import%s+" .. alias .. "%s+as%s+")
    if from_mod then return from_mod .. "." .. alias end
    local aliased_import = line:match("import%s+([%w%.]+)%s+as%s+" .. alias)
    if aliased_import then return aliased_import end
    local bare_import = line:match("^import%s+(" .. alias .. ")%s*$")
    if bare_import then return bare_import end
  end
  return nil
end

local function find_venv_python(root_dir)
  local candidates = {
    root_dir .. "/venv/bin/python",
    root_dir .. "/.venv/bin/python",
  }
  for _, p in ipairs(candidates) do
    if vim.fn.executable(p) == 1 then return p end
  end
  return "python3"
end

function M.add_stub_for_diagnostic()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line = cursor[1] - 1

  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line })
  if #diagnostics == 0 then
    vim.notify("No diagnostics on current line", vim.log.levels.WARN)
    return
  end

  local diag = diagnostics[1]
  local attr = M.extract_missing_attr(diag.message)
  if not attr then
    vim.notify("Could not extract missing attribute from: " .. diag.message, vim.log.levels.WARN)
    return
  end

  local module_path, _ = extract_module_from_import(bufnr, attr)
  if not module_path then
    local line_text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
    local inline = line_text:match("([%w%.]+)%." .. attr)
    if inline then
      module_path = resolve_import_alias(bufnr, inline) or inline
    end
  end

  if not module_path then
    vim.ui.input({ prompt = "Module path for '" .. attr .. "': " }, function(input)
      if input and input ~= "" then
        M._finish_add_stub(attr, input, bufnr)
      end
    end)
    return
  end

  M._finish_add_stub(attr, module_path, bufnr)
end

function M._finish_add_stub(attr, module_path, bufnr)
  local root_dir = vim.fn.getcwd()
  local python = find_venv_python(root_dir)
  local stub_file = find_stub_file(module_path)

  vim.notify("Introspecting " .. module_path .. "." .. attr .. " ...", vim.log.levels.INFO)

  local result = introspect_symbol(module_path, attr, python)
  local lines = build_stub_lines(attr, result)

  vim.fn.mkdir(vim.fn.fnamemodify(stub_file, ":h"), "p")

  local existing = read_file(stub_file) or ""
  local already = existing:find(attr .. "[%s:(]")
  if already then
    vim.notify("'" .. attr .. "' already exists in " .. stub_file, vim.log.levels.INFO)
    return
  end

  local ok = append_to_file(stub_file, lines)
  if ok then
    vim.notify("Added stub for '" .. attr .. "' to " .. vim.fn.fnamemodify(stub_file, ":~"), vim.log.levels.INFO)
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "basedpyright" })) do
      client.notify("workspace/didChangeWatchedFiles", {
        changes = { { uri = vim.uri_from_fname(stub_file), type = 2 } },
      })
    end
  else
    vim.notify("Failed to write to " .. stub_file, vim.log.levels.ERROR)
  end
end

function M.setup()
  vim.api.nvim_create_user_command("StubAddDiagnostic", function()
    M.add_stub_for_diagnostic()
  end, { desc = "Generate stub entry for missing symbol on current line" })
end

return M
