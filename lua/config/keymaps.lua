-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local keymaps = vim.keymap
local opts = { noremap = true, silent = true }

-- Increment/decrement
keymaps.set("n", "+", "C-a")
keymaps.set("n", "-", "C-x")

-- Select all
keymaps.set("n", "<C-a>", "gg<S-v>G")

-- Add new line below without entering insert mode and move cursor there
vim.keymap.set('n', '<CR>', 'o<Esc>')

-- Add new line and move text from cursor to new line
vim.keymap.set('n', '<S-CR>', 'i<CR><Esc>')

-- When you press <leader>-i -> jump backwards (older position)
-- When you press <leader>-o -> jump forwards (newer position)
vim.keymap.set('n', '<leader>i', '<C-o>', { noremap = true, desc = "Jump backward" })
vim.keymap.set('n', '<leader>o', '<C-i>', { noremap = true, desc = "Jump forward" })

-- New tab
keymaps.set("n", "te", "tabedit")
vim.api.nvim_set_keymap("n", "te", ":tabedit<CR>", opts)
vim.api.nvim_set_keymap("n", "tq", ":tabclose<CR>", opts)
-- Tab indentation keymaps for all modes
-- Normal mode: Tab to indent, Shift+Tab to unindent
keymaps.set("n", "<Tab>", ">>", opts)
keymaps.set("n", "<S-Tab>", "<<", opts)

-- Insert mode: Force Shift+Tab to unindent (override completion plugin)
keymaps.set("i", "<S-Tab>", "<C-d>", { noremap = true, silent = true })

-- Visual mode: Tab to indent selection, Shift+Tab to unindent selection
keymaps.set("v", "<Tab>", ">gv", opts)
keymaps.set("v", "<S-Tab>", "<gv", opts)

-- Fix delete key behavior in insert mode (works on both Linux and macOS)
-- Map Delete key to delete character to the right of cursor

-- Function to delete character to the right
local function delete_char_right()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  
  if col < #line then
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col + 1, {})
  end
end

-- Comprehensive Delete key mapping for macOS and Linux
-- Map all possible key codes that could be the "Delete" key

-- Standard delete key codes
keymaps.set("i", "<Del>", delete_char_right, { noremap = true, silent = true })
keymaps.set("i", "<kDel>", delete_char_right, { noremap = true, silent = true })

-- macOS specific combinations
keymaps.set("i", "<D-BS>", delete_char_right, { noremap = true, silent = true })  -- Cmd + Backspace
keymaps.set("i", "<M-BS>", delete_char_right, { noremap = true, silent = true })  -- Alt + Backspace
keymaps.set("i", "<C-BS>", delete_char_right, { noremap = true, silent = true })  -- Ctrl + Backspace

-- Terminal escape sequences
keymaps.set("i", "<Esc>[3~", delete_char_right, { noremap = true, silent = true })
keymaps.set("i", "<Esc>[P", delete_char_right, { noremap = true, silent = true })

-- Alternative approach: use Ctrl+D as forward delete (common vim convention)
keymaps.set("i", "<C-d>", delete_char_right, { noremap = true, silent = true })

-- Test key to verify the function works
keymaps.set("i", "<F9>", delete_char_right, { noremap = true, silent = true })  -- Test with F9

