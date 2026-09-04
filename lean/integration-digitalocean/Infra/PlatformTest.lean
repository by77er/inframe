import Infra.Platform

/-!
Policies for the platform stack.

Each policy is an ordinary function from the completed `Graph` to a list of violations. The
theorems below are checked by the Lean kernel while this module compiles, so `lake build`
(and therefore `inframe test --stack lean-example`) fails if a change to `Infra.Platform`
violates a policy. `main` prints the same policies' reports at run time.
-/

open Inframe

/-- Every DigitalOcean database must sit on the managed VPC, referenced symbolically. -/
def databaseUsesManagedVpc : Policy :=
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" fun database =>
    if database.argumentRefersTo "private_network_uuid" (.res "digitalocean_vpc" "platform") ["id"]
    then none
    else some "private_network_uuid must reference digitalocean_vpc.platform.id"

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

/-- Every policy holds for every environment, not just the one being deployed. -/
theorem platform_policies (env : Environment) : policies.Holds (buildGraph (infrastructureFor env)) := by
  cases env <;> decide

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
    policies.enforce (buildGraph (infrastructureFor env))
  IO.println "platform policies hold (also proved at compile time)"
