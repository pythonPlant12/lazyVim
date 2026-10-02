; jinja_html: jinja injections plus html for the template text between tags.
; inherits: jinja

((content) @injection.content
  (#set! injection.language "html")
  (#set! injection.combined))
