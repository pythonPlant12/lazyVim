return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          -- Gradle 7.x requires Java <= 17; use Java 17 for Gradle tooling API
          -- while jdtls itself runs on Java 25 (JAVA_HOME).
          import = {
            gradle = {
              java = {
                home = "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home",
              },
            },
          },
          -- Advertise available JDK runtimes so jdtls can compile sources
          -- with the correct language level per project.
          configuration = {
            runtimes = {
              {
                name = "JavaSE-17",
                path = "/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home",
              },
              {
                name = "JavaSE-25",
                path = "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
                default = true,
              },
            },
          },
        },
      })
    end,
  },
}
