-- Language > Python keymaps

local keymaps = vim.keymap
local python_lsp_settings = require("lsp.python_settings")
local typescript_lsp_settings = require("lsp.typescript_settings")

local function get_pyright_client()
  for _, name in ipairs({ "basedpyright", "pyright" }) do
    local clients = vim.lsp.get_clients({ bufnr = 0, name = name })
    if #clients > 0 then return clients[1], name end
  end
  return nil, nil
end

local function python_type_check_settings_patch(server_name, mode)
  local root = server_name == "basedpyright" and "basedpyright" or "python"
  return {
    [root] = {
      analysis = {
        typeCheckingMode = mode,
      },
    },
  }
end

local function with_python_client(fn)
  if vim.bo.filetype ~= "python" then
    vim.notify("Not a Python buffer", vim.log.levels.WARN, { title = "Python" })
    return
  end
  local client, name = get_pyright_client()
  if not client then
    vim.notify("No pyright/basedpyright attached", vim.log.levels.WARN, { title = "Python" })
    return
  end
  return fn(client, name)
end

local function apply_python_server_value(client, server_name, path, value)
  python_lsp_settings.set_value(server_name, path, value)
  return python_lsp_settings.apply_to_client(client, server_name)
end

local function toggle_python_server_value(path, label)
  with_python_client(function(client, name)
    local current = python_lsp_settings.get_value(name, path)
    local next_value = not current
    apply_python_server_value(client, name, path, next_value)
    vim.notify(label .. " = " .. tostring(next_value), vim.log.levels.INFO, { title = name })
  end)
end

