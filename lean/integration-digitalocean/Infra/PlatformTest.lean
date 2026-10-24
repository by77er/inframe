import Infra.Platform
import DigitalOcean.Data.Region

/-!
Policies for the platform stack.

Each policy is an ordinary function from the completed `Graph` to a list of violations. The
theorems below are checked by the Lean kernel while this module compiles, so `lake build`
(and therefore `inframe test --stack lean-example`) fails if a change to `Infra.Platform`
violates a policy. `main` prints the same policies' reports at run time.
-/

open Inframe
open DigitalOcean
open DigitalOcean.Resource

/-- The rule for one database: it must sit on the managed VPC, referenced symbolically. The
argument and the referenced attribute are named through the generated `names` records, so a
schema rename is a compile error here rather than a rule that silently matches nothing. -/
def databaseRule (database : ResourceSpec) : Option String :=
  if database.argumentRefersTo DatabaseCluster.names.privateNetworkUuid
      (.res "digitalocean_vpc" "platform") [Vpc.names.id]
  then none
  else some "private_network_uuid must reference digitalocean_vpc.platform.id"

/-- Every DigitalOcean database must sit on the managed VPC. -/
def databaseUsesManagedVpc : Policy :=
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" databaseRule

/-- Every Kubernetes cluster is created before its predecessor is destroyed. -/
def clustersReplaceSafely : Policy :=
  Policy.resourcesOfType "clusters-replace-safely" "digitalocean_kubernetes_cluster" fun cluster =>
    match cluster.lifecycle with
    | some lifecycle => if lifecycle.createBeforeDestroy then none else some "set createBeforeDestroy"
    | none => some "set createBeforeDestroy"

/-- Regional resources must all live in the same region as the VPC. A region read from a data
source or another resource is known only once OpenTofu plans, so `argumentValues` reports it as
unknown rather than letting it pass; the rule compares the literal regions. -/
def singleRegion : Policy :=
  Policy.argumentValues "single-region" "region" fun regions =>
    match (regions.map (·.2)).eraseDups with
    | [] => some "no resource has a known region"
    | [_] => none
    | many => some s!"resources span regions {many}"

/-- Secrets only ever enter the graph through `secretEnv`, never as literals. -/
def noLiteralTokens : Policy :=
  Policy.graph "no-literal-tokens" fun graph =>
    let literalToken := graph.providerConfigs.any fun config =>
      match config.argument? "token" with
      | some (.literal _) => true
      | _ => false
    if literalToken then some "provider token must come from secretEnv" else none

def policies : Policy :=
  Policy.all "platform"
    [Policy.validGraph, databaseUsesManagedVpc, clustersReplaceSafely, singleRegion, noLiteralTokens]

/-- The production graph passes the reference validator. -/
theorem platform_valid : (buildGraph infrastructure).Valid := by decide

/-! The same checks by evaluation. On a graph this size the theorems above are the better
tool; once a graph outgrows kernel `decide` (dozens of resources with multi-kilobyte literals)
these assertions are the ones that keep failing the build with a report. -/
#assert_valid (buildGraph infrastructure)
#assert_policy policies (buildGraph infrastructure)

/-- Every policy holds for every environment with the deployed database list. -/
theorem platform_policies (env : Environment) :
    policies.Holds (buildGraph (infrastructureFor env [Identifier.mk "postgres"])) := by
  cases env <;> decide

/-! ### A proof over every database list

`platform_policies` checks two concrete graphs. The database policy also holds for *any* list
of databases, which no test can check: the proof goes by induction over the list using the
core's `run` lemmas to compute what each step adds to the graph. -/

/-- Each database `createDatabases` adds references the platform VPC, whatever the list. -/
theorem createDatabases_ok (env : Environment) (network : Vpc.Vpc) (databases : List Identifier)
    (graph : Graph)
    (vpc : inputNode network.id = ExprNode.resourceAttribute (.res "digitalocean_vpc" "platform") ["id"])
    (before : ∀ r ∈ graph.resources, r.resourceType = "digitalocean_database_cluster" → databaseRule r = none) :
    ∀ r ∈ ((createDatabases env network databases).run graph).2.resources,
      r.resourceType = "digitalocean_database_cluster" → databaseRule r = none := by
  induction databases generalizing graph with
  | nil => simpa [createDatabases] using before
  | cons db rest ih =>
    simp only [createDatabases, Infra.run_bind, Infra.run_pure, DatabaseCluster.create,
      DatabaseCluster.createWith]
    apply ih
    intro r member
    simp only [run_addResource_resources, run_requireProvider, List.mem_append,
      List.mem_singleton] at member
    rcases member with member | rfl
    · exact before r member
    · intro _
      simp [databaseRule, ResourceSpec.argumentRefersTo, ResourceSpec.argument?, resourceSpecOf,
        DatabaseCluster.Args.toInputObject, List.filterMap, List.lookup, vpc, ExprNode.refersTo]

