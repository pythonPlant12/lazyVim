package.loaded["themes.cursor"] = nil -- always re-read so edits apply on :colorscheme
package.loaded["themes.semantic"] = nil
require("themes.cursor").apply("light")
