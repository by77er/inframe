module DigitalOcean.Resource.VectorDatabase
  ( Args
  , Required
  , VectorDatabase
  , VectorDatabaseResource
  , args
  , create
  , Config
  , ConfigRequired
  , configArgs
  , configDefaultQuantization
  , configEnableAutoSchema
  , configWeaviateVersion
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , config
  , id
  , projectId
  , tags
  , timeouts
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data VectorDatabaseResource

newtype Config = Config InputObject

type ConfigRequired =
  {
  }

configArgs :: ConfigRequired -> Config
configArgs _ = Config (inputObject
  [
  ])

configDefaultQuantization :: Input String -> Config -> Config
configDefaultQuantization value (Config values) = Config (insertInputField "default_quantization" (inputJson value) values)

configEnableAutoSchema :: Input Boolean -> Config -> Config
configEnableAutoSchema value (Config values) = Config (insertInputField "enable_auto_schema" (inputJson value) values)

configWeaviateVersion :: Input String -> Config -> Config
configWeaviateVersion value (Config values) = Config (insertInputField "weaviate_version" (inputJson value) values)

configJson :: Config -> Json
configJson (Config values) = inputObjectJson values

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  ])

config :: Array Config -> Args -> Args
config value (Args values) = Args (insertInputField "config" (arrayExprJson (map configJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (insertInputField "project_id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

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
