module DigitalOcean.Data.GradientaiOpenaiApiKeys
  ( Args
  , Required
  , GradientaiOpenaiApiKeys
  , GradientaiOpenaiApiKeysDataSource
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

data GradientaiOpenaiApiKeysDataSource

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

type GradientaiOpenaiApiKeys =
  { dataSource :: DataSource GradientaiOpenaiApiKeysDataSource
  , id :: Expr String
  , openaiApiKeys :: Expr (Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, models :: Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) }), name :: String, updatedAt :: String, uuid :: String }))
  }

read :: String -> Args -> Infra GradientaiOpenaiApiKeys
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_openai_api_keys" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , openaiApiKeys: dataSourceAttr handle [ "openai_api_keys" ]
    }
