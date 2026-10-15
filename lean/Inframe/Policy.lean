import Inframe.Validate

/-!
# Policies

A policy is a function from a completed graph to a list of violations. `Policy.Holds policy
graph` is the proposition that the list is empty; it is decidable, so a policy over a concrete
stack is proved by `decide` and enforced by the compiler. The same policy value produces a
human-readable report at run time.

A rule over symbolic values has three outcomes, not two: it passes, it is violated, or it cannot
be decided from the graph because a value it checks is only known once OpenTofu plans (a data
source's or another resource's attribute, a function of one, a secret). The third is an
`unknown` finding. Nothing here evaluates a rule against the plan, so an unknown finding fails
the policy exactly as a violation does, and the report names it apart: a value the policy
cannot see never passes.
-/

namespace Inframe

/-- What a finding says about the graph. -/
inductive Outcome where
  /-- The graph breaks the rule. -/
  | violated
  /-- The rule cannot be decided from the graph: a value it checks is only known once OpenTofu
  plans. It fails the policy like a violation, since no plan is consulted here. -/
  | unknown
  deriving DecidableEq, Repr

structure Violation where
  rule : String
  address : String
  message : String
  outcome : Outcome
  deriving DecidableEq, Repr

namespace Violation

def render (violation : Violation) : String :=
  match violation.outcome with
  | .violated => s!"[{violation.rule}] {violation.address}: {violation.message}"
  | .unknown => s!"[{violation.rule}] {violation.address}: unknown until plan: {violation.message}"

/-- The heading of a report listing `violations`: a policy that only failed to decide is not
called violated. -/
def heading (violations : List Violation) : String :=
  if violations.any (·.outcome == .violated) then "is violated"
  else "cannot be decided from the graph"

instance : ToString Violation := ⟨render⟩

end Violation

structure Policy where
  name : String
  check : Graph → List Violation

namespace Policy

def violations (policy : Policy) (graph : Graph) : List Violation :=
  policy.check graph

/-- The policy reports no violation, and no unknown value, for `graph`. Decidable. -/
abbrev Holds (policy : Policy) (graph : Graph) : Prop :=
  policy.check graph = []

def holds (policy : Policy) (graph : Graph) : Bool :=
  policy.check graph == []

/-- A rule evaluated against every managed resource. Return `some message` to report a
violation. -/
def resources (name : String) (rule : ResourceSpec → Option String) : Policy :=
  ⟨name, fun graph =>
    graph.resources.filterMap fun resource =>
      (rule resource).map fun message => ⟨name, resource.address.toString, message, .violated⟩⟩

/-- A rule evaluated against every managed resource of one provider type. -/
def resourcesOfType (name : String) (resourceType : String) (rule : ResourceSpec → Option String) :
    Policy :=
  resources name fun resource =>
    if resource.resourceType == resourceType then rule resource else none

/-- A rule evaluated against every data source. -/
def dataSources (name : String) (rule : DataSourceSpec → Option String) : Policy :=
  ⟨name, fun graph =>
    graph.dataSources.filterMap fun dataSource =>
      (rule dataSource).map fun message => ⟨name, dataSource.address.toString, message, .violated⟩⟩

/-- A rule evaluated against every root output. -/
def outputs (name : String) (rule : String → OutputSpec → Option String) : Policy :=
  ⟨name, fun graph =>
    graph.outputs.filterMap fun (outputName, output) =>
      (rule outputName output).map fun message =>
        ⟨name, "output." ++ outputName, message, .violated⟩⟩

/-- A rule over the whole graph. -/
def graph (name : String) (rule : Graph → Option String) : Policy :=
  ⟨name, fun graph =>
    ((rule graph).map fun message => [⟨name, "graph", message, .violated⟩]).getD []⟩

/-- A rule over the values one argument takes across the managed resources that set it (a null
literal counts as unset, as it does for OpenTofu). The graph knows a value only when it is a
literal, so `rule` sees the literal values with their resources, and every resource whose
argument is anything else is reported `unknown` at its address instead of being left out: a
policy written this way cannot pass a value it cannot see. -/
def argumentValues (name argument : String) (rule : List (ResourceSpec × Value) → Option String) :
    Policy :=
  ⟨name, fun graph =>
    let set := graph.resources.filterMap fun resource =>
      match resource.argument? argument with
      | none | some (.literal .null) => none
      | some expression => some (resource, expression)
    let unknown := set.filterMap fun (resource, expression) =>
      match expression.literal? with
      | some _ => none
      | none => some ⟨name, resource.address.toString, s!"{argument} is {expression}", .unknown⟩
    let known := set.filterMap fun (resource, expression) => expression.literal?.map (resource, ·)
    unknown ++ ((rule known).map fun message => [⟨name, "graph", message, .violated⟩]).getD []⟩

/-- A resource rule holds for a graph exactly when it holds for every resource. This is the
bridge from `decide`-style checks to proofs by induction over the resources a stack creates. -/
theorem resources_holds_iff (name : String) (rule : ResourceSpec → Option String) (graph : Graph) :
    (resources name rule).Holds graph ↔ ∀ resource ∈ graph.resources, rule resource = none := by
  simp [Holds, resources, List.filterMap_eq_nil_iff]

theorem resourcesOfType_holds_iff (name resourceType : String) (rule : ResourceSpec → Option String)
    (graph : Graph) :
    (resourcesOfType name resourceType rule).Holds graph
      ↔ ∀ resource ∈ graph.resources, resource.resourceType = resourceType → rule resource = none := by
  simp only [Holds, resourcesOfType, resources, List.filterMap_eq_nil_iff, Option.map_eq_none_iff]
  constructor
  · intro h resource member equal
    have := h resource member
    simpa [equal] using this
  · intro h resource member
    by_cases equal : resource.resourceType = resourceType
    · simp [equal, h resource member equal]
    · simp [equal]

/-- The conjunction of several policies. -/
def all (name : String) (policies : List Policy) : Policy :=
  ⟨name, fun graph => policies.flatMap (·.check graph)⟩

/-- The reference validator as a policy, so structural validity and domain rules can be
enforced together. -/
def validGraph : Policy :=
  ⟨"valid-graph", fun graph =>
    match graph.validate with
    | .ok () => []
    | .error error => [⟨"valid-graph", "graph", error.message, .violated⟩]⟩

/-- Human-readable outcome. -/
def report (policy : Policy) (graph : Graph) : String :=
  match policy.check graph with
  | [] => s!"policy `{policy.name}` holds"
  | violations =>
    s!"policy `{policy.name}` {Violation.heading violations}:\n"
      ++ "\n".intercalate (violations.map fun violation => "  " ++ violation.render)

/-- Print the report and exit with status 1 when the policy is violated or cannot be decided.
Intended for stack test executables; the same policy is normally also proved with `decide`. -/
def enforce (policy : Policy) (graph : Graph) : IO Unit := do
  IO.println (policy.report graph)
  unless (policy.check graph).isEmpty do
    IO.Process.exit 1

end Policy

end Inframe
