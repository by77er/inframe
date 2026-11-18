import Infra.Atlas
import DigitalOcean.Resource.Project
import DigitalOcean.Resource.SpacesBucket
import DigitalOcean.Resource.UptimeCheck

/-!
Storefront: a stack built on Atlas. It never names an Atlas resource; it reads the exports
Atlas publishes, through the stack reference `data.terraform_remote_state.atlas`.
-/

open Inframe
open DigitalOcean.Resource

namespace Storefront

def monitoring (atlas : Atlas.Exports) : Infra Unit := do
  let _ ← UptimeCheck.create "api" { name := "storefront-api", target := atlas.clusterEndpoint }
  pure ()

def infrastructure : Infra Unit := do
  let atlas ← Atlas.stack.read
  let assets ← SpacesBucket.create "assets" { name := "storefront-assets", region := "ams3" }
  let _ ← Project.create "storefront"
    { name := "storefront", purpose := some "Web Application", resources := some (array [assets.urn]) }
  monitoring atlas
  output "assets_endpoint" assets.endpoint
  output "registry" atlas.registryEndpoint

end Storefront

def main : IO Unit :=
  Inframe.emitGraph Storefront.infrastructure
