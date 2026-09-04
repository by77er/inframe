module DigitalOcean.Resource.Tag
  ( Args
  , Required
  , Tag
  , TagResource
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

data TagResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type Tag =
  { resource :: Resource TagResource
  , databasesCount :: Expr Number
  , dropletsCount :: Expr Number
  , id :: Expr String
  , imagesCount :: Expr Number
  , name :: Expr String
  , totalResourceCount :: Expr Number
  , volumeSnapshotsCount :: Expr Number
  , volumesCount :: Expr Number
  }

create :: String -> Args -> Infra Tag
create logicalName (Args values) = do
  handle <- addResource "digitalocean_tag" logicalName values
  pure
    { resource: handle
    , databasesCount: resourceAttr handle [ "databases_count" ]
    , dropletsCount: resourceAttr handle [ "droplets_count" ]
    , id: resourceAttr handle [ "id" ]
    , imagesCount: resourceAttr handle [ "images_count" ]
    , name: resourceAttr handle [ "name" ]
    , totalResourceCount: resourceAttr handle [ "total_resource_count" ]
    , volumeSnapshotsCount: resourceAttr handle [ "volume_snapshots_count" ]
    , volumesCount: resourceAttr handle [ "volumes_count" ]
    }
