module Infra.PlatformTest where

-- | Policies for the platform stack, the twins of the Lean stack's. `main` enforces them
-- | for `inframe test`; `[stacks.example.gate]` in `inframe.toml` names `policies` and
-- | `Infra.Platform.infrastructure`, so `plan` and `apply` check the program that is
-- | deployed rather than whatever this module chose to check.

import Prelude

import Data.Argonaut.Core (stringify)
import Data.Array (any, nubEq)
import Data.Maybe (Maybe(..))
import Data.String.Common (joinWith)
import Data.Tuple (snd)
import Effect (Effect)
import Foreign.Object as Object
import Infra.Platform (infrastructure)
import Inframe.Builder (buildGraph)
import Inframe.Core (ExprNode(..))
import Inframe.Policy (Policy)
import Inframe.Policy as Policy

-- | Every DigitalOcean database must sit on the managed VPC, referenced symbolically.
databaseUsesManagedVpc :: Policy
databaseUsesManagedVpc =
  Policy.resourcesOfType "database-uses-managed-vpc" "digitalocean_database_cluster" \database ->
    case Object.lookup "private_network_uuid" database.arguments of
      Just (ResourceAttribute "digitalocean_vpc.platform" [ "id" ]) -> Nothing
      _ -> Just "private_network_uuid must reference digitalocean_vpc.platform.id"

-- | Every Kubernetes cluster is created before its predecessor is destroyed.
clustersReplaceSafely :: Policy
clustersReplaceSafely =
  Policy.resourcesOfType "clusters-replace-safely" "digitalocean_kubernetes_cluster" \cluster ->
    case cluster.lifecycle of
      Just lifecycle | lifecycle.createBeforeDestroy -> Nothing
      _ -> Just "set createBeforeDestroy"

-- | Regional resources must all live in the same region. A region that only the plan
-- | knows is reported as unknown rather than passing.
singleRegion :: Policy
singleRegion =
  Policy.argumentValues "single-region" "region" \regions ->
    case nubEq (map snd regions) of
      [] -> Just "no resource has a known region"
      [ _ ] -> Nothing
      many -> Just ("resources span regions " <> joinWith ", " (map stringify many))

-- | Secrets only ever enter the graph through `secretEnv`, never as literals.
noLiteralTokens :: Policy
noLiteralTokens =
  Policy.graph "no-literal-tokens" \completed ->
    if any literalToken completed.providerConfigs then Just "provider token must come from secretEnv"
    else Nothing
  where
  literalToken config = case Object.lookup "token" config.arguments of
    Just (Literal _) -> true
    _ -> false

policies :: Policy
policies =
  Policy.all "platform" [ databaseUsesManagedVpc, clustersReplaceSafely, singleRegion, noLiteralTokens ]

main :: Effect Unit
main = Policy.enforce policies (buildGraph infrastructure)
