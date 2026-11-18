import Lean.Elab.Term

/-!
# Where a node was declared

Every builder primitive takes an `Origin`: the module, the enclosing declaration, and the line
of the call that added the node. It is filled in at the call site by the `origin_here` tactic,
so a stack never writes one, and it is recorded beside the graph rather than in it: no
`ResourceSpec` carries its origin, Graph IR does not mention it, and neither validity nor any
policy can depend on it. `inframe serve` reads the origins to lay a stack out by the modules and
definitions of its source.
-/

namespace Inframe

/-- The source position of the call that added a node. -/
structure Origin where
  /-- The module being compiled, for example `Infra.Platform`. -/
  module : String
  /-- The declaration the call is written in, for example `createDatabases`; empty at top level. -/
  declaration : String
  /-- The one-based line of the call; `0` when the call has no position. -/
  line : Nat
  deriving DecidableEq, Repr

/-- An origin for nodes with no call site, such as those built by a metaprogram. -/
def Origin.unknown : Origin := ⟨"", "", 0⟩

open Lean Elab Term in
/-- The `Origin` of the place this term is elaborated: an ordinary structure literal, so the
kernel and compiled code see the same constant. -/
elab "origin_here%" : term => do
  let module := (← getMainModule).toString
  let declaration := match (← getDeclName?) with
    | some name => (privateToUserName name.eraseMacroScopes).toString
    | none => ""
  let fileMap ← getFileMap
  let line := match (← getRef).getPos? with
    | some position => (fileMap.toPosition position).line
    | none => 0
  return mkApp3 (mkConst ``Origin.mk) (mkStrLit module) (mkStrLit declaration) (mkNatLit line)

/-- Supplies an `Origin` parameter with the position of the call that left it out. A helper
that wraps a builder can forward its own origin instead, so the node is attributed to the
helper's caller:

```lean
def bucket (name : String) (origin : Origin := by origin_here) : Infra … :=
  SpacesBucket.create name { … } (origin := origin)
```
-/
macro "origin_here" : tactic => `(tactic| exact origin_here%)

end Inframe
