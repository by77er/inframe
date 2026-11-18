import Infra.Atlas.Cluster
import Infra.Atlas.Data
import Infra.Atlas.Edge
import DigitalOcean.Provider

/-!
Atlas: a larger stack split across modules, as a project of some size would be. `Network`,
`Cluster`, `Data` and `Edge` each declare their own resources; this module composes them and
publishes what other stacks read. It exists to show `inframe serve` a source hierarchy worth
looking at: it is not deployed by any test.
-/

open Inframe
open DigitalOcean

namespace Atlas

/-- What Atlas exports to the stacks built on it. -/
structure Exports where
  clusterEndpoint : Input String
  vpcID : Input String
  registryEndpoint : Input String
  postgresUri : Sensitive String
  deriving StackExports

def stack : Stack Exports :=
  .define "atlas" do
    let _ ← Provider.configure { token := secretEnv "DIGITALOCEAN_TOKEN" }
    let net ← network "ams3"
    workerFirewall net
    let workloads ← cluster "ams3" net
    let images ← registry "ams3"
    let database ← postgres "ams3" net workloads
      [Identifier.mk "billing", Identifier.mk "catalog", Identifier.mk "identity"]
    let cache ← cache "ams3" net workloads
    let uploads ← buckets "ams3"
    let balancer ← edge "ams3" "atlas.example" net uploads
    output "public_ip" balancer.ip
    output "cache_host" cache.privateHost
    pure
      { clusterEndpoint := workloads.endpoint
        vpcID := net.vpc.id
        registryEndpoint := images.endpoint
        postgresUri := ⟨database.privateUri⟩ }

end Atlas
