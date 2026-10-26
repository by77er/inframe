-- expect: anything depends on `cheat`
import Inframe
open Inframe

/-! An `axiom` a stack declares proves whatever it states; the deployment gate refuses it. -/

axiom cheat : False

theorem anything (policy : Policy) (program : Infra Unit) : Gated policy program :=
  cheat.elim

#assert_standard_axioms anything
