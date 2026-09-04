module Infra.Main where

import Prelude

import DigitalOcean.Provider as DigitalOcean
import DigitalOcean.Resource.Tag as Tag
import Effect (Effect)
import Effect.Console (log)
import TofuDag.Builder (Infra, output, requireProvider)
import TofuDag.Core (lit)
import TofuDag.Json (renderGraph)

infrastructure :: Infra Unit
infrastructure = do
  requireProvider "digitalocean" "digitalocean/digitalocean" "= 2.100.0"
  DigitalOcean.configure (DigitalOcean.args {})
  tag <- Tag.create "mvp" (Tag.args { name: lit "tofu-dag-mvp" })
  output "tag_id" tag.id

main :: Effect Unit
main = log (renderGraph infrastructure)
