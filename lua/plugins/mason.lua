return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        -- LSP servers
        "ansible-language-server",
        "angular-language-server", 
        "lua-language-server",
        "python-lsp-server",
        "rust-analyzer",
        "sqlls",
        "typescript-language-server",
        "vtsls",
        "vue-language-server",
        "yaml-language-server",
        
        -- DAP adapters
        "codelldb",
        "js-debug-adapter",
        
        -- Formatters
        "prettier",
        "shfmt",
        "stylua",
        
        -- Linters
        "ruff",
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "ansiblels",
        "angularls",
        "lua_ls",
        "pylsp",
        "rust_analyzer",
        "sqlls",
        "ts_ls",
        "vtsls",
        "volar",
        "yamlls",
      },
    },
  },
}