local M = {}

local PERSISTENT_EXCLUDES = {
  "node_modules/**",
  "venv/**",
  ".venv/**",
  ".idea",
  ".idea/**",
  "**/.idea/**",
  ".vscode/**",
  ".zed/**",
  ".git/**",
  "shelved.patch",
  "**/shelved.patch",
}

local toggle_actions = {
  toggle_word = function(picker)
    local args = picker.opts.args or {}
    local found = false
    for i, v in ipairs(args) do
      if v == "--word-regexp" then
        table.remove(args, i)
        found = true
        break
      end
    end
    if not found then
      args[#args + 1] = "--word-regexp"
    end
    picker.opts.args = args
    picker.list:set_target()
    picker:find()
    vim.notify(found and "Word: off" or "Word: on", vim.log.levels.INFO, { title = "Grep" })
  end,
  toggle_case = function(picker)
    local args = picker.opts.args or {}
    local found_ic = false
    for i, v in ipairs(args) do
      if v == "--ignore-case" then
        table.remove(args, i)
        found_ic = true
        break
      end
    end
    if not found_ic then
      for i, v in ipairs(args) do
        if v == "--case-sensitive" then
          table.remove(args, i)
          break
        end
      end
      args[#args + 1] = "--ignore-case"
    else
      args[#args + 1] = "--case-sensitive"
    end
    picker.opts.args = args
    picker.list:set_target()
    picker:find()
    vim.notify(found_ic and "Case: sensitive" or "Case: insensitive", vim.log.levels.INFO, { title = "Grep" })
  end,
}

local toggle_keys = {
  ["<C-h>"]          = { "toggle_hidden", mode = { "i", "n" } },
  ["<localleader>c"] = { "toggle_case",   mode = { "n" } },
  ["<localleader>w"] = { "toggle_word",   mode = { "n" } },
  ["<localleader>r"] = { "toggle_regex",  mode = { "n" } },
  ["<localleader>R"] = { "toggle_camel_case", mode = { "n" } },
}

local function get_snacks()
  if _G.Snacks and _G.Snacks.picker then
    return _G.Snacks
  end
  local ok, snacks = pcall(require, "snacks")
  if ok and snacks and snacks.picker then
    return snacks
  end
  vim.notify("Snacks picker is not available", vim.log.levels.ERROR, { title = "Grep" })
  return nil
end

local function split_filter_tokens(raw)
  local tokens = {}
  if type(raw) ~= "string" or raw == "" then
    return tokens
  end
  for token in raw:gmatch("[^,%s]+") do
    token = vim.trim(token)
    if token ~= "" then
      tokens[#tokens + 1] = token
    end
  end
  return tokens
end

local function normalize_grep_glob(token, cwd)
  local glob = vim.trim(token or "")
  if glob == "" then
    return nil
  end

  glob = glob:gsub("\\", "/")
  if glob:sub(1, 2) == "./" then
    glob = glob:sub(3)
  end

  local norm_cwd = vim.fs.normalize(cwd):gsub("\\", "/")
  if glob:sub(1, #norm_cwd + 1) == norm_cwd .. "/" then
    glob = glob:sub(#norm_cwd + 2)
  end

  if glob == "" then
    return nil
  end

  local has_wildcards = glob:find("[%*%?%[%]{}]") ~= nil
  if not has_wildcards then
    local abs = vim.fs.normalize(norm_cwd .. "/" .. glob)
    local uv = vim.uv or vim.loop
    local stat = uv and uv.fs_stat(abs) or nil
    if stat and stat.type == "directory" then
      glob = glob:gsub("/+$", "") .. "/**"
    end
  end

  return glob
end

local function build_grep_globs(raw, cwd)
  local seen = {}
  local globs = {}
  for _, token in ipairs(split_filter_tokens(raw)) do
    local glob = normalize_grep_glob(token, cwd)
    if glob and not seen[glob] then
      seen[glob] = true
      globs[#globs + 1] = glob
    end
  end
  return globs
end

local function normalize_extension_token(token)
  local ext = vim.trim(token or "")
  if ext == "" then
    return nil
  end
  ext = ext:gsub("^%*%.", "")
  ext = ext:gsub("^%.", "")
  ext = ext:gsub("%.$", "")
  if ext == "" then
    return nil
  end
  return ext
end

local function build_extension_globs(raw)
  local seen = {}
  local globs = {}
  for _, token in ipairs(split_filter_tokens(raw)) do
    local ext = normalize_extension_token(token)
    if ext then
      local glob = "**/*." .. ext
      if not seen[glob] then
        seen[glob] = true
        globs[#globs + 1] = glob
      end
    end
  end
  return globs
end

local function collect_extension_items(cwd)
  local counts = {}
  local lines = vim.fn.systemlist({ "git", "-C", cwd, "ls-files" })
  if vim.v.shell_error == 0 then
    for _, path in ipairs(lines) do
      local ext = path:match("%.([^.\\/]+)$")
      if ext and ext ~= "" then
        counts[ext] = (counts[ext] or 0) + 1
      end
    end
  end

  local items = {}
  for ext, count in pairs(counts) do
    items[#items + 1] = {
      id = ext,
      label = string.format(".%s (%d)", ext, count),
      count = count,
    }
  end

  table.sort(items, function(a, b)
    if a.count == b.count then
      return a.id < b.id
    end
    return a.count > b.count
  end)

  if #items > 30 then
    while #items > 30 do
      items[#items] = nil
    end
  end

  items[#items + 1] = { id = "custom", label = "Custom extension...", count = 0 }
  items[#items + 1] = { id = "none", label = "No extension filter", count = 0 }
  return items
end

local function select_extension(cwd, on_done)
  local items = collect_extension_items(cwd)
  vim.ui.select(items, {
    prompt = "Select extension:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then
      on_done(nil)
      return
    end
    if choice.id == "none" then
      on_done("")
      return
    end
    if choice.id ~= "custom" then
      on_done(choice.id)
      return
    end
    vim.ui.input({ prompt = "Extension (e.g. lua): " }, function(value)
      on_done(normalize_extension_token(value))
    end)
  end)
end

local function input_path_filters(prompt, on_done)
  vim.ui.input({ prompt = prompt, completion = "file" }, function(value)
    on_done(value)
  end)
end

local function merge_excludes(extra)
  local seen = {}
  local out = {}
  local function add(v)
    if v and v ~= "" and not seen[v] then
      seen[v] = true
      out[#out + 1] = v
    end
  end
  for _, v in ipairs(PERSISTENT_EXCLUDES) do
    add(v)
  end
  for _, v in ipairs(extra or {}) do
    add(v)
  end
  return out
end

local function run_grep(opts)
  local snacks = get_snacks()
  if not snacks then
    return
  end
  opts.actions = vim.tbl_extend("force", toggle_actions, opts.actions or {})
  opts.win = vim.tbl_deep_extend("force", { input = { keys = toggle_keys } }, opts.win or {})
  snacks.picker.grep(opts)
end

function M.cwd_with_filter_mode()
  local cwd = vim.fn.getcwd()
  local mode_items = {
    { id = "include", label = "Include paths/globs" },
    { id = "exclude", label = "Exclude paths/globs" },
    { id = "extension", label = "Filter by file extension" },
    { id = "none", label = "No path filters" },
  }

  vim.ui.select(mode_items, {
    prompt = "Grep mode:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then
      return
    end

    local grep_opts = {
      cwd = cwd,
      args = { "--ignore-case" },
      camel_case = false,
      exclude = merge_excludes(),
    }

    if choice.id == "none" then
      run_grep(grep_opts)
      return
    end

    if choice.id == "include" then
      input_path_filters("Include paths/globs (optional, comma/space separated): ", function(include_raw)
        if include_raw == nil then
          return
        end

        local include = build_grep_globs(include_raw, cwd)
        if #include > 0 then
          grep_opts.glob = include
        else
          vim.notify("No include filters entered; searching all paths", vim.log.levels.INFO, { title = "Grep" })
        end

        run_grep(grep_opts)
      end)
      return
    end

    if choice.id == "extension" then
      select_extension(cwd, function(ext)
        if ext == nil then
          return
        end

        local ext_globs = build_extension_globs(ext)
        if #ext_globs > 0 then
          grep_opts.glob = ext_globs
        else
          vim.notify("No extensions entered; searching all files", vim.log.levels.INFO, { title = "Grep" })
        end

        run_grep(grep_opts)
      end)
      return
    end

    input_path_filters("Exclude paths/globs (optional, comma/space separated): ", function(exclude_raw)
      if exclude_raw == nil then
        return
      end

      local exclude = build_grep_globs(exclude_raw, cwd)
      grep_opts.exclude = merge_excludes(exclude)

      run_grep(grep_opts)
    end)
  end)
end

M.toggle_case = toggle_actions.toggle_case
M.toggle_word = toggle_actions.toggle_word

return M
