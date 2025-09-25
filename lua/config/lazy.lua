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
    {
      "tpope/vim-surround",
      event = "VeryLazy",
    },

    -- Text objects
    {
      "kana/vim-textobj-user", -- Required for other textobj plugins
      event = "VeryLazy",
    },
    {
      "kana/vim-textobj-entire", -- ae/ie for entire buffer
      dependencies = "kana/vim-textobj-user",
      event = "VeryLazy",
    },
    {
      "vim-scripts/argtextobj.vim", -- aa/ia for function arguments
      event = "VeryLazy",
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
    { import = "lazyvim.plugins.extras.lang.vue" },
    -- import/override with your plugins
    { import = "plugins" },
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      event = "BufReadPost",
      dependencies = {
        "nvim-treesitter/nvim-treesitter-textobjects",
      },
      ensure_installed = {
        "rust",
        "ron"
      },
      opts = {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
        ensure_installed = {
          "bash",
          "c",
          "html",
          "javascript",
          "json",
          "lua",
          "luadoc",
          "luap",
          "python",
          "query",
          "regex",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "vue",
          "yaml",
        },
        rainbow = {
          enable = true,
          extended_mode = true,
          max_file_lines = nil,
        },
      },
    },
    -- Multiple cursors with simple, working configuration
    {
      "mg979/vim-visual-multi",
      lazy = false,  -- Load immediately to avoid timing issues
      init = function()
        -- Configure BEFORE plugin loads
        vim.g.VM_default_mappings = 0  -- Disable all default mappings
        vim.g.VM_maps = {
          -- Exit multiple cursor mode
          ["Exit"] = "<Esc>",
        }
        vim.g.VM_set_statusline = 0
        vim.g.VM_silent_exit = 1
      end,
      config = function()
        -- Additional keymaps using Neovim's keymap function for reliability
        vim.keymap.set({'n', 'v'}, '<leader>mw', '<Plug>(VM-Find-Under)', { desc = "Select word under cursor" })
        vim.keymap.set({'n', 'v'}, '<leader>mk', '<Plug>(VM-Add-Cursor-Down)', { desc = "Add cursor below" })
        vim.keymap.set({'n', 'v'}, '<leader>mj', '<Plug>(VM-Add-Cursor-Up)', { desc = "Add cursor above" })
        vim.keymap.set({'n', 'v'}, '<leader>mc', '<Plug>(VM-Add-Cursor-At-Pos)', { desc = "Add cursor at current position" })
        vim.keymap.set({'n', 'v'}, '<leader>ma', '<Plug>(VM-Select-All)', { desc = "Select all occurrences" })
        vim.keymap.set({'n', 'v'}, '<leader>mx', '<Plug>(VM-Skip-Region)', { desc = "Skip current selection" })
        vim.keymap.set({'n', 'v'}, '<leader>mq', '<Plug>(VM-Remove-Region)', { desc = "Remove current cursor" })
      end,
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

        -- Store the initial startup directory
        local startup_cwd = vim.fn.getcwd()
        
        -- Bind <space><space> to Telescope find_files from startup directory
        vim.keymap.set("n", "<space><space>", function()
          require("telescope.builtin").find_files({ cwd = startup_cwd })
        end, { noremap = true, silent = true })
        
        -- Bind <leader><leader> to Telescope find_files from startup directory
        vim.keymap.set("n", "<leader><leader>", function()
          require("telescope.builtin").find_files({ cwd = startup_cwd })
        end, { noremap = true, silent = true })
        
        -- Bind <leader>ff to Telescope find_files from startup directory
        vim.keymap.set("n", "<leader>ff", function()
          require("telescope.builtin").find_files({ cwd = startup_cwd })
        end, { noremap = true, silent = true })

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
    -- {
    --   "RRethy/vim-illuminate",
    --   config = function()
    --     require("illuminate").configure({
    --       -- Configuration options for the vim-illuminate plugin
    --       -- You can customize the behavior as needed
    --       delay = 100,
    --       increment_at_cursor = true,
    --     })
    --   end,
    -- },
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
    -- Rust packages
    {
      "Saecki/crates.nvim",
      event = { "BufRead Cargo.toml" },
      opts = {
        completion = {
          crates = {
            enabled = true,
          },
        },
        lsp = {
          enabled = false,  -- Disable to prevent duplicate rust-analyzer
          actions = false,
          completion = false,
          hover = false,
        },
      },
    },
    -- Vim bookmarks
    {
      "MattesGroeger/vim-bookmarks",
      config = function()
        vim.g.bookmark_sign = '⚑'
        vim.g.bookmark_annotation_sign = '☰'
        vim.g.bookmark_auto_save = 1
        vim.g.bookmark_auto_close = 1
        vim.g.bookmark_highlight_lines = 1
        vim.g.bookmark_show_warning = 0
        vim.g.bookmark_center = 1
      end,
    },
    -- Better quickfix window
    {
      "kevinhwang91/nvim-bqf",
      ft = "qf",
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

-- Add serpl (search and replace) keybindings
vim.keymap.set("n", "<leader>sr", function()
  -- Search from the root where vim was opened
  local startup_cwd = vim.fn.fnamemodify(vim.fn.argv()[1] or ".", ":p:h")
  if vim.fn.isdirectory(startup_cwd) == 0 then
    startup_cwd = vim.fn.getcwd()
  end
  LazyVim.terminal("serpl --project-root " .. vim.fn.shellescape(startup_cwd), { cwd = startup_cwd })
end, { desc = "Search and Replace from root (serpl)" })

vim.keymap.set("n", "<leader>sf", function()
  -- Search only in current file, do nothing if no buffer is open
  local current_file = vim.fn.expand("%:p")
  if current_file == "" or vim.fn.filereadable(current_file) == 0 then
    vim.notify("No file open in current buffer", vim.log.levels.WARN)
    return
  end
  
  -- Create a temporary directory with only the current file for serpl to search
  local file_dir = vim.fn.fnamemodify(current_file, ":h")
  local filename = vim.fn.fnamemodify(current_file, ":t")
  
  -- Use serpl with project root set to the file's directory
  LazyVim.terminal("serpl --project-root " .. vim.fn.shellescape(file_dir), { cwd = file_dir })
end, { desc = "Search in current file directory (serpl)" })
