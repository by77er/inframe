-- expect: Type mismatch
import Inframe
import DigitalOcean.Resource.KubernetesCluster
open Inframe DigitalOcean.Resource

/-! `digitalocean_kubernetes_cluster` requires exactly one `node_pool` block, so the argument
record holds a single `NodePoolArgs`, not a list: an empty list does not type-check. -/

def emptyPool : Infra Unit := do
  let _ ← KubernetesCluster.create "missing_pool"
    { name := "missing-pool", region := "nyc3", version := "1.34.1-do.0", nodePool := [] }
  pure ()
