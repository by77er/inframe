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

/-- Resolved values decode through `FromValue`; `Marshal Option` tolerates nulls where
`Marshal Resolved` refuses them. -/
theorem marshalling_decodes_known_values :
    (fromValue (value% ["a", "b"]) : Except String (List String)) = .ok ["a", "b"] ∧
    (fromValue (value% { k: 1 }) : Except String (Map Number)) = .ok ⟨[("k", 1)]⟩ ∧
    (Marshal.optional (f := Resolved) (o := Option) (value% { present: "x", missing: null }) "missing"
      : Except String (Option String)) = .ok none ∧
    (Marshal.required (f := Resolved) (o := Option) (value% { present: "x" }) "present"
      : Except String (Resolved String)) = .ok "x" ∧
    (Marshal.required (f := Resolved) (o := Option) (value% { present: "x" }) "absent"
      : Except String (Resolved String)) = .error "attribute `absent` is null or missing" ∧
    (Marshal.optional (f := Input) (o := Resolved) (value% { present: "x" }) "absent"
      : Except String (Input String)) = .ok (unsafeInput (.literal .null)) := by
  exact ⟨rfl, rfl, rfl, rfl, rfl, rfl⟩

/-- `value%` builds known values for `dynamic` attributes, with `$` splices. -/
theorem value_literals (name : String) :
    (value% { team: "core", replicas: 3, tags: ["a", true, null], nested: { deep: -1.5 } })
      = .object [("team", .string "core"), ("replicas", .number 3),
          ("tags", .array [.string "a", .bool true, .null]), ("nested", .object [("deep", .number (-1.5))])] ∧
    (value% { name: $name }) = .object [("name", .string name)] ∧
    (((resourceAttr (resourceHandle (Identifier.mk "digitalocean_tag") (Identifier.mk "app") : Resource Unit)
        ["meta"] : Input Value)["team"] : Input Value)
      == unsafeInput (.index (.resourceAttribute (.res "digitalocean_tag" "app") ["meta"])
          (.literal (.string "team")))) = true := by
  exact ⟨rfl, rfl, by decide⟩

/-- `tf!` folds known text and splices symbolic parts into one flat template. -/
theorem interpolation_is_a_flat_template (x : Input String) (hx : x = secretEnv "X") :
    inputNode tf!"a-{x}-b" = .template [.text "a-", .interpolation (.secretEnvironment "X"), .text "-b"] ∧
    tf!"a-{"b"}" = (lit "a-b" : Input String) ∧
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

/-- Two nodes that depend on each other: `a` through `depends_on`, `b` through a reference. -/
def cyclic : Graph :=
  { resources :=
      [ { resourceType := "terraform_data", name := "a", arguments := []
          dependsOn := [.res "terraform_data" "b"], provider := none, lifecycle := none }
      , { resourceType := "terraform_data", name := "b"
          arguments := [("input", .resourceAttribute (.res "terraform_data" "a") ["id"])]
          dependsOn := [], provider := none, lifecycle := none } ] }

/-- Cycles fail validation with the path that closes them; a resource that names itself in
`replace_triggered_by` is the smallest one. -/
theorem cycles_are_rejected :
    cyclic.validate = .error (.cycle
      [.res "terraform_data" "a", .res "terraform_data" "b", .res "terraform_data" "a"]) ∧
    (buildGraph (do
        let self : Resource Unit := resourceHandle (Identifier.mk "digitalocean_tag") (Identifier.mk "loop")
        let _ : Resource Unit ← addResource ((resourceOptions : ResourceOptions Unit) |>.replaceTriggeredBy self)
          (Identifier.mk "digitalocean_tag") (Identifier.mk "loop") InputObject.empty
        pure ())).validate
      = .error (.cycle [.res "digitalocean_tag" "loop", .res "digitalocean_tag" "loop"]) := by
  decide

def contains (haystack needle : String) : Bool :=
  (haystack.splitOn needle).length > 1

def expect (condition : Bool) (message : String) : IO Unit :=
  unless condition do
    throw (IO.userError s!"assertion failed: {message}")

