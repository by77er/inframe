-- expect: weakened depends on `sorryAx`
import Inframe
open Inframe

/-! A `sorry` builds with only a warning, so a test executable that checks a concrete graph at
run time still exits 0 while a universal theorem beside it is unproved. The deployment gate
refuses it. -/

theorem weakened (graph : Graph) : graph.Valid := by
  sorry

#assert_standard_axioms weakened
