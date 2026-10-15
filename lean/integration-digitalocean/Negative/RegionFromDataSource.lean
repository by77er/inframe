-- expect: unknown until plan: region is data.digitalocean_region.here.slug
import Infra.PlatformTest
open Inframe DigitalOcean DigitalOcean.Resource

/-! A policy over values cannot pass a value it cannot see. The bucket's region is a data
source's attribute, which OpenTofu resolves to `sfo3` while the VPC sits in `nyc3`; the graph
only knows the reference, so `single-region` reports it as unknown until plan and the stack does
not build. -/

#assert_policy singleRegion (buildGraph do
  let here ← Data.Region.read "here" { slug := "sfo3" }
  let _ ← Vpc.create "platform" { name := "platform", region := "nyc3" }
  let _ ← SpacesBucket.create "assets" { name := "assets", region := here.slug }
  pure ())
