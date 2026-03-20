local resolver = require("config.lsp_resolver")

local function merge_before_init(server_opts, hook)
  local previous = server_opts.before_init
  server_opts.before_init = function(params, config)
    hook(params, config)
    if type(previous) == "function" then
      return previous(params, config)
    end
  end
end

local function apply_python_path_from_venv(_, config)
  local venv = resolver.python_venv_for_root(config.root_dir)
  local py_exec = resolver.python_exec_from_venv(venv, "python")
  if not py_exec then
    return
  end

  config.settings = config.settings or {}
  config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
    pythonPath = py_exec,
  })
end

local function apply_ruff_cmd_from_venv(_, config)
  local venv = resolver.python_venv_for_root(config.root_dir)
  local ruff = resolver.python_exec_from_venv(venv, "ruff")
  if ruff then
    config.cmd = { ruff, "server" }
  end
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "ruff",
        "pyright",
        "basedpyright",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}

      opts.servers.pylsp = { enabled = false }

      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
        root_dir = function(bufnr, on_dir)
          on_dir(resolver.python_root(bufnr))
        end,
      })
      merge_before_init(opts.servers.pyright, apply_python_path_from_venv)

      opts.servers.basedpyright = vim.tbl_deep_extend("force", opts.servers.basedpyright or {}, {
        root_dir = function(bufnr, on_dir)
          on_dir(resolver.python_root(bufnr))
        end,
      })
      merge_before_init(opts.servers.basedpyright, apply_python_path_from_venv)

      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
        root_dir = function(bufnr, on_dir)
          on_dir(resolver.python_root(bufnr))
        end,
      })
      merge_before_init(opts.servers.ruff, apply_ruff_cmd_from_venv)

      opts.servers.ruff_lsp = vim.tbl_deep_extend("force", opts.servers.ruff_lsp or {}, {
        root_dir = function(bufnr, on_dir)
          on_dir(resolver.python_root(bufnr))
        end,
      })

      return opts
    end,
  },
}
