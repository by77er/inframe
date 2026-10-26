-- expect: compiled depends on `compiled._native.native_decide
import Inframe
open Inframe

/-! `native_decide` trusts the compiler instead of the kernel; the deployment gate refuses it. -/

theorem compiled : (buildGraph (pure () : Infra Unit)).Valid := by
  native_decide

#assert_standard_axioms compiled
