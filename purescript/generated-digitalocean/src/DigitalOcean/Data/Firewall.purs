module DigitalOcean.Data.Firewall
  ( Args
  , Required
  , Firewall
  , FirewallDataSource
  , args
  , read
  , InboundRule
  , InboundRuleRequired
  , inboundRuleArgs
  , inboundRulePortRange
  , inboundRuleSourceAddresses
  , inboundRuleSourceDropletIds
  , inboundRuleSourceKubernetesIds
  , inboundRuleSourceLoadBalancerUids
  , inboundRuleSourceTags
  , OutboundRule
  , OutboundRuleRequired
  , outboundRuleArgs
  , outboundRuleDestinationAddresses
  , outboundRuleDestinationDropletIds
  , outboundRuleDestinationKubernetesIds
  , outboundRuleDestinationLoadBalancerUids
  , outboundRuleDestinationTags
  , outboundRulePortRange
  , dropletIds
  , id
  , inboundRule
  , outboundRule
  , tags
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data FirewallDataSource

newtype InboundRule = InboundRule InputObject

type InboundRuleRequired =
  { protocol :: Input String
  }

inboundRuleArgs :: InboundRuleRequired -> InboundRule
inboundRuleArgs required = InboundRule (inputObject
  [ Tuple "protocol" (inputJson required.protocol)
  ])

inboundRulePortRange :: Input String -> InboundRule -> InboundRule
inboundRulePortRange value (InboundRule values) = InboundRule (insertInputField "port_range" (inputJson value) values)

inboundRuleSourceAddresses :: Input (Array String) -> InboundRule -> InboundRule
inboundRuleSourceAddresses value (InboundRule values) = InboundRule (insertInputField "source_addresses" (inputJson value) values)

inboundRuleSourceDropletIds :: Input (Array Number) -> InboundRule -> InboundRule
inboundRuleSourceDropletIds value (InboundRule values) = InboundRule (insertInputField "source_droplet_ids" (inputJson value) values)

inboundRuleSourceKubernetesIds :: Input (Array String) -> InboundRule -> InboundRule
inboundRuleSourceKubernetesIds value (InboundRule values) = InboundRule (insertInputField "source_kubernetes_ids" (inputJson value) values)

inboundRuleSourceLoadBalancerUids :: Input (Array String) -> InboundRule -> InboundRule
inboundRuleSourceLoadBalancerUids value (InboundRule values) = InboundRule (insertInputField "source_load_balancer_uids" (inputJson value) values)

inboundRuleSourceTags :: Input (Array String) -> InboundRule -> InboundRule
inboundRuleSourceTags value (InboundRule values) = InboundRule (insertInputField "source_tags" (inputJson value) values)

inboundRuleJson :: InboundRule -> Json
inboundRuleJson (InboundRule values) = inputObjectJson values

newtype OutboundRule = OutboundRule InputObject

type OutboundRuleRequired =
  { protocol :: Input String
  }

outboundRuleArgs :: OutboundRuleRequired -> OutboundRule
outboundRuleArgs required = OutboundRule (inputObject
  [ Tuple "protocol" (inputJson required.protocol)
  ])

outboundRuleDestinationAddresses :: Input (Array String) -> OutboundRule -> OutboundRule
outboundRuleDestinationAddresses value (OutboundRule values) = OutboundRule (insertInputField "destination_addresses" (inputJson value) values)

outboundRuleDestinationDropletIds :: Input (Array Number) -> OutboundRule -> OutboundRule
outboundRuleDestinationDropletIds value (OutboundRule values) = OutboundRule (insertInputField "destination_droplet_ids" (inputJson value) values)

outboundRuleDestinationKubernetesIds :: Input (Array String) -> OutboundRule -> OutboundRule
outboundRuleDestinationKubernetesIds value (OutboundRule values) = OutboundRule (insertInputField "destination_kubernetes_ids" (inputJson value) values)

outboundRuleDestinationLoadBalancerUids :: Input (Array String) -> OutboundRule -> OutboundRule
outboundRuleDestinationLoadBalancerUids value (OutboundRule values) = OutboundRule (insertInputField "destination_load_balancer_uids" (inputJson value) values)

outboundRuleDestinationTags :: Input (Array String) -> OutboundRule -> OutboundRule
outboundRuleDestinationTags value (OutboundRule values) = OutboundRule (insertInputField "destination_tags" (inputJson value) values)

outboundRulePortRange :: Input String -> OutboundRule -> OutboundRule
outboundRulePortRange value (OutboundRule values) = OutboundRule (insertInputField "port_range" (inputJson value) values)

outboundRuleJson :: OutboundRule -> Json
outboundRuleJson (OutboundRule values) = inputObjectJson values

type Required =
  { firewallId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "firewall_id" (inputJson required.firewallId)
  ])

dropletIds :: Input (Array Number) -> Args -> Args
dropletIds value (Args values) = Args (insertInputField "droplet_ids" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

inboundRule :: Array InboundRule -> Args -> Args
inboundRule value (Args values) = Args (insertInputField "inbound_rule" (arrayExprJson (map inboundRuleJson value)) values)

outboundRule :: Array OutboundRule -> Args -> Args
outboundRule value (Args values) = Args (insertInputField "outbound_rule" (arrayExprJson (map outboundRuleJson value)) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

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
