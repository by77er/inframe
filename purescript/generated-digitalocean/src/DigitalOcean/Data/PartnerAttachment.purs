module DigitalOcean.Data.PartnerAttachment
  ( Args
  , Required
  , PartnerAttachment
  , PartnerAttachmentDataSource
  , args
  , read
  , Bgp
  , BgpRequired
  , bgpArgs
  , bgpLocalRouterIp
  , bgpPeerRouterAsn
  , bgpPeerRouterIp
  , bgp
  , id
  , name
  , redundancyZone
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data PartnerAttachmentDataSource

newtype Bgp = Bgp InputObject

type BgpRequired =
  {
  }

bgpArgs :: BgpRequired -> Bgp
bgpArgs _ = Bgp (inputObject
  [
  ])

bgpLocalRouterIp :: Input String -> Bgp -> Bgp
bgpLocalRouterIp value (Bgp values) = Bgp (insertInputField "local_router_ip" (inputJson value) values)

bgpPeerRouterAsn :: Input Number -> Bgp -> Bgp
bgpPeerRouterAsn value (Bgp values) = Bgp (insertInputField "peer_router_asn" (inputJson value) values)

bgpPeerRouterIp :: Input String -> Bgp -> Bgp
bgpPeerRouterIp value (Bgp values) = Bgp (insertInputField "peer_router_ip" (inputJson value) values)

bgpJson :: Bgp -> Json
bgpJson (Bgp values) = inputObjectJson values

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

bgp :: Array Bgp -> Args -> Args
bgp value (Args values) = Args (insertInputField "bgp" (arrayExprJson (map bgpJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (insertInputField "name" (inputJson value) values)

redundancyZone :: Input String -> Args -> Args
redundancyZone value (Args values) = Args (insertInputField "redundancy_zone" (inputJson value) values)

type PartnerAttachment =
  { dataSource :: DataSource PartnerAttachmentDataSource
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

read :: String -> Args -> Infra PartnerAttachment
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_partner_attachment" logicalName values
  pure
    { dataSource: handle
    , children: dataSourceAttr handle [ "children" ]
    , connectionBandwidthInMbps: dataSourceAttr handle [ "connection_bandwidth_in_mbps" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , naasProvider: dataSourceAttr handle [ "naas_provider" ]
    , name: dataSourceAttr handle [ "name" ]
    , parentUuid: dataSourceAttr handle [ "parent_uuid" ]
    , redundancyZone: dataSourceAttr handle [ "redundancy_zone" ]
    , region: dataSourceAttr handle [ "region" ]
    , state: dataSourceAttr handle [ "state" ]
    , vpcIds: dataSourceAttr handle [ "vpc_ids" ]
    }
