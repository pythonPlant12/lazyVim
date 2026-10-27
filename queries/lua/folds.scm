; extends

; One fold per branch, so `zc` on an `if`, `elseif` or `else` line toggles only that branch.
; The stock fold for the full statement stays.
(if_statement
  "if" @fold
  consequence: (block) @fold
  alternative: (_))

[
  (elseif_statement)
  (else_statement)
] @fold
