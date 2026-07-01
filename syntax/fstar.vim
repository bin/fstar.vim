" Vim syntax file
" Language:    F* (fstar-lang.org), including embedded Pulse
" Maintainer:  fstar.vim
" Filenames:   *.fst *.fsti
"
" Rules here are grounded in F*'s own lexer,
" src/ml/FStarC_Parser_LexFStar.ml, at the pinned commit recorded in
" syntax/fstar_tokens.vim. The reserved-keyword lists in that companion file
" are generated from the lexer; everything else (operators, literals, comments,
" pragmas, Pulse vprops) is hand-written from the same lexer's regexps.

if exists("b:current_syntax")
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

syn case match

" ---------------------------------------------------------------------------
" Reserved keywords (generated from F*'s lexer keyword table).
" Defines: fstarKeyword fstarConditional fstarBoolean fstarInclude
"          fstarStructure fstarException fstarStorageClass fstarSpec
"          fstarPulseKeyword fstarPulseRepeat
" ---------------------------------------------------------------------------
execute 'source' fnameescape(expand('<sfile>:p:h') . '/fstar_tokens.vim')

" ---------------------------------------------------------------------------
" Built-in types and effects (case-based; F* types can be lower- or upper-case)
" ---------------------------------------------------------------------------
" Common ulib type names that are lowercase (case heuristic below only catches
" the upper-case ones). Not exhaustive, and not authoritative like the keyword
" table -- these are library identifiers, highlighted as a convenience.
syn keyword fstarType nat int bool unit string char exn prop logical
syn keyword fstarType Type Type0 eqtype squash pos
syn keyword fstarType int8 int16 int32 int64
syn keyword fstarType uint8 uint16 uint32 uint64 size_t

" Standard effect labels. These are ordinary upper-case identifiers that users
" can extend (via `effect` / `new_effect` / `layered_effect`), so this list is
" a heuristic hint, not a closed set. Pulse computation types included.
syn keyword fstarEffect Tot GTot Pure Ghost Lemma PURE GHOST DIV Div Dv
syn keyword fstarEffect ML EXN Exn Ex All ALL ST St STATE Stack StackInline
syn keyword fstarEffect Heap Steel SteelT SteelGhost SteelAtomic Tac Tactic
syn keyword fstarEffect stt stt_atomic stt_ghost stt_unobservable

" Pulse separation-logic vprop builtins (library identifiers).
syn keyword fstarPulseBuiltin emp pure pts_to

" Proof holes -- flagged loudly. `assume`/`assert` are keywords (not always
" holes) and are left alone; these library functions always admit goals.
syn keyword fstarUnsafe admit admit_ magic sorry

" ---------------------------------------------------------------------------
" Operators.
" F* uses maximal munch over the symbol set !$%&*+-.<>=?^|~:@#\/ and allows
" user-defined mixfix operators, so we match whole runs, never char-by-char.
" `.` is deliberately excluded so qualified names and record access stay plain.
"
" IMPORTANT: this is defined BEFORE comments and pragmas. Among overlapping
" `syn match` items that start at the same column, Vim gives priority to the
" one defined LAST (not the longest). Line comments (//), doc lines (///), and
" pragmas (# %) share a start column with an operator run, so they must be
" defined after this to win -- mirroring the lexer's operator-vs-comment
" tie-break (ensure_no_comment).
"
" A `/` that begins `//` is excluded from the run so that an operator directly
" abutting a comment (e.g. `x +// note`) stops before the `//`, exactly as the
" lexer's ensure_no_comment rolls the operator match back at an embedded `//`.
" ---------------------------------------------------------------------------
syn match   fstarOperator "\%([-!#$%&*+<=>?@^|~:\\]\|/\%(/\)\@!\)\+" display

" ---------------------------------------------------------------------------
" Comments
"   (* ... *)   nested block comment
"   (** ... *)  block doc comment (FSDOC)
"   // ...      line comment
"   /// ...     line doc comment (literate / markdown)
" ---------------------------------------------------------------------------
syn keyword fstarCommentTodo contained TODO FIXME XXX NOTE HACK BUG

" Nested block comment: contains itself to allow (* (* *) *).
syn region  fstarComment matchgroup=fstarComment
      \ start="(\*" end="\*)"
      \ contains=fstarComment,fstarCommentTodo,@Spell fold
" Block doc comment `(**` -- but not the empty comment `(**)`. Defined after the
" plain comment so it wins the longest-match tie on `(**`.
syn region  fstarDocComment matchgroup=fstarDocComment
      \ start="(\*\*)\@!" end="\*)"
      \ contains=fstarComment,fstarCommentTodo,@Spell fold

syn match   fstarLineComment "//.*$" contains=fstarCommentTodo,@Spell
" Line doc comment `///` -- defined after the line comment to win the tie.
syn match   fstarLineDocComment "///.*$" contains=fstarCommentTodo,@Spell

" ---------------------------------------------------------------------------
" Pragmas, meta, macros, attributes
" ---------------------------------------------------------------------------
syn match   fstarPragma "#\%(set-options\|reset-options\|push-options\|pop-options\|restart-solver\|show-options\|print-effects-graph\|check\|eval\)\>"
syn match   fstarPragma "#lang-\w\+"
syn match   fstarPragma "%splice\%(_t\)\?\>"
syn keyword fstarMacro  __SOURCE_FILE__ __LINE__ __FILELINE__

