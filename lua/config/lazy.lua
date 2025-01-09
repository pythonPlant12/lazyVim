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
    { import = "lazyvim.plugins.extras.lang.python" },
    -- import/override with your plugins
    { import = "plugins" },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = "BufReadPost",
      dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
      opts = {
        highlight = {
          -- Your existing highlight configuration
        },
        rainbow = {
          enable = true,
          extended_mode = true,
          max_file_lines = nil,
        },
      },
    },
    -- Plugin for multiple cursors
    {
      "terryma/vim-multiple-cursors",
    },
    -- Plugin and configuration for neo-tree
    {
      "nvim-neo-tree/neo-tree.nvim",
      opts = {
        filesystem = {
          filtered_items = {
            visible = true,
            show_hidden_count = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      },
    },
    -- Configure telescope.nvim
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.6",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        require("telescope").setup({
          defaults = {
            file_ignore_patterns = { ".git/" },
            vimgrep_arguments = {
              "rg",
              "--no-heading",
              "--with-filename",
              "--line-number",
              "--column",
              "--smart-case",
            },
          },
          extensions = {
            media_files = {
              -- filetypes whitelist
              -- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
              filetypes = { "png", "webp", "jpg", "jpeg" },
              -- find command (defaults to `fd`)
              find_cmd = "rg",
            },
          },
        })

        -- Bind <space><space> to Telescope find_files
        vim.api.nvim_set_keymap("n", "<space><space>", ":Telescope find_files<CR>", { noremap = true, silent = true })

        -- Optional: Load project extension if using project.nvim
        -- require('telescope').load_extension('projects')
      end,
    },

    -- Transparent Background on NVIM
    -- { "xiyaowong/transparent.nvim" },

    -- Theme
    -- {
    --   "xiantang/darcula-dark.nvim",
    --   name = "darcula-dark",
    --   priority = 1000, -- High priority to load before other plugins
    --   dependencies = {
    --     "nvim-treesitter/nvim-treesitter",
    --   },
    --   config = function()
    --     -- Apply the theme
    --     vim.cmd("colorscheme darcula-dark")
    --   end,
    -- },
    -- Underline same word
    {
      "RRethy/vim-illuminate",
      config = function()
        require("illuminate").configure({
          -- Configuration options for the vim-illuminate plugin
          -- You can customize the behavior as needed
          delay = 100,
          increment_at_cursor = true,
        })
      end,
    },
    -- Nvim DAP for python debugging
    {
      "mfussenegger/nvim-dap",
      config = function() end,
    },
    -- venv-selector plugin
    "mfussenegger/nvim-dap-python",
    {
      "linux-cultist/venv-selector.nvim",
      dependencies = { "neovim/nvim-lspconfig", "nvim-telescope/telescope.nvim" },
      config = function()
        require("venv-selector").setup({
          name = {
            "venv",
            ".venv",
            "env",
            ".env",
          },
          dap_enabled = false,
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
vim.api.nvim_set_keymap(
  "n",
  "<leader>gg",
  ':lua require("lazyvim.util.terminal").lazygit()<CR>',
  { noremap = true, silent = true }
)
