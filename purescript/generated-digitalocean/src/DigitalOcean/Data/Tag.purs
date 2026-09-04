module DigitalOcean.Data.Tag
  ( Args
  , Required
  , Tag
  , TagDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data TagDataSource

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
  { dataSource :: DataSource TagDataSource
  , databasesCount :: Expr Number
  , dropletsCount :: Expr Number
  , id :: Expr String
  , imagesCount :: Expr Number
  , name :: Expr String
  , totalResourceCount :: Expr Number
  , volumeSnapshotsCount :: Expr Number
  , volumesCount :: Expr Number
  }

read :: String -> Args -> Infra Tag
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_tag" logicalName values
  pure
    { dataSource: handle
    , databasesCount: dataSourceAttr handle [ "databases_count" ]
    , dropletsCount: dataSourceAttr handle [ "droplets_count" ]
    , id: dataSourceAttr handle [ "id" ]
    , imagesCount: dataSourceAttr handle [ "images_count" ]
    , name: dataSourceAttr handle [ "name" ]
    , totalResourceCount: dataSourceAttr handle [ "total_resource_count" ]
    , volumeSnapshotsCount: dataSourceAttr handle [ "volume_snapshots_count" ]
    , volumesCount: dataSourceAttr handle [ "volumes_count" ]
    }
