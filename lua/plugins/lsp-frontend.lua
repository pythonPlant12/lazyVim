local resolver = require("config.lsp_resolver")
local typescript_lsp_settings = require("config.typescript_lsp_settings")

local function normalize(path)
  if not path or path == "" then
    return nil
  end
  return vim.uv.fs_realpath(path) or path
end

local function exists(path)
  return path and vim.uv.fs_stat(path) ~= nil
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

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
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
      opts.setup = opts.setup or {}

      opts.servers.ts_ls = { enabled = false }
      opts.servers.tsserver = { enabled = false }

      opts.servers.vtsls = vim.tbl_deep_extend("force", opts.servers.vtsls or {}, {
        root_dir = function(bufnr, on_dir)
          on_dir(resolver.nearest_root_by_markers(bufnr, resolver.frontend_markers.vtsls))
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
          preferences = {
            importModuleSpecifier = "non-relative",
            importModuleSpecifierEnding = "js",
            quoteStyle = "single",
          },
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
          typescript_lsp_settings.attach(client)
        end,
      })

      opts.servers.vue_ls = vim.tbl_deep_extend("force", opts.servers.vue_ls or {}, {
        filetypes = { "vue" },
        root_dir = function(bufnr, on_dir)
          on_dir(resolver.nearest_root_by_markers(bufnr, resolver.frontend_markers.vue_ls))
        end,
        on_attach = function(client)
          typescript_lsp_settings.attach(client)
        end,
      })

      local prev_eslint = opts.servers.eslint or {}
      local prev_eslint_on_init = prev_eslint.on_init

      opts.servers.eslint = vim.tbl_deep_extend("force", prev_eslint, {
        root_dir = function(bufnr, on_dir)
          if resolver.eslint_has_project_config(bufnr) then
            on_dir(resolver.eslint_root(bufnr))
            return
          end

          local root = resolver.workspace_root()

          if resolver.eslint_no_config_roots[root] then
            -- User disabled global eslint for this project; don't attach.
            return
          end

          if not resolver.eslint_warned_roots[root] then
            resolver.eslint_warned_roots[root] = true
            vim.schedule(function()
              vim.notify(
                "No ESLint config found — using global config. Toggle with <leader>Lje",
                vim.log.levels.WARN,
                { title = "ESLint" }
              )
            end)
          end

          on_dir(resolver.global_eslint_config_dir)
        end,
        on_init = function(client, init_result)
          if prev_eslint_on_init then
            prev_eslint_on_init(client, init_result)
          end
          if client.root_dir == resolver.global_eslint_config_dir then
            vim.defer_fn(function()
              client.notify("workspace/didChangeConfiguration", {
                settings = {
                  eslint = {
                    options = {
                      overrideConfigFile = resolver.global_eslint_config_file,
                    },
                  },
                },
              })
            end, 100)
          end
        end,
        settings = {
          format = true,
          workingDirectory = { mode = "location" },
          onIgnoredFiles = "off",
        },
      })

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
  },
}
