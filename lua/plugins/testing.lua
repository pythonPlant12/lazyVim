return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-jest",
      "nvim-neotest/neotest-vim-test",
      "vim-test/vim-test",
    },
    opts = function(_, opts)
      local resolver = require("config.lsp_resolver")

      local function file_dir(path)
        if not path or path == "" then
          return vim.fn.getcwd()
        end
        return vim.fn.fnamemodify(path, ":p:h")
      end

      local vitest_root_markers = {
        "vitest.config.ts",
        "vitest.config.js",
        "vitest.config.mts",
        "vitest.config.mjs",
        "vite.config.ts",
        "vite.config.js",
        "vite.config.mts",
        "vite.config.mjs",
        "package.json",
        "pnpm-workspace.yaml",
        "pnpm-lock.yaml",
        "yarn.lock",
        "package-lock.json",
        "bun.lock",
        "bun.lockb",
      }

      local jest_root_markers = {
        "jest.config.ts",
        "jest.config.js",
        "jest.config.mjs",
        "jest.config.cjs",
        "package.json",
        "pnpm-workspace.yaml",
        "pnpm-lock.yaml",
        "yarn.lock",
        "package-lock.json",
        "bun.lock",
        "bun.lockb",
      }

      local function nearest_root(path, markers)
        local target = path and path ~= "" and path or vim.fn.getcwd()
        return resolver.nearest_root_by_markers(target, markers)
      end

      local function vitest_root(path)
        return nearest_root(path, vitest_root_markers)
      end

      local function jest_root(path)
        return nearest_root(path, jest_root_markers)
      end

      local function package_vitest_config(path)
        local root = vitest_root(path)
        local package_json = root .. "/package.json"
        local ok_pkg, pkg_data = pcall(vim.fn.readfile, package_json)
        if ok_pkg and pkg_data and #pkg_data > 0 then
          local ok_dec, pkg = pcall(vim.json.decode, table.concat(pkg_data, "\n"))
          if ok_dec and type(pkg) == "table" and type(pkg.scripts) == "table" then
            for _, name in ipairs({ "test", "test:watch", "test:coverage" }) do
              local cmd = pkg.scripts[name]
              if type(cmd) == "string" then
                local cfg_rel = cmd:match("%-%-config%s+([^%s]+)")
                if cfg_rel then
                  cfg_rel = cfg_rel:gsub("^['\"]", ""):gsub("['\"]$", "")
                  local cfg_abs = vim.fs.normalize(root .. "/" .. cfg_rel)
                  if vim.fn.filereadable(cfg_abs) == 1 then
                    return cfg_abs
                  end
                end
              end
            end
          end
        end

        local cfg = vim.fs.find({
          "vitest.config.ts",
          "vitest.config.js",
          "vitest.config.mts",
          "vitest.config.mjs",
          "vite.config.ts",
          "vite.config.js",
          "vite.config.mts",
          "vite.config.mjs",
        }, {
          path = file_dir(path),
          upward = true,
          stop = root,
        })[1]
        if cfg then
          return cfg
        end

        for _, rel in ipairs({
          "config/vitest.config.ts",
          "config/vitest.config.js",
          "config/vitest.config.mts",
          "config/vitest.config.mjs",
          "config/vite.config.ts",
          "config/vite.config.js",
          "config/vite.config.mts",
          "config/vite.config.mjs",
        }) do
          local cfg_abs = root .. "/" .. rel
          if vim.fn.filereadable(cfg_abs) == 1 then
            return cfg_abs
          end
        end

        return nil
      end

      local function package_vitest_command(path)
        local root = vitest_root(path)
        local local_bin = root .. "/node_modules/.bin/vitest"
        local binary = (vim.fn.executable(local_bin) == 1) and local_bin or "vitest"
        return binary .. " --root=" .. root
      end

      local function current_test_root()
        local buf = vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(buf)
        if path and path ~= "" then
          return nearest_root(path, vitest_root_markers)
        end
        return vim.fn.getcwd()
      end

      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-vitest"] = vim.tbl_deep_extend("force", opts.adapters["neotest-vitest"] or {}, {
        vitestCommand = function(path)
          return package_vitest_command(path)
        end,
        cwd = function(path)
          return vitest_root(path)
        end,
        vitestConfigFile = function(path)
          return package_vitest_config(path)
        end,
        filter_dir = function(name)
          return name ~= "node_modules" and name ~= "dist" and name ~= ".git"
        end,
      })
      opts.adapters["neotest-jest"] = vim.tbl_deep_extend("force", opts.adapters["neotest-jest"] or {}, {
        env = { CI = "true" },
        cwd = function(path)
          return jest_root(path)
        end,
      })
      opts.adapters["neotest-vim-test"] = opts.adapters["neotest-vim-test"] or {}
    end,
    keys = {
      {
        "<leader>tn",
        function() require("neotest").run.run() end,
        desc = "Run Nearest (Neotest)",
      },
      {
        "<leader>tf",
        function() require("neotest").run.run(vim.fn.expand("%")) end,
        desc = "Run File (Neotest)",
      },
      {
        "<leader>tA",
        function() require("neotest").run.run(current_test_root()) end,
        desc = "Run All Test Files (Neotest)",
      },
      {
        "<leader>tq",
        function() require("neotest").run.stop() end,
        desc = "Stop (Neotest)",
      },
      {
        "[t",
        function() require("neotest").jump.prev({ status = "failed" }) end,
        desc = "Prev Failed Test",
      },
      {
        "]t",
        function() require("neotest").jump.next({ status = "failed" }) end,
        desc = "Next Failed Test",
      },
    },
  },
}
