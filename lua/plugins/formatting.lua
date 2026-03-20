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

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "ruff" },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
      },
      formatters = {
        ruff_fix = {
          command = ruff_command,
        },
        ruff_format = {
          command = ruff_command,
        },
      },
    },
  },
}
