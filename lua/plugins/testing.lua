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
      opts.adapters = opts.adapters or {}
      opts.adapters["neotest-vitest"] = opts.adapters["neotest-vitest"] or {
        filter_dir = function(name)
          return name ~= "node_modules" and name ~= "dist" and name ~= ".git"
        end,
      }
      opts.adapters["neotest-jest"] = opts.adapters["neotest-jest"] or {
        env = { CI = "true" },
        cwd = function(path)
          local pkg = vim.fs.find("package.json", { path = path or vim.fn.getcwd(), upward = true })[1]
          return pkg and vim.fs.dirname(pkg) or vim.fn.getcwd()
        end,
      }
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
        function() require("neotest").run.run(vim.uv.cwd()) end,
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
