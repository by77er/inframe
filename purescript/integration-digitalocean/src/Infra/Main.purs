module Infra.Main where

import Prelude

import DigitalOcean.Resource.Tag as Tag
import Effect (Effect)
import Effect.Console (log)
import Inframe.Builder (Infra, output)
import Inframe.Core (lit)
import Inframe.Json (renderGraph)

infrastructure :: Infra Unit
infrastructure = do
  tag <- Tag.create "smoke" (Tag.args { name: lit "inframe-smoke" })
  output "tag_id" tag.id

main :: Effect Unit
main = log (renderGraph infrastructure)
