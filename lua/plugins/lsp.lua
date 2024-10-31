return {
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        -- Existing tools
        "stylua",
        "selene",
        "luacheck",
        "shellcheck",
        "shfmt",
        "tailwindcss-language-server",
        "typescript-language-server",
        "pyright",
        "angular-language-server",
        "css-lsp",
        "css-variables-language-server",
        -- Added new ones
        "vue-language-server",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Automatically refresh grep results after changes
      local function refresh_grep()
        vim.cmd("cclose")
        vim.cmd("copen")
        vim.cmd("cclose")
      end

      vim.api.nvim_create_autocmd({ "BufWritePost", "QuickFixCmdPost" }, {
        callback = refresh_grep,
      })
    end,
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
        },
        severity_sort = true,
      },
      autoformat = true,
      servers = {
        -- TypeScript configuration
        tsserver = {
          enabled = true,
          filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
          root_dir = require("lspconfig").util.root_pattern("package.json", "tsconfig.json", "jsconfig.json"),
          single_file_support = true,
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        -- Python configuration
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                typeCheckingMode = "on",
                executionEnvironments = {
                  { root = "src" },
                },
              },
            },
          },
        },
      },
      setup = {
        -- TypeScript setup
        tsserver = function(_, opts)
          require("lazyvim.util").lsp.on_attach(function(client, buffer)
            if client.name == "tsserver" then
              vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buffer, desc = "Goto Definition" })
              vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = buffer, desc = "Goto References" })
              vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = buffer, desc = "Hover" })
            end
          end)
          return true
        end,
      },
    },
  },
}
