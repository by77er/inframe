module DigitalOcean.Data.GradientaiModels
  ( Args
  , Required
  , GradientaiModels
  , GradientaiModelsDataSource
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

data GradientaiModelsDataSource

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

type GradientaiModels =
  { dataSource :: DataSource GradientaiModelsDataSource
  , id :: Expr String
  , models :: Expr (Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, id :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, uuid :: String, version :: Array ({ major :: Number, minor :: Number, patch :: Number }) }))
  }

read :: String -> Args -> Infra GradientaiModels
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_models" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , models: dataSourceAttr handle [ "models" ]
    }
