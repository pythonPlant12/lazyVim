return {
  "ibhagwan/fzf-lua",
  opts = function()
    local fzf_bin = "fzf" -- Default to system PATH
    
    -- Check common fzf locations
    local possible_paths = {
      vim.fn.expand("~/.fzf/bin/fzf"),     -- Source install (Linux/macOS)
      vim.fn.expand("~/.local/bin/fzf"),   -- Local bin (Linux)
      "/usr/local/bin/fzf",                -- Homebrew (macOS)
      "/opt/homebrew/bin/fzf",             -- Apple Silicon Homebrew (macOS)
    }
    
    for _, path in ipairs(possible_paths) do
      if vim.fn.executable(path) == 1 then
        fzf_bin = path
        break
      end
    end
    
    return {
      fzf_bin = fzf_bin,
    }
  end,
}