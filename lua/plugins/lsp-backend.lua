---@diagnostic disable: undefined-global

local resolver = require("utils.lsp_resolver")
local python_lsp_settings = require("lsp.python_settings")
local stub_generator = require("lsp.stub_generator")
stub_generator.setup()

local function add_unique_path(paths, path)
  if not path or path == "" or vim.fn.isdirectory(path) ~= 1 then
    return
  end
  for _, existing in ipairs(paths) do
    if existing == path then
      return
    end
  end
  table.insert(paths, path)
end

local function python_user_site()
  if vim.fn.executable("python3") ~= 1 then
    return nil
  end
  local output = vim.fn.systemlist({ "python3", "-m", "site", "--user-site" })
  if vim.v.shell_error ~= 0 or type(output) ~= "table" then
    return nil
  end
  return output[1]
end

local function apply_stub_paths(_, config)
  local stub_paths = {}
  local ms_stubs = vim.fn.stdpath("data") .. "/lazy/python-type-stubs"
  add_unique_path(stub_paths, ms_stubs)
  local custom_stubs = vim.fn.stdpath("config") .. "/stubs"
  add_unique_path(stub_paths, custom_stubs)
  local user_site = python_user_site()
  if user_site and vim.fn.isdirectory(user_site .. "/django-stubs") == 1 then
    add_unique_path(stub_paths, user_site)
  end
  if #stub_paths == 0 then return end
  config.settings = config.settings or {}
  config.settings.basedpyright = config.settings.basedpyright or {}
  config.settings.basedpyright.analysis = config.settings.basedpyright.analysis or {}
  -- basedpyright only accepts a single stubPath string; use the first match
  -- and append custom stubs second so they take precedence via order
  if not config.settings.basedpyright.analysis.stubPath then
    config.settings.basedpyright.analysis.stubPath = stub_paths[1]
  end
  if #stub_paths > 1 then
    local extra = config.settings.basedpyright.analysis.extraPaths or {}
    for i = 2, #stub_paths do
      table.insert(extra, stub_paths[i])
    end
    config.settings.basedpyright.analysis.extraPaths = extra
  end
end

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

local function disable_template_document_highlight(client, bufnr)
  local ft = vim.bo[bufnr].filetype
  if ft == "html" or ft == "htmldjango" or ft == "jinja" or ft == "jinja2" then
    client.server_capabilities.documentHighlightProvider = false
  end
end

local function ensure_ty_lspconfig()
  local configs = require("lspconfig.configs")
  if not configs.ty then
    configs.ty = {
      default_config = {
        cmd = { "ty", "server" },
        filetypes = { "python" },
        root_dir = function(fname)
          return resolver.python_root(fname)
        end,
        single_file_support = true,
      },
      docs = {
        description = "https://github.com/astral-sh/ty",
      },
    }
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
        "jinja-lsp",
        "ty",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}
      opts.setup = opts.setup or {}
      ensure_ty_lspconfig()

      opts.servers.pylsp = { enabled = false }
      opts.servers.pyright = { enabled = false }

      opts.servers.basedpyright = vim.tbl_deep_extend("force", opts.servers.basedpyright or {}, {
        root_dir = function(fname)
          return resolver.python_root(fname)
        end,
        settings = python_lsp_settings.server_settings("basedpyright"),
      })
      merge_before_init(opts.servers.basedpyright, apply_python_path_from_venv)
      merge_before_init(opts.servers.basedpyright, apply_stub_paths)

      opts.servers.ruff = vim.tbl_deep_extend("force", opts.servers.ruff or {}, {
        root_dir = function(fname)
          return resolver.python_root(fname)
        end,
      })
      merge_before_init(opts.servers.ruff, apply_ruff_cmd_from_venv)

      opts.servers.ruff_lsp = vim.tbl_deep_extend("force", opts.servers.ruff_lsp or {}, {
        root_dir = function(fname)
          return resolver.python_root(fname)
        end,
      })

      opts.servers.ty = vim.tbl_deep_extend("force", opts.servers.ty or {}, {
        autostart = false,
        root_dir = function(fname)
          return resolver.python_root(fname)
        end,
        on_init = function(client)
          client.server_capabilities.completionProvider     = nil
          client.server_capabilities.hoverProvider          = false
          client.server_capabilities.definitionProvider     = false
          client.server_capabilities.referencesProvider     = false
          client.server_capabilities.documentSymbolProvider = false
          client.server_capabilities.workspaceSymbolProvider= false
          client.server_capabilities.renameProvider         = false
          client.server_capabilities.signatureHelpProvider  = nil
          client.server_capabilities.codeActionProvider     = false
          client.server_capabilities.inlayHintProvider      = false
          client.server_capabilities.semanticTokensProvider = nil
        end,
      })

      opts.servers.jinja_lsp = vim.tbl_deep_extend("force", opts.servers.jinja_lsp or {}, {
        filetypes = { "html", "jinja", "jinja2", "htmldjango" },
        root_dir = function(fname)
          return resolver.python_root(fname)
        end,
        on_attach = disable_template_document_highlight,
      })

      local lspconfig = require("lspconfig")
      opts.setup.basedpyright = function(_, server_opts)
        lspconfig.basedpyright.setup(server_opts)
        return true
      end
      opts.setup.ruff = function(_, server_opts)
        lspconfig.ruff.setup(server_opts)
        return true
      end
      opts.setup.ruff_lsp = function(_, server_opts)
        lspconfig.ruff_lsp.setup(server_opts)
        return true
      end
      opts.setup.ty = function(_, server_opts)
        lspconfig.ty.setup(server_opts)
        return true
      end
      opts.setup.jinja_lsp = function(_, server_opts)
        lspconfig.jinja_lsp.setup(server_opts)
        return true
      end

      return opts
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "htmldjango", "jinja" })
    end,
  },
  {
    "microsoft/python-type-stubs",
    build = false,
    lazy = true,
  },
}
