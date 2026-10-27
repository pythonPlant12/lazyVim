; extends

; One fold per branch, so `zc` on an `if`, `elif`, `else`, `try`, `except` or `finally` line
; toggles only that branch. The stock fold for the full statement stays.
(if_statement
  "if" @fold
  consequence: (block) @fold
  alternative: (_))

(try_statement
  "try" @fold
  body: (block) @fold)

[
  (elif_clause)
  (else_clause)
  (except_clause)
  (finally_clause)
] @fold
