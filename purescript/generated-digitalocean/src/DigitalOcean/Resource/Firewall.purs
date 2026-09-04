module DigitalOcean.Resource.Firewall
  ( Args
  , Required
  , Firewall
  , FirewallResource
  , args
  , create
  , dropletIds
  , id
  , inboundRule
  , outboundRule
  , tags
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data FirewallResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

dropletIds :: Input (Array Number) -> Args -> Args
dropletIds value (Args values) = Args (Object.insert "droplet_ids" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

inboundRule :: Input (Array ({ portRange :: String, protocol :: String, sourceAddresses :: Array String, sourceDropletIds :: Array Number, sourceKubernetesIds :: Array String, sourceLoadBalancerUids :: Array String, sourceTags :: Array String })) -> Args -> Args
inboundRule value (Args values) = Args (Object.insert "inbound_rule" (inputJson value) values)

outboundRule :: Input (Array ({ destinationAddresses :: Array String, destinationDropletIds :: Array Number, destinationKubernetesIds :: Array String, destinationLoadBalancerUids :: Array String, destinationTags :: Array String, portRange :: String, protocol :: String })) -> Args -> Args
outboundRule value (Args values) = Args (Object.insert "outbound_rule" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

type Firewall =
  { resource :: Resource FirewallResource
  , createdAt :: Expr String
  , dropletIds :: Expr (Array Number)
  , id :: Expr String
  , name :: Expr String
  , pendingChanges :: Expr (Array ({ dropletId :: Number, removing :: Boolean, status :: String }))
  , status :: Expr String
  , tags :: Expr (Array String)
  }

create :: String -> Args -> Infra Firewall
create logicalName (Args values) = do
  handle <- addResource "digitalocean_firewall" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , dropletIds: resourceAttr handle [ "droplet_ids" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , pendingChanges: resourceAttr handle [ "pending_changes" ]
    , status: resourceAttr handle [ "status" ]
    , tags: resourceAttr handle [ "tags" ]
    }
