" F* filetype plugin.
if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" F* identifiers may contain apostrophes (x', foo'bar), so treat ' as a keyword
" character for word motions and completion.
setlocal iskeyword+='

" Comments. Line comments use // and /// ; block comments use (* ... *).
setlocal comments=sr:(*,mb:*,ex:*),:///,://
setlocal commentstring=(*\ %s\ *)
setlocal formatoptions-=t formatoptions+=croql

" Fold on syntax regions (block comments are marked foldable in the syntax
" file). Opt-in: `let g:fstar_fold = 1`.
if get(g:, 'fstar_fold', 0)
  setlocal foldmethod=syntax
endif

" matchit: jump between paired keywords with %.
if exists("loaded_matchit") && !exists("b:match_words")
  let b:match_words = '\<begin\>:\<end\>,\<if\>:\<then\>:\<else\>'
endif

let b:undo_ftplugin = "setlocal iskeyword< comments< commentstring< formatoptions< foldmethod<"
      \ . " | unlet! b:match_words"

let &cpo = s:cpo_save
unlet s:cpo_save
