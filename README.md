# fstar.vim

Syntax highlighting for F\*.  `.fst`, `.fsti`, and Pulse.

## Install

`Plug 'bin/fstar.vim'`

## Options

```vim
let g:fstar_fold = 1              " fold block comments; off by default
let g:fstar_indent_enabled = 0   " turn off the heuristic indenter
let g:fstar_sync_fromstart = 0   " faster on huge files, occasionally wrong after edits
```

## Bumping F*

Point `fstar-src` in `flake.nix` at new commit, then `nix flake lock && nix
run .#gen`.  Commit result.  Reserved keywords get highlighted;
anything generator doesn't recognize is listed in the generated file's
header.

## Rough edges

Indentation is heuristic; F* has no layout rule, so exact indentation isn't
decidable. Handles usual cases and otherwise keeps the previous indent;
turn it off if it fights you.

Pulse keywords are contextual but colored wherever they appear as a bare word,
so `fold` used as a variable will light up while `List.fold` won't.
Since it's regex, not a parser, some things are approximate. `**` is one
color whether it's exponent or separating conjunction and refinement braces
look like record braces. A tree-sitter grammar would fix that but that would
require switching to nvim (hipster cringe).
