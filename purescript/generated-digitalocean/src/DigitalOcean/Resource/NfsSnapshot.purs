module DigitalOcean.Resource.NfsSnapshot
  ( Args
  , Required
  , NfsSnapshot
  , NfsSnapshotResource
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

data NfsSnapshotResource

type Required =
  { name :: Input String
  , region :: Input String
  , shareId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "share_id" (inputJson required.shareId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type NfsSnapshot =
  { resource :: Resource NfsSnapshotResource
  , createdAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , shareId :: Expr String
  , size :: Expr Number
  , status :: Expr String
  }

create :: String -> Args -> Infra NfsSnapshot
create logicalName (Args values) = do
  handle <- addResource "digitalocean_nfs_snapshot" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , region: resourceAttr handle [ "region" ]
    , shareId: resourceAttr handle [ "share_id" ]
    , size: resourceAttr handle [ "size" ]
    , status: resourceAttr handle [ "status" ]
    }
