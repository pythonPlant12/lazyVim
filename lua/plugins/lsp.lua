local resolver = require("config.lsp_resolver")

local function max_popup_size()
  return math.floor(vim.o.columns * 0.5), math.floor(vim.o.lines * 0.3)
end

local function command_check_lsp()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then
    vim.notify("No file in current buffer", vim.log.levels.WARN, { title = "CheckLsp" })
    return
  end

  local frontend_roots = {
    vtsls = resolver.nearest_root_by_markers(bufnr, resolver.frontend_markers.vtsls),
    vue_ls = resolver.nearest_root_by_markers(bufnr, resolver.frontend_markers.vue_ls),
    eslint = resolver.eslint_root(bufnr),
  }

  local py_root, py_source = resolver.python_root_info(bufnr)
  local py_venv = resolver.python_venv_for_root(py_root)
  local py_exec = resolver.python_exec_from_venv(py_venv, "python")
  local ruff_exec = resolver.python_exec_from_venv(py_venv, "ruff")

  local lines = {
    "cwd: " .. resolver.workspace_root(),
    "file: " .. file,
    "",
    "computed roots:",
    "  vtsls  -> " .. frontend_roots.vtsls,
    "  vue_ls -> " .. frontend_roots.vue_ls,
    "  eslint -> " .. frontend_roots.eslint,
    "  python-lsp -> " .. py_root .. " [" .. py_source .. "]",
    "  ruff    -> " .. py_root .. " [" .. py_source .. "]",
    "",
    "python executables:",
    "  python -> " .. (py_exec or "python (PATH/default)"),
    "  ruff   -> " .. (ruff_exec or "ruff (PATH/default)"),
    "",
    "attached clients:",
  }

  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    lines[#lines + 1] = "  (none)"
  else
    for _, client in ipairs(clients) do
      local client_root = client.root_dir
      if (not client_root or client_root == "") and type(client.config) == "table" and type(client.config.root_dir) == "string" then
        client_root = client.config.root_dir
      end
      local display_root = (client_root and client_root ~= "") and client_root or "(none)"
      lines[#lines + 1] = string.format("  %s -> %s", client.name, display_root)
    end
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "CheckLsp" })
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "stylua",
        "selene",
        "luacheck",
        "shellcheck",
        "shfmt",
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts = opts or {}
      opts.servers = opts.servers or {}
      opts.diagnostics = opts.diagnostics or {}
      opts.diagnostics.signs = false
      -- Disable LSP fold ranges: they override treesitter foldexpr asynchronously,
      -- causing `zc` to find no folds on html/vue/css until the LSP responds.
      -- Treesitter folds work immediately and reliably for all these filetypes.
      opts.folds = { enabled = false }
      return opts
    end,
    init = function()
      if vim.fn.exists(":CheckLsp") == 0 then
        vim.api.nvim_create_user_command("CheckLsp", command_check_lsp, {
          desc = "Show LSP root resolution for current buffer",
        })
      end

      vim.keymap.set("c", "check-lsp", function()
        if vim.fn.getcmdtype() == ":" then
          return "CheckLsp"
        end
        return "check-lsp"
      end, { expr = true, noremap = true, silent = true, desc = "Alias :check-lsp to :CheckLsp" })

      local max_width, max_height = max_popup_size()

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

      vim.api.nvim_set_hl(0, "@lsp.type.component", { link = "@type" })
    end,
  },
}
