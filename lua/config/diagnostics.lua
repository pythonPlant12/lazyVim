-- Custom diagnostic deduplication for Rust
local M = {}

-- Function to deduplicate diagnostics
local function deduplicate_diagnostics(diagnostics)
  local seen = {}
  local deduped = {}
  
  for _, diagnostic in ipairs(diagnostics) do
    -- Create a unique key based on line, column, message, and severity
    local key = string.format("%d:%d:%s:%d", 
      diagnostic.lnum or 0, 
      diagnostic.col or 0, 
      diagnostic.message or "", 
      diagnostic.severity or 0
    )
    
    if not seen[key] then
      seen[key] = true
      table.insert(deduped, diagnostic)
    end
  end
  
  return deduped
end

-- Override the diagnostic handler for Rust files
local function setup_rust_diagnostic_handler()
  -- Store the original handler
  local original_handler = vim.diagnostic.handlers.virtual_text
  
  -- Create custom handler that deduplicates
  vim.diagnostic.handlers.virtual_text = vim.tbl_extend("force", original_handler, {
    show = function(namespace, bufnr, diagnostics, opts)
      -- Only deduplicate for Rust files
      if vim.bo[bufnr].filetype == "rust" then
        diagnostics = deduplicate_diagnostics(diagnostics)
      end
      
      -- Call the original handler with deduplicated diagnostics
      return original_handler.show(namespace, bufnr, diagnostics, opts)
    end,
  })
end

-- Setup function to be called after LSP is loaded
function M.setup()
  -- Set up the diagnostic handler
  setup_rust_diagnostic_handler()
  
  -- Configure diagnostic display settings
  vim.diagnostic.config({
    virtual_text = {
      -- Only show source if there are multiple sources
      source = "if_many",
      -- Custom prefix function
      prefix = function(diagnostic)
        -- Don't show duplicate prefixes
        local severity = diagnostic.severity
        if severity == vim.diagnostic.severity.ERROR then
          return "●"
        elseif severity == vim.diagnostic.severity.WARN then
          return "●"
        elseif severity == vim.diagnostic.severity.INFO then
          return "●"
        elseif severity == vim.diagnostic.severity.HINT then
          return "●"
        end
        return "●"
      end,
    },
    -- Reduce update frequency to minimize duplicate flashing
    update_in_insert = true,
    severity_sort = true,
  })
end

return M
