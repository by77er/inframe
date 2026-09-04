module DigitalOcean.Resource.Project
  ( Args
  , Required
  , Project
  , ProjectResource
  , args
  , create
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsDelete
  , description
  , environment
  , id
  , isDefault
  , purpose
  , resources
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data ProjectResource

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsDelete :: Input String -> Timeouts -> Timeouts
timeoutsDelete value (Timeouts values) = Timeouts (insertInputField "delete" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

description :: Input String -> Args -> Args
description value (Args values) = Args (insertInputField "description" (inputJson value) values)

environment :: Input String -> Args -> Args
environment value (Args values) = Args (insertInputField "environment" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

isDefault :: Input Boolean -> Args -> Args
isDefault value (Args values) = Args (insertInputField "is_default" (inputJson value) values)

purpose :: Input String -> Args -> Args
purpose value (Args values) = Args (insertInputField "purpose" (inputJson value) values)

resources :: Input (Array String) -> Args -> Args
resources value (Args values) = Args (insertInputField "resources" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

type Project =
  { resource :: Resource ProjectResource
  , createdAt :: Expr String
  , description :: Expr String
  , environment :: Expr String
  , id :: Expr String
  , isDefault :: Expr Boolean
  , name :: Expr String
  , ownerId :: Expr Number
  , ownerUuid :: Expr String
  , purpose :: Expr String
  , resources :: Expr (Array String)
  , updatedAt :: Expr String
  }

create :: String -> Args -> Infra Project
create logicalName (Args values) = do
  handle <- addResource "digitalocean_project" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , description: resourceAttr handle [ "description" ]
    , environment: resourceAttr handle [ "environment" ]
    , id: resourceAttr handle [ "id" ]
    , isDefault: resourceAttr handle [ "is_default" ]
    , name: resourceAttr handle [ "name" ]
    , ownerId: resourceAttr handle [ "owner_id" ]
    , ownerUuid: resourceAttr handle [ "owner_uuid" ]
    , purpose: resourceAttr handle [ "purpose" ]
    , resources: resourceAttr handle [ "resources" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    }
