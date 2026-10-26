import Lean
import Inframe.Json
import Inframe.Policy

/-!
# The deployment gate

`inframe test`, `plan`, and `apply` gate a Lean stack on more than a test executable's exit
status. For a stack with a `[stacks.<name>.gate]` table the CLI writes a module of its own that
imports the stack and

* states `Gated policy program` about the program and policy `inframe.toml` names, and proves
  it with the configured theorem (or evaluates it when there is none), so a proof of a weaker
  statement, or of a different program, gates nothing;
* runs `#assert_standard_axioms`, so no declaration of the stack, its bindings, or the core may
  rest on `sorry` (`sorryAx`), on `native_decide` (an axiom trusting the compiler), or on an
  `axiom` of its own;
* runs `#assert_compiled_as_proved`, so no definition there swaps in other compiled code with
  `implemented_by` or `extern`: the kernel would prove facts about one body while `main` ran
  another;
* writes the graph of the gated program with `writeGraph`, which the CLI compares with the one
  the stack's `main` printed, so the graph that is deployed is the graph that was checked.

The kernel checks every proof term; what the gate cannot rule out is a stack that runs
metaprograms to tamper with the environment itself. `leanchecker`, shipped with the toolchain,
re-checks compiled modules from scratch for that case.
-/

namespace Inframe

/-- What the deployment gate requires of a stack: the graph `program` builds passes the
reference validator and `policy`. Decidable, so `by decide` proves it for a concrete program. -/
def Gated (policy : Policy) (program : Infra α) : Prop :=
  (buildGraph program).Valid ∧ policy.Holds (buildGraph program)

instance (policy : Policy) (program : Infra α) : Decidable (Gated policy program) :=
  inferInstanceAs (Decidable (_ ∧ _))

/-- Write `program`'s Graph IR to `path`, rendered exactly as `emitGraph` prints it. -/
def writeGraph (path : System.FilePath) (program : Infra α) : IO Unit :=
  IO.FS.writeFile path (renderGraph program ++ "\n")

open Lean Elab Command

/-- The axioms a gated stack may depend on: Lean's standard three. Everything else is refused,
in particular `sorryAx` (what `sorry` elaborates to), the axiom `native_decide` adds for each
use (`<decl>._native.native_decide.ax_…`, or `Lean.ofReduceBool` on older toolchains: trust in
the compiler rather than the kernel), and any `axiom` a stack declares. -/
def standardAxioms : List Name := [``propext, ``Classical.choice, ``Quot.sound]

/-- Whether `module` ships with the Lean toolchain, whose declarations are trusted as built. -/
private def toolchainModule (module : Name) : Bool :=
  [`Init, `Std, `Lean, `Lake].contains module.getRoot

/-- The declarations the gate checks: those of every imported module outside the Lean toolchain
(the stack's own modules, its generated bindings, and the core library) and of the current
module. -/
private def outsideToolchain (env : Environment) : Array Name := Id.run do
  let mut names := env.constants.foldStage2 (fun names name _ => names.push name) #[]
  for module in env.header.moduleNames, data in env.header.moduleData do
    unless toolchainModule module do
      names := names ++ data.constNames
  return names

/-- `#assert_standard_axioms decl*` fails unless every named declaration, every declaration of
the current module, and every declaration imported from outside the Lean toolchain, depends on
`standardAxioms` alone. Checking the
imports matters as much as the named theorem: a `sorry` in a lemma nobody names, or in a
universal theorem the CLI does not state, is still a claim the build would otherwise accept
with a warning. Axiom sets of imported declarations are precomputed in their `.olean`s, so the
check is a lookup per declaration. -/
syntax (name := assertStandardAxioms) "#assert_standard_axioms" (ppSpace ident)* : command

@[command_elab assertStandardAxioms] def elabAssertStandardAxioms : CommandElab
  | `(#assert_standard_axioms $ids*) => do
    let named ← ids.mapM fun id => liftCoreM <| realizeGlobalConstNoOverloadWithInfo id
    let env ← getEnv
    let mut offenders : Array (Name × Array Name) := #[]
    for name in named ++ outsideToolchain env do
      let axioms ← collectAxioms name
      let extra := axioms.filter (!standardAxioms.contains ·)
      unless extra.isEmpty do
        offenders := offenders.push (name, extra)
    unless offenders.isEmpty do
      -- Auxiliary declarations (`_proof_1`, matchers) repeat what their parent says.
      let visible := offenders.filter (!·.1.isInternalDetail)
      let shown := (if visible.isEmpty then offenders else visible).toList
      let lines := (shown.take 20).map fun (name, extra) =>
        s!"  {name} depends on {", ".intercalate (extra.toList.map (s!"`{·}`"))}"
      let more := if shown.length > 20 then s!"\n  … and {shown.length - 20} more" else ""
      throwError "declarations rely on axioms outside Lean's standard three \
        (`sorryAx` is `sorry`; `native_decide` adds an axiom trusting the compiler):\n\
        {"\n".intercalate lines}{more}"
  | _ => throwUnsupportedSyntax

/-- `#assert_compiled_as_proved` fails if a definition of the current module, or one imported
from outside the Lean toolchain, has `@[implemented_by]` or `@[extern]`. The kernel unfolds a definition's body while compiled
code, `main` included, runs the replacement, so `@[implemented_by other] def infrastructure`
would prove one graph and deploy another. Opaque constants (`partial def` among them) may carry
either attribute: the kernel never sees their body, so a proof about them holds whatever runs. -/
syntax (name := assertCompiledAsProved) "#assert_compiled_as_proved" : command

@[command_elab assertCompiledAsProved] def elabAssertCompiledAsProved : CommandElab
  | `(#assert_compiled_as_proved) => do
    let env ← getEnv
    let offenders := (outsideToolchain env).filterMap fun name =>
      match env.find? name with
      | some (.defnInfo _) =>
        match Compiler.getImplementedBy? env name with
        | some implementation => some s!"  {name} is implemented by {implementation}"
        | none => if isExtern env name then some s!"  {name} is implemented externally" else none
      | _ => none
    unless offenders.isEmpty do
      throwError "definitions run different code than the kernel checks:\n\
        {"\n".intercalate offenders.toList}"
  | _ => throwUnsupportedSyntax

end Inframe
