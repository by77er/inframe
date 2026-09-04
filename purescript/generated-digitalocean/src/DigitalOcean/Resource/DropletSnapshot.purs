module DigitalOcean.Resource.DropletSnapshot
  ( Args
  , Required
  , DropletSnapshot
  , DropletSnapshotResource
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

data DropletSnapshotResource

type Required =
  { dropletId :: Input String
  , name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "droplet_id" (inputJson required.dropletId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type DropletSnapshot =
  { resource :: Resource DropletSnapshotResource
  , createdAt :: Expr String
  , dropletId :: Expr String
  , id :: Expr String
  , minDiskSize :: Expr Number
  , name :: Expr String
  , regions :: Expr (Array String)
  , size :: Expr Number
  }

create :: String -> Args -> Infra DropletSnapshot
create logicalName (Args values) = do
  handle <- addResource "digitalocean_droplet_snapshot" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , dropletId: resourceAttr handle [ "droplet_id" ]
    , id: resourceAttr handle [ "id" ]
    , minDiskSize: resourceAttr handle [ "min_disk_size" ]
    , name: resourceAttr handle [ "name" ]
    , regions: resourceAttr handle [ "regions" ]
    , size: resourceAttr handle [ "size" ]
    }
