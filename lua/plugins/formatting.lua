return {
  -- Use conform.nvim for formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fp",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
      {
        "<leader>fs",
        function()
          vim.g.format_on_save_enabled = not vim.g.format_on_save_enabled
          print("Format on save " .. (vim.g.format_on_save_enabled and "enabled" or "disabled") .. " globally")
        end,
        desc = "Toggle format on save globally",
      },
      {
        "<leader>fap",
        function()
          vim.g.prettier_on_save_enabled = not vim.g.prettier_on_save_enabled
          local status = vim.g.prettier_on_save_enabled and "✅ ENABLED" or "❌ DISABLED"
          local icon = vim.g.prettier_on_save_enabled and "🎨" or "🚫"
          
          -- Use custom notification if available, otherwise print
          if _G.format_notify then
            _G.format_notify(icon .. " Prettier on save " .. status .. " globally", "info")
          else
            print("🎨 Prettier on save " .. status .. " globally")
          end
          
          -- Update statusline to show change
          vim.cmd('redrawstatus')
        end,
        desc = "Toggle prettier format on save globally",
      },
      {
        "<leader>far",
        function()
          vim.g.ruff_format_on_save_enabled = not vim.g.ruff_format_on_save_enabled
          local status = vim.g.ruff_format_on_save_enabled and "✅ ENABLED" or "❌ DISABLED"
          local icon = vim.g.ruff_format_on_save_enabled and "🐍" or "🚫"
          
          -- Use custom notification if available, otherwise print
          if _G.format_notify then
            _G.format_notify(icon .. " Ruff format on save " .. status .. " globally", "info")
          else
            print("🐍 Ruff format on save " .. status .. " globally")
          end
          
          -- Update statusline to show change
          vim.cmd('redrawstatus')
        end,
        desc = "Toggle ruff format on save globally",
      },
      {
        "<leader>fa",
        function()
          local prettier_status = vim.g.prettier_on_save_enabled and "🎨 ✅" or "🎨 ❌"
          local eslint_status = vim.g.eslint_fix_on_save_enabled and "🔧 ✅" or "🔧 ❌"
          local ruff_status = vim.g.ruff_format_on_save_enabled and "🐍 ✅" or "🐍 ❌"
          local format_status = vim.g.format_on_save_enabled and "📝 ✅" or "📝 ❌"
          local lint_status = vim.g.lint_on_save_enabled and "🔍 ✅" or "🔍 ❌"
          
          local auto_save_ok, auto_save_config = pcall(require, "auto-save.config")
          local autosave_status = (auto_save_ok and auto_save_config.opts.enabled) and "💾 ✅" or "💾 ❌"
          
          print("═══════════════════════════════════")
          print("    🚀 AUTO FORMAT STATUS 🚀")
          print("═══════════════════════════════════")
          print("  " .. prettier_status .. "  <leader>fap - Prettier on save")
          print("  " .. eslint_status .. "  <leader>fae - ESLint fix on save")
          print("  " .. ruff_status .. "  <leader>far - Ruff format on save")
          print("  " .. format_status .. "  <leader>fs  - Format on save (general)")
          print("  " .. lint_status .. "  <leader>ls  - Lint on save")
          print("  " .. autosave_status .. "  <leader>as  - Auto-save")
          print("═══════════════════════════════════")
        end,
        desc = "Show auto format status and commands",
      },
    },
    config = function()
      local conform = require("conform")
      
      -- Disable format on save by default
      vim.g.format_on_save_enabled = false
      vim.g.prettier_on_save_enabled = false
      vim.g.ruff_format_on_save_enabled = false
      
      conform.setup({
        formatters_by_ft = {
          javascript = { "prettier" },
          typescript = { "prettier" },
          javascriptreact = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          html = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          less = { "prettier" },
          markdown = { "prettier" },
          yaml = { "prettier" },
          yml = { "prettier" },
          python = { "ruff_format" },
          lua = { "stylua" },
        },
        formatters = {
          prettier = {
            command = "prettier",
            args = { "--stdin-filepath", "$FILENAME" },
            stdin = true,
            cwd = require("conform.util").root_file({
              -- Prettier config files in order of precedence
              ".prettierrc",
              ".prettierrc.json",
              ".prettierrc.yml",
              ".prettierrc.yaml",
              ".prettierrc.json5",
              ".prettierrc.js",
              ".prettierrc.cjs",
              ".prettierrc.mjs",
              ".prettierrc.toml",
              "prettier.config.js",
              "prettier.config.cjs",
              "prettier.config.mjs",
              "package.json",
            }),
          },
        },
        format_on_save = function(bufnr)
          local filetype = vim.bo[bufnr].filetype
          
          -- Check specific formatters first
          if filetype == "python" and vim.g.ruff_format_on_save_enabled then
            return {
              timeout_ms = 500,
              lsp_fallback = true,
            }
          end
          
          -- Check if format on save is globally enabled OR prettier is specifically enabled
          if not vim.g.format_on_save_enabled and not vim.g.prettier_on_save_enabled then
            return
          end
          return {
            timeout_ms = 500,
            lsp_fallback = true,
          }
        end,
      })
    end,
  },
  -- Use nvim-lint for linting
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "<leader>ls",
        function()
          vim.g.lint_on_save_enabled = not vim.g.lint_on_save_enabled
          print("Lint on save " .. (vim.g.lint_on_save_enabled and "enabled" or "disabled") .. " globally")
        end,
        desc = "Toggle lint on save globally",
      },
      {
        "<leader>fae",
        function()
          vim.g.eslint_fix_on_save_enabled = not vim.g.eslint_fix_on_save_enabled
          local status = vim.g.eslint_fix_on_save_enabled and "✅ ENABLED" or "❌ DISABLED"
          local icon = vim.g.eslint_fix_on_save_enabled and "🔧" or "🚫"
          
          -- Use custom notification if available, otherwise print
          if _G.format_notify then
            _G.format_notify(icon .. " ESLint fix on save " .. status .. " globally", "info")
          else
            print("🔧 ESLint fix on save " .. status .. " globally")
          end
          
          -- Update statusline to show change
          vim.cmd('redrawstatus')
        end,
        desc = "Toggle eslint fix on save globally",
      },
    },
    config = function()
      local lint = require("lint")
      
      -- Disable lint on save by default
      vim.g.lint_on_save_enabled = false
      vim.g.eslint_fix_on_save_enabled = false
      
      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        vue = { "eslint_d" },
        svelte = { "eslint_d" },
        python = { "ruff" },
      }
      
      -- Configure eslint_d with full path and comprehensive project config detection
      lint.linters.eslint_d.cmd = "/Users/nikitalutsai/.nvm/versions/node/v20.18.0/bin/eslint_d"
      lint.linters.eslint_d.args = {
        "--no-warn-ignored",
        "--format",
        "json",
        "--stdin",
        "--stdin-filename",
        function()
          return vim.api.nvim_buf_get_name(0)
        end,
      }
      
      -- Function to find project root with ESLint config (comprehensive list)
      local function find_eslint_config_root()
        local config_files = {
          -- New flat config files (ESLint 9+)
          "eslint.config.js",
          "eslint.config.mjs",
          "eslint.config.cjs",
          "eslint.config.ts",
          "eslint.config.mts",
          "eslint.config.cts",
          -- Legacy config files
          ".eslintrc",
          ".eslintrc.js",
          ".eslintrc.cjs",
          ".eslintrc.mjs",
          ".eslintrc.json",
          ".eslintrc.yaml",
          ".eslintrc.yml",
          -- Package.json with eslintConfig
          "package.json",
        }
        
        local current_dir = vim.fn.expand("%:p:h")
        while current_dir ~= "/" do
          for _, config_file in ipairs(config_files) do
            local config_path = current_dir .. "/" .. config_file
            if vim.fn.filereadable(config_path) == 1 then
              -- For package.json, check if it has eslintConfig
              if config_file == "package.json" then
                local ok, package_content = pcall(vim.fn.readfile, config_path)
                if ok and package_content then
                  local content = table.concat(package_content, "\n")
                  if string.find(content, '"eslintConfig"') then
                    return current_dir
                  end
                end
              else
                return current_dir
              end
            end
          end
          current_dir = vim.fn.fnamemodify(current_dir, ":h")
        end
        return nil
      end
      
      -- Set cwd for eslint_d to project root
      lint.linters.eslint_d.cwd = find_eslint_config_root
      
      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })
      
      -- Auto-lint on save, enter, and insert leave
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        group = lint_augroup,
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          
          -- Check if ESLint fix on save is enabled globally
          if vim.g.eslint_fix_on_save_enabled then
            local filetype = vim.bo[bufnr].filetype
            local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
            
            if vim.tbl_contains(js_filetypes, filetype) then
              local filename = vim.api.nvim_buf_get_name(bufnr)
              if filename and filename ~= '' then
                local eslint_cmd = '/Users/nikitalutsai/.nvm/versions/node/v20.18.0/bin/eslint_d --fix ' .. vim.fn.shellescape(filename)
                vim.fn.system(eslint_cmd)
                vim.cmd('edit!') -- Reload the file to show changes
              end
            end
          end
          
          -- Only lint if globally enabled
          if vim.g.lint_on_save_enabled then
            lint.try_lint()
          end
        end,
      })
      
      -- Auto-lint on buffer enter and insert leave (for real-time feedback)
      vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
        group = lint_augroup,
        callback = function()
          if vim.g.lint_on_save_enabled then
            lint.try_lint()
          end
        end,
      })
      
      -- Manual lint trigger
      vim.keymap.set("n", "<leader>l", function()
        lint.try_lint()
      end, { desc = "Trigger linting for current file" })
    end,
  },
}