local function select_python_server_value(path, values, label)
  with_python_client(function(client, name)
    local current = python_lsp_settings.get_value(name, path)
    local items = {}
    for _, value in ipairs(values) do
      local marker = value == current and " \u{25cf}" or ""
      items[#items + 1] = { label = tostring(value) .. marker, value = value }
    end
    vim.ui.select(items, {
      prompt = label .. " (" .. name .. "):",
      format_item = function(item) return item.label end,
    }, function(choice)
      if not choice then return end
      apply_python_server_value(client, name, path, choice.value)
      vim.notify(label .. " = " .. tostring(choice.value), vim.log.levels.INFO, { title = name })
    end)
  end)
end

local function run_basedpyright_command(command, arguments)
  with_python_client(function(_, name)
    if name ~= "basedpyright" then
      vim.notify("Command requires basedpyright", vim.log.levels.WARN, { title = "Python" })
      return
    end
    vim.lsp.buf.execute_command({ command = command, arguments = arguments or {} })
  end)
end

local function read_config_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function escape_lua_pattern(s)
  return s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
end

local function toml_get(content, section, key)
  local key_pat = escape_lua_pattern(key)
  local in_target = (section == nil)
  for line in content:gmatch("[^\r\n]+") do
    local hdr = line:match("^%[([^%]]+)%]")
    if hdr then
      in_target = (section ~= nil and hdr == section)
    elseif in_target then
      local sval = line:match("^%s*" .. key_pat .. "%s*=%s*\"([^\"]+)\"")
      if sval then return sval end
      local nval = line:match("^%s*" .. key_pat .. "%s*=%s*(%d+)")
      if nval then return tonumber(nval) end
    end
  end
  return nil
end

local function walk_ancestors(callback)
  local bufpath = vim.api.nvim_buf_get_name(0)
  if bufpath == "" then return nil end
  local dir = vim.fn.fnamemodify(bufpath, ":h")
  local stop = vim.fn.getcwd()
  local checked_stop = false
  while dir do
    local result = callback(dir)
    if result then return result end
    if dir == stop then checked_stop = true; break end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  if not checked_stop then
    return callback(stop)
  end
  return nil
end

local function read_project_type_checking_mode(server_name)
  return walk_ancestors(function(dir)
    local content = read_config_file(dir .. "/pyrightconfig.json")
    if content then
      local mode = content:match('"typeCheckingMode"%s*:%s*"([^"]+)"')
      if mode then return mode end
    end
    content = read_config_file(dir .. "/pyproject.toml")
    if content then
      local section = server_name == "basedpyright" and "tool.basedpyright" or "tool.pyright"
      local mode = toml_get(content, section, "typeCheckingMode")
      if mode then return mode end
    end
  end) or "standard"
end

local function read_python_indent_config(dir)
  for _, name in ipairs({ "ruff.toml", ".ruff.toml" }) do
    local content = read_config_file(dir .. "/" .. name)
    if content then
      local val = toml_get(content, "format", "indent-width")
        or toml_get(content, nil, "indent-width")
      if val then return val end
    end
  end
  local content = read_config_file(dir .. "/pyproject.toml")
  if content then
    local val = toml_get(content, "tool.ruff.format", "indent-width")
      or toml_get(content, "tool.ruff", "indent-width")
    if val then return val end
  end
end

local function json_decode_safe(content)
  if not content then return nil end
  local ok, data = pcall(vim.json.decode, content)
  if ok and type(data) == "table" then return data end
  return nil
end

local function json_get(data, ...)
  local val = data
  for _, key in ipairs({ ... }) do
    if type(val) ~= "table" then return nil end
    val = val[key]
  end
  return (type(val) == "number") and val or nil
end

local function strip_json_comments(text)
  text = text:gsub("//[^\r\n]*", "")
  text = text:gsub("/%*.-%*/", "")
  return text
end

local function read_js_indent_config(dir)
  for _, name in ipairs({ "biome.json", "biome.jsonc" }) do
    local raw = read_config_file(dir .. "/" .. name)
    if raw then
      if name:find("jsonc$") then raw = strip_json_comments(raw) end
      local data = json_decode_safe(raw)
      if data then
        local val = json_get(data, "javascript", "formatter", "indentWidth")
          or json_get(data, "formatter", "indentWidth")
        if val then return val end
      end
    end
  end
  for _, name in ipairs({ ".prettierrc", ".prettierrc.json" }) do
    local raw = read_config_file(dir .. "/" .. name)
    if raw then
      local data = json_decode_safe(raw)
      if data then
        local val = json_get(data, "tabWidth")
        if val then return val end
      else
        local val = raw:match("tabWidth%s*:%s*(%d+)")
        if val then return tonumber(val) end
      end
    end
  end
  local raw = read_config_file(dir .. "/package.json")
  if raw then
    local data = json_decode_safe(raw)
    if data then
      local val = json_get(data, "prettier", "tabWidth")
      if val then return val end
    end
  end
end

local function read_html_indent_config(dir)
  for _, name in ipairs({ "biome.json", "biome.jsonc" }) do
    local raw = read_config_file(dir .. "/" .. name)
    if raw then
      if name:find("jsonc$") then raw = strip_json_comments(raw) end
      local data = json_decode_safe(raw)
      if data then
        local val = json_get(data, "html", "formatter", "indentWidth")
          or json_get(data, "formatter", "indentWidth")
        if val then return val end
      end
    end
  end
  for _, name in ipairs({ ".prettierrc", ".prettierrc.json" }) do
    local raw = read_config_file(dir .. "/" .. name)
    if raw then
      local data = json_decode_safe(raw)
      if data then
        local val = json_get(data, "tabWidth")
        if val then return val end
      else
        local val = raw:match("tabWidth%s*:%s*(%d+)")
        if val then return tonumber(val) end
      end
    end
  end
  local raw = read_config_file(dir .. "/package.json")
  if raw then
    local data = json_decode_safe(raw)
    if data then
      local val = json_get(data, "prettier", "tabWidth")
      if val then return val end
    end
  end
end

local js_filetypes = {
  javascript = true, javascriptreact = true,
  typescript = true, typescriptreact = true,
  vue = true,
}

local function get_typescript_clients()
  local seen = {}
  local attached = {}
  for _, name in ipairs({ "vtsls", "vue_ls" }) do
    local clients = vim.lsp.get_clients({ bufnr = 0, name = name })
    for _, client in ipairs(clients) do
      if not seen[client.id] then
        seen[client.id] = true
        attached[#attached + 1] = client
      end
    end
  end
  return attached
end

local function with_typescript_project_clients(fn)
  if not js_filetypes[vim.bo.filetype] then
    vim.notify("Not a TypeScript/Vue buffer", vim.log.levels.WARN, { title = "TypeScript" })
    return
  end

  local clients = get_typescript_clients()
  if #clients == 0 then
    vim.notify("No vtsls/vue_ls client attached", vim.log.levels.WARN, { title = "TypeScript" })
    return
  end

  local seen_roots = {}
  local roots = {}
  for _, client in ipairs(clients) do
    local root = typescript_lsp_settings.root_for_client(client)
    if not seen_roots[root] then
      seen_roots[root] = true
      roots[#roots + 1] = root
    end
  end

  return fn(roots)
end

local html_filetypes = {
  html = true, htmldjango = true,
  jinja = true, jinja2 = true,
}

local auto_indent_filetypes = vim.tbl_extend("force", { python = true }, js_filetypes, html_filetypes)

local function read_project_indent()
  local ft = vim.bo.filetype
  local reader
  if ft == "python" then
    reader = read_python_indent_config
  elseif js_filetypes[ft] then
    reader = read_js_indent_config
  elseif html_filetypes[ft] then
    reader = read_html_indent_config
  end
  if reader then return walk_ancestors(reader) end
  return nil
end

local function detect_indent()
  local lines = vim.api.nvim_buf_get_lines(0, 0, math.min(200, vim.api.nvim_buf_line_count(0)), false)
  local counts = {}
  local prev_indent = 0
  for _, line in ipairs(lines) do
    if line:match("%S") then
      local indent = #(line:match("^(%s*)") or "")
      local diff = math.abs(indent - prev_indent)
      if diff > 0 and diff <= 8 then
        counts[diff] = (counts[diff] or 0) + 1
      end
      prev_indent = indent
    end
  end
  local best, best_count = 2, 0
  for width, count in pairs(counts) do
    if count > best_count then
      best, best_count = width, count
    end
  end
  return best
end

keymaps.set("n", "<leader>Lpt", function()
  with_python_client(function(client, name)
    local modes = { "off", "basic", "standard", "strict" }
    if name == "basedpyright" then
      table.insert(modes, "recommended")
      table.insert(modes, "all")
    end
    local persisted = python_lsp_settings.get_value(name, { "analysis", "typeCheckingMode" }, { user_only = true })
    local current = persisted or read_project_type_checking_mode(name)
    local items = {}
    for _, m in ipairs(modes) do
      local marker = m == current and " \u{25cf}" or ""
      table.insert(items, { label = m .. marker, value = m })
    end
    vim.ui.select(items, {
      prompt = "Type checking mode (" .. name .. "):",
      format_item = function(item) return item.label end,
    }, function(choice)
      if not choice then return end
      apply_python_server_value(client, name, { "analysis", "typeCheckingMode" }, choice.value)
      vim.notify("typeCheckingMode = " .. choice.value, vim.log.levels.INFO, { title = name })
    end)
  end)
end, { desc = "Type check level" })

keymaps.set("n", "<leader>LTt", function()
  with_typescript_project_clients(function(roots)
    local first_level = typescript_lsp_settings.type_check_level(roots[1])
    local same_level = true
    for _, root in ipairs(roots) do
      if typescript_lsp_settings.type_check_level(root) ~= first_level then
        same_level = false
        break
      end
    end
    local items = {}
    for _, level in ipairs({ "project", "off" }) do
      local marker = same_level and level == first_level and " ●" or ""
      items[#items + 1] = { label = level .. marker, value = level }
    end
    vim.ui.select(items, {
      prompt = "TypeScript type checking (project):",
      format_item = function(item) return item.label end,
    }, function(choice)
      if not choice then return end
      local applied_roots = {}
      local level = choice.value
      for _, root in ipairs(roots) do
        level = typescript_lsp_settings.set_type_check_level(root, choice.value)
        typescript_lsp_settings.apply_to_root(root)
        applied_roots[#applied_roots + 1] = vim.fn.fnamemodify(root, ":~")
      end
      vim.notify(
        "typeCheckLevel = " .. level .. " (" .. table.concat(applied_roots, ", ") .. ")",
        vim.log.levels.INFO,
        { title = "TypeScript" }
      )
    end)
  end)
end, { desc = "TypeScript type check level" })

keymaps.set({ "n", "v" }, "<leader>Lpc", function()
  with_python_client(function()
    vim.lsp.buf.code_action()
  end)
end, { desc = "Python code actions" })

keymaps.set("n", "<leader>Lpi", function()
  run_basedpyright_command("basedpyright.organizeimports", { vim.uri_from_bufnr(0) })
end, { desc = "Python organize imports" })

keymaps.set("n", "<leader>Lpr", function()
  run_basedpyright_command("basedpyright.restartserver")
end, { desc = "Python restart server" })

keymaps.set("n", "<leader>Lpb", function()
  run_basedpyright_command("basedpyright.writeBaseline")
end, { desc = "Python write baseline" })

local function python_snacks_toggle(path, name, lhs)
  Snacks.toggle({
    name = name,
    get = function()
      return python_lsp_settings.get_value("basedpyright", path) == true
    end,
    set = function(state)
      with_python_client(function(client, server_name)
        apply_python_server_value(client, server_name, path, state)
      end)
    end,
  }):map(lhs)
end

python_snacks_toggle({ "analysis", "autoImportCompletions" },        "Auto import completions",     "<leader>Lpa")
python_snacks_toggle({ "analysis", "autoFormatStrings" },            "Auto format strings",         "<leader>Lpf")
python_snacks_toggle({ "analysis", "useTypingExtensions" },          "Typing extensions",           "<leader>Lpy")
python_snacks_toggle({ "disableTaggedHints" },                       "Tagged hints",                "<leader>Lph")
python_snacks_toggle({ "analysis", "inlayHints", "variableTypes" },  "Variable type hints",         "<leader>Lpv")
python_snacks_toggle({ "analysis", "inlayHints", "callArgumentNames" },         "Argument name hints",         "<leader>Lpn")
python_snacks_toggle({ "analysis", "inlayHints", "callArgumentNamesMatching" }, "Matching argument hints",     "<leader>Lpm")
python_snacks_toggle({ "analysis", "inlayHints", "functionReturnTypes" },       "Function return type hints",  "<leader>LpR")
python_snacks_toggle({ "analysis", "inlayHints", "genericTypes" },              "Generic type hints",          "<leader>Lpg")

keymaps.set("n", "<leader>LpV", function()
  local resolver = require("utils.lsp_resolver")
  local uv = vim.uv
  local root = resolver.workspace_root() or vim.fn.getcwd()
  local items = {}
  local seen = {}

  local function add_venv(path, label)
    local real = uv.fs_realpath(path) or path
    if seen[real] then return end
    local py = real .. "/bin/python"
    if vim.fn.executable(py) ~= 1 then return end
    seen[real] = true
    local cur = uv.fs_realpath(vim.env.VIRTUAL_ENV or "") or ""
    local marker = (real == cur) and "  ✓" or ""
    table.insert(items, { label = label .. marker, path = real, python = py })
  end

  -- 1. project-local venvs
  for _, name in ipairs(resolver.python_venv_dirs) do
    local candidate = root .. "/" .. name
    if uv.fs_stat(candidate) and uv.fs_stat(candidate .. "/pyvenv.cfg") then
      add_venv(candidate, name .. " (project)")
    end
  end

  -- 2. active shell venvs
  if vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" then
    add_venv(vim.env.VIRTUAL_ENV, vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t") .. " (shell)")
  end
  if vim.env.CONDA_PREFIX and vim.env.CONDA_PREFIX ~= "" then
    add_venv(vim.env.CONDA_PREFIX, vim.fn.fnamemodify(vim.env.CONDA_PREFIX, ":t") .. " (conda)")
  end

  -- 3. ~/.virtualenvs (virtualenvwrapper)
  local workon = vim.env.WORKON_HOME or (vim.env.HOME .. "/.virtualenvs")
  for _, cfg in ipairs(vim.fn.glob(workon .. "/*/pyvenv.cfg", false, true)) do
    local d = vim.fn.fnamemodify(cfg, ":h")
    add_venv(d, vim.fn.fnamemodify(d, ":t") .. " (~/.virtualenvs)")
  end

  -- 4. pyenv versions
  local pyenv_root = vim.env.PYENV_ROOT or (vim.env.HOME .. "/.pyenv")
  for _, py in ipairs(vim.fn.glob(pyenv_root .. "/versions/*/bin/python", false, true)) do
    local ver_dir = vim.fn.fnamemodify(py, ":h:h")
    local real = uv.fs_realpath(ver_dir) or ver_dir
    if not seen[real] and vim.fn.executable(py) == 1 then
      seen[real] = true
      table.insert(items, { label = vim.fn.fnamemodify(ver_dir, ":t") .. " (pyenv)", path = real, python = py })
    end
  end

  -- 5. system python fallback
  local sys_py = vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or vim.fn.exepath("python")
  if sys_py and sys_py ~= "" then
    table.insert(items, { label = "system (" .. sys_py .. ")", path = "", python = sys_py, system = true })
  end

  if #items == 0 then
    vim.notify("No Python environments found", vim.log.levels.WARN, { title = "Python venv" })
    return
  end

  vim.ui.select(items, {
    prompt = "Select Python environment",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end

    vim.env.VIRTUAL_ENV = (not choice.system) and choice.path or nil
    local bufnr = vim.api.nvim_get_current_buf()
    local updated = {}

    for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
      if client.name == "basedpyright" then
        local settings = vim.tbl_deep_extend("force", client.settings or {}, {
          python = { pythonPath = choice.python },
        })
        client.settings = settings
        client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, settings)
        client:notify("workspace/didChangeConfiguration", { settings = client.settings })
        table.insert(updated, "basedpyright")
      elseif client.name == "ty" then
        vim.lsp.stop_client(client.id)
        vim.defer_fn(function() require('lspconfig').ty.launch() end, 200)
        table.insert(updated, "ty (restarted)")
      end
    end

    local msg = vim.fn.fnamemodify(choice.python, ":~")
    if #updated > 0 then msg = msg .. "\n↳ " .. table.concat(updated, ", ") end
    vim.notify(msg, vim.log.levels.INFO, { title = "Python env" })
  end)
end, { desc = "Select Python virtual environment" })

keymaps.set("n", "<leader>LpL", function()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "python" then
    vim.notify("Not a Python buffer", vim.log.levels.WARN, { title = "Python LSP" })
    return
  end

  local py_servers = { "basedpyright", "ty" }
  local items = {}

  for _, name in ipairs(py_servers) do
    local clients = vim.lsp.get_clients({ bufnr = bufnr, name = name })
    local active = #clients > 0
    local icon = active and "✓" or "○"
    local role = name == "basedpyright"
      and (active and " — primary (completions, hover, goto)" or " — primary (inactive)")
      or  (active and " — diagnostics-only" or " — diagnostics-only (inactive)")
    table.insert(items, { label = icon .. " " .. name .. role, name = name, active = active, client = clients[1] })
  end

  local active_count = 0
  for _, i in ipairs(items) do if i.active then active_count = active_count + 1 end end

  vim.ui.select(items, {
    prompt = "Python LSP (" .. active_count .. " active) — toggle",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    if choice.name == "basedpyright" then
      if choice.active then
        vim.notify(
          "basedpyright is the primary LSP.\nUse :LspStop basedpyright to force-stop.",
          vim.log.levels.INFO, { title = "Python LSP" })
      else
        require('lspconfig').basedpyright.launch()
        vim.notify("basedpyright started", vim.log.levels.INFO, { title = "Python LSP" })
      end
    elseif choice.name == "ty" then
      if choice.active then
        vim.lsp.stop_client(choice.client.id)
        vim.notify("ty stopped", vim.log.levels.INFO, { title = "Python LSP" })
      else
        require('lspconfig').ty.launch()
        vim.notify("ty started (diagnostics-only alongside basedpyright)", vim.log.levels.INFO, { title = "Python LSP" })
      end
    end
  end)
end, { desc = "Python LSP manager" })

keymaps.set("n", "<leader>Lpd", function()
  select_python_server_value({ "analysis", "diagnosticMode" }, { "openFilesOnly", "workspace" }, "diagnosticMode")
end, { desc = "Diagnostic mode" })

keymaps.set("n", "<leader>Lsi", function()
  local ft = vim.bo.filetype
  if not auto_indent_filetypes[ft] then
    vim.notify("Not a supported filetype: " .. ft, vim.log.levels.WARN, { title = "Indent" })
    return
  end
  local project_indent = read_project_indent()
  local current = vim.b.indent_width_override or project_indent
  local widths = { 1, 2, 3, 4 }
  local items = {}
  for _, w in ipairs(widths) do
    local marker = (current == w) and " \u{25cf}" or ""
    table.insert(items, { label = tostring(w) .. marker, value = w })
  end
  local auto_marker = (current == nil) and " \u{25cf}" or ""
  table.insert(items, { label = "auto" .. auto_marker, value = "auto" })
  vim.ui.select(items, {
    prompt = "Indentation width:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local width = choice.value
    if width == "auto" then
      width = detect_indent()
      vim.b.indent_width_override = nil
      vim.notify("Detected indent: " .. width, vim.log.levels.INFO, { title = "Indent" })
    else
      vim.b.indent_width_override = width
    end
    vim.bo.shiftwidth = width
    vim.bo.tabstop = width
    vim.bo.softtabstop = width
    vim.notify("Indentation = " .. width, vim.log.levels.INFO, { title = "Indent" })
  end)
end, { desc = "Indentation width" })

keymaps.set("n", "<leader>LI", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  local ft = vim.bo.filetype
  local lines = {}

  lines[#lines + 1] = "file: " .. (file ~= "" and file or "(no file)")
  lines[#lines + 1] = "filetype: " .. (ft ~= "" and ft or "(none)")
  lines[#lines + 1] = ""

  lines[#lines + 1] = "attached clients:"
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    lines[#lines + 1] = "  (none)"
  else
    for _, client in ipairs(clients) do
      local root = client.root_dir
      if (not root or root == "") and type(client.config) == "table" then
        root = client.config.root_dir
      end
      lines[#lines + 1] = string.format("  %s -> %s", client.name, root or "(none)")
    end
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "indentation:"
  local source = "default"
  local width = vim.bo.shiftwidth
  if vim.b.indent_width_override then
    source = "manual override"
    width = vim.b.indent_width_override
  elseif auto_indent_filetypes[ft] then
    local proj = read_project_indent()
    if proj then
      source = "project config"
      width = proj
    else
      local detected = detect_indent()
      source = "file detection"
      width = detected
    end
  end
  lines[#lines + 1] = string.format("  width: %d (%s)", width, source)
  lines[#lines + 1] = string.format("  shiftwidth=%d tabstop=%d softtabstop=%d",
    vim.bo.shiftwidth, vim.bo.tabstop, vim.bo.softtabstop)

  if ft == "python" then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "type checking:"
    local client, name = get_pyright_client()
    if client then
      local persisted_mode = python_lsp_settings.get_value(name, { "analysis", "typeCheckingMode" }, { user_only = true })
      local mode = persisted_mode or read_project_type_checking_mode(name)
      local mode_source = persisted_mode and "persistent override" or "project/default"
      lines[#lines + 1] = string.format("  %s: %s (%s)", name, mode, mode_source)
      lines[#lines + 1] = string.format("  diagnosticMode: %s", python_lsp_settings.get_value(name, { "analysis", "diagnosticMode" }))
      lines[#lines + 1] = string.format("  autoImportCompletions: %s", tostring(python_lsp_settings.get_value(name, { "analysis", "autoImportCompletions" })))
      lines[#lines + 1] = string.format("  autoFormatStrings: %s", tostring(python_lsp_settings.get_value(name, { "analysis", "autoFormatStrings" })))
      lines[#lines + 1] = string.format("  state file: %s", python_lsp_settings.state_file())
    else
      lines[#lines + 1] = "  (no pyright/basedpyright attached)"
    end
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "Language Info" })
end, { desc = "Language info" })

local function apply_auto_indent()
  if not auto_indent_filetypes[vim.bo.filetype] then return end
  if vim.b.indent_width_override then return end
  local width = read_project_indent() or detect_indent()
  vim.bo.shiftwidth = width
  vim.bo.tabstop = width
  vim.bo.softtabstop = width
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("AutoIndent", { clear = true }),
  pattern = { "python", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue", "html", "htmldjango", "jinja", "jinja2" },
  callback = apply_auto_indent,
})
if auto_indent_filetypes[vim.bo.filetype] then apply_auto_indent() end

pcall(vim.keymap.del, "n", "<leader>L")

vim.keymap.set("n", "<leader>If", function()
  require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } })
end, { desc = "File diagnostics" })

vim.keymap.set("n", "<leader>Iw", function()
  require("trouble").toggle("diagnostics")
end, { desc = "Workspace diagnostics" })

vim.keymap.set("n", "<leader>Ih", "<cmd>Inspect<CR>", { desc = "Inspect highlight groups" })

vim.keymap.set("n", "<leader>Ef", function()
  require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } })
end, { desc = "File errors (LSP)" })

vim.keymap.set("n", "<leader>Ew", function()
  require("trouble").toggle({ mode = "diagnostics" })
end, { desc = "Workspace errors (LSP)" })

vim.keymap.set("n", "<leader>Ee", function()
  require("trouble").toggle({ mode = "diagnostics", filter = { source = "eslint" } })
end, { desc = "ESLint errors" })

vim.schedule(function()
  require("which-key").add({
    { "<leader>I",  group = "Inspect",  icon = { icon = "󰋇", color = "cyan" } },
    { "<leader>L",  group = "Language", icon = { icon = "󰗊", color = "blue" } },
    { "<leader>Ln", group = "Noice",    icon = { icon = "󰈸", color = "orange" } },
    { "<leader>Lp", group = "Python",   icon = { cat = "filetype", name = "python" } },
    { "<leader>LT", group = "TypeScript", icon = { cat = "filetype", name = "typescript" } },
    { "<leader>Ls", group = "Shared",   icon = { icon = "󰈝", color = "green" } },
    { "<leader>E",  group = "Errors",   icon = { icon = "󰅚", color = "red" } },
  })
end)

keymaps.set("n", "<leader>Lps", function()
  require("lsp.stub_generator").add_stub_for_diagnostic()
end, { desc = "Add stub for diagnostic" })

keymaps.set("n", "<leader>Lnr", function()
  require("noice").enable()
  vim.notify("Noice restarted", vim.log.levels.INFO, { title = "Noice" })
end, { desc = "Restart Noice" })

keymaps.set("n", "<leader>Lje", function()
  local resolver = require("utils.lsp_resolver")
  local bufnr = vim.api.nvim_get_current_buf()

  if resolver.eslint_has_project_config(bufnr) then
    vim.notify(
      "Project ESLint config found — global config toggle has no effect",
      vim.log.levels.INFO,
      { title = "ESLint" }
    )
    return
  end

  local root = resolver.workspace_root()

  if resolver.eslint_no_config_roots[root] then
    -- Currently disabled → enable global config
    resolver.eslint_no_config_roots[root] = nil
    resolver.eslint_warned_roots[root] = nil
    vim.schedule(function()
      local ok, lspconf = pcall(require, "lspconfig")
      if ok and lspconf.eslint and lspconf.eslint.manager then
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            pcall(lspconf.eslint.manager.try_add, lspconf.eslint.manager, buf)
          end
        end
      end
    end)
    vim.notify("ESLint global config enabled", vim.log.levels.INFO, { title = "ESLint" })
  else
    -- Currently enabled → disable global config
    resolver.eslint_no_config_roots[root] = true
    for _, client in ipairs(vim.lsp.get_clients({ name = "eslint" })) do
      if client.root_dir == resolver.global_eslint_config_dir then
        client.stop()
      end
    end
    vim.notify("ESLint global config disabled", vim.log.levels.WARN, { title = "ESLint" })
  end
end, { desc = "Toggle ESLint global config" })
