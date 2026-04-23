local M = {}

local state_file = vim.fn.stdpath("state") .. "/python-lsp-settings.json"

local defaults = {
  basedpyright = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        autoFormatStrings = true,
        useTypingExtensions = false,
        inlayHints = {
          variableTypes = true,
          callArgumentNames = true,
          callArgumentNamesMatching = false,
          functionReturnTypes = true,
          genericTypes = true,
        },
      },
      disableOrganizeImports = false,
      disableTaggedHints = false,
    },
  },
}

local cached_state = nil

local function deepcopy(value)
  return vim.deepcopy(value)
end

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

local function nested_get(tbl, path)
  local value = tbl
  for _, key in ipairs(path) do
    if type(value) ~= "table" then
      return nil
    end
    value = value[key]
  end
  return value
end

local function nested_set(tbl, path, value)
  local current = tbl
  for index = 1, #path - 1 do
    local key = path[index]
    if type(current[key]) ~= "table" then
      current[key] = {}
    end
    current = current[key]
  end
  current[path[#path]] = value
end

function M.server_root(server_name)
  return server_name == "basedpyright" and "basedpyright" or "python"
end

local function rooted_path(server_name, path)
  local full = { M.server_root(server_name) }
  vim.list_extend(full, path)
  return full
end

local function load_state()
  if cached_state ~= nil then
    return cached_state
  end

  local content = read_file(state_file)
  if not content or content == "" then
    cached_state = {}
    return cached_state
  end

  local ok, decoded = pcall(vim.json.decode, content)
  cached_state = ok and type(decoded) == "table" and decoded or {}
  return cached_state
end

local function save_state(state)
  cached_state = state
  return write_file(state_file, vim.json.encode(state))
end

function M.default_server_settings(server_name)
  return deepcopy(defaults[server_name] or { [M.server_root(server_name)] = {} })
end

function M.server_settings(server_name)
  local default_settings = M.default_server_settings(server_name)
  local user_state = deepcopy(load_state()[server_name] or {})
  return vim.tbl_deep_extend("force", default_settings, user_state)
end

function M.get_value(server_name, path, opts)
  local source = opts and opts.user_only and (load_state()[server_name] or {}) or M.server_settings(server_name)
  return nested_get(source, rooted_path(server_name, path))
end

function M.set_value(server_name, path, value)
  local state = load_state()
  state[server_name] = state[server_name] or {}
  nested_set(state[server_name], rooted_path(server_name, path), value)
  save_state(state)
  return M.server_settings(server_name)
end

function M.apply_to_client(client, server_name)
  local settings = M.server_settings(server_name)
  client.settings = vim.tbl_deep_extend("force", client.settings or {}, settings)
  client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {}, settings)
  client:notify("workspace/didChangeConfiguration", { settings = client.settings })
  return settings
end

function M.state_file()
  return state_file
end

return M
