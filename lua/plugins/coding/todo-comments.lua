-- todo-comments: the tag (WARNING, TODO, NOTE, ...) keeps its colored
-- background; the text after it keeps the comment color.
return {
  {
    "folke/todo-comments.nvim",
    opts = { highlight = { after = "" } },
  },
}
