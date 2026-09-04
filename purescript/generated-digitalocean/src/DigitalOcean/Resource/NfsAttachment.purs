module DigitalOcean.Resource.NfsAttachment
  ( Args
  , Required
  , NfsAttachment
  , NfsAttachmentResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data NfsAttachmentResource

type Required =
  { region :: Input String
  , shareId :: Input String
  , vpcId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "region" (inputJson required.region)
  , Tuple "share_id" (inputJson required.shareId)
  , Tuple "vpc_id" (inputJson required.vpcId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type NfsAttachment =
  { resource :: Resource NfsAttachmentResource
  , id :: Expr String
  , region :: Expr String
  , shareId :: Expr String
  , vpcId :: Expr String
  }

create :: String -> Args -> Infra NfsAttachment
create logicalName (Args values) = do
  handle <- addResource "digitalocean_nfs_attachment" logicalName values
  pure
    { resource: handle
    , id: resourceAttr handle [ "id" ]
    , region: resourceAttr handle [ "region" ]
    , shareId: resourceAttr handle [ "share_id" ]
    , vpcId: resourceAttr handle [ "vpc_id" ]
    }