" Attribute openers: [@ ...] [@@ ...] [@@@ ...]. The payload is ordinary F*
" code (strings/identifiers highlight normally); only the marker is colored.
syn match   fstarAttribute "\[@\{1,3}"

" SMT-pattern / well-founded annotation openers.
syn match   fstarSmtPattern "{:\%(pattern\|well-founded\)"

" Uninterpreted ```lang ... ``` blob (e.g. ```pulse). The lexer consumes this
" as one opaque token, so its contents must not be highlighted as F* code.
syn region  fstarBlob start="```\w\+" end="```" contains=NONE keepend

" ---------------------------------------------------------------------------
" Literals
" ---------------------------------------------------------------------------
" String, with escapes and backslash-newline line continuation.
syn match   fstarStringEscape contained "\\\%(x\x\x\|u\x\x\x\x\|[\\\"'bfntrv0]\|$\)"
syn region  fstarString start=+"+ skip=+\\.+ end=+"+ contains=fstarStringEscape,@Spell

" Type variables: 'a 'b ... (an apostrophe-led identifier with no closing quote)
syn match   fstarTypeVar "'\%(\a\|_\)\w*"

" Character literal, incl. escapes and the byte-char `'c'B` variant. Defined
" AFTER type variables so it wins the same-column tie: among overlapping
" syn-match items Vim gives priority to the one defined last. This matches F*'s
" lexer, which lexes char literals before identifiers/type variables ("Must
" appear before ident to avoid 'a <-> 'a' conflict").
syn match   fstarChar "'\%(\\\%(x\x\x\|u\x\x\x\x\|[\\\"'bfntrv0]\)\|[^\\']\)'B\?"

" Numbers. Integers in dec/hex/oct/bin with optional machine-int suffixes
" (y uy s us l ul L uL z sz) and the hex-float suffix LF.
syn match   fstarNumber "\<\%(0[xX]\x\+\|0[oO]\o\+\|0[bB][01]\+\|\d\+\)\%([uU]\?[yslLz]\|sz\|LF\)\?\>"
" Floats / reals: 1.5  1.5e-3  3.14R  and the exponent-only form 1e10.
syn match   fstarFloat  "\<\d\+\.\d\+\%([eE][-+]\?\d\+\)\?R\?\>"
syn match   fstarFloat  "\<\d\+[eE][-+]\?\d\+\>"

" ---------------------------------------------------------------------------
" Names: upper-case identifiers are modules / type & data constructors.
" A qualified path `FStar.List.Tot.map` colors each upper segment and leaves
" the dots and the final lower-case name plain.
" ---------------------------------------------------------------------------
syn match   fstarConstructor "\<\u\w*\>"

" ---------------------------------------------------------------------------
" Unicode token equivalents (from the lexer's keyword / operator / constructor
" tables). ASCII spellings are the norm; these cover the common Unicode forms.
" ---------------------------------------------------------------------------
syn match   fstarKeyword  "∀\|∃\|λ"
syn match   fstarType     "ℕ\|ℤ\|𝔹"
syn match   fstarTypeVar  "α\|β\|γ\|δ\|ε\|φ\|χ\|η\|ι\|κ\|μ\|ν\|π\|θ\|ρ\|σ\|τ\|ψ\|ω\|ξ\|ζ"
syn match   fstarOperator "∧\|∨\|¬\|→\|←\|⟵\|⟹\|⟺\|↝\|▹\|×\|∗\|⇒\|≥\|≤\|≠\|≪\|◃\|÷\|≔\|‖\|√\|∂\|∁\|±"

" ---------------------------------------------------------------------------
" Highlight links
" ---------------------------------------------------------------------------
hi def link fstarKeyword        Keyword
hi def link fstarConditional    Conditional
hi def link fstarBoolean        Boolean
hi def link fstarInclude        Include
hi def link fstarStructure      Structure
hi def link fstarException      Exception
hi def link fstarStorageClass   StorageClass
hi def link fstarSpec           Keyword
hi def link fstarPulseKeyword   Keyword
hi def link fstarPulseRepeat    Repeat
hi def link fstarPulseBuiltin   Function

hi def link fstarType           Type
hi def link fstarEffect         Type
hi def link fstarConstructor    Type
hi def link fstarTypeVar        Special

hi def link fstarComment        Comment
hi def link fstarDocComment     SpecialComment
hi def link fstarLineComment    Comment
hi def link fstarLineDocComment SpecialComment
hi def link fstarCommentTodo    Todo

hi def link fstarString         String
hi def link fstarStringEscape   SpecialChar
hi def link fstarChar           Character
hi def link fstarNumber         Number
hi def link fstarFloat          Float

hi def link fstarPragma         PreProc
hi def link fstarMacro          Macro
hi def link fstarAttribute      PreProc
hi def link fstarSmtPattern     Special
hi def link fstarBlob           String
hi def link fstarOperator       Operator
hi def link fstarUnsafe         Error

" Nested block comments require scanning from the start of the file to be
" colored correctly. Override with `let g:fstar_sync_fromstart = 0` for speed
" on very large files (at the cost of occasional mis-coloring after edits).
if get(g:, 'fstar_sync_fromstart', 1)
  syn sync fromstart
else
  syn sync minlines=200 maxlines=500
endif

let b:current_syntax = "fstar"

let &cpo = s:cpo_save
unlet s:cpo_save
