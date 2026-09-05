import Infra.Platform

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

/-- The rule for one database: it must sit on the managed VPC, referenced symbolically. -/
def databaseRule (database : ResourceSpec) : Option String :=
  if database.argumentRefersTo "private_network_uuid" (.res "digitalocean_vpc" "platform") ["id"]
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

/-- Regional resources must all live in the same region as the VPC. -/
def singleRegion : Policy :=
  Policy.graph "single-region" fun graph =>
    let regions := graph.resources.filterMap fun resource =>
      match resource.argument? "region" with
      | some (.literal (.string region)) => some region
      | _ => none
    match regions.eraseDups with
    | [] => some "no regional resources"
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

def main : IO Unit := do
  for env in [Environment.dev, Environment.prod] do
    IO.println s!"environment {repr env}:"
    policies.enforce (buildGraph (infrastructureFor env [Identifier.mk "postgres"]))
  IO.println "platform policies hold (also proved at compile time)"
