local uv = vim.uv

local M = {}

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return uv.fs_realpath(path) or path
end

local function dir_of(path)
  return normalize(vim.fs.dirname(path))
end

local function join_path(dir, name)
  return string.format("%s/%s", dir, name)
end

local function stat(path)
  if not path then
    return nil
  end
  return uv.fs_stat(path)
end

local function is_file(path)
  local s = stat(path)
  return s and s.type == "file"
end

local function is_dir(path)
  local s = stat(path)
  return s and s.type == "directory"
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

local function has_any_file(dir, names)
  for _, name in ipairs(names) do
    if is_file(join_path(dir, name)) then
      return true
    end
  end
  return false
end

local function ancestors_until(start_dir, stop_dir)
  local dirs = {}
  local current = normalize(start_dir)
  local stop = normalize(stop_dir)

  while current and current ~= "" do
    dirs[#dirs + 1] = current
    if stop and current == stop then
      break
    end
    local parent = dir_of(current)
    if not parent or parent == current then
      break
    end
    current = parent
  end

  return dirs
end

local function package_json_has_eslint(dir)
  local package_json = join_path(dir, "package.json")
  if not is_file(package_json) then
    return false
  end
  local content = read_file(package_json)
  if not content then
    return false
  end
  return content:find('"eslintConfig"%s*:') ~= nil
end

local function is_windows()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
end

local function python_bin_dir_name()
  return is_windows() and "Scripts" or "bin"
end

M.frontend_markers = {
  vtsls = {
    "tsconfig.json",
    "jsconfig.json",
    "package.json",
    "pnpm-workspace.yaml",
    "pnpm-lock.yaml",
    "yarn.lock",
    "package-lock.json",
    "bun.lock",
    "bun.lockb",
  },
  vue_ls = {
    "nuxt.config.ts",
    "nuxt.config.js",
    "nuxt.config.mjs",
    "nuxt.config.cjs",
    "vue.config.js",
    "tsconfig.json",
    "jsconfig.json",
    "package.json",
    "pnpm-workspace.yaml",
  },
}

M.python_project_markers = {
  "pyproject.toml",
  "ruff.toml",
  ".ruff.toml",
  "pyrightconfig.json",
  "mypy.ini",
  "setup.py",
  "setup.cfg",
  "requirements.txt",
  "Pipfile",
  "tox.ini",
}

M.python_venv_config_markers = {
  "pyproject.toml",
  "ruff.toml",
  ".ruff.toml",
  "pyrightconfig.json",
  "setup.cfg",
  "mypy.ini",
}

M.python_venv_dirs = { ".venv", "venv", ".env" }

function M.workspace_root()
  return normalize(vim.fn.getcwd()) or normalize(vim.env.HOME) or "/"
end

function M.nearest_root_by_markers(bufnr, markers)
  local fname = type(bufnr) == "string" and bufnr or vim.api.nvim_buf_get_name(bufnr)
  local file_dir = dir_of(fname)
  local root = M.workspace_root()

  for _, dir in ipairs(ancestors_until(file_dir, root)) do
    if has_any_file(dir, markers) then
      return dir
    end
  end

  if has_any_file(root, markers) then
    return root
  end

  return root
end

function M.eslint_root(bufnr)
  local eslint_configs = {
    "eslint.config.js",
    "eslint.config.cjs",
    "eslint.config.mjs",
    "eslint.config.ts",
    "eslint.config.cts",
    "eslint.config.mts",
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    ".eslintrc.yml",
    ".eslintrc.yaml",
  }
  local ignore_files = { ".gitignore", ".eslintignore" }
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local file_dir = dir_of(fname)
  local root = M.workspace_root()

  local config_candidate = nil
  local package_candidate = nil

  for _, dir in ipairs(ancestors_until(file_dir, root)) do
    local has_config = has_any_file(dir, eslint_configs) or package_json_has_eslint(dir)
    local has_ignore = has_any_file(dir, ignore_files)
    local has_package = is_file(join_path(dir, "package.json"))

    if has_config and has_ignore then
      return dir
    end

    if has_config and not config_candidate then
      config_candidate = dir
    end

    if has_package and has_ignore and not package_candidate then
      package_candidate = dir
    end
  end

  return config_candidate or package_candidate or root or normalize(vim.env.HOME) or "/"
end

function M.active_venv_dir()
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

function M.python_venv_for_root(root)
  local nroot = normalize(root)
  if nroot then
    for _, name in ipairs(M.python_venv_dirs) do
      local candidate = join_path(nroot, name)
      if is_dir(candidate) and is_file(join_path(candidate, "pyvenv.cfg")) then
        return candidate
      end
    end
  end
  return M.active_venv_dir()
end

function M.python_exec_from_venv(venv_dir, executable)
  if not venv_dir then
    return nil
  end
  local exec_name = executable
  if is_windows() and not executable:match("%.exe$") then
    exec_name = executable .. ".exe"
  end
  local candidate = join_path(join_path(venv_dir, python_bin_dir_name()), exec_name)
  if vim.fn.executable(candidate) == 1 then
    return candidate
  end

  local resolved = normalize(candidate)
  if resolved and vim.fn.executable(resolved) == 1 then
    return resolved
  end
  return nil
end

function M.python_root_info(bufnr)
  local fname = type(bufnr) == "string" and bufnr or vim.api.nvim_buf_get_name(bufnr)
  local file_dir = dir_of(fname)
  local root = M.workspace_root()

  for _, dir in ipairs(ancestors_until(file_dir, root)) do
    if has_any_file(dir, M.python_project_markers) then
      return dir, "project"
    end
  end

  local venv = M.python_venv_for_root(root)
  if venv and has_any_file(venv, M.python_venv_config_markers) then
    return venv, "venv"
  end

  return root or normalize(vim.env.HOME) or "/", "default-ruff"
end

function M.python_root(bufnr)
  local root = M.python_root_info(bufnr)
  return root
end

return M
