-- expect: a nested block list has fewer or more entries than the provider schema allows
import Inframe
import DigitalOcean.Resource.DatabaseFirewall
open Inframe DigitalOcean.Resource

/-! `digitalocean_database_firewall` requires at least one `rule` block. The list type cannot
say so, so `create` carries `Args.blocksInRange`, discharged by `decide` for literal records:
an empty list makes the proposition false and the obligation fails. -/

def unguarded : Infra Unit := do
  let _ ← DatabaseFirewall.create "open" { clusterId := "cluster", rule := [] }
  pure ()
