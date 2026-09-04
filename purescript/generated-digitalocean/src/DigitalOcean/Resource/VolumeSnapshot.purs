module DigitalOcean.Resource.VolumeSnapshot
  ( Args
  , Required
  , VolumeSnapshot
  , VolumeSnapshotResource
  , args
  , create
  , id
  , tags
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data VolumeSnapshotResource

type Required =
  { name :: Input String
  , volumeId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "volume_id" (inputJson required.volumeId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

type VolumeSnapshot =
  { resource :: Resource VolumeSnapshotResource
  , createdAt :: Expr String
  , id :: Expr String
  , minDiskSize :: Expr Number
  , name :: Expr String
  , regions :: Expr (Array String)
  , size :: Expr Number
  , tags :: Expr (Array String)
  , volumeId :: Expr String
  }

create :: String -> Args -> Infra VolumeSnapshot
create logicalName (Args values) = do
  handle <- addResource "digitalocean_volume_snapshot" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , minDiskSize: resourceAttr handle [ "min_disk_size" ]
    , name: resourceAttr handle [ "name" ]
    , regions: resourceAttr handle [ "regions" ]
    , size: resourceAttr handle [ "size" ]
    , tags: resourceAttr handle [ "tags" ]
    , volumeId: resourceAttr handle [ "volume_id" ]
    }
