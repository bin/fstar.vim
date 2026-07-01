/// A sample F* module exercising the constructs this plugin highlights.
/// Open it in Vim to eyeball the colors; it is not meant to typecheck.
module Sample.Highlight

open FStar.List.Tot
open FStar.Mul
module U64 = FStar.UInt64

(** An FSDOC block doc comment.
    Spanning multiple lines. *)

// A line comment, and (* a nested (* block *) comment *).

#push-options "--fuel 1 --ifuel 0 --z3rlimit 20"
#restart-solver

[@@ "opaque_to_smt"]
let answer : nat = 42

irreducible
unfold let twice (x: int) : int = x + x

let hexy  : U64.t = 0x8080808080808080uL
let bytey  = 255uy
let sizey  = 32sz
let realpi = 3.14R
let floaty = 1.5e-3
let ch     = '\n'
let chb    = 'A'B
let greeting = "hello,\t\"world\"\n"

type color =
  | Red
  | Green
  | Blue

let is_warm (c: color) : bool =
  match c with
  | Red   -> true
  | Green -> false
  | Blue  -> false

// Refinement type, effects, and logical operators in a spec.
val clamp (lo hi x: int) : Pure int
  (requires lo <= hi)
  (ensures fun r -> lo <= r /\ r <= hi)

let rec sum (xs: list nat) : Tot nat (decreases xs) =
  match xs with
  | []      -> 0
  | y :: ys -> y + sum ys

let lemma_sum_nonneg (xs: list nat)
  : Lemma (ensures sum xs >= 0)
  = admit ()

let pipe_example (xs: list int) : list int =
  xs |> filter (fun x -> x > 0) |> map (fun x -> x * 2)

let quantified (p: int -> prop) : prop =
  forall (x: int). x >= 0 ==> p x <==> p (x + 1)
