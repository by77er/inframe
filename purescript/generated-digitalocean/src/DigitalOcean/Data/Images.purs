module DigitalOcean.Data.Images
  ( Args
  , Required
  , Images
  , ImagesDataSource
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

data ImagesDataSource

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

type Images =
  { dataSource :: DataSource ImagesDataSource
  , id :: Expr String
  , images :: Expr (Array ({ created :: String, description :: String, distribution :: String, errorMessage :: String, id :: Number, image :: String, minDiskSize :: Number, name :: String, private :: Boolean, regions :: Array String, sizeGigabytes :: Number, slug :: String, status :: String, tags :: Array String, type_ :: String }))
  }

read :: String -> Args -> Infra Images
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_images" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , images: dataSourceAttr handle [ "images" ]
    }
