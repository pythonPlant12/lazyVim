local keymaps = vim.keymap

local function set_exact_visual_search(text)
  if not text or text == "" then
    return false
  end
  local escaped = vim.fn.escape(text, "/\\")
  escaped = escaped:gsub("\n", "\\n")
  if text:match("^%w+$") then
    vim.fn.setreg("/", "\\<" .. escaped .. "\\>")
  else
    vim.fn.setreg("/", "\\V" .. escaped)
  end
  vim.cmd("set hlsearch")
  return true
end

local function parse_search_query(input)
  if not input or input == "" then
    return nil
  end

  local has_prefix = false
  local regex = false
  local case_sensitive = false
  local whole_word = false
  local search_text = input

  local colon = input:find(":", 1, true)
  if colon then
    local prefix = vim.trim(input:sub(1, colon - 1)):lower()
    local rest = input:sub(colon + 1)

    if prefix ~= "" then
      local i = 1
      local ok_prefix = true
      while i <= #prefix do
        local two = prefix:sub(i, i + 1)
        local one = prefix:sub(i, i)
        if two == "re" then
          regex = true
          has_prefix = true
          i = i + 2
        elseif one == "c" then
          case_sensitive = true
          has_prefix = true
          i = i + 1
        elseif one == "w" then
          whole_word = true
          has_prefix = true
          i = i + 1
        elseif one == " " then
          i = i + 1
        else
          ok_prefix = false
          break
        end
      end

      if ok_prefix and has_prefix then
        search_text = rest
      end
    end
  end

  search_text = vim.trim(search_text)
  if search_text == "" then
    return nil
  end

  local case_flag = case_sensitive and "\\C" or "\\c"
  local pattern

  if regex then
    pattern = case_flag .. search_text
    if whole_word then
      pattern = case_flag .. "\\<" .. search_text .. "\\>"
    end
  else
    local escaped = vim.fn.escape(search_text, "/\\")
    if whole_word then
      pattern = case_flag .. "\\V\\<" .. escaped .. "\\>"
    else
      pattern = case_flag .. "\\V" .. escaped
    end
  end

  return {
    pattern = pattern,
  }
end

local function set_prefixed_search(input)
  local parsed = parse_search_query(input)
  if not parsed then
    return false
  end

  vim.fn.setreg("/", parsed.pattern)
  vim.fn.histadd("search", parsed.pattern)
  vim.cmd("set hlsearch")
  return true
end

keymaps.set("n", "<Esc>", "<cmd>nohlsearch<cr><Esc>", { desc = "Clear search highlight" })

keymaps.set("n", "/", function()
  local input = vim.fn.input("/ ")
  if not set_prefixed_search(input) then
    return
  end

  local pattern = vim.fn.getreg("/")
  if pattern == "" then
    vim.notify("No search pattern set", vim.log.levels.INFO, { title = "Search" })
    return
  end

  local ok, match_line = pcall(vim.fn.search, pattern, "sw")
  if not ok then
    vim.notify("Invalid search pattern", vim.log.levels.WARN, { title = "Search" })
    return
  end

  if not match_line or match_line == 0 then
    vim.notify("No matches found", vim.log.levels.INFO, { title = "Search" })
    return
  end

  pcall(vim.cmd, "normal! zv")
end, { desc = "Search (prefix flags before ':' e.g. re:, c:, w:, cw:, wcre:)" })

local function visual_search_set()
  local saved = vim.fn.getreg('"')
  local saved_type = vim.fn.getregtype('"')
  vim.cmd("normal! y")
  local text = vim.fn.getreg('"')
  vim.fn.setreg('"', saved, saved_type)
  set_exact_visual_search(text)
end

keymaps.set("v", "n", function()
  visual_search_set()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "n", false)
end, { desc = "Search selected text forward" })
keymaps.set("v", "/", function()
  visual_search_set()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("n", true, false, true), "n", false)
end, { desc = "Search selected text" })
keymaps.set("v", "N", function()
  visual_search_set()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("N", true, false, true), "n", false)
end, { desc = "Search selected text backward" })
