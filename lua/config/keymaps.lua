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

-- Jumplist
keymaps.set("n", "<C-m>", "<C-i>", opts)

-- Add new line below without entering insert mode and move cursor there
vim.keymap.set('n', '<CR>', 'o<Esc>')

-- Add new line and move text from cursor to new line
vim.keymap.set('n', '<S-CR>', 'i<CR><Esc>')

-- When you press Ctrl-i -> jump backwards (older position)
-- When you press Ctrl-o -> jump forwards (newer position)
vim.keymap.set('n', '<C-i>', '<C-o>', { noremap = true, desc = "Jump backward (older position)" })
vim.keymap.set('n', '<C-o>', '<C-i>', { noremap = true, desc = "Jump forward (newer position)" })

-- New tab
keymaps.set("n", "te", "tabedit")
vim.api.nvim_set_keymap("n", "te", ":tabedit<CR>", opts)
vim.api.nvim_set_keymap("n", "tq", ":tabclose<CR>", opts)
keymaps.set("n", "<Tab>", ":tabnext<CR>", opts)
keymaps.set("n", "<s-Tab>", ":tabprev<CR>", opts)

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

keymaps.set("n", "j", "k")
keymaps.set("n", "k", "j")

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
-- Easy escape from terminal mode
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { noremap = true })

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

-- Swap j and k for up and down 
vim.keymap.set('n', 'j', 'k', { noremap = true })
vim.keymap.set('v', 'j', 'k', { noremap = true })

vim.keymap.set('n', 'k', 'j', { noremap = true })
vim.keymap.set('v', 'k', 'j', { noremap = true })

-- Swap j and k for up and down switching for window
vim.keymap.set('n', '<C-w>j', '<C-w>k', { noremap = true })
vim.keymap.set('n', '<C-w>k', '<C-w>j', { noremap = true })

-- In your keymaps.lua or init.lua
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
