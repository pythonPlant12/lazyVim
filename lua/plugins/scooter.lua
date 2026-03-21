local scooter_term = nil

_G.EditLineFromScooter = function(file_path, line)
  if scooter_term and scooter_term:buf_valid() then
    scooter_term:hide()
  end

  local current_path = vim.fn.expand("%:p")
  local target_path = vim.fn.fnamemodify(file_path, ":p")
  if current_path ~= target_path then
    vim.cmd.edit(vim.fn.fnameescape(file_path))
  end
  vim.api.nvim_win_set_cursor(0, { line, 0 })
end

local function is_terminal_running(term)
  if not term or not term:buf_valid() then
    return false
  end
  local channel = vim.fn.getbufvar(term.buf, "terminal_job_id")
  return channel and vim.fn.jobwait({ channel }, 0)[1] == -1
end

local function open_scooter(opts)
  opts = opts or {}
  if not opts.force_new and is_terminal_running(scooter_term) then
    scooter_term:toggle()
    return
  end
  if scooter_term and scooter_term:buf_valid() then
    scooter_term:close()
  end
  local cmd = "scooter"
  if opts.args then
    cmd = cmd .. " " .. opts.args
  end
  scooter_term = require("snacks").terminal.open(cmd, {
    win = { position = "float" },
  })
end

local function open_scooter_for_file(search_text)
  local file = vim.fn.expand("%:t")
  if file == "" then
    return
  end
  local args = "-I " .. vim.fn.shellescape(file)
  if search_text then
    args = args .. " --fixed-strings --search-text " .. vim.fn.shellescape(search_text:gsub("\r?\n", " "))
  end
  open_scooter({ force_new = true, args = args })
end

local function open_scooter_with_text(search_text)
  open_scooter({ force_new = true, args = "--fixed-strings --search-text " .. vim.fn.shellescape(search_text:gsub("\r?\n", " ")) })
end

return {
  { "MagicDuck/grug-far.nvim", enabled = false },

  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>sr",
        function() open_scooter() end,
        desc = "Search and Replace (Scooter)",
      },
      {
        "<leader>sr",
        function()
          local selection = vim.fn.getreg('"')
          vim.cmd('normal! "ay')
          open_scooter_with_text(vim.fn.getreg("a"))
          vim.fn.setreg('"', selection)
        end,
        mode = "v",
        desc = "Search selected text (Scooter)",
      },
      {
        "<leader>sf",
        function() open_scooter_for_file() end,
        desc = "Search and Replace in File (Scooter)",
      },
      {
        "<leader>sf",
        function()
          local selection = vim.fn.getreg('"')
          vim.cmd('normal! "ay')
          open_scooter_for_file(vim.fn.getreg("a"))
          vim.fn.setreg('"', selection)
        end,
        mode = "v",
        desc = "Search selected text in File (Scooter)",
      },
    },
  },
}
