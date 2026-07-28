-- Semantic highlight registry.
--
-- One place that lists every Treesitter + LSP token group, grouped by semantic
-- category (function call vs definition, type, variable, member, parameter, ...).
-- A theme calls M.apply(hl, colors, langs) with a color per category and every
-- group in that category is assigned the color.
--
-- Language coverage:
--   * Treesitter language variants (@variable.python, @variable.member.ts, ...)
--     link to their base group automatically, so listing the base is enough.
--   * LSP semantic tokens (@lsp.type.*) are registered per language at priority
--     125 and do NOT auto-link, so apply() also stamps the .<lang> variants.
--   * There is a single `python` Treesitter parser/filetype (no python2 vs 3),
--     and "JS old" is the same `javascript` parser — so both collapse into one
--     language entry each.
local M = {}

-- category -> list of base highlight groups
M.registry = {
  -- Functions --------------------------------------------------------------
  ["function.call"] = {
    "@function.call", "@function.method.call",
    "@lsp.type.function", "@lsp.type.method",
  },
  ["function.definition"] = {
    "@function", "@function.method",
    "@lsp.typemod.function.declaration", "@lsp.typemod.method.declaration",
  },
  ["function.special"] = { "@function.special", "@function.builtin", "@function.macro" },

  -- Types / classes --------------------------------------------------------
  ["type"] = {
    "@type", "@constructor",
    "@lsp.type.class", "@lsp.type.enum", "@lsp.type.interface", "@lsp.type.struct",
    "@lsp.type.type", "@lsp.type.typeAlias", "@lsp.type.typeParameter",
  },
  ["type.builtin"] = { "@type.builtin" },

  -- Variables --------------------------------------------------------------
  ["variable"] = {
    "@variable", "@lsp.type.variable", "@lsp.typemod.variable.defaultLibrary",
  },
  ["variable.builtin"] = { "@variable.builtin" },

  -- Members / properties / fields -----------------------------------------
  ["member"] = { "@variable.member", "@property", "@field", "@lsp.type.property" },

  -- Parameters -------------------------------------------------------------
  ["parameter"] = {
    "@variable.parameter", "@parameter",
    "@lsp.type.parameter",
    "@lsp.typemod.parameter.declaration", "@lsp.typemod.parameter.readonly",
    "@lsp.typemod.variable.parameter", "@lsp.typemod.variable.parameter.readonly",
    "@lsp.typemod.variable.readonly.parameter",
  },
  ["parameter.builtin"] = { "@variable.parameter.builtin" },

  -- Constants / enum members -----------------------------------------------
  ["constant"] = { "@constant", "@lsp.typemod.variable.readonly" },
  ["constant.builtin"] = { "@constant.builtin" },
  ["enum.member"] = { "@lsp.type.enumMember" },

  -- Namespaces / decorators ------------------------------------------------
  ["namespace"] = { "@module", "@lsp.type.namespace" },
  ["decorator"] = { "@attribute", "@lsp.type.decorator" },

  -- Literals ---------------------------------------------------------------
  ["string"] = { "@string" },
  ["number"] = { "@number", "@number.float" },
  ["boolean"] = { "@boolean" },

  -- Punctuation / operators / comments -------------------------------------
  ["keyword"] = { "@keyword" },
  ["operator"] = { "@operator" },
  ["punctuation"] = { "@punctuation.bracket", "@punctuation.delimiter" },
  ["comment"] = { "@comment" },
}

-- Languages whose LSP semantic-token variants get stamped explicitly.
M.langs = { "rust", "typescript", "javascript", "python" }

-- Assign a color to every group in each category.
--   hl     : vim.api.nvim_set_hl
--   colors : { [category] = "#rrggbb" | { fg = ..., italic = ..., ... } }
--   langs  : list of language suffixes for LSP groups (defaults to M.langs)
function M.apply(hl, colors, langs)
  langs = langs or M.langs
  for category, groups in pairs(M.registry) do
    local color = colors[category]
    if color ~= nil then
      local spec = type(color) == "table" and color or { fg = color }
      for _, group in ipairs(groups) do
        hl(0, group, spec)
        -- LSP semantic tokens don't auto-link across languages; stamp variants.
        if group:sub(1, 5) == "@lsp." then
          for _, lang in ipairs(langs) do
            hl(0, group .. "." .. lang, spec)
          end
        end
      end
    end
  end
end

return M
