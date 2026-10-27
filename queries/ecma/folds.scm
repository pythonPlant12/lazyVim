; Full copy of the nvim-treesitter ecma folds query, not `; extends`: the stock `(catch_clause)`
; fold ends on the `} finally {` line, overlaps the `finally` fold, and nvim-ufo joins the two.
[
  (arguments)
  (for_in_statement)
  (for_statement)
  (while_statement)
  (arrow_function)
  (function_expression)
  (function_declaration)
  (class_declaration)
  (method_definition)
  (do_statement)
  (with_statement)
  (switch_statement)
  (switch_case)
  (switch_default)
  (import_statement)+
  (if_statement)
  (try_statement)
  (array)
  (object)
  (generator_function)
  (generator_function_declaration)
] @fold

; One fold per branch, so `zc` on an `if`, `else`, `try`, `catch` or `finally` line toggles only
; that branch. A branch fold runs from its keyword to its last statement, so the `} else {` line
; of the next branch stays visible.
(if_statement
  "if" @fold
  consequence: (statement_block (_) @fold .)
  alternative: (else_clause))

(else_clause
  (statement_block) @fold)

(try_statement
  "try" @fold
  body: (statement_block (_) @fold .))

(try_statement
  handler: (catch_clause) @fold
  !finalizer)

(try_statement
  handler: (catch_clause
    "catch" @fold
    body: (statement_block (_) @fold .))
  finalizer: (finally_clause))

(finally_clause) @fold
