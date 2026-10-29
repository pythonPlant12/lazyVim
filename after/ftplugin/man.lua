-- The man ftplugin maps j/k to gj/gk per buffer, which hides the global j/k swap.
vim.keymap.set("n", "j", "gk", { buffer = true, silent = true, desc = "Up" })
vim.keymap.set("n", "k", "gj", { buffer = true, silent = true, desc = "Down" })
