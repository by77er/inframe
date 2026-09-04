module DigitalOcean.Resource.SpacesKey
  ( Args
  , Required
  , SpacesKey
  , SpacesKeyResource
  , args
  , create
  , Grant
  , GrantRequired
  , grantArgs
  , grant
  , id
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data SpacesKeyResource

newtype Grant = Grant InputObject

type GrantRequired =
  { bucket :: Input String
  , permission :: Input String
  }

grantArgs :: GrantRequired -> Grant
grantArgs required = Grant (inputObject
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "permission" (inputJson required.permission)
  ])

grantJson :: Grant -> Json
grantJson (Grant values) = inputObjectJson values

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

grant :: Array Grant -> Args -> Args
grant value (Args values) = Args (insertInputField "grant" (arrayExprJson (map grantJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type SpacesKey =
  { resource :: Resource SpacesKeyResource
  , accessKey :: Expr String
  , createdAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , secretKey :: Expr String
  }

create :: String -> Args -> Infra SpacesKey
create logicalName (Args values) = do
  handle <- addResource "digitalocean_spaces_key" logicalName values
  pure
    { resource: handle
    , accessKey: resourceAttr handle [ "access_key" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , secretKey: resourceAttr handle [ "secret_key" ]
    }
