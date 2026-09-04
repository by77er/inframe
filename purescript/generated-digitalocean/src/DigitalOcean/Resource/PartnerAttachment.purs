module DigitalOcean.Resource.PartnerAttachment
  ( Args
  , Required
  , PartnerAttachment
  , PartnerAttachmentResource
  , args
  , create
  , bgp
  , parentUuid
  , redundancyZone
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data PartnerAttachmentResource

type Required =
  { connectionBandwidthInMbps :: Input Number
  , naasProvider :: Input String
  , name :: Input String
  , region :: Input String
  , vpcIds :: Input (Array String)
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "connection_bandwidth_in_mbps" (inputJson required.connectionBandwidthInMbps)
  , Tuple "naas_provider" (inputJson required.naasProvider)
  , Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "vpc_ids" (inputJson required.vpcIds)
  ])

bgp :: Input (Array ({ authKey :: String, localRouterIp :: String, peerRouterAsn :: Number, peerRouterIp :: String })) -> Args -> Args
bgp value (Args values) = Args (Object.insert "bgp" (inputJson value) values)

parentUuid :: Input String -> Args -> Args
parentUuid value (Args values) = Args (Object.insert "parent_uuid" (inputJson value) values)

redundancyZone :: Input String -> Args -> Args
redundancyZone value (Args values) = Args (Object.insert "redundancy_zone" (inputJson value) values)

timeouts :: Input ({ create :: String, delete :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

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
