import Inframe

/-!
Core library tests. The theorems are checked while this module compiles; `main` re-checks the
same facts at run time and inspects the rendered Graph IR document.
-/

open Inframe

inductive TagResource
inductive VpcResource

def program : Infra Unit := do
  requireProvider (Identifier.mk "digitalocean") "digitalocean/digitalocean" "= 2.100.0"
  let network : Resource VpcResource ← addResource (resourceOptions : ResourceOptions Unit)
    (Identifier.mk "digitalocean_vpc") (Identifier.mk "network")
    (InputObject.ofList [("name", inputNode (lit "network"))])
  let tag : Resource TagResource ← addResource
    ((resourceOptions : ResourceOptions Unit)
      |>.dependsOn network
      |>.replaceTriggeredBy network
      |>.createBeforeDestroy true)
    (Identifier.mk "digitalocean_tag") (Identifier.mk "app")
    (InputObject.ofList [("name", inputNode (lit "app"))]
      |>.insert "description"
        (inputNode (template [text "token-", interpolate (secretEnv "DIGITALOCEAN_TOKEN")]))
      |>.insert "purpose" (inputNode (ifThenElse (lit true) (lit "prod") (lit "dev")))
      |>.insert "normalized" (inputNode (unsafeCall "lower" [unsafeArgument (lit "APP")] : Input String))
      |>.insert "count" (inputNode (lit (2 : Number))))
  sensitiveOutput "tag_id" (resourceAttr tag ["id"] : Input String)
  output "literal" (lit "known-now" : Input String)
  output "greeting" (tf!"hello {(resourceAttr tag ["name"] : Input String)}, {count}")
  output "joined" (array [resourceAttr tag ["id"], "known"] |>.join ",")
  output "first" (array ["a", "b"] : Input (List String))[0]
where
  count : Input Number := 2

def graph : Graph := buildGraph program

/-- The Rust validator's rules, proved in the kernel for this concrete graph. -/
theorem graph_valid : graph.Valid := by decide

theorem tag_depends_on_vpc :
    graph.dependsOn (.res "digitalocean_tag" "app") (.res "digitalocean_vpc" "network") = true := by
  decide

theorem tag_has_explicit_edge :
    graph.dependencies.contains ⟨.res "digitalocean_vpc" "network", .res "digitalocean_tag" "app", true⟩ = true := by
  decide

theorem needs_token : graph.secretEnvironmentNames = ["DIGITALOCEAN_TOKEN"] := by decide

def tagsAreNamed : Policy :=
  Policy.resourcesOfType "tags-are-named" "digitalocean_tag" fun resource =>
    match resource.argument? "name" with
    | some (.literal (.string _)) => none
    | _ => some "tag name must be a known string"

def noProdPurpose : Policy :=
  Policy.resources "no-literal-prod" fun resource =>
    if resource.argumentIs "purpose" "prod" then some "purpose must not be the literal prod" else none

theorem tags_are_named : tagsAreNamed.Holds graph := by decide

/-- The conditional is symbolic, so the literal check does not fire. -/
theorem purpose_is_symbolic : noProdPurpose.Holds graph := by decide

theorem typed_functions_lower_to_calls :
    (inputNode (Input.tonumber "42") == .function "tonumber" [.literal (.string "42")]) = true ∧
    (inputNode (Input.join ["a", "b"] ",")
      == .function "join" [.literal (.string ","), .literal (.array [.string "a", .string "b"])]) = true := by
  decide

/-- `tf!` folds known text and splices symbolic parts into one flat template. -/
theorem interpolation_is_a_flat_template (x : Input String) (hx : x = .symbolic (.secretEnvironment "X")) :
    tf!"a-{x}-b" = .symbolic (.template [.text "a-", .interpolation (.secretEnvironment "X"), .text "-b"]) ∧
    tf!"a-{"b"}" = (.known (.string "a-b") : Input String) ∧
    ((2 : Input Number) == lit (2 : Number)) = true ∧
    (((array ["a", "b"] : Input (List String))[0] : Input String)
      == index (array ["a", "b"]) 0) = true := by
  subst hx
  exact ⟨rfl, rfl, by decide, by decide⟩

theorem literal_equality_is_decidable :
    (ExprNode.literal (.string "a") == ExprNode.literal (.string "a")) = true ∧
    (ExprNode.literal (.string "a") == ExprNode.literal (.number 1)) = false := by
  decide

theorem invalid_graph_is_rejected :
    (buildGraph (do
        let _ : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
          (Identifier.mk "digitalocean_tag") (Identifier.mk "twice") InputObject.empty
        let _ : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
          (Identifier.mk "digitalocean_tag") (Identifier.mk "twice") InputObject.empty
        pure ())).validate
      = .error (.duplicateAddress (.res "digitalocean_tag" "twice")) := by
  decide

def contains (haystack needle : String) : Bool :=
  (haystack.splitOn needle).length > 1

def expect (condition : Bool) (message : String) : IO Unit :=
  unless condition do
    throw (IO.userError s!"assertion failed: {message}")

def main : IO Unit := do
  let rendered := (encodeGraph graph).compress
  for needle in ["digitalocean_tag.app", "resource_attr", "required_providers",
      "create_before_destroy", "replace_triggered_by", "secret_env", "conditional",
      "\"function\"", "\"sensitive\":true", "known-now", "\"count\":{\"kind\":\"literal\",\"value\":2}"] do
    expect (contains rendered needle) s!"rendered graph contains {needle}"
  match Lean.Json.parse (renderGraph program) with
  | .ok json => expect (json == encodeGraph graph) "pretty-printed Graph IR round-trips"
  | .error error => throw (IO.userError s!"rendered Graph IR does not parse: {error}")
  expect (graph.validate == .ok ()) "graph validates at run time"
  expect (tagsAreNamed.holds graph) "policy holds at run time"
  expect (Policy.all "everything" [Policy.validGraph, tagsAreNamed, noProdPurpose] |>.holds graph)
    "combined policy holds"
  IO.println "inframe core tests passed"
