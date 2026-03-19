return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "stylua",
        "selene",
        "luacheck",
        "shellcheck",
        "shfmt",
        "tailwindcss-language-server",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pylsp = {
          enabled = false,
        },
        eslint = {
          settings = {
            format = true,
          },
        },
        vtsls = {
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
            "html",
          },
          on_attach = function(client, bufnr)
            if vim.bo[bufnr].filetype == "html" then
              client.server_capabilities.documentHighlightProvider = false
            end
          end,
        },
      },
    },
    init = function()
      local max_width = math.floor(vim.o.columns * 0.5)
      local max_height = math.floor(vim.o.lines * 0.3)

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
    end,
  },
}
