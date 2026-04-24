return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "bacon",
        "bacon-ls",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}

      -- bacon-ls: continuous background checker (replaces checkOnSave flow)
      -- Reads diagnostics produced by `bacon` running in the background.
      -- Start bacon in your project root: `bacon`
      opts.servers.bacon_ls = vim.tbl_deep_extend("force", opts.servers.bacon_ls or {}, {
        enabled = true,
        -- bacon-ls locates bacon's output automatically via .bacon-locations
        settings = {
          ["bacon-ls"] = {
            updateOnSave = false,
            updateOnSaveWaitMillis = 0,
            autoStart = true,
          },
        },
      })

      -- rust-analyzer: enable inline (non-checkOnSave) diagnostics
      -- checkOnSave is turned off in lang-rust.lua so bacon owns cargo check.
      opts.servers.rust_analyzer = vim.tbl_deep_extend("force", opts.servers.rust_analyzer or {}, {
        settings = {
          ["rust-analyzer"] = {
            diagnostics = {
              enable = true,
              -- Borrow checker, type inference, and other native RA diagnostics
              -- that update in real-time without saving.
              experimental = {
                enable = true,
              },
            },
          },
        },
      })

      return opts
    end,
  },
}
