return {
  "zbirenbaum/copilot.lua",
  opts = {
    copilot_node_command = (function()
      local nvm = vim.fn.expand("$HOME/.nvm")
      local f = io.open(nvm .. "/alias/default", "r")
      if not f then return "node" end
      local ver = f:read("*l"):gsub("%s", "")
      f:close()
      for _ = 1, 3 do
        if ver:match("^v%d") then break end
        local af = io.open(nvm .. "/alias/" .. ver, "r")
        if not af then break end
        ver = af:read("*l"):gsub("%s", "")
        af:close()
      end
      if not ver:match("^v") then ver = "v" .. ver end
      local path = nvm .. "/versions/node/" .. ver .. "/bin/node"
      return vim.fn.filereadable(path) == 1 and path or "node"
    end)(),
  },
}
