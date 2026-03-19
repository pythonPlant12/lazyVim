local uv = vim.uv

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

local function exists(path)
  return stat(path) ~= nil
end

local function is_file(path)
  local s = stat(path)
  return s and s.type == "file"
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

local function has_any_file(dir, names)
  for _, name in ipairs(names) do
    if is_file(join_path(dir, name)) then
      return true
    end
  end
  return false
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

local function workspace_root()
  return normalize(vim.fn.getcwd()) or normalize(vim.env.HOME) or "/"
end

local function machine_root_fallback()
  return normalize(vim.env.HOME) or "/"
end

--- Walk from the file's directory toward workspace root, find nearest dir
--- that has any of the given marker files. Falls back to workspace root
--- and finally to $HOME.
--- @param bufnr integer
--- @param markers string[]
--- @return string
local function nearest_root_by_markers(bufnr, markers)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local file_dir = dir_of(fname)
  local root = workspace_root()

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

--- Walk from the file's directory toward workspace root looking for an
--- ESLint config (legacy or flat) combined with a boundary marker
--- (.gitignore or .eslintignore). Returns the nearest boundary.
--- @param bufnr integer
--- @return string
local function eslint_root(bufnr)
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
  local root = workspace_root()

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

  return config_candidate or package_candidate or root or machine_root_fallback()
end

local function vue_language_server_path()
  local mason_v2 = normalize(vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/@vue/language-server")
  if mason_v2 and exists(mason_v2) then
    return mason_v2
  end

  local ok, mason_registry = pcall(require, "mason-registry")
  if ok then
    local has_pkg, pkg = pcall(mason_registry.get_package, "vue-language-server")
    if has_pkg and pkg then
      local path = normalize(pkg:get_install_path() .. "/node_modules/@vue/language-server")
      if path and exists(path) then
        return path
      end
    end
  end

  return normalize("/usr/local/lib/node_modules/@vue/language-server")
end

local function vue_typescript_plugin()
  return {
    name = "@vue/typescript-plugin",
    location = vue_language_server_path(),
    languages = { "vue" },
    configNamespace = "typescript",
    enableForWorkspaceTypeScriptVersions = true,
  }
end

local function max_popup_size()
  return math.floor(vim.o.columns * 0.5), math.floor(vim.o.lines * 0.3)
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "stylua",
        "selene",
        "luacheck",
        "shellcheck",
        "shfmt",
        "tailwindcss-language-server",
        "vtsls",
        "vue-language-server",
        "eslint-lsp",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}

      opts.servers.pylsp = { enabled = false }
      opts.servers.ts_ls = { enabled = false }
      opts.servers.tsserver = { enabled = false }

      opts.servers.vtsls = {
        -- Neovim 0.11: root_dir(bufnr, on_dir) — must call on_dir(path) or return nil
        root_dir = function(bufnr, on_dir)
          local root = nearest_root_by_markers(bufnr, {
            "tsconfig.json",
            "jsconfig.json",
            "package.json",
            "pnpm-workspace.yaml",
            "pnpm-lock.yaml",
            "yarn.lock",
            "package-lock.json",
            "bun.lock",
            "bun.lockb",
          })
          on_dir(root)
        end,
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
          "vue",
        },
        settings = {
          complete_function_calls = true,
          vtsls = {
            enableMoveToFileCodeAction = true,
            autoUseWorkspaceTsdk = true,
            experimental = {
              maxInlayHintLength = 30,
              completion = {
                enableServerSideFuzzyMatch = true,
              },
            },
            tsserver = {
              globalPlugins = {
                vue_typescript_plugin(),
              },
            },
          },
          typescript = {
            updateImportsOnFileMove = { enabled = "always" },
            suggest = {
              completeFunctionCalls = true,
            },
            inlayHints = {
              enumMemberValues = { enabled = true },
              functionLikeReturnTypes = { enabled = true },
              parameterNames = { enabled = "literals" },
              parameterTypes = { enabled = true },
              propertyDeclarationTypes = { enabled = true },
              variableTypes = { enabled = false },
            },
          },
        },
        on_attach = function(client, bufnr)
          if vim.bo[bufnr].filetype == "html" then
            client.server_capabilities.documentHighlightProvider = false
          end
          local semantic = client.server_capabilities.semanticTokensProvider
          if semantic and semantic.full ~= nil then
            semantic.full = vim.bo[bufnr].filetype ~= "vue"
          end
        end,
      }

      opts.servers.vue_ls = {
        filetypes = { "vue" },
        root_dir = function(bufnr, on_dir)
          local root = nearest_root_by_markers(bufnr, {
            "nuxt.config.ts",
            "nuxt.config.js",
            "nuxt.config.mjs",
            "nuxt.config.cjs",
            "vue.config.js",
            "tsconfig.json",
            "jsconfig.json",
            "package.json",
            "pnpm-workspace.yaml",
          })
          on_dir(root)
        end,
        -- on_init is provided by the built-in lspconfig (lsp/vue_ls.lua) and
        -- handles the vtsls bridge automatically (with retry logic). We do NOT
        -- override it here so we get the better built-in version.
      }

      opts.servers.eslint = {
        root_dir = function(bufnr, on_dir)
          on_dir(eslint_root(bufnr))
        end,
        settings = {
          format = true,
          workingDirectory = { mode = "auto" },
          onIgnoredFiles = "off",
        },
      }

      opts.setup = opts.setup or {}
      opts.setup.vtsls = opts.setup.vtsls
        or function(_, server_opts)
          server_opts.settings = server_opts.settings or {}
          server_opts.settings.javascript = vim.tbl_deep_extend(
            "force",
            {},
            server_opts.settings.typescript or {},
            server_opts.settings.javascript or {}
          )
        end

      return opts
    end,
    init = function()
      local max_width, max_height = max_popup_size()

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
        max_width = max_width,
        max_height = max_height,
      })

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
        max_width = max_width,
        max_height = max_height,
      })

      vim.api.nvim_set_hl(0, "@lsp.type.component", { link = "@type" })
    end,
  },
}
