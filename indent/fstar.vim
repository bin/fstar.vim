" F* indentation.
"
" F* has no layout rule and permits very free formatting, so precise
" indentation is undecidable in general. This is a deliberately heuristic
" indenter that handles the common cases (definitions, match/if bodies,
" begin/end, bracket nesting) and otherwise keeps the previous indent. It is
" best-effort by design; disable with `let g:fstar_indent_enabled = 0` to fall
" back to plain autoindent.

if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal autoindent

if !get(g:, 'fstar_indent_enabled', 1)
  finish
endif

setlocal indentexpr=GetFStarIndent()
setlocal indentkeys=0{,0},0),0],!^F,o,O,0=end,0=in,0=\|

let b:undo_indent = "setlocal autoindent< indentexpr< indentkeys<"

if exists("*GetFStarIndent")
  finish
endif

" Strip a trailing line comment and surrounding whitespace (crude: does not
" understand strings, so a // inside a string can over-trim -- acceptable for
" an indentation heuristic).
function! s:Trimmed(line) abort
  let l = substitute(a:line, '//.*$', '', '')
  return substitute(l, '\s\+$', '', '')
endfunction

function! GetFStarIndent() abort
  let prevlnum = prevnonblank(v:lnum - 1)
  if prevlnum == 0
    return 0
  endif

  let sw = shiftwidth()
  let prev = s:Trimmed(getline(prevlnum))
  let curr = getline(v:lnum)
  let ind = indent(prevlnum)

  " Previous line opens a new indented block when it ends with a definition
  " '=', an arrow, then/else, begin, match ... with, or an unclosed bracket.
  if prev =~# '\%(\s\|^\)=$'
        \ || prev =~# '->$' || prev =~# '→$'
        \ || prev =~# '\<then$' || prev =~# '\<else$'
        \ || prev =~# '\<begin$'
        \ || prev =~# '\<with$'
        \ || prev =~# '[([{]$'
    let ind += sw
  endif

  " Current line closes a block: end / in / closing bracket dedent one level.
  if curr =~# '^\s*\%(end\>\|in\>\)' || curr =~# '^\s*[)\]}]'
    let ind -= sw
  endif

  if ind < 0
    let ind = 0
  endif
  return ind
endfunction
