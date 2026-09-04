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

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data NfsAttachmentResource

type Required =
  { region :: Input String
  , shareId :: Input String
  , vpcId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "region" (inputJson required.region)
  , Tuple "share_id" (inputJson required.shareId)
  , Tuple "vpc_id" (inputJson required.vpcId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
