/// A sample file exercising embedded Pulse (separation-logic) syntax.
module Sample.Pulse

open Pulse.Lib.Pervasives
module V = Pulse.Lib.Vec

// Pulse `fn` blocks, vprops (** separating conjunction, pts_to, emp, pure),
// and the exists*/forall* quantifiers over vprops.

fn noop (_: unit)
  requires emp
  ensures emp
{
  ()
}

fn incr (r: ref int)
  requires pts_to r 'i
  ensures pts_to r ('i + 1)
{
  let x = !r;
  r := x + 1;
}

ghost
fn reveal_pair (r1 r2: ref int)
  requires pts_to r1 'a ** pts_to r2 'b
  ensures  pts_to r1 'a ** pts_to r2 'b
{
  ()
}

atomic
fn read_atomic (r: ref int)
  requires exists* v. pts_to r v
  returns v: int
  ensures pure (v >= 0)
{
  admit ()
}
