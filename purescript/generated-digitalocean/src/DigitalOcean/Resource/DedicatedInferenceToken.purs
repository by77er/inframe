module DigitalOcean.Resource.DedicatedInferenceToken
  ( Args
  , Required
  , DedicatedInferenceToken
  , DedicatedInferenceTokenResource
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

data DedicatedInferenceTokenResource

type Required =
  { dedicatedInferenceId :: Input String
  , name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "dedicated_inference_id" (inputJson required.dedicatedInferenceId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type DedicatedInferenceToken =
  { resource :: Resource DedicatedInferenceTokenResource
  , createdAt :: Expr String
  , dedicatedInferenceId :: Expr String
  , id :: Expr String
  , name :: Expr String
  , token :: Expr String
  }

create :: String -> Args -> Infra DedicatedInferenceToken
create logicalName (Args values) = do
  handle <- addResource "digitalocean_dedicated_inference_token" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , dedicatedInferenceId: resourceAttr handle [ "dedicated_inference_id" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , token: resourceAttr handle [ "token" ]
    }
