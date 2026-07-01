(* generate_tokens.ml -- generate syntax/fstar_tokens.vim from F*'s own lexer.
 *
 * Source of truth (at a pinned F* commit):
 *   - src/ml/FStarC_Parser_LexFStar.ml            (reserved keyword table)
 *   - pulse/src/ml/PulseSyntaxExtension_Parser.ml (Pulse contextual keywords)
 *
 * We parse the keyword tables directly out of the lexer so the highlighter
 * tracks the exact F* dialect the project compiles. On an F* bump, re-run this
 * against the new pinned sources (`nix run .#gen`) and commit the result.
 *
 * Every reserved keyword is emitted. Keywords are sorted into a handful of vim
 * highlight groups by the classification table below; anything not in the table
 * still gets highlighted (falls through to fstarKeyword) and is listed in a
 * banner in the output header so a maintainer notices new keywords.
 *
 * Stdlib only; run as `ocaml generate_tokens.ml --lexer .. --pulse .. --rev .. --out ..`. *)

(* --- classification of F* reserved keywords into vim highlight groups ------- *)
let classify = [
  "fstarConditional", ["if"; "then"; "else"; "match"; "with"; "when"];
  "fstarBoolean",     ["true"; "false"];
  "fstarInclude",     ["module"; "open"; "include"; "friend"];
  "fstarStructure",   ["type"; "effect"; "new_effect"; "layered_effect"; "sub_effect";
                       "polymonadic_bind"; "polymonadic_subcomp"; "class"; "instance";
                       "exception"; "new"];
  "fstarException",   ["try"];
  (* declaration qualifiers / storage-class-like modifiers *)
  "fstarStorageClass", ["noeq"; "unopteq"; "irreducible"; "unfold"; "unfoldable"; "inline";
                        "inline_for_extraction"; "noextract"; "private"; "opaque"; "logic";
                        "total"; "reifiable"; "reflectable"; "attributes"];
  (* proof / specification vocabulary *)
  "fstarSpec",        ["requires"; "ensures"; "decreases"; "returns"];
  (* general terms / expression keywords (the default bucket also lands here) *)
  "fstarKeyword",     ["and"; "as"; "assert"; "assume"; "begin"; "by"; "calc"; "eliminate";
                       "end"; "exists"; "forall"; "fun"; "function"; "in"; "introduce"; "let";
                       "of"; "quote"; "range_of"; "rec"; "reify"; "set_range_of"; "synth"; "val"];
]

(* Pulse contextual keywords -> groups. Unlisted -> fstarPulseKeyword. *)
let pulse_classify = [
  "fstarPulseRepeat",  ["while"];
  "fstarPulseKeyword", ["fn"; "mut"; "invariant"; "predicate"; "each"; "rewrite"; "fold";
                        "atomic"; "ghost"; "unobservable"; "opens"; "show_proof_state";
                        "norewrite"; "preserves"; "goto"; "label"; "return"; "continue";
                        "break"; "defer"];
]

let read_file path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic; s

let is_start c = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || c = '_'
let is_cont c  = is_start c || (c >= '0' && c <= '9')
let is_ascii_kw s =
  s <> "_" && String.length s > 0 && is_start s.[0] && String.for_all is_cont s

let dedup xs =
  let seen = Hashtbl.create 97 in
  List.filter
    (fun x -> if Hashtbl.mem seen x then false else (Hashtbl.add seen x (); true))
    xs

(* index of [sub] in [s] at or after [start], or -1 *)
let find_from s sub start =
  let ls = String.length s and lsub = String.length sub in
  let rec go i =
    if i + lsub > ls then -1
    else if String.sub s i lsub = sub then i
    else go (i + 1)
  in
  go (max 0 start)

let skip_ws s i =
  let n = String.length s in
  let rec go i = if i < n && (s.[i] = ' ' || s.[i] = '\t') then go (i + 1) else i in
  go i

let starts_at s i sub =
  let lsub = String.length sub in
  i + lsub <= String.length s && String.sub s i lsub = sub

(* read a double-quoted string body starting just after the opening quote *)
let read_quoted s i =
  let n = String.length s in
  let b = Buffer.create 16 in
  let rec go i =
    if i >= n then None
    else if s.[i] = '"' then Some (Buffer.contents b)
    else (Buffer.add_char b s.[i]; go (i + 1))
  in
  go i

(* reserved keyword strings from `Hashtbl.add keywords "kw" TOKEN` *)
let parse_keywords text =
  let lines = String.split_on_char '\n' text in
  dedup (List.filter_map (fun line ->
    let h = find_from line "Hashtbl.add" 0 in
    if h < 0 then None
    else
      let p = skip_ws line (h + String.length "Hashtbl.add") in
      if starts_at line p "keywords" then
        let p2 = skip_ws line (p + String.length "keywords") in
        if p2 < String.length line && line.[p2] = '"' then
          match read_quoted line (p2 + 1) with
          | Some kw when is_ascii_kw kw -> Some kw
          | _ -> None
        else None
      else None) lines)

