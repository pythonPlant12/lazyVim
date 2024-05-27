local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = "catppuccin",
      },
    },
    -- import any extras modules here
    { import = "lazyvim.plugins.extras.linting.eslint" },
    { import = "lazyvim.plugins.extras.formatting.prettier" },
    { import = "lazyvim.plugins.extras.util.mini-hipatterns" },
    { import = "lazyvim.plugins.extras.coding.copilot" },
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.tailwind" },
    -- { import = "lazyvim.plugins.extras.lang.python" },
    -- import/override with your plugins
    { import = "plugins" },

    -- Configure telescope.nvim
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.6",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require('telescope').setup{
          defaults = {
            file_ignore_patterns = {".git/"},
            vimgrep_arguments = {
              'rg',
              '--color=never',
              '--no-heading',
              '--with-filename',
              '--line-number',
              '--column',
              '--smart-case'
            },
          },
        }

        -- Bind <space><space> to Telescope find_files
        vim.api.nvim_set_keymap('n', '<space><space>', ':Telescope find_files<CR>', { noremap = true, silent = true })

        -- Optional: Load project extension if using project.nvim
        -- require('telescope').load_extension('projects')
      end
    },

    -- Transparent Background on NVIM
    { "xiyaowong/transparent.nvim" },

    -- Catpuccin Theme
    {
      "catppuccin/nvim",
      name = "catppuccin",
      priority = 1000,
      config = function()
        -- Catppuccin configuration
        require("catppuccin").setup({
          flavour = "mocha", -- latte, frappe, macchiato, mocha
          term_colors = true,
          integrations = {
            treesitter = true,
            native_lsp = {
              enabled = true,
              virtual_text = {
                errors = { "italic" },
                hints = { "italic" },
                warnings = { "italic" },
                information = { "italic" },
              },
              underlines = {
                errors = { "underline" },
                hints = { "underline" },
                warnings = { "underline" },
                information = { "underline" },
              },
            },
            -- other integrations you want to enable
          },
        })

        -- Apply the theme
        vim.cmd("colorscheme catppuccin")
      end,
    },

    -- venv-selector plugin
    {
      "linux-cultist/venv-selector.nvim",
      dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim", "mfussenegger/nvim-dap-python" },
      config = function()
        require("venv-selector").setup({
          name = {
            "venv",
            ".venv",
            "env",
            ".env",
          },
          dap_enabled = true,
        })
      end,
      event = "VeryLazy", -- Optional: needed only if you want to type `:VenvSelect` without a keymapping
      keys = {
        -- Keymap to open VenvSelector to pick a venv.
        { "<leader>vs", "<cmd>VenvSelect<cr>" },
        -- Keymap to retrieve the venv from a cache (the one previously used for the same project directory).
        { "<leader>vc", "<cmd>VenvSelectCached<cr>" },
      },
    },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  checker = { enabled = true }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- vim.opt.number = true -- Enable line numbers
-- vim.opt.relativenumber = false -- Disable relative line numbers

-- Add LazyGit configuration
vim.api.nvim_set_keymap('n', '<leader>gg', ':lua require("lazyvim.util.terminal").lazygit()<CR>', { noremap = true, silent = true })