/-- The database policy holds for every environment and every list of databases. -/
theorem databases_use_managed_vpc (env : Environment) (databases : List Identifier) :
    databaseUsesManagedVpc.Holds (buildGraph (infrastructureFor env databases)) := by
  rw [databaseUsesManagedVpc, Policy.resourcesOfType_holds_iff]
  simp only [buildGraph, infrastructureFor, Infra.run_bind, Infra.run_pure, run_output,
    run_outputDatabaseHost, Provider.configure, run_addProvider_fst,
    Data.KubernetesVersions.readWith, run_addDataSource_fst, Vpc.create, Vpc.createWith,
    KubernetesCluster.createWith, SpacesBucket.create, SpacesBucket.createWith,
    run_addResource_fst]
  apply createDatabases_ok
  · rfl
  · intro r member
    simp only [run_addResource_resources, run_requireProvider, run_addDataSource_resources,
      run_addProvider_resources, List.mem_append, List.mem_singleton, List.not_mem_nil,
      false_or, or_assoc] at member
    rcases member with rfl | rfl | rfl <;> simp [resourceSpecOf]

/-- A stack whose regions the graph cannot see: the VPC is in `nyc3`, a second VPC follows the
first one's `region` attribute, and the bucket takes the slug of a `digitalocean_region` data
source that OpenTofu resolves to `sfo3`. -/
def regionsFromTheGraph : Infra Unit := do
  let here ← Data.Region.read "here" { slug := "sfo3" }
  let network ← Vpc.create "platform" { name := "platform", region := "nyc3" }
  let _ ← Vpc.create "mirror" { name := "mirror", region := network.region }
  let _ ← SpacesBucket.create "assets" { name := "assets", region := here.slug }
  pure ()

/-- Neither region passes silently: each is an unknown finding at its resource, and the policy
does not hold. -/
theorem regions_from_the_graph_are_unknown :
    (singleRegion.violations (buildGraph regionsFromTheGraph)).map (fun v => (v.address, v.outcome))
      = [("digitalocean_vpc.mirror", .unknown), ("digitalocean_spaces_bucket.assets", .unknown)] ∧
    ¬ singleRegion.Holds (buildGraph regionsFromTheGraph) := by
  decide

/-- Structural facts about the graph are theorems too: the database depends on the VPC through a
reference, and the cluster version flows in from the data source. -/
theorem database_depends_on_vpc :
    (buildGraph infrastructure).dependsOn
      (.res "digitalocean_database_cluster" "postgres") (.res "digitalocean_vpc" "platform") = true := by
  decide

theorem cluster_version_comes_from_data_source :
    (buildGraph infrastructure).dependsOn
      (.res "digitalocean_kubernetes_cluster" "platform")
      (.data "digitalocean_kubernetes_versions" "available") = true := by
  decide

/-- The only secret the stack needs at plan time. -/
theorem secrets : (buildGraph infrastructure).secretEnvironmentNames = ["DIGITALOCEAN_TOKEN"] := by
  decide


/-- Names from data: an `Identifier` is accepted wherever a literal name is, and its proof is
reused, so `create` takes `site.indexed 3` or `site.slug cidr` directly. -/
example (site : Identifier) (index : Nat) : Infra Vpc.Vpc :=
  Vpc.create (site.indexed index) { name := "platform", region := "nyc3" }

example (site : Identifier) : Infra Vpc.Vpc :=
  Vpc.create site { name := "platform", region := "nyc3" }

/-- Adoption of an existing VPC into the graph: one `import` block, one plan. -/
example : Infra Unit := do
  let network ← Vpc.create "existing" { name := "existing", region := "nyc3" }
  adopt network "a1b2c3d4-0000-4000-8000-000000000000"

def main : IO Unit := do
  for env in [Environment.dev, Environment.prod] do
    IO.println s!"environment {repr env}:"
    policies.enforce (buildGraph (infrastructureFor env [Identifier.mk "postgres"]))
  IO.println "platform policies hold (also proved at compile time)"

/-! ### Limits that depend on the input

Prod clusters are highly available with at least two nodes, and dev clusters never grow past
three, for every environment and every list of databases. -/

