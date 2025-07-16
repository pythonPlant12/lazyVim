-- Rust-specific configuration to prevent duplicate diagnostics
return {
  -- Override rustaceanvim configuration
  {
    "mrcjkb/rustaceanvim",
    version = "^4", -- Recommended
    lazy = false, -- This plugin is already lazy
    opts = {
      server = {
        on_attach = function(client, bufnr)
          -- Disable semantic tokens to reduce duplicate highlighting
          client.server_capabilities.semanticTokensProvider = nil
          
          -- Custom diagnostic configuration for Rust
          vim.diagnostic.config({
            virtual_text = {
              source = false, -- Don't show source since we know it's rust-analyzer
              prefix = "●",
              spacing = 4,
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
          }, bufnr)
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ['rust-analyzer'] = {
            diagnostics = {
              enable = true,
              experimental = {
                enable = false, -- Disable experimental diagnostics that might duplicate
              },
            },
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              runBuildScripts = true,
            },
            -- Add clippy lints for better diagnostics
            checkOnSave = {
              allFeatures = true,
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
    end,
  },
}