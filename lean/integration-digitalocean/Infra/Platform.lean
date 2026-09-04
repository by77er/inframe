import Inframe
import DigitalOcean.Provider
import DigitalOcean.Data.KubernetesVersions
import DigitalOcean.Resource.DatabaseCluster
import DigitalOcean.Resource.KubernetesCluster
import DigitalOcean.Resource.SpacesBucket
import DigitalOcean.Resource.Vpc

/-!
The platform stack: a shared VPC, an autoscaling managed Kubernetes cluster whose version comes
from a data source, a versioned Spaces bucket, and an autoscaling PostgreSQL database. It is
the Lean twin of the PureScript `Infra.Platform` module and renders the same Graph IR.
-/

open Inframe
open DigitalOcean
open DigitalOcean.Resource

/-- Stack parameters that are known while the graph is built. Every deployment environment
gets its own graph; policies are proved for all of them at once. -/
inductive Environment where
  | dev
  | prod
  deriving DecidableEq, Repr

def Environment.region : Environment → String
  | .dev => "sfo3"
  | .prod => "nyc3"

def Environment.workerMax : Environment → Number
  | .dev => 3
  | .prod => 6

/-- One PostgreSQL cluster per requested name, every one on the platform VPC. Written with
explicit recursion (rather than `List.mapM`) so that proofs can follow it by induction. -/
def createDatabases (env : Environment) (network : Vpc.Vpc) :
    List Identifier → Infra (List DatabaseCluster.DatabaseCluster)
  | [] => pure []
  | db :: rest => do
    let storageAutoscale :=
      DatabaseCluster.storageAutoscaleArgs { enabled := true }
        |>.thresholdPercent 80
        |>.incrementGib 10
    let database ← DatabaseCluster.create db.raw
      (DatabaseCluster.args
        { engine := "pg"
          name := "platform-" ++ db.raw
          nodeCount := 1
          region := env.region
          size := "db-s-1vcpu-1gb" }
        |>.privateNetworkUuid network.id
        |>.storageAutoscale [storageAutoscale]
        |>.version "15")
      db.valid
    let databases ← createDatabases env network rest
    pure (database :: databases)

/-- The host of the first database, when there is one. -/
def outputDatabaseHost : List DatabaseCluster.DatabaseCluster → Infra Unit
  | database :: _ => output "database_host" database.host
  | [] => pure ()

@[simp] theorem run_outputDatabaseHost (clusters : List DatabaseCluster.DatabaseCluster)
    (graph : Graph) : ((outputDatabaseHost clusters).run graph).2.resources = graph.resources := by
  cases clusters <;> rfl

def infrastructureFor (env : Environment) (databases : List Identifier) : Infra Unit := do
  let provider ← Provider.configure (Provider.args {} |>.token (secretEnv "DIGITALOCEAN_TOKEN"))

  let versions ← Data.KubernetesVersions.readWith "available" (Data.KubernetesVersions.args {})
    (dataSourceOptions |>.withProvider provider)

  let network ← Vpc.create "platform" (Vpc.args
    { name := "platform"
      region := env.region })

  let workerPool :=
    KubernetesCluster.nodePoolArgs
      { name := "workers"
        size := "s-2vcpu-4gb" }
      |>.nodeCount 2
      |>.autoScale true
      |>.minNodes 2
      |>.maxNodes env.workerMax
      |>.tags ["platform", "workers"]

  let cluster ← KubernetesCluster.createWith "platform"
    (KubernetesCluster.args
      { name := "platform"
        nodePool := [workerPool]
        region := env.region
        version := versions.latestVersion }
      |>.autoUpgrade true
      |>.ha (env == .prod)
      |>.surgeUpgrade true
      |>.vpcUuid network.id)
    (resourceOptions
      |>.withProvider provider
      |>.createBeforeDestroy true)

  let versioning := SpacesBucket.versioningArgs {} |>.enabled true

  let bucket ← SpacesBucket.create "assets"
    (SpacesBucket.args { name := "replace-with-a-globally-unique-space-name" }
      |>.region env.region
      |>.versioning [versioning])

  let clusters ← createDatabases env network databases

  output "cluster_endpoint" cluster.endpoint
  output "bucket_endpoint" bucket.endpoint
  outputDatabaseHost clusters

/-- The graph `inframe build --stack lean-example` renders. -/
def infrastructure : Infra Unit :=
  infrastructureFor .prod [Identifier.mk "postgres"]
