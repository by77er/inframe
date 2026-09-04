module DigitalOcean.Data.Regions
  ( Args
  , Required
  , Regions
  , RegionsDataSource
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

data RegionsDataSource

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

type Regions =
  { dataSource :: DataSource RegionsDataSource
  , id :: Expr String
  , regions :: Expr (Array ({ available :: Boolean, features :: Array String, name :: String, sizes :: Array String, slug :: String }))
  }

read :: String -> Args -> Infra Regions
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_regions" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , regions: dataSourceAttr handle [ "regions" ]
    }
