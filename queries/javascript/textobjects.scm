; extends

; Class expressions (`const Foo = class { ... }`, `module.exports = class { ... }`)
; are `class` nodes, not `class_declaration`, so the stock query skips them.
(class
  body: (class_body)) @class.outer

(class
  body: (class_body
    .
    "{"
    _+ @class.inner
    "}"))
