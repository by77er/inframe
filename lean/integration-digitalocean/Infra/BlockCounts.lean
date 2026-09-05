import Inframe
import DigitalOcean.Resource.DatabaseCluster
import DigitalOcean.Resource.DatabaseFirewall
import DigitalOcean.Resource.KubernetesCluster

/-!
Block-count obligations are discharged automatically whenever the *number* of blocks is
literal, even when the blocks' *values* are symbolic references to other resources. Such a
record has free variables (the handles), which puts it out of `decide`'s reach; the
`blocks_in_range` tactic falls back to `rfl`, which reduces the length check regardless.
-/

open Inframe DigitalOcean.Resource

/-- One firewall rule whose value is another resource's attribute: no proof at the call site. -/
def guarded (database : DatabaseCluster.DatabaseCluster)
    (cluster : KubernetesCluster.KubernetesCluster) : Infra Unit := do
  let _ ← DatabaseFirewall.create "guarded"
    { clusterId := database.id, rule := [{ type := "k8s", value := cluster.id }] }
  pure ()

/-- Explicit options take the same automatic proof. -/
def guardedWith (database : DatabaseCluster.DatabaseCluster)
    (cluster : KubernetesCluster.KubernetesCluster) : Infra Unit := do
  let _ ← DatabaseFirewall.createWith "guarded"
    { clusterId := database.id, rule := [{ type := "k8s", value := cluster.id }] }
    (resourceOptions |>.dependsOn cluster)
  pure ()