/-- A literal number in the first `block` of a resource, such as `node_pool.min_nodes`. -/
def blockNumber? (resource : ResourceSpec) (block field : String) : Option Number :=
  match resource.argument? block with
  | some (.array (.object fields :: _)) =>
    match fields.lookup field with
    | some (.literal (.number n)) => some n
    | _ => none
  | _ => none

def numberAtLeast (n : Number) (k : Nat) : Bool := n.mantissa ≥ (k * 10 ^ n.exponent : Nat)
def numberAtMost (n : Number) (k : Nat) : Bool := n.mantissa ≤ (k * 10 ^ n.exponent : Nat)

def clusterSizing : Environment → Policy
  | .prod =>
    Policy.resourcesOfType "prod-cluster-sizing" "digitalocean_kubernetes_cluster" fun cluster =>
      if !cluster.argumentIs KubernetesCluster.names.ha true then some "prod clusters set ha"
      else match blockNumber? cluster KubernetesCluster.names.nodePool
          KubernetesCluster.NodePoolAttributes.names.minNodes with
        | some n => if numberAtLeast n 2 then none else some "prod node pools keep at least 2 nodes"
        | none => some "prod node pools set a literal min_nodes"
  | .dev =>
    Policy.resourcesOfType "dev-cluster-sizing" "digitalocean_kubernetes_cluster" fun cluster =>
      match blockNumber? cluster KubernetesCluster.names.nodePool
          KubernetesCluster.NodePoolAttributes.names.maxNodes with
      | some n => if numberAtMost n 3 then none else some "dev node pools grow to at most 3 nodes"
      | none => some "dev node pools set a literal max_nodes"

/-- `createDatabases` adds database clusters and nothing else, so a policy about any other
resource type is unaffected by the database list. -/
theorem createDatabases_adds_databases (env : Environment) (network : Vpc.Vpc)
    (databases : List Identifier) (graph : Graph) :
    ∀ r ∈ ((createDatabases env network databases).run graph).2.resources,
      r ∈ graph.resources ∨ r.resourceType = "digitalocean_database_cluster" := by
  induction databases generalizing graph with
  | nil => exact fun r member => .inl member
  | cons db rest ih =>
    simp only [createDatabases, Infra.run_bind, Infra.run_pure, DatabaseCluster.create,
      DatabaseCluster.createWith]
    intro r member
    rcases ih _ r member with member | database
    · simp only [run_addResource_resources, run_requireProvider, List.mem_append,
        List.mem_singleton] at member
      rcases member with member | rfl
      · exact .inl member
      · exact .inr rfl
    · exact .inr database

theorem cluster_sizing (env : Environment) (databases : List Identifier) :
    (clusterSizing env).Holds (buildGraph (infrastructureFor env databases)) := by
  cases env <;> simp only [clusterSizing] <;>
  · rw [Policy.resourcesOfType_holds_iff]
    simp only [buildGraph, infrastructureFor, Infra.run_bind, Infra.run_pure, run_output,
      run_outputDatabaseHost, Provider.configure, run_addProvider_fst,
      Data.KubernetesVersions.readWith, run_addDataSource_fst, Vpc.create, Vpc.createWith,
      KubernetesCluster.createWith, SpacesBucket.create, SpacesBucket.createWith,
      run_addResource_fst]
    intro r member type
    rcases createDatabases_adds_databases _ _ _ _ r member with member | database
    · simp only [run_addResource_resources, run_requireProvider, run_addDataSource_resources,
        run_addProvider_resources, List.mem_append, List.mem_singleton, List.not_mem_nil,
        false_or, or_assoc] at member
      rcases member with rfl | rfl | rfl <;> first | decide | simp [resourceSpecOf] at type
    · rw [database] at type
      exact absurd type (by decide)

/-! ### Adding a database never touches what is already there

Growing the database list keeps every existing resource exactly as it was, in the same place:
nothing is changed, so nothing is replaced, and nothing is removed. -/

theorem createDatabases_append (env : Environment) (network : Vpc.Vpc)
    (xs ys : List Identifier) (graph : Graph) :
    ((createDatabases env network (xs ++ ys)).run graph).2
      = ((createDatabases env network ys).run ((createDatabases env network xs).run graph).2).2 := by
  induction xs generalizing graph with
  | nil => rfl
  | cons db rest ih => simp only [List.cons_append, createDatabases, Infra.run_bind, Infra.run_pure, ih]

