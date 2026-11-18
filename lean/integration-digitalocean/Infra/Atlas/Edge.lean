import Infra.Atlas.Network
import DigitalOcean.Resource.Cdn
import DigitalOcean.Resource.Certificate
import DigitalOcean.Resource.Domain
import DigitalOcean.Resource.Loadbalancer
import DigitalOcean.Resource.Record
import DigitalOcean.Resource.SpacesBucket

/-! The public edge: DNS, TLS, the load balancer in front of the workers, and the CDN. -/

open Inframe
open DigitalOcean.Resource

namespace Atlas

/-- `A` records for each name, all pointing at the load balancer. -/
def records (zone : Domain.Domain) (balancer : Loadbalancer.Loadbalancer) :
    List Identifier → Infra Unit
  | [] => pure ()
  | name :: rest => do
    let _ ← Record.create name
      { domain := zone.name, type := "A", name := name.raw, value := balancer.ip, ttl := some 300 }
    records zone balancer rest

def edge (region domain : String) (net : Network) (uploads : SpacesBucket.SpacesBucket) :
    Infra Loadbalancer.Loadbalancer := do
  let zone ← Domain.create "public" { name := domain }
  let certificate ← Certificate.create "public"
    { name := "atlas-public", type := some "lets_encrypt", domains := some (array [zone.name]) }
  let balancer ← Loadbalancer.create "public"
    { name := "atlas-public"
      region := some region
      vpcUuid := some net.vpc.id
      dropletTag := some net.workers.name
      redirectHttpToHttps := some true
      forwardingRule :=
        [ { entryPort := 443, entryProtocol := "https", targetPort := 30080, targetProtocol := "http"
            certificateName := some certificate.name } ]
      healthcheck := some { port := 30080, protocol := "http", path := some "/healthz" } }
  records zone balancer [Identifier.mk "api", Identifier.mk "app", Identifier.mk "admin"]
  let _ ← Cdn.create "uploads"
    { origin := uploads.bucketDomainName, certificateName := some certificate.name, ttl := some 3600 }
  pure balancer

end Atlas
