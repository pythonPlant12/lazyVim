-- Lualine statusline: custom mode/git/diagnostics/LSP chips with theme-aware highlights.
return {
  -- statusline
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      -- Match lualine's surface to transparent/opaque theme behavior.
      -- Islands themes render lualine transparently over the editor background.
      local function is_transparent_lualine()
        local cs = vim.g.colors_name or ""
        return cs == "islands-dark"
          or cs == "islands-white"
          or cs == "islands-light"
          or cs:find("^islands%-rose%-pine") ~= nil
      end
      -- Statusline surface color: transparent for islands, else theme-dependent gray.
      local function lualine_bg()
        if is_transparent_lualine() then return "NONE" end
        if vim.g._lualine_theme_hint == "cursor-dark" then return "#141414" end
        if vim.g._lualine_theme_hint == "cursor-dark-midnight" then return "#191c22" end
        if vim.g._lualine_theme_hint == "cursor-light" then return "#F3F3F3" end
        return vim.o.background == "light" and "#F3F3F3" or "#2B2D30"
      end
      local surface_bg = lualine_bg()
      local function cursor_lualine_palette()
        local hint = vim.g._lualine_theme_hint or ""
        if hint == "cursor-dark" then
          return {
            fg = "#D6D6DD", fg_bright = "#F0F0F0", muted = "#626262", surface = "#141414",
            normal = "#81A1C1", insert = "#70B489", visual = "#AAA0FA", replace = "#E34671", command = "#F1B467",
            green = "#70B489", yellow = "#F1B467", peach = "#EFB080", red = "#E34671", info = "#88C0D0",
            lsp_bg = "#181818", lsp_ts = "#87C3FF", lsp_js = "#F8C762", lsp_py = "#88C0D0", lsp_misc = "#82D2CE",
          }
        elseif hint == "cursor-dark-midnight" then
          return {
            fg = "#7b88a1", fg_bright = "#D8DEE9", muted = "#4b5163", surface = "#191c22",
            normal = "#88C0D0", insert = "#A3BE8C", visual = "#B48EAD", replace = "#BF616A", command = "#EBCB8B",
            green = "#A3BE8C", yellow = "#EBCB8B", peach = "#D08770", red = "#BF616A", info = "#88C0D0",
            lsp_bg = "#20242c", lsp_ts = "#81A1C1", lsp_js = "#EBCB8B", lsp_py = "#88C0D0", lsp_misc = "#8FBCBB",
          }
        elseif hint == "cursor-light" then
          return {
            fg = "#444444", fg_bright = "#141414", muted = "#999999", surface = "#F3F3F3",
            normal = "#2778C1", insert = "#007041", visual = "#654DC0", replace = "#BE1744", command = "#A8552A",
            green = "#007041", yellow = "#A46700", peach = "#A8552A", red = "#BE1744", info = "#176C74",
            lsp_bg = "#EAEAEA", lsp_ts = "#005293", lsp_js = "#A8552A", lsp_py = "#176C74", lsp_misc = "#3B7E84",
          }
        end
      end
      local lualine_light = {
        normal   = { a = { fg = "#2F496F", bg = "#D2E4F5", gui = "bold" }, b = { fg = "#4C4F69", bg = surface_bg, gui = "bold" }, c = { fg = "#4C4F69", bg = surface_bg } },
        insert   = { a = { fg = "#34523E", bg = "#D8E8DA", gui = "bold" }, b = { fg = "#4C4F69", bg = surface_bg, gui = "bold" } },
        visual   = { a = { fg = "#342F67", bg = "#DDD9F7", gui = "bold" }, b = { fg = "#4C4F69", bg = surface_bg, gui = "bold" } },
        replace  = { a = { fg = "#672D2D", bg = "#F5DADA", gui = "bold" }, b = { fg = "#4C4F69", bg = surface_bg, gui = "bold" } },
        command  = { a = { fg = "#5A3A1A", bg = "#F0E0C8", gui = "bold" }, b = { fg = "#4C4F69", bg = surface_bg, gui = "bold" } },
        inactive = { a = { fg = "#7A7880", bg = surface_bg }, b = { fg = "#7A7880", bg = surface_bg }, c = { fg = "#7A7880", bg = surface_bg } },
      }
      local lualine_dark = {
        normal   = { a = { fg = "#E8F0FA", bg = "#2F496F", gui = "bold" }, b = { fg = "#BCBEC4", bg = surface_bg, gui = "bold" }, c = { fg = "#BCBEC4", bg = surface_bg } },
        insert   = { a = { fg = "#EFF3F0", bg = "#34523E", gui = "bold" }, b = { fg = "#BCBEC4", bg = surface_bg, gui = "bold" } },
        visual   = { a = { fg = "#ECEBFB", bg = "#342F67", gui = "bold" }, b = { fg = "#BCBEC4", bg = surface_bg, gui = "bold" } },
        replace  = { a = { fg = "#FCF0F0", bg = "#672D2D", gui = "bold" }, b = { fg = "#BCBEC4", bg = surface_bg, gui = "bold" } },
        command  = { a = { fg = "#F5E8D0", bg = "#5A3A1A", gui = "bold" }, b = { fg = "#BCBEC4", bg = surface_bg, gui = "bold" } },
        inactive = { a = { fg = "#6F737A", bg = surface_bg }, b = { fg = "#6F737A", bg = surface_bg }, c = { fg = "#6F737A", bg = surface_bg } },
      }
      local cursor_palette = cursor_lualine_palette()
      local lualine_cursor = cursor_palette and {
        normal   = { a = { fg = vim.o.background == "light" and "#FCFCFC" or "#191c22", bg = cursor_palette.normal, gui = "bold" }, b = { fg = cursor_palette.fg, bg = surface_bg, gui = "bold" }, c = { fg = cursor_palette.fg, bg = surface_bg } },
        insert   = { a = { fg = vim.o.background == "light" and "#FCFCFC" or "#191c22", bg = cursor_palette.insert, gui = "bold" }, b = { fg = cursor_palette.fg, bg = surface_bg, gui = "bold" } },
        visual   = { a = { fg = vim.o.background == "light" and "#FCFCFC" or "#191c22", bg = cursor_palette.visual, gui = "bold" }, b = { fg = cursor_palette.fg, bg = surface_bg, gui = "bold" } },
        replace  = { a = { fg = "#FCFCFC", bg = cursor_palette.replace, gui = "bold" }, b = { fg = cursor_palette.fg, bg = surface_bg, gui = "bold" } },
        command  = { a = { fg = vim.o.background == "light" and "#FCFCFC" or "#191c22", bg = cursor_palette.command, gui = "bold" }, b = { fg = cursor_palette.fg, bg = surface_bg, gui = "bold" } },
        inactive = { a = { fg = cursor_palette.muted, bg = surface_bg }, b = { fg = cursor_palette.muted, bg = surface_bg }, c = { fg = cursor_palette.muted, bg = surface_bg } },
      } or nil
      local _hint = vim.g._lualine_theme_hint or ""
      local mode_theme = lualine_cursor or _hint == "islands-light" and lualine_light or _hint == "islands-dark" and lualine_dark or (vim.o.background == "light" and lualine_light or lualine_dark)
      opts.options = vim.tbl_extend("force", opts.options or {}, {
        theme = mode_theme,
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
        -- Avoid CursorMoved refreshes; diagnostics/LSP/git events keep this fresh enough.
        refresh = {
          statusline = 99999,
          tabline = 99999,
          winbar = 99999,
          events = {
            "WinEnter",
            "BufEnter",
            "BufWritePost",
            "SessionLoadPost",
            "FileChangedShellPost",
            "VimResized",
            "Filetype",
            "DiagnosticChanged",
            "LspAttach",
            "LspDetach",
            "ModeChanged",
          },
        },
      })
      opts.sections = opts.sections or {}
      local mode_colors = mode_theme
      opts.sections.lualine_a = {
        {
          "mode",
          fmt = function(mode)
            if vim.g.multicursor_build_mode then return "M CURSOR" end
            if vim.g.window_resize_mode then return "RESIZE WINDOW" end

            if vim.g.multicursor_mode_active then return "MULTI SELECT" end

            return mode
          end,
          color = function()
            if vim.g.multicursor_build_mode then
              return vim.o.background == "light"
                  and { fg = "#4F3800", bg = "#F4D58D", gui = "bold" }
                or { fg = "#211600", bg = "#F2C14E", gui = "bold" }
            end

            if vim.g.window_resize_mode then
              return vim.o.background == "light"
                  and { fg = "#5A2E00", bg = "#F1C7A6", gui = "bold" }
                or { fg = "#271000", bg = "#E6985A", gui = "bold" }
            end

            if vim.g.multicursor_mode_active then
              return vim.o.background == "light"
                  and { fg = "#1B4D4A", bg = "#BFE7E3", gui = "bold" }
                or { fg = "#081F1D", bg = "#7AD7CD", gui = "bold" }
            end

            local mode = vim.fn.mode(1)
            if mode:sub(1, 1) == "i" then return mode_colors.insert.a end
            if mode == "v" or mode == "V" or mode == "\22" then return mode_colors.visual.a end
            return mode_colors.normal.a
          end,
          separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
          padding = { left = 1, right = 1 },
        },
      }
      opts.sections.lualine_x = {}
      -- Git counters update asynchronously so the statusline never blocks on git commands.
      vim.g._git_ahead = vim.g._git_ahead or 0
      vim.g._git_behind = vim.g._git_behind or 0
      vim.g._git_untracked = vim.g._git_untracked or 0
      vim.g._git_modified = vim.g._git_modified or 0
      vim.g._git_deleted = vim.g._git_deleted or 0
      vim.g._git_conflicted = vim.g._git_conflicted or 0
      -- Async count of commits ahead/behind upstream for the branch chip.
      local function refresh_git_ab()
        vim.fn.jobstart({ "git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}" }, {
          cwd = vim.fn.getcwd(),
          stdout_buffered = true,
          on_stdout = function(_, data)
            if data and data[1] and data[1] ~= "" then
              local a, b = data[1]:match("(%d+)%s+(%d+)")
              vim.g._git_ahead = tonumber(a) or 0
              vim.g._git_behind = tonumber(b) or 0
            end
          end,
          on_exit = function(_, code)
            if code ~= 0 then
              vim.g._git_ahead = 0
              vim.g._git_behind = 0
            end
          end,
        })
      end
      -- Async tally of untracked/modified/deleted/conflicted files from git status.
      local function refresh_git_status()
        vim.fn.jobstart({ "git", "status", "--porcelain" }, {
          cwd = vim.fn.getcwd(),
          stdout_buffered = true,
          on_stdout = function(_, data)
            if not data then return end
            local untracked, modified, deleted, conflicted = 0, 0, 0, 0
            for _, line in ipairs(data) do
              if line ~= "" then
                local x, y = line:sub(1, 1), line:sub(2, 2)
                if x == "?" then
                  untracked = untracked + 1
                elseif x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D") then
                  conflicted = conflicted + 1
                else
                  if y == "M" or x == "M" then modified = modified + 1 end
                  if y == "D" or x == "D" then deleted = deleted + 1 end
                end
              end
            end
            vim.g._git_untracked = untracked
            vim.g._git_modified = modified
            vim.g._git_deleted = deleted
            vim.g._git_conflicted = conflicted
          end,
          on_exit = function(_, code)
            if code ~= 0 then
              vim.g._git_untracked = 0
              vim.g._git_modified = 0
              vim.g._git_deleted = 0
              vim.g._git_conflicted = 0
            end
          end,
        })
      end
      local function refresh_git_all()
        refresh_git_ab()
        refresh_git_status()
      end
      local grp = vim.api.nvim_create_augroup("lualine_git_ab", { clear = true })
      vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "BufWritePost" }, { group = grp, callback = refresh_git_all })
      refresh_git_all()

      -- Custom chip highlights are reapplied because colorschemes reset them.
      local function setup_breadcrumb_hl()
        local chip_bgs_hl = { lualine_bg(), lualine_bg(), lualine_bg() }
        local breadcrumb_bg = chip_bgs_hl[2] or chip_bgs_hl[1]
        local breadcrumb_fg = vim.o.background == "light" and "#4C4F69" or "#CED0D6"
        local arrow_fg = vim.o.background == "light" and "#2F3147" or "#DCE0E8"
        for i, bg in ipairs(chip_bgs_hl) do
          vim.api.nvim_set_hl(0, "LualineBreadcrumbSep" .. i, { fg = arrow_fg, bg = bg })
        end
        vim.api.nvim_set_hl(0, "LualineBreadcrumbStatus", { fg = breadcrumb_fg, bg = breadcrumb_bg })
      end
      setup_breadcrumb_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_breadcrumb_hl })

      -- Theme-aware highlights for the git branch chip and its status indicators.
      local function setup_git_hl()
        local hint = vim.g._lualine_theme_hint or ""
        if vim.o.background == "light" then
          local bg = hint == "islands-light" and "#DDD9F7" or "#6B3CC8"
          local base_fg = hint == "islands-light" and "#342F67" or "#FFFFFF"
          vim.api.nvim_set_hl(0, "LualineGitBase",   { fg = base_fg, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitBranch", { fg = base_fg, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitGreen",  { fg = hint == "islands-light" and "#3A7A52" or "#7CA686", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = hint == "islands-light" and "#8A6B20" or "#A8983A", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitPeach",  { fg = hint == "islands-light" and "#8E5324" or "#C87A3A", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitRed",    { fg = hint == "islands-light" and "#B54A5C" or "#B85C5C", bg = bg, bold = true })
        elseif cursor_lualine_palette() then
          local c = cursor_lualine_palette()
          local bg = c.normal
          vim.api.nvim_set_hl(0, "LualineGitBase",   { fg = "#191c22", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitBranch", { fg = "#191c22", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitGreen",  { fg = c.green, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = c.yellow, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitPeach",  { fg = c.peach, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitRed",    { fg = c.red, bg = bg, bold = true })
        else
          local bg = hint == "islands-dark" and "#342F67" or "#cba6f7"
          local base_fg = hint == "islands-dark" and "#ECEBFB" or "#151619"
          vim.api.nvim_set_hl(0, "LualineGitBase",   { fg = base_fg, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitBranch", { fg = base_fg, bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitGreen",  { fg = hint == "islands-dark" and "#7CA686" or "#a6e3a1", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = hint == "islands-dark" and "#D5B778" or "#f9e2af", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitPeach",  { fg = hint == "islands-dark" and "#CF8E6D" or "#fab387", bg = bg, bold = true })
          vim.api.nvim_set_hl(0, "LualineGitRed",    { fg = hint == "islands-dark" and "#F75464" or "#f38ba8", bg = bg, bold = true })
        end
      end
      setup_git_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_git_hl })

      -- Reapply the lualine mode theme + StatusLine highlights from the theme hint.
      local function setup_lualine_theme_hl()
        local hint = vim.g._lualine_theme_hint or ""
        local theme
        if hint == "islands-light" then
          theme = lualine_light
        elseif cursor_lualine_palette() then
          theme = lualine_cursor
        elseif hint == "islands-dark" then
          theme = lualine_dark
        else
          theme = "auto"
        end
        local ok, lualine = pcall(require, "lualine")
        if not ok then return end
        local cfg = lualine.get_config()
        cfg.options = cfg.options or {}
        cfg.options.theme = theme
        lualine.setup(cfg)
        local c = cursor_lualine_palette()
        vim.api.nvim_set_hl(0, "StatusLine",   { fg = c and c.fg or (vim.o.background == "light" and "#4C4F69" or "#BCBEC4"), bg = lualine_bg() })
        vim.api.nvim_set_hl(0, "StatusLineNC", { fg = c and c.muted or (vim.o.background == "light" and "#7A7880" or "#6F737A"), bg = lualine_bg() })
      end
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_lualine_theme_hl })
      vim.defer_fn(function()
        local hint = vim.g._lualine_theme_hint or ""
        local c = cursor_lualine_palette()
        vim.api.nvim_set_hl(0, "StatusLine",   { fg = c and c.fg or (vim.o.background == "light" and "#4C4F69" or "#BCBEC4"), bg = lualine_bg() })
        vim.api.nvim_set_hl(0, "StatusLineNC", { fg = c and c.muted or (vim.o.background == "light" and "#7A7880" or "#6F737A"), bg = lualine_bg() })
      end, 50)

      opts.sections.lualine_b = {
        {
          function()
            local branch = vim.b.gitsigns_head
            if not branch or branch == "" then return "" end
            local parts = { "%#LualineGitBranch#󰘬 " .. branch }
            local a, b = vim.g._git_ahead or 0, vim.g._git_behind or 0
            local u, m, d, c = vim.g._git_untracked or 0, vim.g._git_modified or 0, vim.g._git_deleted or 0, vim.g._git_conflicted or 0
            local indicators = {}
            if a > 0 and b > 0 then table.insert(indicators, "%#LualineGitYellow#+-") end
            if a > 0 and b == 0 then table.insert(indicators, "%#LualineGitGreen#+") end
            if b > 0 and a == 0 then table.insert(indicators, "%#LualineGitPeach#-") end
            if c > 0 then table.insert(indicators, "%#LualineGitRed#!") end
            if u > 0 then table.insert(indicators, "%#LualineGitGreen#?") end
            if m > 0 then table.insert(indicators, "%#LualineGitYellow#*") end
            if d > 0 then table.insert(indicators, "%#LualineGitRed#x") end
            if #indicators > 0 then
              table.insert(parts, " " .. table.concat(indicators, "") .. "%#LualineGitBase#")
            end
            return table.concat(parts, "")
          end,
          cond = function()
            return vim.b.gitsigns_head ~= nil and vim.b.gitsigns_head ~= ""
          end,
          padding = { left = 1, right = 0 },
          separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        },
        {
          function() return "|" end,
          padding = { left = 1, right = 1 },
          separator = "",
          color = function()
            return { fg = vim.o.background == "light" and "#9B9792" or "#6B6F75" }
          end,
          cond = function()
            return vim.b.gitsigns_head ~= nil and vim.b.gitsigns_head ~= ""
          end,
        },
      }

      -- Highlights for the compact diagnostics pill.
      local function setup_diag_hl()
        local hint = vim.g._lualine_theme_hint or ""
        local c = cursor_lualine_palette()
        if c then
          vim.api.nvim_set_hl(0, "DiagPillCap",   { fg = c.lsp_bg, bg = c.surface })
          vim.api.nvim_set_hl(0, "DiagPillBase",  { fg = c.muted, bg = c.lsp_bg })
          vim.api.nvim_set_hl(0, "DiagPillError", { fg = c.red, bg = c.lsp_bg })
          vim.api.nvim_set_hl(0, "DiagPillWarn",  { fg = c.yellow, bg = c.lsp_bg })
          vim.api.nvim_set_hl(0, "DiagPillInfo",  { fg = c.info, bg = c.lsp_bg })
          vim.api.nvim_set_hl(0, "DiagPillHint",  { fg = c.info, bg = c.lsp_bg })
        elseif vim.o.background == "light" then
          vim.api.nvim_set_hl(0, "DiagPillCap",   { fg = "#D5D0CA", bg = "#E2DFDB" })
          vim.api.nvim_set_hl(0, "DiagPillBase",  { fg = "#7A7880", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillError", { fg = "#B85C5C", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillWarn",  { fg = "#A8983A", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillInfo",  { fg = "#5A8FD4", bg = "#D5D0CA" })
          vim.api.nvim_set_hl(0, "DiagPillHint",  { fg = "#7CA686", bg = "#D5D0CA" })
        else
          vim.api.nvim_set_hl(0, "DiagPillCap",   { fg = "#313438", bg = "#2B2D30" })
          vim.api.nvim_set_hl(0, "DiagPillBase",  { fg = "#BCBEC4", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillError", { fg = "#f38ba8", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillWarn",  { fg = "#f9e2af", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillInfo",  { fg = "#89b4fa", bg = "#313438" })
          vim.api.nvim_set_hl(0, "DiagPillHint",  { fg = "#a6e3a1", bg = "#313438" })
        end
      end
      setup_diag_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_diag_hl })

      -- Remove LazyVim defaults before adding custom diagnostics/LSP/tool chips.
      local new_c = {}
      for i, comp in ipairs(opts.sections.lualine_c or {}) do
        if i == 1 then goto skip end
        if type(comp) == "table" and comp[1] == "diagnostics" then goto skip end
        if type(comp) == "table" and comp[1] == "filetype" and comp.icon_only then goto skip end
        if type(comp) == "table" and type(comp[1]) == "function" and type(comp.cond) == "function" then goto skip end
        table.insert(new_c, comp)
        ::skip::
      end
      opts.sections.lualine_c = new_c

      -- Remove LazyVim's Trouble symbols component from the statusline. Keep
      -- the file path chip, but avoid showing the current code breadcrumb next
      -- to it.
      local breadcrumb_symbols = nil
      do
        local ok_t = pcall(require, "trouble")
        if ok_t then
          for i, comp in ipairs(opts.sections.lualine_c) do
            if type(comp) == "table" and type(comp[1]) == "function" and type(comp.cond) == "function" then
              table.remove(opts.sections.lualine_c, i)
              break
            end
          end
        end
      end

      -- Compact diagnostics pill, hidden when the current buffer has no diagnostics.
      table.insert(opts.sections.lualine_x, 1, {
        function()
          local d = vim.diagnostic.count(0)
          local e = d[vim.diagnostic.severity.ERROR] or 0
          local w = d[vim.diagnostic.severity.WARN] or 0
          local inf = d[vim.diagnostic.severity.INFO] or 0
          local h = d[vim.diagnostic.severity.HINT] or 0
          if e + w + inf + h == 0 then return "" end
          local parts = {}
          if e > 0 then table.insert(parts, "%#DiagPillError#E " .. e) end
          if w > 0 then table.insert(parts, "%#DiagPillWarn#W " .. w) end
          if inf > 0 then table.insert(parts, "%#DiagPillInfo#I " .. inf) end
          if h > 0 then table.insert(parts, "%#DiagPillHint#H " .. h) end
          return table.concat(parts, " ")
        end,
        cond = function()
          local d = vim.diagnostic.count(0)
          local e = d[vim.diagnostic.severity.ERROR] or 0
          local w = d[vim.diagnostic.severity.WARN] or 0
          local inf = d[vim.diagnostic.severity.INFO] or 0
          local h = d[vim.diagnostic.severity.HINT] or 0
          return e + w + inf + h > 0
        end,
        separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        color = function()
          local light = vim.o.background == "light"
          local c = cursor_lualine_palette()
          if c then
            return { fg = c.muted, bg = c.surface }
          end
          return { fg = light and "#7A7880" or "#7A7E85", bg = light and "#D5D0CA" or "#2B2D30" }
        end,
        padding = { left = 1, right = 1 },
      })

      -- Status chips render attached tools with stable colors per theme.
      local lsp_icons = {
        vtsls          = "󰛦 ",
        ts_ls          = "󰛦 ",
        tsserver       = "󰛦 ",
        vue_ls         = "󰡄 ",
        volar          = "󰡄 ",
        eslint         = "󰅪 ",
        tailwindcss    = "󱏿 ",
        lua_ls         = "󰢱 ",
        pyright        = "󰌠 ",
        basedpyright   = "󰌠 ",
        pylsp          = "󰌠 ",
        jsonls         = "󰘦 ",
        html           = "󰌝 ",
        cssls          = "󰌜 ",
        emmet_ls       = "󰯸 ",
        bashls         = " ",
        dockerls       = "󰡨 ",
        yamlls         = "󰘦 ",
        copilot        = " ",
        ["null-ls"]    = "󱏿 ",
      }

      local lsp_colors = {
        vtsls          = "#89b4fa",
        ts_ls          = "#89b4fa",
        tsserver       = "#89b4fa",
        vue_ls         = "#a6e3a1",
        volar          = "#a6e3a1",
        tailwindcss    = "#94e2d5",
        lua_ls         = "#89b4fa",
        pyright        = "#fab387",
        basedpyright   = "#fab387",
        pylsp          = "#fab387",
        jsonls         = "#f9e2af",
        html           = "#fab387",
        cssls          = "#74c7ec",
        emmet_ls       = "#fab387",
        bashls         = "#a6e3a1",
        dockerls       = "#89dceb",
        yamlls         = "#f9e2af",
        copilot        = "#cba6f7",
        ["null-ls"]    = "#94e2d5",
      }

      local lsp_colors_light = {
        vtsls          = "#0B74D6",
        ts_ls          = "#0B74D6",
        tsserver       = "#0B74D6",
        vue_ls         = "#2E7D4F",
        volar          = "#2E7D4F",
        tailwindcss    = "#1A8894",
        lua_ls         = "#0B74D6",
        pyright        = "#A04B10",
        basedpyright   = "#A04B10",
        pylsp          = "#A04B10",
        jsonls         = "#7A5C00",
        html           = "#A04B10",
        cssls          = "#1A8894",
        emmet_ls       = "#A04B10",
        bashls         = "#2E7D4F",
        dockerls       = "#1A8894",
        yamlls         = "#7A5C00",
        copilot        = "#6B3CC8",
        ["null-ls"]    = "#1A8894",
      }

      -- Per-server highlight groups for the LSP/tool status chips.
      local function setup_lsp_hl()
        local light = vim.o.background == "light"
        local c = cursor_lualine_palette()
        local lsp_bg = c and c.lsp_bg or (light and "#D5D0CA" or "#45475a")
        local colors = light and lsp_colors_light or lsp_colors
        if c then
          colors = vim.tbl_extend("force", colors, {
            vtsls = c.lsp_ts, ts_ls = c.lsp_ts, tsserver = c.lsp_ts,
            vue_ls = c.green, volar = c.green, tailwindcss = c.info,
            lua_ls = c.lsp_ts, pyright = c.lsp_py, basedpyright = c.lsp_py, pylsp = c.lsp_py,
            jsonls = c.lsp_js, html = c.peach, cssls = c.info, emmet_ls = c.peach,
            bashls = c.green, dockerls = c.info, yamlls = c.lsp_js, copilot = c.visual, ["null-ls"] = c.info,
          })
        end
        vim.api.nvim_set_hl(0, "LualineLspBase",        { fg = c and c.muted or (light and "#7A7880" or "#93a1a1"),  bg = lsp_bg })
        vim.api.nvim_set_hl(0, "LualineCopilotOn",      { fg = c and c.visual or (light and "#7B72C9" or "#cba6f7"),  bg = lsp_bg })
        vim.api.nvim_set_hl(0, "LualineCopilotSpinner", { fg = c and c.yellow or (light and "#A8983A" or "#f9e2af"),  bg = lsp_bg })
        vim.api.nvim_set_hl(0, "LualineCopilotOff",     { fg = c and c.muted or (light and "#7A7880" or "#6c7086"),  bg = lsp_bg })
        for name, fg in pairs(colors) do
          local hl = "LualineLsp_" .. name:gsub("[%-%.]", "_")
          vim.api.nvim_set_hl(0, hl, { fg = fg, bg = lsp_bg })
        end
      end
      setup_lsp_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_lsp_hl })

      -- One refresh path keeps all statusline highlights in sync after theme/layout changes.
      local function refresh_statusline_colors(full)
        setup_breadcrumb_hl()
        setup_git_hl()
        setup_diag_hl()
        setup_lsp_hl()
        if full then
          setup_lualine_theme_hl()
          setup_breadcrumb_hl()
          setup_git_hl()
          setup_diag_hl()
          setup_lsp_hl()
          local ok, lualine = pcall(require, "lualine")
          if ok then lualine.refresh({ place = { "statusline" } }) end
        else
          local ok, lualine = pcall(require, "lualine")
          if ok then
            lualine.refresh({ place = { "statusline" } })
          else
            vim.cmd("redrawstatus")
          end
        end
      end

      local refresh_group = vim.api.nvim_create_augroup("LualineStatuslineRefresh", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = refresh_group,
        callback = function()
          vim.schedule(function()
            refresh_statusline_colors(true)
          end)
        end,
      })
      vim.api.nvim_create_autocmd("OptionSet", {
        group = refresh_group,
        pattern = "background",
        callback = function()
          vim.schedule(function()
            refresh_statusline_colors(true)
          end)
        end,
      })
      vim.api.nvim_create_autocmd({ "VimResized", "WinResized", "FocusGained", "TabEnter" }, {
        group = refresh_group,
        callback = function()
          vim.schedule(function()
            refresh_statusline_colors(false)
          end)
        end,
      })

      -- Show attached language servers, excluding standalone ESLint/Copilot chips below.
      table.insert(opts.sections.lualine_x, {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then return "" end
          local parts = {}
          local seen = {}
          local labels = {
            cssls = "css",
          }
          for _, c in ipairs(clients) do
            if c.name == "eslint" or c.name == "copilot" or c.name == "emmet_language_server" then goto continue end
            if not seen[c.name] then
              seen[c.name] = true
              local icon = lsp_icons[c.name] or "󰒋 "
              local hl = "LualineLsp_" .. c.name:gsub("[%-%.]", "_")
              local label = labels[c.name] or c.name
              if lsp_colors[c.name] then
                parts[#parts + 1] = "%#" .. hl .. "#" .. icon .. label .. "%#LualineLspBase#"
              else
                parts[#parts + 1] = icon .. label
              end
            end
            ::continue::
          end
          return table.concat(parts, "  ")
        end,
        separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        color = function()
          local light = vim.o.background == "light"
          return { fg = light and "#7A7880" or "#93a1a1", bg = light and "#D5D0CA" or "#45475a" }
        end,
      })

      -- Copilot gets a separate status chip so progress/off states are visible.
      table.insert(opts.sections.lualine_x, {
        function()
          local icon = " "
          local ok, status = pcall(require, "copilot.status")
          if not ok then
            return "%#LualineCopilotOff#" .. icon .. "copilot%#LualineLspBase#"
          end
          local s = status.data and status.data.status or ""
          if s == "InProgress" then
            return "%#LualineCopilotSpinner#" .. icon .. "copilot%#LualineLspBase#"
          elseif s == "Normal" then
            return "%#LualineCopilotOn#" .. icon .. "copilot%#LualineLspBase#"
          else
            return "%#LualineCopilotOff#" .. icon .. "copilot%#LualineLspBase#"
          end
        end,
        separator = { left = "", right = "" },
        color = function()
          local light = vim.o.background == "light"
          return { fg = light and "#9BA5B0" or "#6c7086", bg = light and "#C8CCD1" or "#45475a" }
        end,
        cond = function()
          return LazyVim.has("copilot.lua")
        end,
      })

      -- Format chip mirrors the global autoformat toggle.
      table.insert(opts.sections.lualine_x, {
        function()
          local fmt_active = vim.g.autoformat == nil or vim.g.autoformat
          return "󰉼 fmt" .. (fmt_active and " (A)" or "")
        end,
        separator = { left = "", right = "" },
        color = function()
          local light = vim.o.background == "light"
          local lsp_bg = light and "#C8CCD1" or "#45475a"
          return (vim.g.autoformat == nil or vim.g.autoformat)
            and { fg = light and "#7CA686" or "#a6e3a1", bg = lsp_bg }
            or  { fg = light and "#7A7880" or "#586e75", bg = lsp_bg }
        end,
      })

      -- ESLint chip shows both attachment and autosave-fix state.
      table.insert(opts.sections.lualine_x, {
        function()
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return "󰅪 eslint" end
          return "󰅪 eslint" .. (autosave_on and " (A)" or "")
        end,
        separator = { left = "\u{E0B6}", right = "\u{E0B4}" },
        color = function()
          local light = vim.o.background == "light"
          local lsp_bg = light and "#D5D0CA" or "#45475a"
          local eslint_attached = #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          if not eslint_attached then return { fg = light and "#7A7880" or "#586e75", bg = lsp_bg } end
          return autosave_on
            and { fg = light and "#A8983A" or "#f9e2af", bg = lsp_bg }
            or  { fg = light and "#7A7880" or "#93a1a1", bg = lsp_bg }
        end,
      })

      opts.sections.lualine_z = {}
      opts.sections.lualine_y = {}

      -- Path/breadcrumb components are wrapped into rounded chips and truncated safely.
      -- Rotating chip background colors for the path/breadcrumb segments.
      local function chip_bgs()
        return vim.o.background == "light"
          and { "#D5D0CA", "#D5D0CA", "#D5D0CA" }
          or  { "#3A3D41", "#42464D", "#4A4F57" }
      end

      -- Wrap a component into a rounded chip with the given background color.
      local function style_chip(component, bg_fn)
        local comp = component
        if type(comp) == "function" then
          comp = { comp }
        end
        if type(comp) == "string" then
          comp = { comp }
        end
        if type(comp) ~= "table" then
          return comp
        end

        local existing_color = comp.color
        comp.separator = { left = "", right = "" }
        comp.padding = comp.padding or { left = 1, right = 1 }
        comp.color = function()
          local color
          if type(existing_color) == "function" then
            color = existing_color() or {}
          else
            color = existing_color or {}
          end
          color.fg = color.fg or (vim.o.background == "light" and "#4C4F69" or "#CED0D6")
          color.bg = bg_fn()
          return color
        end

        return comp
      end

      opts.sections.lualine_c = opts.sections.lualine_c or {}
      local chip_index = 1
      local styled_c = {}
      for _, comp in ipairs(opts.sections.lualine_c) do
        local head = type(comp) == "table" and comp[1] or comp
        local is_path_like = type(head) == "function" or head == "filename"
        if is_path_like then
          local bg_fn = function()
            local bgs = chip_bgs()
            return bgs[((chip_index - 1) % #bgs) + 1]
          end
          local styled_comp = style_chip(comp, bg_fn)
          if chip_index == 1 then
            styled_comp.padding = { left = 1, right = 0 }
            local path_fn = LazyVim.lualine.pretty_path({ filename_hl = "", directory_hl = "" })
            styled_comp[1] = function(self)
              local icon = require("mini.icons").get("file", vim.fn.expand("%:t"))
              local path = type(path_fn) == "function" and path_fn(self) or ""
              if icon and icon ~= "" then return " " .. icon .. " " .. path end
              return path
            end
            local existing_color_fn = styled_comp.color
            styled_comp.color = function()
              local c = type(existing_color_fn) == "function" and existing_color_fn() or {}
              local cs = vim.g.colors_name or ""
              local is_light = vim.o.background == "light"
              local is_default_white = cs == "default-light"
              local is_islands_white = cs == "islands-white" or cs == "islands-light"
              c.fg = is_light and ((is_default_white or is_islands_white) and "#2F496F" or "#FFFFFF") or "#151619"
              c.bg = is_light and ((is_default_white or is_islands_white) and "#D2E4F5" or "#2A6296") or "#9ccfd8"
              c.gui = (c.gui and c.gui .. ",bold" or "bold")
              return c
            end
          end
          if chip_index > 1 then
            local sep_hl = "LualineBreadcrumbSep" .. (((chip_index - 1) % 3) + 1)
            styled_comp.padding = { left = 0, right = 0 }
            local original = styled_comp[1]
            if type(original) == "function" then
              styled_comp[1] = function(self)
                local str = (original(self) or ""):gsub("^%s+", ""):gsub("%s+$", "")
                return str:gsub(" %%#", "%%#" .. sep_hl .. "#> %%#")
              end
            end
            styled_comp.fmt = function(str)
              local max = math.max(0, vim.o.columns - 100)
              local visible = str:gsub("%%#[^#]*#", "")
              if #visible <= max then return str end
              if max < 5 then return "" end
              local out, count, i = {}, 0, 1
              while i <= #str and count < max - 1 do
                if str:sub(i, i) == "%" and str:sub(i + 1, i + 1) == "#" then
                  local j = str:find("#", i + 2)
                  if j then table.insert(out, str:sub(i, j)); i = j + 1
                  else i = i + 1 end
                else
                  local b = str:byte(i)
                  local char_len = (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
                  table.insert(out, str:sub(i, i + char_len - 1)); count = count + 1; i = i + char_len
                end
              end
              return table.concat(out) .. "..."
            end
          end
          table.insert(styled_c, styled_comp)
          if chip_index == 1 then
            local sep_bg_fn = function()
              return chip_bgs()[1]
            end
            local sep_comp = style_chip({ function() return "|" end }, sep_bg_fn)
            sep_comp.padding = { left = 0, right = 1 }
            sep_comp.color = function()
              return { fg = vim.o.background == "light" and "#9B9792" or "#6B6F75", bg = sep_bg_fn() }
            end
            sep_comp.cond = function()
              return breadcrumb_symbols ~= nil
                and vim.b.trouble_lualine ~= false
                and breadcrumb_symbols.has()
            end
            table.insert(styled_c, sep_comp)
          end
          chip_index = chip_index + 1
        else
          table.insert(styled_c, comp)
        end
      end
      opts.sections.lualine_c = styled_c

      return opts
    end,
  },
}
