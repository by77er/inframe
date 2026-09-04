module DigitalOcean.Resource.PartnerAttachment
  ( Args
  , Required
  , PartnerAttachment
  , PartnerAttachmentResource
  , args
  , create
  , Bgp
  , BgpRequired
  , bgpArgs
  , bgpAuthKey
  , bgpLocalRouterIp
  , bgpPeerRouterAsn
  , bgpPeerRouterIp
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , timeoutsDelete
  , bgp
  , parentUuid
  , redundancyZone
  , timeouts
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data PartnerAttachmentResource

newtype Bgp = Bgp InputObject

type BgpRequired =
  {
  }

bgpArgs :: BgpRequired -> Bgp
bgpArgs _ = Bgp (inputObject
  [
  ])

bgpAuthKey :: Input String -> Bgp -> Bgp
bgpAuthKey value (Bgp values) = Bgp (insertInputField "auth_key" (inputJson value) values)

bgpLocalRouterIp :: Input String -> Bgp -> Bgp
bgpLocalRouterIp value (Bgp values) = Bgp (insertInputField "local_router_ip" (inputJson value) values)

bgpPeerRouterAsn :: Input Number -> Bgp -> Bgp
bgpPeerRouterAsn value (Bgp values) = Bgp (insertInputField "peer_router_asn" (inputJson value) values)

bgpPeerRouterIp :: Input String -> Bgp -> Bgp
bgpPeerRouterIp value (Bgp values) = Bgp (insertInputField "peer_router_ip" (inputJson value) values)

bgpJson :: Bgp -> Json
bgpJson (Bgp values) = inputObjectJson values

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsDelete :: Input String -> Timeouts -> Timeouts
timeoutsDelete value (Timeouts values) = Timeouts (insertInputField "delete" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { connectionBandwidthInMbps :: Input Number
  , naasProvider :: Input String
  , name :: Input String
  , region :: Input String
  , vpcIds :: Input (Array String)
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "connection_bandwidth_in_mbps" (inputJson required.connectionBandwidthInMbps)
  , Tuple "naas_provider" (inputJson required.naasProvider)
  , Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "vpc_ids" (inputJson required.vpcIds)
  ])

bgp :: Array Bgp -> Args -> Args
bgp value (Args values) = Args (insertInputField "bgp" (arrayExprJson (map bgpJson value)) values)

parentUuid :: Input String -> Args -> Args
parentUuid value (Args values) = Args (insertInputField "parent_uuid" (inputJson value) values)

redundancyZone :: Input String -> Args -> Args
redundancyZone value (Args values) = Args (insertInputField "redundancy_zone" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

type PartnerAttachment =
  { resource :: Resource PartnerAttachmentResource
  , children :: Expr (Array String)
  , connectionBandwidthInMbps :: Expr Number
  , createdAt :: Expr String
  , id :: Expr String
  , naasProvider :: Expr String
  , name :: Expr String
  , parentUuid :: Expr String
  , redundancyZone :: Expr String
  , region :: Expr String
  , state :: Expr String
  , vpcIds :: Expr (Array String)
  }

create :: String -> Args -> Infra PartnerAttachment
create logicalName (Args values) = do
  handle <- addResource "digitalocean_partner_attachment" logicalName values
  pure
    { resource: handle
    , children: resourceAttr handle [ "children" ]
    , connectionBandwidthInMbps: resourceAttr handle [ "connection_bandwidth_in_mbps" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , naasProvider: resourceAttr handle [ "naas_provider" ]
    , name: resourceAttr handle [ "name" ]
    , parentUuid: resourceAttr handle [ "parent_uuid" ]
    , redundancyZone: resourceAttr handle [ "redundancy_zone" ]
    , region: resourceAttr handle [ "region" ]
    , state: resourceAttr handle [ "state" ]
    , vpcIds: resourceAttr handle [ "vpc_ids" ]
    }