theorem createDatabases_extends (env : Environment) (network : Vpc.Vpc)
    (databases : List Identifier) (graph : Graph) :
    graph.resources <+: ((createDatabases env network databases).run graph).2.resources := by
  induction databases generalizing graph with
  | nil => exact List.prefix_refl _
  | cons db rest ih =>
    simp only [createDatabases, Infra.run_bind, Infra.run_pure, DatabaseCluster.create,
      DatabaseCluster.createWith]
    refine List.IsPrefix.trans ?_ (ih _)
    simp only [run_addResource_resources, run_requireProvider]
    exact List.prefix_append _ _

theorem adding_databases_keeps_resources (env : Environment) (databases more : List Identifier) :
    (buildGraph (infrastructureFor env databases)).resources
      <+: (buildGraph (infrastructureFor env (databases ++ more))).resources := by
  simp only [buildGraph, infrastructureFor, Infra.run_bind, run_output,
    run_outputDatabaseHost, createDatabases_append]
  exact createDatabases_extends _ _ _ _

/-! ### Dev and prod stay in step

For every database list, dev and prod create the same resources at the same addresses, in the
same order, and wire every one of them to the same networks: the environment changes sizes,
counts, and the region, never what exists or what talks to what. -/

/-- What a resource is and which networks it joins. -/
def wiring (resource : ResourceSpec) : Address × Option ExprNode × Option ExprNode :=
  (resource.address, resource.argument? KubernetesCluster.names.vpcUuid,
    resource.argument? DatabaseCluster.names.privateNetworkUuid)

