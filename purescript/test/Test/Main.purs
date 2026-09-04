module Test.Main where

import Prelude

import Data.String.CodeUnits (contains)
import Data.String.Pattern (Pattern(..))
import Effect (Effect)
import Foreign.Object as Object
import Test.Assert (assert)
import TofuDag.Builder (Infra, addResource, output, requireProvider)
import TofuDag.Core (inputJson, lit, resourceAttr)
import TofuDag.Json (renderGraph)
import Data.Tuple (Tuple(..))

data TagResource

program :: Infra Unit
program = do
  requireProvider "digitalocean" "digitalocean/digitalocean" "= 2.100.0"
  tag <- addResource "digitalocean_tag" "app" $ Object.fromFoldable
    [ Tuple "name" (inputJson (lit "app")) ]
  output "tag_id" (resourceAttr tag [ "id" ])

main :: Effect Unit
main = do
  let rendered = renderGraph program
  assert $ contains (Pattern "digitalocean_tag.app") rendered
  assert $ contains (Pattern "resource_attr") rendered
  assert $ contains (Pattern "required_providers") rendered
