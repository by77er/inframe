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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DedicatedInferenceTokenResource

type Required =
  { dedicatedInferenceId :: Input String
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "dedicated_inference_id" (inputJson required.dedicatedInferenceId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