/-- Names derived from other names carry their validity proof. -/
theorem identifier_join :
    ((Identifier.mk "droplet").join (Identifier.mk "nyc1")).raw = "droplet-nyc1" ∧
    ((Identifier.mk "east").child "network").raw = "east-network" := by decide

/-- A child name of a run-time identifier needs no proof at the call site. -/
example (site : Identifier) : Identifier := site.child "network"

/-- A name carried by an `Identifier` needs no `decide`: the auto-param reuses its proof. -/
example (name : Identifier) : Address := .res "digitalocean_tag" name

/-- A handle whose attributes are traversed below. -/
def tagHandle : Resource Unit := resourceHandle (Identifier.mk "digitalocean_tag") (Identifier.mk "app")

/-- The shape of a nested block, as the generated adapters emit it, with its `SymbolicFields`
instance so that elements of a computed list can be traversed with types. -/
structure InterfaceAttributes (f o : Type → Type) where
  networkIp : f String
  natIps : f (o (List String))

instance : SymbolicFields (InterfaceAttributes Input Resolved) :=
  ⟨fun value => { networkIp := value.field "network_ip", natIps := value.field "nat_ips" }⟩

def interfaces : Input (List (InterfaceAttributes Input Resolved)) :=
  resourceAttr tagHandle ["network_interface"]

/-- Attribute access on computed expressions: `field` extends a plain reference's path, wraps
anything else in an `attribute` node, and `splat` maps a typed projection over a list. -/
theorem attribute_nodes :
    (inputNode (interfaces[1].fields.networkIp)
      == .attribute (.index (.resourceAttribute (.res "digitalocean_tag" "app") ["network_interface"])
          (.literal (.number 1))) "network_ip") = true ∧
    (inputNode (interfaces.splat (·.networkIp))
      == .attribute (.splat (.resourceAttribute (.res "digitalocean_tag" "app") ["network_interface"]))
          "network_ip") = true ∧
    (inputNode ((resourceAttr tagHandle ["meta"] : Input Value).field "team" : Input String)
      == .resourceAttribute (.res "digitalocean_tag" "app") ["meta", "team"]) = true ∧
    (inputNode (interfaces.splat (·.natIps)) : ExprNode).render
      = "digitalocean_tag.app.network_interface[*].nat_ips" := by
  refine ⟨by decide, by decide, by decide, rfl⟩

/-- The attribute name is validated like any path element, and references inside are found. -/
theorem attribute_nodes_are_validated :
    ({ outputs := [("x", ⟨.attribute (.literal .null) "bad name", false⟩)] } : Graph).validate
      = .error (.invalidIdentifier "output.x" "bad name") ∧
    (ExprNode.attribute (.splat (.resourceAttribute (.res "digitalocean_tag" "app") ["a"])) "b").references
      = [.res "digitalocean_tag" "app"] := by
  exact ⟨by decide, by decide⟩

/-- Names derived from run-time data: an index, arbitrary text, a literal tail. -/
theorem identifier_suffixes :
    ((Identifier.mk "fwd").indexed 1).raw = "fwd-1" ∧
    ((Identifier.mk "net").slug "10.192.0.0/16").raw = "net-10-192-0-0-16" ∧
    ((Identifier.mk "rule").append "22-tcp").raw = "rule-22-tcp" := by
  decide

example (site : Identifier) (index : Nat) : Identifier := site.indexed index
example (site : Identifier) (cidr : String) : Identifier := site.slug cidr

/-- A stack that consumes another stack's outputs through `terraform_remote_state`. -/
def consumer : Infra Unit := do
  let platform ← RemoteState.read "platform" (.gcs "acme-state" (prefix_ := "platform"))
  output "endpoint" (platform.output "cluster_endpoint" : Input String)
  output "region" (platform.outputOr "region" "nyc3" : Input String)

theorem remote_state_is_a_builtin_data_source :
    (buildGraph consumer).Valid ∧
    (buildGraph consumer).requiredProviders = [] ∧
    (((buildGraph consumer).dataSource? (.data "terraform_remote_state" "platform")).map (·.arguments)
      == some
        [ ("backend", .literal (.string "gcs"))
        , ("config", .object [("bucket", .literal (.string "acme-state")), ("prefix", .literal (.string "platform"))]) ]) = true ∧
    (((buildGraph consumer).output? "region").map (·.value)
      == some (.function "try"
          [ .dataSourceAttribute (.data "terraform_remote_state" "platform") ["outputs", "region"]
          , .literal (.string "nyc3") ])) = true := by
  refine ⟨by decide, by decide, by decide, by decide⟩

