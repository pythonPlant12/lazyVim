-- Lualine statusline: mode chip, git branch chip, diagnostics pill, LSP/tool chips,
-- and path breadcrumbs. All colors come from the active theme via themes/statusline_palette.
local P = require("themes.statusline_palette")

return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      require("features.git_status").setup()

      opts.options = vim.tbl_extend("force", opts.options or {}, {
        theme = P.lualine_theme(),
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

      -- Colors for the mode chip; special editor states override the mode color.
      -- All colors come from the theme palette (statusline.states / statusline.mode).
      local function mode_chip_color()
        local p = P.get()
        local state = vim.fn.reg_recording() ~= "" and "recording"
          or vim.g.multicursor_build_mode and "multicursor_build"
          or vim.g.window_resize_mode and "resize"
          or vim.g.multicursor_mode_active and "multicursor"
        if state then
          return { fg = p.states[state].fg, bg = p.states[state].bg, gui = "bold" }
        end

        local mode = vim.fn.mode(1)
        local m = mode:sub(1, 1) == "i" and "insert"
          or (mode == "v" or mode == "V" or mode == "\22") and "visual"
          or "normal"
        return { fg = p.mode[m].fg, bg = p.mode[m].bg, gui = "bold" }
      end

      -- Rounded pill cap as its own component. Cap glyphs are foreground text, so
      -- their color is pre-blended (P.blend_cap) to match the translucent pill body.
      local function chip_cap(glyph, bg_fn, cond)
        return {
          function() return glyph end,
          color = function()
            return { fg = P.blend_cap(bg_fn()), bg = P.get().surface }
          end,
          separator = "",
          padding = { left = 0, right = 0 },
          cond = cond,
        }
      end
      local cap_l, cap_r = "\u{E0B6}", "\u{E0B4}"

      -- Mode chip; special editor states (recording/multicursor/resize) override it.
      opts.sections.lualine_a = {
        chip_cap(cap_l, function() return mode_chip_color().bg end),
        {
          "mode",
          fmt = function(mode)
            -- blink.cmp disables all completion while recording; make it loud.
            local rec = vim.fn.reg_recording()
            if rec ~= "" then return "RECORDING @" .. rec end
            if vim.g.multicursor_build_mode then return "M CURSOR" end
            if vim.g.window_resize_mode then return "RESIZE WINDOW" end
            if vim.g.multicursor_mode_active then return "MULTI SELECT" end
            return mode
          end,
          color = mode_chip_color,
          separator = "",
          padding = { left = 1, right = 1 },
        },
        chip_cap(cap_r, function() return mode_chip_color().bg end),
      }
      opts.sections.lualine_x = {}

      -- Breadcrumb chip highlights; reapplied because colorschemes reset them.
      local function setup_breadcrumb_hl()
        local p = P.get()
        for i, bg in ipairs(p.chips.bgs) do
          vim.api.nvim_set_hl(0, "LualineBreadcrumbSep" .. i, { fg = p.chips.arrow, bg = bg })
          -- Cap + body pair per rotating chip background (caps pre-blended).
          vim.api.nvim_set_hl(0, "LualineChipCap" .. i, { fg = P.blend_cap(bg), bg = p.surface ~= "NONE" and p.surface or nil })
          vim.api.nvim_set_hl(0, "LualineChipBody" .. i, { fg = p.chips.fg, bg = bg })
        end
        vim.api.nvim_set_hl(0, "LualineBreadcrumbStatus", { fg = p.chips.fg, bg = p.chips.bgs[2] or p.chips.bgs[1] })
      end
      setup_breadcrumb_hl()

      -- Git branch chip highlights from the theme palette.
      local function setup_git_hl()
        local g = P.get().git
        vim.api.nvim_set_hl(0, "LualineGitBase",   { fg = g.fg, bg = g.bg, bold = true })
        vim.api.nvim_set_hl(0, "LualineGitBranch", { fg = g.fg, bg = g.bg, bold = true })
        vim.api.nvim_set_hl(0, "LualineGitGreen",  { fg = g.green, bg = g.bg, bold = true })
        vim.api.nvim_set_hl(0, "LualineGitYellow", { fg = g.yellow, bg = g.bg, bold = true })
        vim.api.nvim_set_hl(0, "LualineGitPeach",  { fg = g.peach, bg = g.bg, bold = true })
        vim.api.nvim_set_hl(0, "LualineGitRed",    { fg = g.red, bg = g.bg, bold = true })
      end
      setup_git_hl()

      -- Reapply the lualine mode theme + StatusLine highlights after theme changes.
      local function setup_lualine_theme_hl()
        local ok, lualine = pcall(require, "lualine")
        if not ok then return end
        local cfg = lualine.get_config()
        cfg.options = cfg.options or {}
        cfg.options.theme = P.lualine_theme()
        lualine.setup(cfg)
        local p = P.get()
        vim.api.nvim_set_hl(0, "StatusLine",   { fg = p.fg, bg = p.surface })
        vim.api.nvim_set_hl(0, "StatusLineNC", { fg = p.muted, bg = p.surface })
      end
      vim.defer_fn(function()
        local p = P.get()
        vim.api.nvim_set_hl(0, "StatusLine",   { fg = p.fg, bg = p.surface })
        vim.api.nvim_set_hl(0, "StatusLineNC", { fg = p.muted, bg = p.surface })
      end, 50)

      -- Git branch + working tree indicators (counts come from features/git_status).
      local function has_git_branch()
        return vim.b.gitsigns_head ~= nil and vim.b.gitsigns_head ~= ""
      end
      opts.sections.lualine_b = {
        chip_cap(cap_l, function() return P.get().git.bg end, has_git_branch),
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
          cond = has_git_branch,
          padding = { left = 1, right = 1 },
          separator = "",
          color = function()
            return { bg = P.get().git.bg }
          end,
        },
        chip_cap(cap_r, function() return P.get().git.bg end, has_git_branch),
        {
          function() return "|" end,
          padding = { left = 1, right = 1 },
          separator = "",
          color = function()
            return { fg = P.get().chips.sep }
          end,
          cond = has_git_branch,
        },
      }

      -- Diagnostics pill highlights from the theme palette.
      local function setup_diag_hl()
        local d = P.get().diag
        vim.api.nvim_set_hl(0, "DiagPillCap",   { fg = d.cap, bg = d.cap_bg })
        vim.api.nvim_set_hl(0, "DiagPillBase",  { fg = d.base, bg = d.bg })
        vim.api.nvim_set_hl(0, "DiagPillError", { fg = d.error, bg = d.bg })
        vim.api.nvim_set_hl(0, "DiagPillWarn",  { fg = d.warn, bg = d.bg })
        vim.api.nvim_set_hl(0, "DiagPillInfo",  { fg = d.info, bg = d.bg })
        vim.api.nvim_set_hl(0, "DiagPillHint",  { fg = d.hint, bg = d.bg })
      end
      setup_diag_hl()

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

      -- Compact diagnostics pill, hidden when the current buffer has no diagnostics.
      local function has_diagnostics()
        local d = vim.diagnostic.count(0)
        local e = d[vim.diagnostic.severity.ERROR] or 0
        local w = d[vim.diagnostic.severity.WARN] or 0
        local inf = d[vim.diagnostic.severity.INFO] or 0
        local h = d[vim.diagnostic.severity.HINT] or 0
        return e + w + inf + h > 0
      end
      table.insert(opts.sections.lualine_x, 1, chip_cap(cap_r, function() return P.get().diag.container end, has_diagnostics))
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
        cond = has_diagnostics,
        separator = "",
        color = function()
          local p = P.get()
          return { fg = p.muted, bg = p.diag.container }
        end,
        padding = { left = 1, right = 1 },
      })
      table.insert(opts.sections.lualine_x, 1, chip_cap(cap_l, function() return P.get().diag.container end, has_diagnostics))

      -- Icons for the LSP/tool chips.
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
        copilot        = " ",
        ["null-ls"]    = "󱏿 ",
        ruff           = "󰉁 ",
        ty             = "󰄬 ",
        jinja_lsp      = "󰅩 ",
        ["jinja-lsp"]  = "󰅩 ",
        bacon_ls       = " ",
        ["bacon-ls"]   = " ",
        rust_analyzer  = " ",
        ["rust-analyzer"] = " ",
        jdtls          = "󰬷 ",
      }

      -- Per-server highlight groups for the LSP/tool status chips.
      local function setup_lsp_hl()
        local p = P.get()
        local servers = P.lsp_servers()
        vim.api.nvim_set_hl(0, "LualineLspBase",        { fg = p.lsp.base, bg = p.lsp.bg })
        vim.api.nvim_set_hl(0, "LualineCopilotOn",      { fg = servers.copilot or p.lsp.on, bg = p.lsp.bg })
        vim.api.nvim_set_hl(0, "LualineCopilotSpinner", { fg = p.lsp.spinner, bg = p.lsp.bg })
        vim.api.nvim_set_hl(0, "LualineCopilotOff",     { fg = p.lsp.off, bg = p.lsp.bg })
        for name, fg in pairs(servers) do
          local hl = "LualineLsp_" .. name:gsub("[%-%.]", "_")
          vim.api.nvim_set_hl(0, hl, { fg = fg, bg = p.lsp.bg })
        end
      end
      setup_lsp_hl()

      -- One refresh path keeps all statusline highlights in sync after theme/layout changes.
      local function refresh_statusline_colors(full)
        if full then
          P.refresh_ghostty() -- terminal theme/opacity may have changed
          setup_lualine_theme_hl()
        end
        setup_breadcrumb_hl()
        setup_git_hl()
        setup_diag_hl()
        setup_lsp_hl()
        local ok, lualine = pcall(require, "lualine")
        if ok then
          lualine.refresh({ place = { "statusline" } })
        else
          vim.cmd("redrawstatus")
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
      table.insert(opts.sections.lualine_x, chip_cap(cap_l, function() return P.get().lsp.bg end))
      table.insert(opts.sections.lualine_x, {
        function()
          local clients = vim.lsp.get_clients({ bufnr = 0 })
          if #clients == 0 then return "" end
          local parts = {}
          local seen = {}
          local labels = {
            cssls = "css",
          }
          local servers = P.lsp_servers()
          for _, c in ipairs(clients) do
            if c.name == "eslint" or c.name == "copilot" or c.name == "emmet_language_server" then goto continue end
            if not seen[c.name] then
              seen[c.name] = true
              local icon = lsp_icons[c.name] or "󰒋 "
              local hl = "LualineLsp_" .. c.name:gsub("[%-%.]", "_")
              local label = labels[c.name] or c.name
              if servers[c.name] then
                parts[#parts + 1] = "%#" .. hl .. "#" .. icon .. label .. "%#LualineLspBase#"
              else
                parts[#parts + 1] = icon .. label
              end
            end
            ::continue::
          end
          return table.concat(parts, "  ")
        end,
        separator = "",
        color = function()
          local p = P.get()
          return { fg = p.lsp.base, bg = p.lsp.bg }
        end,
      })

      -- Copilot chip: purple when available, yellow while generating, gray only
      -- when copilot is not attached to the buffer at all.
      table.insert(opts.sections.lualine_x, {
        function()
          local icon = " "
          local ok, status = pcall(require, "copilot.status")
          local s = ok and status.data and status.data.status or ""
          if s == "InProgress" then
            return "%#LualineCopilotSpinner#" .. icon .. "copilot%#LualineLspBase#"
          end
          local attached = #vim.lsp.get_clients({ name = "copilot", bufnr = 0 }) > 0
          if attached then
            return "%#LualineCopilotOn#" .. icon .. "copilot%#LualineLspBase#"
          end
          return "%#LualineCopilotOff#" .. icon .. "copilot%#LualineLspBase#"
        end,
        separator = { left = "", right = "" },
        color = function()
          local p = P.get()
          return { fg = p.lsp.off, bg = p.lsp.bg }
        end,
        cond = function()
          return LazyVim.has("copilot.lua")
        end,
      })

      -- Format chip mirrors the global autoformat toggle: green + (A) when on.
      table.insert(opts.sections.lualine_x, {
        function()
          local fmt_active = vim.g.autoformat == nil or vim.g.autoformat
          return "󰉼 fmt" .. (fmt_active and " (A)" or "")
        end,
        separator = { left = "", right = "" },
        color = function()
          local p = P.get()
          return (vim.g.autoformat == nil or vim.g.autoformat)
            and { fg = p.lsp.green, bg = p.lsp.bg }
            or  { fg = p.lsp.off, bg = p.lsp.bg }
        end,
      })

      -- ESLint chip shows the autosave-fix state; hidden when ESLint does not
      -- apply to the current file (not attached).
      table.insert(opts.sections.lualine_x, {
        function()
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          return "󰅪 eslint" .. (autosave_on and " (A)" or "")
        end,
        separator = "",
        cond = function()
          return #vim.lsp.get_clients({ name = "eslint", bufnr = 0 }) > 0
        end,
        color = function()
          local p = P.get()
          local autosave_on = vim.g.eslint_autosave == nil or vim.g.eslint_autosave
          -- ESLint keeps its identity color; (A) in the text signals autosave.
          local eslint_fg = P.lsp_servers().eslint or p.lsp.yellow
          return autosave_on
            and { fg = eslint_fg, bg = p.lsp.bg }
            or  { fg = p.lsp.off, bg = p.lsp.bg }
        end,
      })
      -- Right edge of the tool pill (fmt is always visible, so the pill never collapses).
      table.insert(opts.sections.lualine_x, chip_cap(cap_r, function() return P.get().lsp.bg end))

      opts.sections.lualine_z = {}
      opts.sections.lualine_y = {}

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
        comp.separator = ""
        comp.padding = comp.padding or { left = 1, right = 1 }
        comp.color = function()
          local color
          if type(existing_color) == "function" then
            color = existing_color() or {}
          else
            color = existing_color or {}
          end
          color.fg = color.fg or P.get().chips.fg
          color.bg = bg_fn()
          return color
        end

        return comp
      end

      -- Path/breadcrumb components are wrapped into rounded chips and truncated safely.
      opts.sections.lualine_c = opts.sections.lualine_c or {}
      local chip_index = 1
      local styled_c = {}
      for _, comp in ipairs(opts.sections.lualine_c) do
        local head = type(comp) == "table" and comp[1] or comp
        local is_path_like = type(head) == "function" or head == "filename"
        if is_path_like then
          local bg_fn = function()
            local bgs = P.get().chips.bgs
            return bgs[((chip_index - 1) % #bgs) + 1]
          end
          local styled_comp = style_chip(comp, bg_fn)
          if chip_index == 1 then
            styled_comp.padding = { left = 1, right = 0 }
            -- modified_hl "" keeps a modified file's name on the chip's own
            -- foreground instead of MatchParen, which this config tints pink.
            local path_fn = LazyVim.lualine.pretty_path({ filename_hl = "", directory_hl = "", modified_hl = "" })
            styled_comp[1] = function(self)
              local icon = require("mini.icons").get("file", vim.fn.expand("%:t"))
              local path = type(path_fn) == "function" and path_fn(self) or ""
              if icon and icon ~= "" then return " " .. icon .. " " .. path end
              return path
            end
            local existing_color_fn = styled_comp.color
            styled_comp.color = function()
              local c = type(existing_color_fn) == "function" and existing_color_fn() or {}
              local p = P.get()
              c.fg = p.path.fg
              c.bg = p.path.bg
              c.gui = (c.gui and c.gui .. ",bold" or "bold")
              return c
            end
          end
          if chip_index > 1 then
            local sep_hl = "LualineBreadcrumbSep" .. (((chip_index - 1) % 3) + 1)
            local cap_idx = ((chip_index - 1) % 3) + 1
            styled_comp.padding = { left = 0, right = 0 }
            local original = styled_comp[1]
            if type(original) == "function" then
              styled_comp[1] = function(self)
                local str = (original(self) or ""):gsub("^%s+", ""):gsub("%s+$", "")
                if str == "" then return "" end
                str = str:gsub(" %%#", "%%#" .. sep_hl .. "#> %%#")
                -- Bracket the chip with pre-blended rounded caps (see chip_cap).
                return "%#LualineChipCap" .. cap_idx .. "#" .. cap_l
                  .. "%#LualineChipBody" .. cap_idx .. "#" .. str
                  .. "%#LualineChipCap" .. cap_idx .. "#" .. cap_r
              end
            end
            -- Truncate long breadcrumbs to the window width, keeping highlight codes intact.
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
          if chip_index == 1 then
            -- First chip (file path) is always visible; caps as own components.
            table.insert(styled_c, chip_cap(cap_l, function() return P.get().path.bg end))
            table.insert(styled_c, styled_comp)
            table.insert(styled_c, chip_cap(cap_r, function() return P.get().path.bg end))
          else
            table.insert(styled_c, styled_comp)
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
