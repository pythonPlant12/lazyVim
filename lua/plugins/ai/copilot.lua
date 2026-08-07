-- copilot.lua: GitHub Copilot inline completion engine; here pinned to a suitable Node runtime.
return {
  "zbirenbaum/copilot.lua",
  opts = {
    -- Resolve the newest nvm-installed Node >= 22 to run the Copilot agent.
    copilot_node_command = (function()
      -- Copilot needs modern Node; scan nvm directly so shell init is not required.
      local nvm_dir = vim.fn.expand("~/.nvm/versions/node")
      local best_major, best_minor, best_patch = 0, 0, 0
      local best_path = nil
      local handle = vim.loop.fs_scandir(nvm_dir)
      if handle then
        while true do
          local name, typ = vim.loop.fs_scandir_next(handle)
          if not name then break end
          if typ == "directory" then
            local major, minor, patch = name:match("^v(%d+)%.(%d+)%.(%d+)$")
            major, minor, patch = tonumber(major), tonumber(minor), tonumber(patch)
            if major and major >= 22 then
              if major > best_major
                or (major == best_major and minor > best_minor)
                or (major == best_major and minor == best_minor and patch > best_patch)
              then
                local bin = nvm_dir .. "/" .. name .. "/bin/node"
                if vim.fn.filereadable(bin) == 1 then
                  best_major, best_minor, best_patch = major, minor, patch
                  best_path = bin
                end
              end
            end
          end
        end
      end
      return best_path or "node"
    end)(),
  },
}
