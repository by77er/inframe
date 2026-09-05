import Inframe
import DigitalOcean.Resource.Tag

open Inframe
open DigitalOcean.Resource

def infrastructure : Infra Unit := do
  let tag ← Tag.create "smoke" { name := "inframe-smoke" }
  output "tag_id" tag.id

def main : IO Unit :=
  IO.println (renderGraph infrastructure)
