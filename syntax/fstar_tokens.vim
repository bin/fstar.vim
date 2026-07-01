" fstar_tokens.vim -- GENERATED FILE, DO NOT EDIT.
"
" Reserved keyword lists extracted from F*'s own lexer so that
" highlighting tracks the exact dialect the project compiles.
"   F* commit: c12e51b16de4a5b499a6dcab33d776f35ed4c5c2
"   sources:   src/ml/FStarC_Parser_LexFStar.ml
"              pulse/src/ml/PulseSyntaxExtension_Parser.ml
" Regenerate with:  nix run .#gen
"
" 67 reserved keywords, 21 Pulse contextual keywords.

" --- F* reserved keywords ---
syn keyword fstarKeyword and assert assume begin by calc eliminate end exists forall fun function in introduce let as of quote range_of rec reify set_range_of synth val
syn keyword fstarConditional else if match then when with
syn keyword fstarBoolean false true
syn keyword fstarInclude friend include module open
syn keyword fstarStructure class effect exception instance new new_effect layered_effect polymonadic_bind polymonadic_subcomp sub_effect type
syn keyword fstarException try
syn keyword fstarStorageClass attributes noeq unopteq inline inline_for_extraction irreducible logic noextract opaque private reifiable reflectable total unfold unfoldable
syn keyword fstarSpec decreases ensures returns requires

" --- Pulse contextual keywords (matched only when not part of a qualified name) ---
syn match fstarPulseKeyword '\.\@<!\<\%(mut\|invariant\|predicate\|fn\|each\|rewrite\|fold\|atomic\|ghost\|unobservable\|opens\|show_proof_state\|norewrite\|preserves\|goto\|label\|return\|continue\|break\|defer\)\>'
syn match fstarPulseRepeat '\.\@<!\<\%(while\)\>'

