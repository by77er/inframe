import Infra.Atlas.Network
import DigitalOcean.Data.KubernetesVersions
import DigitalOcean.Resource.ContainerRegistry
import DigitalOcean.Resource.KubernetesCluster
import DigitalOcean.Resource.KubernetesNodePool

/-! Compute: the Kubernetes cluster, its extra node pools, and the image registry. -/

open Inframe
open DigitalOcean
open DigitalOcean.Resource

namespace Atlas

/-- One extra node pool per requested name, each tagged for the worker firewall. -/
def nodePools (cluster : KubernetesCluster.KubernetesCluster) (net : Network) :
    List (Identifier × String) → Infra Unit
  | [] => pure ()
  | (pool, size) :: rest => do
    let _ ← KubernetesNodePool.create pool
      { clusterId := cluster.id
        name := "atlas-" ++ pool.raw
        size := size
        autoScale := some true
        minNodes := some 1
        maxNodes := some 4
        tags := some (array [net.workers.name]) }
    nodePools cluster net rest

def cluster (region : String) (net : Network) : Infra KubernetesCluster.KubernetesCluster := do
  let versions ← Data.KubernetesVersions.read "stable" {}
  let cluster ← KubernetesCluster.createWith "atlas"
    { name := "atlas"
      region := region
      version := versions.latestVersion
      vpcUuid := net.vpc.id
      autoUpgrade := true
      surgeUpgrade := true
      nodePool :=
        { name := "system", size := "s-2vcpu-4gb", nodeCount := 2, tags := array [net.workers.name] } }
    (resourceOptions |>.createBeforeDestroy true)
  nodePools cluster net
    [(Identifier.mk "general", "s-4vcpu-8gb"), (Identifier.mk "batch", "c-8"), (Identifier.mk "memory", "m-4vcpu-32gb")]
  pure cluster

def registry (region : String) : Infra ContainerRegistry.ContainerRegistry :=
  ContainerRegistry.create "images"
    { name := "atlas-images", region := some region, subscriptionTierSlug := "professional" }

end Atlas
