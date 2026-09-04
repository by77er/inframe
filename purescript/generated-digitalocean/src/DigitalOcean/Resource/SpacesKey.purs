module DigitalOcean.Resource.SpacesKey
  ( Args
  , Required
  , SpacesKey
  , SpacesKeyResource
  , args
  , create
  , grant
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data SpacesKeyResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

grant :: Input (Array ({ bucket :: String, permission :: String })) -> Args -> Args
grant value (Args values) = Args (Object.insert "grant" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