theorem createDatabases_wiring (env env' : Environment) (network : Vpc.Vpc)
    (databases : List Identifier) (left right : Graph)
    (same : left.resources.map wiring = right.resources.map wiring) :
    ((createDatabases env network databases).run left).2.resources.map wiring
      = ((createDatabases env' network databases).run right).2.resources.map wiring := by
  induction databases generalizing left right with
  | nil => simpa [createDatabases] using same
  | cons db rest ih =>
    simp only [createDatabases, Infra.run_bind, Infra.run_pure, DatabaseCluster.create,
      DatabaseCluster.createWith]
    apply ih
    simp only [run_addResource_resources, run_requireProvider, List.map_append, same]
    simp [wiring, resourceSpecOf, ResourceSpec.address, ResourceSpec.argument?,
      DatabaseCluster.Args.toInputObject, List.filterMap, List.lookup]

theorem environments_share_wiring (databases : List Identifier) :
    (buildGraph (infrastructureFor .dev databases)).resources.map wiring
      = (buildGraph (infrastructureFor .prod databases)).resources.map wiring := by
  simp only [buildGraph, infrastructureFor, Infra.run_bind, run_output, run_outputDatabaseHost]
  apply createDatabases_wiring
  rfl

theorem environments_share_resources (databases : List Identifier) :
    (buildGraph (infrastructureFor .dev databases)).resources.map (·.address)
      = (buildGraph (infrastructureFor .prod databases)).resources.map (·.address) := by
  have := congrArg (List.map Prod.fst) (environments_share_wiring databases)
  simpa [List.map_map, wiring, Function.comp_def] using this

/-! ### A policy over tagged resources

Here the rule applies only to databases that carry a tag: every database tagged `pci` must sit
on the platform VPC, and the others may go anywhere. The stack below takes each database's tags
as input and puts only the `pci` ones on the VPC, so the policy holds while
`databaseUsesManagedVpc` does not. -/

/-- The rule for one database tagged `tag`: it must sit on the VPC at `vpc`. -/
def taggedDatabaseRule (vpc : Address) (database : ResourceSpec) : Option String :=
  if database.argumentRefersTo DatabaseCluster.names.privateNetworkUuid vpc [Vpc.names.id]
  then none
  else some s!"private_network_uuid must reference {vpc}.id"

/-- Every DigitalOcean database tagged `tag` must sit on the VPC at `vpc`. -/
def taggedDatabasesUseVpc (tag : String) (vpc : Address) : Policy :=
  Policy.resourcesOfTypeContaining s!"{tag}-databases-use-vpc" "digitalocean_database_cluster"
    DatabaseCluster.names.tags tag (taggedDatabaseRule vpc)

def pciDatabasesUseVpc : Policy :=
  taggedDatabasesUseVpc "pci" (.res "digitalocean_vpc" "platform")

/-- A database the stack is asked for, with its tags. -/
structure DatabaseRequest where
  name : Identifier
  tags : List String

/-- One cluster per request; only the ones tagged `pci` go on the VPC. -/
def createRequestedDatabases (env : Environment) (network : Vpc.Vpc) :
    List DatabaseRequest → Infra Unit
  | [] => pure ()
  | request :: rest => do
    let _ ← DatabaseCluster.create request.name
      { engine := "pg"
        name := "platform-" ++ request.name.raw
        nodeCount := 1
        region := env.region
        size := "db-s-1vcpu-1gb"
        privateNetworkUuid := if "pci" ∈ request.tags then some network.id else none
        tags := some (lit request.tags)
        version := "15" }
    createRequestedDatabases env network rest

def requestedDatabases (env : Environment) (requests : List DatabaseRequest) : Infra Unit := do
  let network ← Vpc.create "platform" { name := "platform", region := env.region }
  createRequestedDatabases env network requests

theorem string_beq (a b : String) : (Value.string a == Value.string b) = (a == b) := rfl

theorem createRequestedDatabases_ok (env : Environment) (network : Vpc.Vpc)
    (requests : List DatabaseRequest) (graph : Graph)
    (vpc : inputNode network.id = ExprNode.resourceAttribute (.res "digitalocean_vpc" "platform") ["id"])
    (before : ∀ r ∈ graph.resources, r.resourceType = "digitalocean_database_cluster" →
      r.argumentContains? "tags" "pci" ≠ some false →
      taggedDatabaseRule (.res "digitalocean_vpc" "platform") r = none) :
    ∀ r ∈ ((createRequestedDatabases env network requests).run graph).2.resources,
      r.resourceType = "digitalocean_database_cluster" →
      r.argumentContains? "tags" "pci" ≠ some false →
      taggedDatabaseRule (.res "digitalocean_vpc" "platform") r = none := by
  induction requests generalizing graph with
  | nil => simpa [createRequestedDatabases] using before
  | cons request rest ih =>
    simp only [createRequestedDatabases, Infra.run_bind, Infra.run_pure, DatabaseCluster.create,
      DatabaseCluster.createWith]
    apply ih
    intro r member
    simp only [run_addResource_resources, run_requireProvider, List.mem_append,
      List.mem_singleton] at member
    rcases member with member | rfl
    · exact before r member
    · intro _ tagged
      by_cases pci : "pci" ∈ request.tags
      · simp [taggedDatabaseRule, ResourceSpec.argumentRefersTo, ResourceSpec.argument?,
          resourceSpecOf, DatabaseCluster.Args.toInputObject, List.filterMap, List.lookup, vpc,
          ExprNode.refersTo, pci]
      · exfalso
        apply tagged
        simp [ResourceSpec.argumentContains?, ResourceSpec.argument?, resourceSpecOf,
          DatabaseCluster.Args.toInputObject, List.filterMap, List.lookup, pci, lit, inputNode,
          toValue, string_beq]
        intro tag member equal
        exact pci (equal ▸ member)

/-- Every database tagged `pci` is on the VPC, for every environment and every list of
requests with any tags. -/
theorem pci_databases_use_vpc (env : Environment) (requests : List DatabaseRequest) :
    pciDatabasesUseVpc.Holds (buildGraph (requestedDatabases env requests)) := by
  rw [pciDatabasesUseVpc, taggedDatabasesUseVpc, Policy.resourcesOfTypeContaining_holds_iff]
  simp only [buildGraph, requestedDatabases, Infra.run_bind, Infra.run_pure, Vpc.create, Vpc.createWith,
    run_addResource_fst]
  apply createRequestedDatabases_ok
  · rfl
  · intro r member
    simp only [run_addResource_resources, run_requireProvider, List.mem_append,
      List.mem_singleton, List.not_mem_nil, false_or] at member
    subst member
    simp [resourceSpecOf]

/-- The tag is what the policy turns on: an untagged database off the VPC breaks the
unconditional rule but not the tagged one. -/
theorem untagged_database_may_leave_vpc :
    let graph := buildGraph (requestedDatabases .prod [⟨Identifier.mk "analytics", []⟩])
    pciDatabasesUseVpc.Holds graph ∧ ¬ databaseUsesManagedVpc.Holds graph := by
  decide

/-- A tag the graph cannot read does not pass silently: a database off the VPC whose tags come
from another resource's attribute might be tagged `pci`, so it is an unknown finding. -/
def tagsFromTheGraph : Infra Unit := do
  let network ← Vpc.create "platform" { name := "platform", region := "nyc3" }
  let _ ← DatabaseCluster.create "ledger"
    { engine := "pg", name := "ledger", nodeCount := 1, region := "nyc3"
      size := "db-s-1vcpu-1gb", tags := some (array [network.name]) }
  pure ()

theorem tags_from_the_graph_are_unknown :
    (pciDatabasesUseVpc.violations (buildGraph tagsFromTheGraph)).map (fun v => (v.address, v.outcome))
      = [("digitalocean_database_cluster.ledger", .unknown)] := by
  decide
