module DigitalOcean.Data.PartnerAttachment
  ( Args
  , Required
  , PartnerAttachment
  , PartnerAttachmentDataSource
  , args
  , read
  , bgp
  , id
  , name
  , redundancyZone
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data PartnerAttachmentDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

bgp :: Input (Array ({ localRouterIp :: String, peerRouterAsn :: Number, peerRouterIp :: String })) -> Args -> Args
bgp value (Args values) = Args (Object.insert "bgp" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

redundancyZone :: Input String -> Args -> Args
redundancyZone value (Args values) = Args (Object.insert "redundancy_zone" (inputJson value) values)

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
