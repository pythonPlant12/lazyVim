local resolver = require("config.lsp_resolver")

local vitest_root_markers_global = {
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

local playwright_root_markers_global = {
  "playwright.config.ts",
  "playwright.config.js",
  "package.json",
  "pnpm-workspace.yaml",
  "pnpm-lock.yaml",
  "yarn.lock",
  "package-lock.json",
  "bun.lock",
  "bun.lockb",
}

local function normalize_slashes(path)
  return (path or ""):gsub("\\", "/")
end

local function is_playwright_test_path(path)
  local normalized = normalize_slashes(path)
  if normalized == "" then
    return false
  end

  local under_e2e = normalized:match("/tests/e2e/") ~= nil or normalized:match("/e2e/") ~= nil
  if not under_e2e then
    return false
  end

  return normalized:match("%.spec%.[jt]sx?$") ~= nil or normalized:match("%.test%.[jt]sx?$") ~= nil
end

local python_test_markers_global = {
  "pytest.ini",
  "pyproject.toml",
  "setup.cfg",
  "setup.py",
  "tox.ini",
  "requirements.txt",
  "Pipfile",
  "conftest.py",
}

for _, marker in ipairs(resolver.python_project_markers or {}) do
  python_test_markers_global[#python_test_markers_global + 1] = marker
end

local function current_test_root_for_active_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(bufnr)
  if not path or path == "" then
    return vim.fn.getcwd()
  end

  if vim.bo[bufnr].filetype == "python" or path:match("%.py$") then
    return resolver.nearest_root_by_markers(path, python_test_markers_global)
  end

  if is_playwright_test_path(path) then
    return resolver.nearest_root_by_markers(path, playwright_root_markers_global)
  end

  return resolver.nearest_root_by_markers(path, vitest_root_markers_global)
end

return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/neotest-python",
      "marilari88/neotest-vitest",
      "nvim-neotest/neotest-jest",
      "thenbe/neotest-playwright",
    },
    opts = function(_, opts)
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

      local playwright_root_markers = {
        "playwright.config.ts",
        "playwright.config.js",
        "package.json",
        "pnpm-workspace.yaml",
        "pnpm-lock.yaml",
        "yarn.lock",
        "package-lock.json",
        "bun.lock",
        "bun.lockb",
      }

      local python_test_markers = {
        "pytest.ini",
        "pyproject.toml",
        "setup.cfg",
        "setup.py",
        "tox.ini",
        "requirements.txt",
        "Pipfile",
        "conftest.py",
      }

      for _, marker in ipairs(resolver.python_project_markers or {}) do
        python_test_markers[#python_test_markers + 1] = marker
      end

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

      local function python_test_root(path)
        return nearest_root(path, python_test_markers)
      end

      local function uv_is_file(path)
        local st = path and vim.uv.fs_stat(path) or nil
        return st and st.type == "file"
      end

      local function uv_is_dir(path)
        local st = path and vim.uv.fs_stat(path) or nil
        return st and st.type == "directory"
      end

      local function parent_dir(path)
        local normalized = normalize_slashes(path):gsub("/+$", "")
        if normalized == "" or normalized == "/" then
          return "/"
        end
        local parent = normalized:match("^(.*)/[^/]+$")
        if not parent or parent == "" then
          if normalized:sub(1, 1) == "/" then
            return "/"
          end
          return normalized
        end
        return parent
      end

      local function path_dir(path)
        if uv_is_dir(path) then
          return normalize_slashes(path):gsub("/+$", "")
        end
        return parent_dir(path)
      end

      local function path_within(path, base)
        local p = normalize_slashes(path):gsub("/+$", "")
        local b = normalize_slashes(base):gsub("/+$", "")
        if p == b then
          return true
        end
        return p:sub(1, #b + 1) == (b .. "/")
      end

      local function has_any_marker_fs(dir, markers)
        for _, marker in ipairs(markers) do
          if uv_is_file(dir .. "/" .. marker) then
            return true
          end
        end
        return false
      end

      local function nearest_root_fs(path, markers)
        local start_dir = path_dir(path)
        local cwd = normalize_slashes(vim.uv.cwd() or ""):gsub("/+$", "")
        local stop = (cwd ~= "" and path_within(start_dir, cwd)) and cwd or nil
        local current = start_dir

        while current and current ~= "" do
          if has_any_marker_fs(current, markers) then
            return current
          end
          if stop and current == stop then
            break
          end
          local parent = parent_dir(current)
          if not parent or parent == current then
            break
          end
          current = parent
        end

        if stop and stop ~= "" then
          return stop
        end
        if cwd ~= "" then
          return cwd
        end
        return start_dir
      end

      local function playwright_root(path)
        return nearest_root_fs(path, playwright_root_markers)
      end

      local function package_manager_for_root(root)
        local package_json = root .. "/package.json"
        local ok_pkg, pkg_data = pcall(vim.fn.readfile, package_json)
        if ok_pkg and pkg_data and #pkg_data > 0 then
          local ok_dec, pkg = pcall(vim.json.decode, table.concat(pkg_data, "\n"))
          if ok_dec and type(pkg) == "table" and type(pkg.packageManager) == "string" then
            local manager = pkg.packageManager:match("^(%w+)@")
            if manager == "pnpm" or manager == "yarn" or manager == "npm" or manager == "bun" then
              return manager
            end
          end
        end

        if vim.fn.filereadable(root .. "/pnpm-lock.yaml") == 1 or vim.fn.filereadable(root .. "/pnpm-workspace.yaml") == 1 then
          return "pnpm"
        end
        if vim.fn.filereadable(root .. "/yarn.lock") == 1 then
          return "yarn"
        end
        if vim.fn.filereadable(root .. "/bun.lock") == 1 or vim.fn.filereadable(root .. "/bun.lockb") == 1 then
          return "bun"
        end

        return "npm"
      end

      local function package_exec_command(root, executable)
        local local_bin = root .. "/node_modules/.bin/" .. executable
        if vim.fn.executable(local_bin) == 1 then
          return local_bin
        end

        local manager = package_manager_for_root(root)
        if manager == "pnpm" and vim.fn.executable("pnpm") == 1 then
          return "pnpm exec " .. executable
        end
        if manager == "yarn" and vim.fn.executable("yarn") == 1 then
          return "yarn " .. executable
        end
        if manager == "bun" and vim.fn.executable("bun") == 1 then
          return "bun x " .. executable
        end
        if vim.fn.executable("npx") == 1 then
          return "npx --yes " .. executable
        end

        return executable
      end

      local function find_upward(path, targets, stop_dir)
        return vim.fs.find(targets, {
          path = file_dir(path),
          upward = true,
          stop = stop_dir,
        })[1]
      end

      local function find_node_binary(start_dir, executable)
        local current = normalize_slashes(start_dir):gsub("/+$", "")
        local workspace = normalize_slashes(vim.uv.cwd() or ""):gsub("/+$", "")
        while current and current ~= "" do
          local candidate = current .. "/node_modules/.bin/" .. executable
          if uv_is_file(candidate) then
            return candidate
          end
          if workspace ~= "" and current == workspace then
            break
          end
          local parent = parent_dir(current)
          if not parent or parent == "" or parent == current then
            break
          end
          current = parent
        end
        return nil
      end

      local function find_in_path(executable)
        local path_env = vim.env.PATH or ""
        local sep = (vim.loop.os_uname().version or ""):match("Windows") and ";" or ":"
        for dir in path_env:gmatch("[^" .. sep .. "]+") do
          local candidate = normalize_slashes(dir) .. "/" .. executable
          if uv_is_file(candidate) then
            return candidate
          end
        end
        return nil
      end

      local function find_upward_fs(path, targets, stop_dir)
        local current = path_dir(path)
        local stop = stop_dir and normalize_slashes(stop_dir):gsub("/+$", "") or nil

        while current and current ~= "" do
          for _, name in ipairs(targets) do
            local candidate = current .. "/" .. name
            if uv_is_file(candidate) then
              return candidate
            end
          end

          if stop and current == stop then
            break
          end
          local parent = parent_dir(current)
          if not parent or parent == current then
            break
          end
          current = parent
        end

        return nil
      end

      local function playwright_test_file(path)
        if type(path) ~= "string" then
          return false
        end
        local is_pw = is_playwright_test_path(path)
        if is_pw then
          vim.g.neotest_playwright_last_test_path = path
        end
        return is_pw
      end

      local function playwright_context_path()
        local cached = vim.g.neotest_playwright_last_test_path
        if type(cached) == "string" and cached ~= "" then
          return cached
        end
        return vim.loop.cwd()
      end

      local function playwright_config(path)
        local root = playwright_root(path)
        local cfg = find_upward_fs(path, { "playwright.config.ts", "playwright.config.js" }, root)
        if cfg then
          return cfg
        end

        for _, name in ipairs({ "playwright.config.ts", "playwright.config.js" }) do
          local candidate = root .. "/" .. name
          if uv_is_file(candidate) then
            return candidate
          end
        end

        return nil
      end

      local function playwright_binary(path)
        local root = playwright_root(path)
        local local_bin = find_node_binary(root, "playwright")
        if local_bin then
          return local_bin
        end

        local from_path = find_in_path("playwright")
        if from_path then
          return from_path
        end

        return "playwright"
      end

      local function python_exec_for_root(root)
        local venv = resolver.python_venv_for_root(root)
        local from_venv = resolver.python_exec_from_venv(venv, "python")
        if from_venv then
          return from_venv
        end

        local py3 = vim.fn.exepath("python3")
        if py3 ~= "" then
          return py3
        end

        local py = vim.fn.exepath("python")
        if py ~= "" then
          return py
        end

        return "python"
      end

      local function python_pytest_config(root)
        for _, name in ipairs({ "pytest.ini", "pyproject.toml", "setup.cfg", "tox.ini" }) do
          local cfg = root .. "/" .. name
          if vim.fn.filereadable(cfg) == 1 then
            return cfg
          end
        end
        return nil
      end

      local function python_has_module(python_command, module)
        local cmd = vim.deepcopy(python_command)
        vim.list_extend(cmd, { "-c", "import " .. module })
        local result = vim.system(cmd, { text = true }):wait()
        return result.code == 0
      end

      local function use_python_filetype(bufnr, path)
        if vim.bo[bufnr].filetype == "python" then
          return true
        end
        return type(path) == "string" and path:match("%.py$") ~= nil
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

        local cfg = find_upward(path, {
          "vitest.config.ts",
          "vitest.config.js",
          "vitest.config.mts",
          "vitest.config.mjs",
          "vite.config.ts",
          "vite.config.js",
          "vite.config.mts",
          "vite.config.mjs",
        }, root)
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
        local binary = package_exec_command(root, "vitest")
        return binary .. " --root=" .. root
      end

      local function current_test_root()
        local buf = vim.api.nvim_get_current_buf()
        local path = vim.api.nvim_buf_get_name(buf)
        if path and path ~= "" then
          if use_python_filetype(buf, path) then
            return python_test_root(path)
          end
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
        is_test_file = function(file_path)
          local normalized = normalize_slashes(file_path)
          if normalized == "" then
            return false
          end
          if playwright_test_file(normalized) then
            return false
          end
          if normalized:match("__tests__") then
            return true
          end
          return normalized:match("%.spec%.[jt]sx?$") ~= nil or normalized:match("%.test%.[jt]sx?$") ~= nil
        end,
      })
      opts.adapters["neotest-playwright"] = vim.tbl_deep_extend("force", opts.adapters["neotest-playwright"] or {}, {
        is_test_file = function(file_path)
          return playwright_test_file(file_path)
        end,
        filter_dir = function(name, rel_path)
          if name == "node_modules" or name == ".git" then
            return false
          end
          if not rel_path or rel_path == "" then
            return true
          end
          local normalized_rel = normalize_slashes(rel_path)
          return normalized_rel == "tests"
            or normalized_rel:match("^tests/e2e$") ~= nil
            or normalized_rel:match("^tests/e2e/") ~= nil
        end,
        options = {
          get_cwd = function()
            local path = playwright_context_path()
            return playwright_root(path)
          end,
          get_playwright_config = function()
            local path = playwright_context_path()
            return playwright_config(path) or (playwright_root(path) .. "/playwright.config.ts")
          end,
          get_playwright_binary = function()
            local path = playwright_context_path()
            return playwright_binary(path)
          end,
          persist_project_selection = true,
          enable_dynamic_test_discovery = false,
        },
      })
      opts.adapters["neotest-jest"] = vim.tbl_deep_extend("force", opts.adapters["neotest-jest"] or {}, {
        env = { CI = "true" },
        cwd = function(path)
          return jest_root(path)
        end,
      })
      opts.adapters["neotest-python"] = vim.tbl_deep_extend("force", opts.adapters["neotest-python"] or {}, {
        python = function(root)
          local resolved_root = root and root ~= "" and root or python_test_root(vim.api.nvim_buf_get_name(0))
          return python_exec_for_root(resolved_root)
        end,
        runner = function(python_command)
          if python_has_module(python_command, "pytest") then
            return "pytest"
          end
          if python_has_module(python_command, "django") then
            return "django"
          end
          return "unittest"
        end,
        args = function(runner, position)
          if runner ~= "pytest" then
            return {}
          end

          local root = python_test_root(position.path)
          local args = { "--rootdir", root }
          local cfg = python_pytest_config(root)
          if cfg then
            vim.list_extend(args, { "-c", cfg })
          end
          return args
        end,
      })
      opts.adapters["neotest-vim-test"] = false
    end,
    keys = {
      {
        "<leader>ta",
        function() require("neotest").run.run(current_test_root_for_active_buffer()) end,
        desc = "Run All Test Files (Neotest)",
      },
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
        function() require("neotest").run.run(current_test_root_for_active_buffer()) end,
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
