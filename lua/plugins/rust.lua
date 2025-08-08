-- Enhanced Rust development with rustaceanvim
return {
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- Use latest stable version
    lazy = false, -- Load immediately for Rust files
    ft = { "rust" },
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin and UI options
        tools = {
          -- Executor for background tasks (termopen, toggleterm, etc.)
          executor = require('rustaceanvim.executors').termopen,
          
          -- Test executor (cargo-nextest if available, fallback to cargo)
          test_executor = require('rustaceanvim.executors').background,
          
          -- Enable clippy for enhanced linting
          enable_clippy = true,
          
          -- Floating window configuration
          float_win_config = {
            auto_focus = true,
            width = 80,
            height = 30,
          },
          
          -- Inlay hints configuration
          inlay_hints = {
            auto = true,
            only_current_line = false,
            show_parameter_hints = true,
            parameter_hints_prefix = "<- ",
            other_hints_prefix = "=> ",
          },
        },
        
        -- LSP configuration
        server = {
          auto_attach = true,
          
          on_attach = function(client, bufnr)
            -- Custom keymaps for Rust
            local opts = { buffer = bufnr, silent = true }
            
            -- Code actions with enhanced Rust support
            vim.keymap.set("n", "<leader>ra", function()
              vim.cmd.RustLsp("codeAction")
            end, vim.tbl_extend("force", opts, { desc = "Rust code actions" }))
            
            -- Enhanced hover with actions
            vim.keymap.set("n", "K", function()
              vim.cmd.RustLsp({ "hover", "actions" })
            end, vim.tbl_extend("force", opts, { desc = "Rust hover actions" }))
            
            -- Run runnables (tests, executables)
            vim.keymap.set("n", "<leader>rr", function()
              vim.cmd.RustLsp("runnables")
            end, vim.tbl_extend("force", opts, { desc = "Run Rust runnables" }))
            
            -- Debug runnables
            vim.keymap.set("n", "<leader>rd", function()
              vim.cmd.RustLsp("debuggables")
            end, vim.tbl_extend("force", opts, { desc = "Debug Rust runnables" }))
            
            -- Expand macros
            vim.keymap.set("n", "<leader>rm", function()
              vim.cmd.RustLsp("expandMacro")
            end, vim.tbl_extend("force", opts, { desc = "Expand Rust macro" }))
            
            -- Show documentation for error codes
            vim.keymap.set("n", "<leader>re", function()
              vim.cmd.RustLsp("explainError")
            end, vim.tbl_extend("force", opts, { desc = "Explain Rust error" }))
            
            -- Render diagnostics
            vim.keymap.set("n", "<leader>rD", function()
              vim.cmd.RustLsp("renderDiagnostic")
            end, vim.tbl_extend("force", opts, { desc = "Render Rust diagnostic" }))
            
            -- Open Cargo.toml
            vim.keymap.set("n", "<leader>rc", function()
              vim.cmd.RustLsp("openCargo")
            end, vim.tbl_extend("force", opts, { desc = "Open Cargo.toml" }))
            
            -- Parent module
            vim.keymap.set("n", "<leader>rp", function()
              vim.cmd.RustLsp("parentModule")
            end, vim.tbl_extend("force", opts, { desc = "Go to parent module" }))
          end,
          
          -- rust-analyzer settings
          default_settings = {
            ["rust-analyzer"] = {
              -- Cargo settings
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
                buildScripts = {
                  enable = true,
                },
              },
              
              -- Clippy lints on save
              checkOnSave = {
                allFeatures = true,
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              
              -- Enhanced diagnostics
              diagnostics = {
                enable = true,
                experimental = {
                  enable = true,
                },
                styleLints = {
                  enable = true,
                },
              },
              
              -- Proc macro support
              procMacro = {
                enable = true,
                ignored = {
                  ["async-trait"] = { "async_trait" },
                  ["napi-derive"] = { "napi" },
                  ["async-recursion"] = { "async_recursion" },
                },
              },
              
              -- Completion settings
              completion = {
                autoimport = {
                  enable = true,
                },
                callable = {
                  snippets = "fill_arguments",
                },
              },
              
              -- Inlay hints
              inlayHints = {
                bindingModeHints = {
                  enable = false,
                },
                chainingHints = {
                  enable = true,
                },
                closingBraceHints = {
                  enable = true,
                  minLines = 25,
                },
                closureReturnTypeHints = {
                  enable = "never",
                },
                lifetimeElisionHints = {
                  enable = "never",
                  useParameterNames = false,
                },
                maxLength = 25,
                parameterHints = {
                  enable = true,
                },
                reborrowHints = {
                  enable = "never",
                },
                renderColons = true,
                typeHints = {
                  enable = true,
                  hideClosureInitialization = false,
                  hideNamedConstructor = false,
                },
              },
              
              -- Lens settings (show references, implementations)
              lens = {
                enable = true,
                debug = {
                  enable = true,
                },
                implementations = {
                  enable = true,
                },
                references = {
                  adt = {
                    enable = true,
                  },
                  enumVariant = {
                    enable = true,
                  },
                  method = {
                    enable = true,
                  },
                  trait = {
                    enable = true,
                  },
                },
                run = {
                  enable = true,
                },
              },
            },
          },
        },
        
        -- Debug adapter configuration
        dap = {
          autoload_configurations = true,
          adapter = function()
            local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
            local codelldb_path = extension_path .. "adapter/codelldb"
            local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib" -- macOS path
            
            return require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path)
          end,
        },
      }
    end,
  },
  
  -- Mason integration for rust tools
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "codelldb", "rust-analyzer" })
    end,
  },
}