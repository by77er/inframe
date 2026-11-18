import Infra.Atlas.Network
import DigitalOcean.Resource.DatabaseCluster
import DigitalOcean.Resource.DatabaseDb
import DigitalOcean.Resource.DatabaseFirewall
import DigitalOcean.Resource.DatabaseUser
import DigitalOcean.Resource.KubernetesCluster
import DigitalOcean.Resource.SpacesBucket

/-! State: PostgreSQL with one database and user per service, a cache, and object storage. -/

open Inframe
open DigitalOcean.Resource

namespace Atlas

/-- A database and a login for each service, in the shared cluster. -/
def serviceDatabases (postgres : DatabaseCluster.DatabaseCluster) : List Identifier → Infra Unit
  | [] => pure ()
  | service :: rest => do
    let _ ← DatabaseDb.create service { clusterId := postgres.id, name := service.raw }
    let _ ← DatabaseUser.create service { clusterId := postgres.id, name := service.raw }
    serviceDatabases postgres rest

def postgres (region : String) (net : Network) (workloads : KubernetesCluster.KubernetesCluster)
    (services : List Identifier) : Infra DatabaseCluster.DatabaseCluster := do
  let postgres ← DatabaseCluster.createWith "postgres"
    { engine := "pg"
      name := "atlas-postgres"
      version := "16"
      nodeCount := 2
      region := region
      size := "db-s-2vcpu-4gb"
      privateNetworkUuid := net.vpc.id
      storageAutoscale := some { enabled := true, thresholdPercent := 80, incrementGib := 20 } }
    (resourceOptions |>.preventDestroy true)
  let _ ← DatabaseFirewall.create "postgres"
    { clusterId := postgres.id, rule := [{ type := "k8s", value := workloads.id }] }
  serviceDatabases postgres services
  pure postgres

def cache (region : String) (net : Network) (workloads : KubernetesCluster.KubernetesCluster) :
    Infra DatabaseCluster.DatabaseCluster := do
  let cache ← DatabaseCluster.create "cache"
    { engine := "valkey"
      name := "atlas-cache"
      version := "8"
      nodeCount := 1
      region := region
      size := "db-s-1vcpu-2gb"
      privateNetworkUuid := net.vpc.id }
  let _ ← DatabaseFirewall.create "cache"
    { clusterId := cache.id, rule := [{ type := "k8s", value := workloads.id }] }
  pure cache

def buckets (region : String) : Infra SpacesBucket.SpacesBucket := do
  let _ ← SpacesBucket.create "backups"
    { name := "atlas-backups", region := region, versioning := some { enabled := true } }
  SpacesBucket.create "uploads" { name := "atlas-uploads", region := region }

end Atlas
