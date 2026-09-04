module DigitalOcean.Data.Firewall
  ( Args
  , Required
  , Firewall
  , FirewallDataSource
  , args
  , read
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
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data FirewallDataSource

type Required =
  { firewallId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "firewall_id" (inputJson required.firewallId)
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
  { dataSource :: DataSource FirewallDataSource
  , createdAt :: Expr String
  , dropletIds :: Expr (Array Number)
  , firewallId :: Expr String
  , id :: Expr String
  , name :: Expr String
  , pendingChanges :: Expr (Array ({ dropletId :: Number, removing :: Boolean, status :: String }))
  , status :: Expr String
  , tags :: Expr (Array String)
  }

read :: String -> Args -> Infra Firewall
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_firewall" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , dropletIds: dataSourceAttr handle [ "droplet_ids" ]
    , firewallId: dataSourceAttr handle [ "firewall_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , pendingChanges: dataSourceAttr handle [ "pending_changes" ]
    , status: dataSourceAttr handle [ "status" ]
    , tags: dataSourceAttr handle [ "tags" ]
    }
