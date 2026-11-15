" Keep HTML heading contents as normal text; tags retain htmlTag/htmlTagN syntax.
syntax clear htmlH1 htmlH2 htmlH3 htmlH4 htmlH5 htmlH6

" Any attribute name is htmlArg, not only the known HTML ones: Vue props such as
" :options get the same color as :disabled. The :, @ or # prefix stays htmlTag.
" The built-in keyword list is cleared: keywords win over matches, so in
" data-media-source-menu only the "data" and "media" parts got the color.
syntax clear htmlArg
syntax match htmlArg contained "\%(\%(^\|\s\)[:@#]\?\)\@3<=[a-zA-Z_][-a-zA-Z0-9_.]*\ze\s*\%(=\|/\?>\|\s\|$\)"
