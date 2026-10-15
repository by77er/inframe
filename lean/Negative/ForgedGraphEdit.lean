-- expect: Constructor for `Inframe.Infra` is marked as private
import Inframe
open Inframe

/-! A program cannot edit the graph except through the builder primitives: `Infra`'s constructor
is private, so a step that empties the graph (or reads it) cannot be written outside the core,
and the `run` lemmas that proofs rely on cover every way a stack changes the graph. -/

def forgetEverything : Infra Unit := ⟨fun _ => ((), {})⟩
