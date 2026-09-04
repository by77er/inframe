module DigitalOcean.Resource.GradientaiOpenaiApiKey
  ( Args
  , Required
  , GradientaiOpenaiApiKey
  , GradientaiOpenaiApiKeyResource
  , args
  , create
  , id
  , model
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data GradientaiOpenaiApiKeyResource

type Required =
  { apiKey :: Input String
  , name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "api_key" (inputJson required.apiKey)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

model :: Input (Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) })) -> Args -> Args
model value (Args values) = Args (Object.insert "model" (inputJson value) values)

type GradientaiOpenaiApiKey =
  { resource :: Resource GradientaiOpenaiApiKeyResource
  , apiKey :: Expr String
  , createdAt :: Expr String
  , createdBy :: Expr String
  , deletedAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiOpenaiApiKey
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_openai_api_key" logicalName values
  pure
    { resource: handle
    , apiKey: resourceAttr handle [ "api_key" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , createdBy: resourceAttr handle [ "created_by" ]
    , deletedAt: resourceAttr handle [ "deleted_at" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
