" F* filetype detection.
" .fst  -- F* implementation module
" .fsti -- F* interface module
" Both share identical lexical syntax; Pulse is embedded inside .fst/.fsti.
autocmd BufRead,BufNewFile *.fst,*.fsti setfiletype fstar