(* Pulse contextual keywords from `IDENT "kw"` *)
let parse_pulse text =
  let n = String.length text in
  let rec collect i acc =
    let j = find_from text "IDENT" i in
    if j < 0 then List.rev acc
    else
      let p = skip_ws text (j + 5) in
      let acc =
        if p < n && text.[p] = '"' then
          match read_quoted text (p + 1) with
          | Some kw when is_ascii_kw kw -> kw :: acc
          | _ -> acc
        else acc
      in
      collect (j + 5) acc
  in
  dedup (collect 0 [])

let flatten cl = List.concat_map (fun (g, ws) -> List.map (fun w -> (w, g)) ws) cl
let assign lookup default kw =
  match List.assoc_opt kw lookup with Some g -> g | None -> default
let words_of lookup default group kws =
  List.filter (fun kw -> assign lookup default kw = group) kws
let unclassified lookup kws =
  List.filter (fun kw -> not (List.mem_assoc kw lookup)) kws

let emit_keyword group words =
  if words = [] then None
  else Some ("syn keyword " ^ group ^ " " ^ String.concat " " words)

let emit_match group words =
  if words = [] then None
  else
    let pat = "\\.\\@<!\\<\\%(" ^ String.concat "\\|" words ^ "\\)\\>" in
    Some ("syn match " ^ group ^ " '" ^ pat ^ "'")

let () =
  let lexer = ref "" and pulse = ref "" and rev = ref "unknown" and out = ref "" in
  let rec pa = function
    | "--lexer" :: v :: r -> lexer := v; pa r
    | "--pulse" :: v :: r -> pulse := v; pa r
    | "--rev"   :: v :: r -> rev := v;   pa r
    | "--out"   :: v :: r -> out := v;   pa r
    | [] -> ()
    | x :: _ -> prerr_endline ("unknown arg: " ^ x); exit 2
  in
  pa (List.tl (Array.to_list Sys.argv));

  let keywords = parse_keywords (read_file !lexer) in
  let pulse_kws = parse_pulse (read_file !pulse) in
  let klook = flatten classify and plook = flatten pulse_classify in
  let kw_un = unclassified klook keywords in
  let pu_un = unclassified plook pulse_kws in

  let lines = ref [] in
  let add s = lines := s :: !lines in
  add "\" fstar_tokens.vim -- GENERATED FILE, DO NOT EDIT.";
  add "\"";
  add "\" Reserved keyword lists extracted from F*'s own lexer so that";
  add "\" highlighting tracks the exact dialect the project compiles.";
  add ("\"   F* commit: " ^ !rev);
  add "\"   sources:   src/ml/FStarC_Parser_LexFStar.ml";
  add "\"              pulse/src/ml/PulseSyntaxExtension_Parser.ml";
  add "\" Regenerate with:  nix run .#gen";
  add "\"";
  add (Printf.sprintf "\" %d reserved keywords, %d Pulse contextual keywords."
         (List.length keywords) (List.length pulse_kws));
  if kw_un <> [] then begin
    add "\" NOTE: keywords with no explicit group (fell back to fstarKeyword):";
    add ("\"   " ^ String.concat " " kw_un)
  end;
  if pu_un <> [] then begin
    add "\" NOTE: Pulse keywords with no explicit group (fell back to fstarPulseKeyword):";
    add ("\"   " ^ String.concat " " pu_un)
  end;
  add "";

  add "\" --- F* reserved keywords ---";
  List.iter
    (fun g -> match emit_keyword g (words_of klook "fstarKeyword" g keywords) with
       | Some l -> add l | None -> ())
    ["fstarKeyword"; "fstarConditional"; "fstarBoolean"; "fstarInclude";
     "fstarStructure"; "fstarException"; "fstarStorageClass"; "fstarSpec"];
  add "";

  add "\" --- Pulse contextual keywords (matched only when not part of a qualified name) ---";
  List.iter
    (fun g -> match emit_match g (words_of plook "fstarPulseKeyword" g pulse_kws) with
       | Some l -> add l | None -> ())
    ["fstarPulseKeyword"; "fstarPulseRepeat"];
  add "";

  let buf = Buffer.create 4096 in
  List.iter (fun l -> Buffer.add_string buf l; Buffer.add_char buf '\n') (List.rev !lines);
  let oc = open_out_bin !out in
  Buffer.output_buffer oc buf;
  close_out oc;

  Printf.eprintf "generated %s: %d keywords (%d unclassified), %d pulse (%d unclassified)\n"
    !out (List.length keywords) (List.length kw_un)
    (List.length pulse_kws) (List.length pu_un)
