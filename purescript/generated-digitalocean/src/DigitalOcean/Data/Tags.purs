module DigitalOcean.Data.Tags
  ( Args
  , Required
  , Tags
  , TagsDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data TagsDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type Tags =
  { dataSource :: DataSource TagsDataSource
  , id :: Expr String
  , tags :: Expr (Array ({ databasesCount :: Number, dropletsCount :: Number, imagesCount :: Number, name :: String, totalResourceCount :: Number, volumeSnapshotsCount :: Number, volumesCount :: Number }))
  }

read :: String -> Args -> Infra Tags
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_tags" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , tags: dataSourceAttr handle [ "tags" ]
    }
