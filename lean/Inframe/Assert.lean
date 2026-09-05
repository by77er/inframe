import Lean
import Inframe.Policy

/-!
# Compile-time assertions by evaluation

`theorem … := by decide` asks the kernel to reduce a policy over a graph. That is a proof, and
it is the right tool for graphs that are small or symbolic; on a deployed graph with dozens of
resources and multi-kilobyte literals the kernel unfolds every string character by character
and `decide` does not finish, and `native_decide` has crashed while re-checking the result.

`#assert_policy` and `#assert_valid` are the scalable check: they evaluate the policy (or the
reference validator) with Lean's compiled evaluator while the module elaborates, and fail the
build with the violation report. Like `#guard`, passing is not a proof, but a stack cannot
build while it violates the policy, which is what `inframe test` and the lifecycle gate need.
-/

namespace Inframe

open Lean Elab Command Term Meta

/-- `#assert_policy policy graph` fails the build with the report if `policy` is violated by
`graph`. Both are ordinary terms (`#assert_policy policies (buildGraph infrastructure)`); they
are evaluated, not reduced by the kernel, so the check scales to real graphs. -/
syntax (name := assertPolicy) "#assert_policy " term:max term:max : command

/-- `#assert_valid graph` fails the build with the validation error if the reference validator
rejects `graph`. -/
syntax (name := assertValid) "#assert_valid " term:max : command

private def evaluate (α : Type) (type : Expr) (term : Syntax) : TermElabM (Option α) := do
  let value ← Term.elabTermEnsuringType term type
  Term.synthesizeSyntheticMVarsNoPostponing
  let value ← instantiateMVars value
  let mvars ← getMVars value
  if mvars.isEmpty then
    some <$> unsafe evalExpr (checkMeta := false) α type value
  else
    _ ← Term.logUnassignedUsingErrorInfos mvars
    pure none

@[command_elab assertPolicy] def elabAssertPolicy : CommandElab
  | `(#assert_policy $policy $graph) => liftTermElabM do
    let type := mkApp (mkConst ``List [Level.zero]) (mkConst ``Violation)
    let term ← `((Inframe.Policy.violations $policy $graph : List Inframe.Violation))
    match ← evaluate (List Violation) type term with
    | some [] | none => pure ()
    | some violations =>
      throwError "policy is violated:\n{"\n".intercalate (violations.map fun v => "  " ++ v.render)}"
  | _ => throwUnsupportedSyntax

@[command_elab assertValid] def elabAssertValid : CommandElab
  | `(#assert_valid $graph) => liftTermElabM do
    let type := mkApp (mkConst ``Option [Level.zero]) (mkConst ``String)
    let term ← `((Inframe.Graph.validationError? $graph : Option String))
    match ← evaluate (Option String) type term with
    | some none | none => pure ()
    | some (some error) => throwError "graph is invalid: {error}"
  | _ => throwUnsupportedSyntax

end Inframe
