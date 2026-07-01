-- Centralize TypeScript/Vue LSP settings shared by keymaps and frontend LSP setup.
local M = {}

local state_file = vim.fn.stdpath("state") .. "/typescript-lsp-settings.json"
local default_type_check_level = "project"
local managed_clients = { vtsls = true, vue_ls = true }

local cached_state = nil

local function read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read("*a")
  file:close()
  return content
end

local function write_file(path, content)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local file = io.open(path, "w")
  if not file then
    return false
  end
  file:write(content)
  file:close()
  return true
end

local function normalize_root(root)
  if not root or root == "" then
    return vim.fn.getcwd()
  end
  return vim.fs.normalize(root)
end

local function client_root(client)
  return normalize_root(client and (client.root_dir or (client.config and client.config.root_dir)))
end

local function load_state()
  if cached_state ~= nil then
    return cached_state
  end

  local content = read_file(state_file)
  if not content or content == "" then
    cached_state = { projects = {} }
    return cached_state
  end

  local ok, decoded = pcall(vim.json.decode, content)
  cached_state = ok and type(decoded) == "table" and decoded or { projects = {} }
  cached_state.projects = cached_state.projects or {}
  return cached_state
end

local function save_state(state)
  cached_state = state
  return write_file(state_file, vim.json.encode(state))
end

function M.state_file()
  return state_file
end

function M.root_for_client(client)
  return client_root(client)
end

function M.is_managed_client(client)
  return client and managed_clients[client.name] == true
end

function M.type_check_level(root)
  local project = load_state().projects[normalize_root(root)] or {}
  return project.typeCheckLevel or default_type_check_level
end

function M.set_type_check_level(root, level)
  level = level == "off" and "off" or default_type_check_level
  local state = load_state()
  local normalized = normalize_root(root)
  state.projects[normalized] = state.projects[normalized] or {}
  state.projects[normalized].typeCheckLevel = level
  save_state(state)
  return level
end

function M.type_check_enabled(root)
  return M.type_check_level(root) ~= "off"
end

local function validation_enabled(root)
  return M.type_check_enabled(root)
end

local function settings_for_root(root)
  local enabled = validation_enabled(root)
  return {
    typescript = {
      validate = { enable = enabled },
    },
    javascript = {
      validate = { enable = enabled },
    },
  }
end

function M.apply_to_client(client)
  if not M.is_managed_client(client) then
    return nil
  end

  local settings = settings_for_root(client_root(client))
  client.settings = vim.tbl_deep_extend("force", client.settings or {}, settings)
  client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, settings)
  client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  return settings
end

local function filter_diagnostics(client, diagnostics)
  if not M.is_managed_client(client) or M.type_check_enabled(client_root(client)) then
    return diagnostics
  end
  return {}
end

local function reset_client_diagnostics(client)
  if not (vim.lsp.diagnostic and vim.lsp.diagnostic.get_namespace) then
    return
  end
  local ok, namespace = pcall(vim.lsp.diagnostic.get_namespace, client.id)
  if ok and namespace then
    vim.diagnostic.reset(namespace)
  end
end

function M.attach(client)
  if not M.is_managed_client(client) or client._typescript_lsp_settings_attached then
    return
  end
  client._typescript_lsp_settings_attached = true
  client.handlers = client.handlers or {}
  local previous_handler = client.handlers["textDocument/publishDiagnostics"]
    or vim.lsp.handlers["textDocument/publishDiagnostics"]
  M.apply_to_client(client)

  client.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if result and type(result.diagnostics) == "table" then
      result = vim.tbl_extend("force", result, {
        diagnostics = filter_diagnostics(client, result.diagnostics),
      })
    end
    if previous_handler then
      return previous_handler(err, result, ctx, config)
    end
  end
end

function M.clients_for_root(root)
  local normalized = normalize_root(root)
  return vim.tbl_filter(function(client)
    return M.is_managed_client(client) and client_root(client) == normalized
  end, vim.lsp.get_clients())
end

function M.apply_to_root(root)
  local enabled = M.type_check_enabled(root)
  for _, client in ipairs(M.clients_for_root(root)) do
    M.apply_to_client(client)
    if enabled then
      client:notify("workspace/didChangeWatchedFiles", { changes = {} })
    else
      reset_client_diagnostics(client)
    end
  end
end

return M