/-! `#assert_policy` and `#assert_valid` evaluate instead of reducing, and fail the build with
the report when violated. -/
#assert_policy tagsAreNamed graph
#assert_valid graph

def prodGraph : Graph := buildGraph do
  let _ : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
    (Identifier.mk "digitalocean_tag") (Identifier.mk "prod")
    (InputObject.ofList [("purpose", .literal (.string "prod"))])
  pure ()

/--
error: policy is violated:
  [no-literal-prod] digitalocean_tag.prod: purpose must not be the literal prod
-/
#guard_msgs in
#assert_policy noProdPurpose prodGraph

/-- error: graph is invalid: duplicate address `digitalocean_tag.twice` -/
#guard_msgs in
#assert_valid (buildGraph (do
  let _ : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
    (Identifier.mk "digitalocean_tag") (Identifier.mk "twice") InputObject.empty
  let _ : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
    (Identifier.mk "digitalocean_tag") (Identifier.mk "twice") InputObject.empty
  pure ()))

def main : IO Unit := do
  let rendered := (encodeGraph graph).compress
  for needle in ["digitalocean_tag.app", "resource_attr", "required_providers",
      "create_before_destroy", "replace_triggered_by", "secret_env", "conditional",
      "\"function\"", "\"sensitive\":true", "known-now", "\"count\":{\"kind\":\"literal\",\"value\":2}"] do
    expect (contains rendered needle) s!"rendered graph contains {needle}"
  match Lean.Json.parse (renderGraph program) with
  | .ok json => expect (json == encodeGraph graph) "rendered Graph IR round-trips"
  | .error error => throw (IO.userError s!"rendered Graph IR does not parse: {error}")
  expect (!(renderGraph program).contains '\n') "rendered Graph IR is one compact line"
  match Lean.Json.parse (renderGraphPretty program) with
  | .ok json => expect (json == encodeGraph graph) "pretty-printed Graph IR round-trips"
  | .error error => throw (IO.userError s!"pretty-printed Graph IR does not parse: {error}")
  expect (graph.validate == .ok ()) "graph validates at run time"
  expect (tagsAreNamed.holds graph) "policy holds at run time"
  expect (Policy.all "everything" [Policy.validGraph, tagsAreNamed, noProdPurpose] |>.holds graph)
    "combined policy holds"
  -- A `tofu show -json` document round-trips through the JSON bridge and resource lookup.
  let shown := "{\"values\": {\"root_module\": {\"resources\": [{\"address\": \"digitalocean_tag.app\", \"type\": \"digitalocean_tag\", \"name\": \"app\", \"values\": {\"id\": \"app\", \"name\": \"app\", \"droplets_count\": 2}}]}}}"
  match ShowDocument.parse shown with
  | .error error => throw (IO.userError s!"show document did not parse: {error}")
  | .ok document =>
    expect ((document.resource? (.res "digitalocean_tag" "app")).bind (·.field? "droplets_count")
        == some (.number 2)) "resource values are found by address"
    expect ((document.decode? (.res "digitalocean_tag" "app") : Except String (Map Value)).toBool)
      "resource values decode"
  match OutputsDocument.parse "{\"secret\": {\"sensitive\": true, \"value\": \"s\"}, \"plain\": {\"sensitive\": false, \"value\": [1, 2]}}" with
  | .error error => throw (IO.userError s!"outputs document did not parse: {error}")
  | .ok outputs =>
    expect ((outputs.value? "plain" : Except String (List Number)) == .ok [1, 2]) "plain output decodes"
    expect (!(outputs.value? "secret" : Except String String).toBool) "sensitive output is refused"
    expect ((outputs.sensitiveValue? "secret" : Except String String) == .ok "s")
      "sensitive output is readable deliberately"
  IO.println "inframe core tests passed"
