module DigitalOcean.Data.GradientaiOpenaiApiKey
  ( Args
  , Required
  , GradientaiOpenaiApiKey
  , GradientaiOpenaiApiKeyDataSource
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

data GradientaiOpenaiApiKeyDataSource

type Required =
  { uuid :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "uuid" (inputJson required.uuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type GradientaiOpenaiApiKey =
  { dataSource :: DataSource GradientaiOpenaiApiKeyDataSource
  , createdAt :: Expr String
  , createdBy :: Expr String
  , deletedAt :: Expr String
  , id :: Expr String
  , models :: Expr (Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) }))
  , name :: Expr String
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra GradientaiOpenaiApiKey
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_openai_api_key" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , createdBy: dataSourceAttr handle [ "created_by" ]
    , deletedAt: dataSourceAttr handle [ "deleted_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , models: dataSourceAttr handle [ "models" ]
    , name: dataSourceAttr handle [ "name" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
