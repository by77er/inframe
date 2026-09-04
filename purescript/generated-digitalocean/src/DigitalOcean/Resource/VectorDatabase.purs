module DigitalOcean.Resource.VectorDatabase
  ( Args
  , Required
  , VectorDatabase
  , VectorDatabaseResource
  , args
  , create
  , config
  , id
  , projectId
  , tags
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data VectorDatabaseResource

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  ])

config :: Input (Array ({ defaultQuantization :: String, enableAutoSchema :: Boolean, weaviateVersion :: String })) -> Args -> Args
config value (Args values) = Args (Object.insert "config" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (Object.insert "project_id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

timeouts :: Input ({ create :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

type VectorDatabase =
  { resource :: Resource VectorDatabaseResource
  , createdAt :: Expr String
  , endpoints :: Expr (Array ({ grpc :: String, http :: String }))
  , id :: Expr String
  , name :: Expr String
  , ownerUuid :: Expr String
  , projectId :: Expr String
  , region :: Expr String
  , size :: Expr String
  , status :: Expr String
  , tags :: Expr (Array String)
  , updatedAt :: Expr String
  }

create :: String -> Args -> Infra VectorDatabase
create logicalName (Args values) = do
  handle <- addResource "digitalocean_vector_database" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , endpoints: resourceAttr handle [ "endpoints" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , ownerUuid: resourceAttr handle [ "owner_uuid" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , status: resourceAttr handle [ "status" ]
    , tags: resourceAttr handle [ "tags" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    }
