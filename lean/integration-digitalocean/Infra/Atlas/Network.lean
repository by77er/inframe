import Inframe
import DigitalOcean.Resource.Firewall
import DigitalOcean.Resource.Tag
import DigitalOcean.Resource.Vpc

/-! The network every other part of Atlas sits on. -/

open Inframe
open DigitalOcean.Resource

namespace Atlas

structure Network where
  vpc : Vpc.Vpc
  workers : Tag.Tag

/-- The private network and the tag the worker firewall selects by. -/
def network (region : String) : Infra Network := do
  let vpc ← Vpc.create "atlas" { name := "atlas", region := region, ipRange := some "10.20.0.0/16" }
  let workers ← Tag.create "workers" { name := "atlas-workers" }
  pure { vpc, workers }

/-- Workers accept traffic from inside the VPC only, and may call out anywhere. -/
def workerFirewall (net : Network) : Infra Unit := do
  let _ ← Firewall.create "workers"
    { name := "atlas-workers"
      tags := some (array [net.workers.name])
      inboundRule :=
        [ { protocol := "tcp", portRange := some "1-65535", sourceAddresses := some ["10.20.0.0/16"] }
        , { protocol := "udp", portRange := some "1-65535", sourceAddresses := some ["10.20.0.0/16"] } ]
      outboundRule :=
        [ { protocol := "tcp", portRange := some "1-65535", destinationAddresses := some ["0.0.0.0/0"] }
        , { protocol := "udp", portRange := some "53", destinationAddresses := some ["0.0.0.0/0"] } ] }
  pure ()

end Atlas
