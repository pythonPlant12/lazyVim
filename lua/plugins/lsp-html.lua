---@diagnostic disable: undefined-global

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "html-lsp",
        "css-lsp",
        "emmet-language-server",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}
      local html_filetypes = { "html", "htmldjango" }

      opts.servers.html = vim.tbl_deep_extend("force", opts.servers.html or {}, {
        filetypes = html_filetypes,
      })

      opts.servers.cssls = vim.tbl_deep_extend("force", opts.servers.cssls or {}, {
        filetypes = { "css", "scss", "less", "html", "htmldjango" },
      })

      opts.servers.emmet_language_server = vim.tbl_deep_extend("force", opts.servers.emmet_language_server or {}, {
        filetypes = { "html", "htmldjango", "css", "scss", "less" },
      })

      return opts
    end,
  },
}
