import Inframe.Validate

/-!
# Policies

A policy is a function from a completed graph to a list of violations. `Policy.Holds policy
graph` is the proposition that the list is empty; it is decidable, so a policy over a concrete
stack is proved by `decide` and enforced by the compiler. The same policy value produces a
human-readable report at run time.
-/

namespace Inframe

structure Violation where
  rule : String
  address : String
  message : String
  deriving DecidableEq, Repr

namespace Violation

def render (violation : Violation) : String :=
  s!"[{violation.rule}] {violation.address}: {violation.message}"

instance : ToString Violation := ⟨render⟩

end Violation

structure Policy where
  name : String
  check : Graph → List Violation

namespace Policy

def violations (policy : Policy) (graph : Graph) : List Violation :=
  policy.check graph

/-- The policy reports no violation for `graph`. Decidable. -/
abbrev Holds (policy : Policy) (graph : Graph) : Prop :=
  policy.check graph = []

def holds (policy : Policy) (graph : Graph) : Bool :=
  policy.check graph == []

/-- A rule evaluated against every managed resource. Return `some message` to report a
violation. -/
def resources (name : String) (rule : ResourceSpec → Option String) : Policy :=
  ⟨name, fun graph =>
    graph.resources.filterMap fun resource =>
      (rule resource).map fun message => ⟨name, resource.address.toString, message⟩⟩

/-- A rule evaluated against every managed resource of one provider type. -/
def resourcesOfType (name : String) (resourceType : String) (rule : ResourceSpec → Option String) :
    Policy :=
  resources name fun resource =>
    if resource.resourceType == resourceType then rule resource else none

/-- A rule evaluated against every data source. -/
def dataSources (name : String) (rule : DataSourceSpec → Option String) : Policy :=
  ⟨name, fun graph =>
    graph.dataSources.filterMap fun dataSource =>
      (rule dataSource).map fun message => ⟨name, dataSource.address.toString, message⟩⟩

/-- A rule evaluated against every root output. -/
def outputs (name : String) (rule : String → OutputSpec → Option String) : Policy :=
  ⟨name, fun graph =>
    graph.outputs.filterMap fun (outputName, output) =>
      (rule outputName output).map fun message => ⟨name, "output." ++ outputName, message⟩⟩

/-- A rule over the whole graph. -/
def graph (name : String) (rule : Graph → Option String) : Policy :=
  ⟨name, fun graph => ((rule graph).map fun message => [⟨name, "graph", message⟩]).getD []⟩

/-- The conjunction of several policies. -/
def all (name : String) (policies : List Policy) : Policy :=
  ⟨name, fun graph => policies.flatMap (·.check graph)⟩

/-- The reference validator as a policy, so structural validity and domain rules can be
enforced together. -/
def validGraph : Policy :=
  ⟨"valid-graph", fun graph =>
    match graph.validate with
    | .ok () => []
    | .error error => [⟨"valid-graph", "graph", error.message⟩]⟩

/-- Human-readable outcome. -/
def report (policy : Policy) (graph : Graph) : String :=
  match policy.check graph with
  | [] => s!"policy `{policy.name}` holds"
  | violations =>
    s!"policy `{policy.name}` is violated:\n"
      ++ "\n".intercalate (violations.map fun violation => "  " ++ violation.render)

/-- Print the report and exit with status 1 when the policy is violated. Intended for stack
test executables; the same policy is normally also proved with `decide`. -/
def enforce (policy : Policy) (graph : Graph) : IO Unit := do
  IO.println (policy.report graph)
  unless (policy.check graph).isEmpty do
    IO.Process.exit 1

end Policy

end Inframe
