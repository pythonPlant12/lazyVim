return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      -- Add format status to lualine with icons
      local format_status = function()
        local status = {}
        
        if vim.g.prettier_on_save_enabled then
          table.insert(status, "🎨")  -- Prettier icon
        end
        
        if vim.g.eslint_fix_on_save_enabled then
          table.insert(status, "🔧")  -- ESLint fix icon
        end
        
        if vim.g.ruff_format_on_save_enabled then
          table.insert(status, "🐍")  -- Ruff format icon
        end
        
        if vim.g.format_on_save_enabled then
          table.insert(status, "📝")  -- Format on save icon
        end
        
        local auto_save_ok, auto_save_config = pcall(require, "auto-save.config")
        if auto_save_ok and auto_save_config.opts.enabled then
          table.insert(status, "💾")  -- Auto-save icon
        end
        
        if #status > 0 then
          return table.concat(status, " ")
        else
          return ""
        end
      end
      
      -- Add to lualine sections
      if not opts.sections then
        opts.sections = {}
      end
      
      if not opts.sections.lualine_x then
        opts.sections.lualine_x = {}
      end
      
      -- Insert format status before existing items
      table.insert(opts.sections.lualine_x, 1, {
        format_status,
        color = { fg = "#98be65" }, -- Green color
      })
      
      return opts
    end,
  },
}