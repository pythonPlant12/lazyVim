-- Jinja HTML templates share the htmldjango filetype with Django templates, but
-- the htmldjango grammar fails on Jinja-only syntax (calls, dicts, "!=").
-- "jinja_html" is the jinja grammar with an html injection (queries/jinja_html).
-- A buffer switches to it only when htmldjango parses with errors and
-- jinja_html parses with fewer, so Django templates keep their parser.
local M = {}

local LANG = "jinja_html"

-- Split query source into top-level patterns, dropping ';' comments. A pattern
-- is a parenthesized or bracketed group, or a bare string, followed by an
-- optional quantifier and any number of @captures.
local function top_level_patterns(source)
  local patterns, current, depth, in_string = {}, {}, 0, false
  local i = 1
  local function finish_pattern()
    local rest = source:sub(i + 1)
    local tail = rest:match("^[+*?]?") .. (rest:match("^[+*?]?([%s@%w_.]*@[%w_.]+)") or "")
    current[#current + 1] = tail
    i = i + #tail
    patterns[#patterns + 1] = table.concat(current)
    current = {}
  end
  while i <= #source do
    local ch = source:sub(i, i)
    if in_string then
      local step = ch == "\\" and 2 or 1
      current[#current + 1] = source:sub(i, i + step - 1)
      i = i + step
      if ch == '"' then
        in_string = false
        if depth == 0 then i = i - 1; finish_pattern(); i = i + 1 end
      end
    elseif ch == ";" then
      i = (source:find("\n", i, true) or #source) + 1
    else
      if ch == '"' then in_string = true
      elseif ch == "(" or ch == "[" then depth = depth + 1
      elseif ch == ")" or ch == "]" then depth = depth - 1 end
      current[#current + 1] = ch
      if depth == 0 and (ch == ")" or ch == "]") then finish_pattern() end
      i = i + 1
    end
  end
  return patterns
end

-- The jinja highlights, each pattern wrapped with priority 101 so jinja captures
-- win over the injected html (and its own injections) where node ranges overlap,
-- e.g. a jinja expression inside an html attribute value.
local function prioritized_highlights()
  local out = {}
  -- get_files resolves the "; inherits: jinja_inline" line.
  for _, file in ipairs(vim.treesitter.query.get_files("jinja", "highlights")) do
    for _, pattern in ipairs(top_level_patterns(table.concat(vim.fn.readfile(file), "\n"))) do
      out[#out + 1] = "(" .. pattern .. " (#set! priority 101))"
    end
  end
  return table.concat(out, "\n")
end

local registered
local function register()
  if registered ~= nil then return registered end
  local path = vim.api.nvim_get_runtime_file("parser/jinja.so", false)[1]
  registered = path ~= nil
    and pcall(vim.treesitter.language.add, LANG, { path = path, symbol_name = "jinja" })
    and pcall(vim.treesitter.query.set, LANG, "highlights", prioritized_highlights())
  return registered
end

-- Number of ERROR nodes when `lang` parses the buffer text (string parser: no buffer cache).
local function error_count(buf, lang)
  local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  local ok, parser = pcall(vim.treesitter.get_string_parser, text, lang)
  if not ok then return math.huge end
  local root = parser:parse(true)[1]:root()
  if not root:has_error() then return 0 end
  local count = 0
  local function walk(node)
    if node:type() == "ERROR" then count = count + 1 end
    for child in node:iter_children() do walk(child) end
  end
  walk(root)
  return count
end

-- Switch an htmldjango buffer to jinja_html when that parses it better.
function M.apply(buf)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  local htmldjango_errors = error_count(buf, "htmldjango")
  if htmldjango_errors == 0 or not register() then return end
  if error_count(buf, LANG) < htmldjango_errors then
    vim.treesitter.stop(buf)
    vim.treesitter.start(buf, LANG)
  end
end

return M
