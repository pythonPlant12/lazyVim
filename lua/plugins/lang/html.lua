---@diagnostic disable: undefined-global

-- HTML/CSS/Emmet LSP setup, extended to cover Django template filetypes.
local function disable_template_document_highlight(client, bufnr)
  -- Template buffers get noisy document highlights from html/css/emmet servers.
  local ft = vim.bo[bufnr].filetype
  if ft == "html" or ft == "htmldjango" or ft == "jinja" or ft == "jinja2" then
    client.server_capabilities.documentHighlightProvider = false
  end
end

return {
  {
    "mason-org/mason.nvim",
    -- Install the HTML/CSS/Emmet language servers.
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
    -- Extend html/cssls/emmet filetypes to include Django templates.
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}
      -- Django templates share most HTML tooling but use their own filetype.
      local html_filetypes = { "html", "htmldjango" }

      opts.servers.html = vim.tbl_deep_extend("force", opts.servers.html or {}, {
        filetypes = html_filetypes,
        on_attach = disable_template_document_highlight,
      })

      opts.servers.cssls = vim.tbl_deep_extend("force", opts.servers.cssls or {}, {
        filetypes = { "css", "scss", "less", "html", "htmldjango" },
        on_attach = disable_template_document_highlight,
      })

      opts.servers.emmet_language_server = vim.tbl_deep_extend("force", opts.servers.emmet_language_server or {}, {
        filetypes = { "html", "htmldjango", "css", "scss", "less" },
        on_attach = disable_template_document_highlight,
      })

      return opts
    end,
  },
}
