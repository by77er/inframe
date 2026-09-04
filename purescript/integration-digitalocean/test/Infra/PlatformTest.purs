module Infra.PlatformTest where

import Prelude

import Data.Array (all)
import Data.Maybe (Maybe(..))
import Effect (Effect)
import Foreign.Object as Object
import Infra.Platform (infrastructure)
import Inframe.Builder (ResourceSpec, buildGraph)
import Inframe.Core (ExprNode(..))
import Test.Assert (assert)

main :: Effect Unit
main = do
  let graph = buildGraph infrastructure
  assert $ all databaseUsesManagedVpc graph.resources

databaseUsesManagedVpc :: ResourceSpec -> Boolean
databaseUsesManagedVpc resource
  | resource.resourceType /= "digitalocean_database_cluster" = true
  | otherwise = case Object.lookup "private_network_uuid" resource.arguments of
      Just (ResourceAttribute address path) ->
        address == "digitalocean_vpc.platform" && path == [ "id" ]
      _ -> false