-- LSP suggestion keymaps
-- Trigger completion manually (works with blink.cmp)
keymaps.set("i", "<C-n>", function()
  -- Try blink.cmp first (LazyVim's default)
  local ok, blink = pcall(require, 'blink.cmp')
  if ok and blink then
    if blink.is_visible() then
      blink.select_next()
    else
      blink.show()
    end
  else
    -- Try nvim-cmp as fallback
    local ok2, cmp = pcall(require, 'cmp')
    if ok2 and cmp then
      if cmp.visible() then
        cmp.select_next_item()
      else
        cmp.complete()
      end
    else
      -- Final fallback to built-in completion
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-x><C-o>", true, false, true), "n", false)
    end
  end
end, { noremap = true, silent = true, desc = "Show/navigate LSP suggestions" })

-- Move lines up/down with Ctrl+Shift+Arrow keys
-- Normal mode: move current line
keymaps.set("n", "<C-S-Up>", ":m .-2<CR>==", { noremap = true, silent = true, desc = "Move line up" })
keymaps.set("n", "<C-S-Down>", ":m .+1<CR>==", { noremap = true, silent = true, desc = "Move line down" })

-- Visual mode: move selected lines
keymaps.set("v", "<C-S-Up>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection up" })
keymaps.set("v", "<C-S-Down>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true, desc = "Move selection down" })

-- Insert mode: move current line and stay in insert mode
keymaps.set("i", "<C-S-Up>", "<Esc>:m .-2<CR>==gi", { noremap = true, silent = true, desc = "Move line up" })
keymaps.set("i", "<C-S-Down>", "<Esc>:m .+1<CR>==gi", { noremap = true, silent = true, desc = "Move line down" })

-- Split window
keymaps.set("n", "ss", ":split<Return>", opts)
keymaps.set("n", "sv", ":vsplit<Return>", opts)

-- Resize window
keymaps.set("n", "<C-w><left>", "<C-w><")
keymaps.set("n", "<C-w><right>", "<C-w>>")
keymaps.set("n", "<C-w><up>", "<C-w>+")
keymaps.set("n", "<C-w><up>", "<C-w>-")

-- Diagnostics
keymaps.set("n", "<C-j>", function()
  vim.diagnostic.goto_next()
end, opts)

-- Delete everything before cursor but preserve indentation
vim.keymap.set('n', 'dB', 'ma^y0`ad^', { noremap = true })

-- Delete everything after cursor
vim.keymap.set('n', 'dW', 'D', { noremap = true })

-- Override "d" and its combinations to delete without yanking in normal mode
keymaps.set("n", "d", '"_d')
keymaps.set("n", "dd", '"_dd')
keymaps.set("n", "dw", '"_dw')
keymaps.set("n", "db", '"_db')


-- Override "d" and its combinations to delete without yanking in visual mode
keymaps.set("x", "d", '"_d')
keymaps.set("x", "dd", '"_dd')
keymaps.set("x", "dw", '"_dw')
keymaps.set("x", "db", '"_db')

-- Override "d" and its combinations to delete without yanking in operator pending mode
keymaps.set("o", "d", '"_d')
keymaps.set("o", "dd", '"_dd')
keymaps.set("o", "dw", '"_dw')
keymaps.set("o", "db", '"_db')

-- Moving throught window with arrow keys
vim.api.nvim_set_keymap('n', '<C-w><Left>', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-w><Down>', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-w><Up>', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-w><Right>', '<C-w>l', { noremap = true, silent = true })


-- Open termianl in new tab
vim.keymap.set('n', '<leader>t', ':tabnew | term<CR>', { noremap = true })
-- -- Easy escape from terminal mode
-- vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

-- These might be in your LSP config
vim.keymap.set('n', 'gD', vim.lsp.buf.declaration)
vim.keymap.set('n', 'gd', vim.lsp.buf.definition)
vim.keymap.set('n', 'K', vim.lsp.buf.hover)
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation)
vim.keymap.set('n', 'gr', vim.lsp.buf.references)

-- Map Shift+B to go to end of line
vim.keymap.set('n', 'B', '^', { noremap = true })
vim.keymap.set('v', 'B', '^', { noremap = true })

-- Map Shift+A to go to beginning of line
vim.keymap.set('n', 'W', '$', { noremap = true })
vim.keymap.set('v', 'W', '$', { noremap = true })

-- Swap j and k for up and down movement with end of line positioning
-- But exclude special buffers like NeoTree, quickfix, etc.
local function setup_navigation_keys()
  -- Check if current buffer should use normal navigation
  local function should_use_normal_nav()
    local filetype = vim.bo.filetype
    local buftype = vim.bo.buftype
    
    -- Exclude these filetypes from end-of-line navigation
    local excluded_filetypes = {
      'neo-tree',
      'NvimTree',
      'qf',
      'quickfix',
      'help',
      'man',
      'lspinfo',
      'telescope',
      'toggleterm',
      'terminal',
      'oil',
      'alpha',
      'dashboard',
      'startify',
      'fugitive',
      'git',
      'DiffviewFiles',
      'DiffviewFileHistory',
    }
    
    -- Exclude these buffer types
    local excluded_buftypes = {
      'quickfix',
      'help',
      'nofile',
      'terminal',
    }
    
    for _, ft in ipairs(excluded_filetypes) do
      if filetype == ft then
        return true
      end
    end
    
    for _, bt in ipairs(excluded_buftypes) do
      if buftype == bt then
        return true
      end
    end
    
    return false
  end
  
  -- Set up the keymaps
  if should_use_normal_nav() then
    -- Use normal j/k navigation for special buffers
    vim.keymap.set('n', 'j', 'k', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', 'j', 'k', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', 'k', 'j', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', 'k', 'j', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', '<Up>', 'k', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', '<Up>', 'k', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', '<Down>', 'j', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', '<Down>', 'j', { noremap = true, silent = true, buffer = true })
  else
    -- Use end-of-line navigation for regular text editing
    vim.keymap.set('n', 'j', 'k$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', 'j', 'k$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', 'k', 'j$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', 'k', 'j$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', '<Up>', 'k$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', '<Up>', 'k$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('n', '<Down>', 'j$', { noremap = true, silent = true, buffer = true })
    vim.keymap.set('v', '<Down>', 'j$', { noremap = true, silent = true, buffer = true })
  end
end

-- Set up navigation keys when entering buffers
vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
  callback = setup_navigation_keys,
})


-- Swap j and k for up and down switching for window
vim.keymap.set('n', '<C-w>j', '<C-w>k', { noremap = true })
vim.keymap.set('n', '<C-w>k', '<C-w>j', { noremap = true })

-- Shortcut for expanding the error lens 
vim.keymap.set('n', 'E', vim.diagnostic.open_float, { noremap = true, silent = true, desc = "Show line diagnostics" })

-- In your keymaps.lua or init.lua
-- Rename the variable from lsp
vim.keymap.set('n', "<leader>r", vim.lsp.buf.rename, { desc = "Rename the variable" })

-- Toggle line comment with Ctrl+/ (using alternative mapping that works in terminals)
vim.keymap.set('n', '<C-_>', function() require('Comment.api').toggle.linewise.current() end, { noremap = true, silent = true, desc = "Toggle line comment" })
vim.keymap.set('v', '<C-_>', "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>", { noremap = true, silent = true, desc = "Toggle selection comment" })

-- Go to line with gl + line number (e.g., gl42 goes to line 42)
vim.keymap.set('n', 'gl', ':', { noremap = true, desc = "Go to line number" })

-- Toggle code folding (fold/unfold current section)
vim.keymap.set('n', '<leader>T', 'za', { noremap = true, silent = true, desc = "Toggle code folding" })

-- Git diff and blame keymaps (using gitsigns)
vim.keymap.set('n', '<leader>gp', ':Gitsigns preview_hunk<CR>', { noremap = true, silent = true, desc = "Preview git hunk diff" })
vim.keymap.set('n', '<leader>gr', ':Gitsigns reset_hunk<CR>', { noremap = true, silent = true, desc = "Reset git hunk (undo changes)" })
vim.keymap.set('n', '<leader>gb', ':Gitsigns toggle_current_line_blame<CR>', { noremap = true, silent = true, desc = "Toggle git blame for current line" })
vim.keymap.set('n', '<leader>gn', ':Gitsigns next_hunk<CR>', { noremap = true, silent = true, desc = "Next git hunk" })
vim.keymap.set('n', '<leader>gP', ':Gitsigns prev_hunk<CR>', { noremap = true, silent = true, desc = "Previous git hunk" })
vim.keymap.set('n', '<leader>gz', ':Gitsigns reset_hunk<CR>', { noremap = true, silent = true, desc = "Revert current git hunk" })

vim.keymap.set('n', '<C-w>z', function()
    if vim.fn.exists('g:zoom_restored') == 0 or vim.g.zoom_restored == 0 then
        -- Save current window state
        vim.g.zoom_winrestcmd = vim.fn.winrestcmd()
        -- Zoom in
        vim.cmd('resize | vertical resize')
        vim.g.zoom_restored = 1
    else
        -- Restore window state
        vim.cmd(vim.g.zoom_winrestcmd)
        vim.g.zoom_restored = 0
    end
end, { noremap = true, silent = true, desc = 'Toggle window zoom' })

-- Fix ESLint issues with eslint_d
vim.keymap.set('n', '<leader>fe', function()
  local filetype = vim.bo.filetype
  local js_filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" }
  
  if vim.tbl_contains(js_filetypes, filetype) then
    -- Run eslint_d with --fix flag using full path
    local filename = vim.fn.expand('%:p')
    if filename and filename ~= '' then
      local eslint_cmd = '/Users/nikitalutsai/.nvm/versions/node/v20.18.0/bin/eslint_d --fix ' .. vim.fn.shellescape(filename)
      vim.fn.system(eslint_cmd)
      vim.cmd('edit!') -- Reload the file to show changes
      print("ESLint fixes applied")
    else
      print("No file to fix")
    end
  else
    print("ESLint not available for this file type")
  end
end, { noremap = true, silent = true, desc = "Fix ESLint issues" })

-- Ensure neo-tree toggle keymap (in case LazyVim default isn't working)
vim.keymap.set('n', '<leader>e', '<cmd>Neotree toggle<cr>', { noremap = true, silent = true, desc = "Toggle Neo-tree" })

-- Open quickfix window
vim.keymap.set('n', '<leader>qf', '<cmd>copen<cr>', { noremap = true, silent = true, desc = "Open quickfix window" })

vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    callback = function()
        vim.keymap.set('n', '<CR>', function()
            -- Get current quickfix item
            local item = vim.fn.getqflist()[vim.fn.line('.')]
            if not item or not item.bufnr then return end

            -- Get full file path from buffer number
            local filename = vim.api.nvim_buf_get_name(item.bufnr)
            if filename == '' then return end

            local lnum = item.lnum
            local col = math.max(0, (item.col or 1) - 1)

            -- Close quickfix
            vim.cmd('cclose')

            -- Open in new buffer (removed enew command)
            vim.cmd('edit ' .. vim.fn.fnameescape(filename))

            -- Set cursor position safely
            vim.schedule(function()
                local bufnr = vim.api.nvim_get_current_buf()
                local line_count = vim.api.nvim_buf_line_count(bufnr)
                local line = math.min(lnum, line_count)
                local line_length = #vim.api.nvim_buf_get_lines(bufnr, line - 1, line, true)[1]
                local column = math.min(col, line_length)
                vim.api.nvim_win_set_cursor(0, {line, column})
            end)
        end, { buffer = true, noremap = true })
    end,
})
