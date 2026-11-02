package.loaded["themes.cursor"] = nil -- always re-read so edits apply on :colorscheme
package.loaded["themes.semantic"] = nil
require("themes.cursor").apply("midnight_dimmed")

local transparency = require("themes.engine.transparency")
transparency.apply_snacks_backdrop()
transparency.apply_transparent_hl()
