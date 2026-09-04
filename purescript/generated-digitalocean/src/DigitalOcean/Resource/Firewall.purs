module DigitalOcean.Resource.Firewall
  ( Args
  , Required
  , Firewall
  , FirewallResource
  , args
  , create
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
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data FirewallResource

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
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
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
