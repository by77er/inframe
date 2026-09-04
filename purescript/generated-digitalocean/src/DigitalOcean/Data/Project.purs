module DigitalOcean.Data.Project
  ( Args
  , Required
  , Project
  , ProjectDataSource
  , args
  , read
  , id
  , name
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data ProjectDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (insertInputField "name" (inputJson value) values)

type Project =
  { dataSource :: DataSource ProjectDataSource
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

read :: String -> Args -> Infra Project
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_project" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , description: dataSourceAttr handle [ "description" ]
    , environment: dataSourceAttr handle [ "environment" ]
    , id: dataSourceAttr handle [ "id" ]
    , isDefault: dataSourceAttr handle [ "is_default" ]
    , name: dataSourceAttr handle [ "name" ]
    , ownerId: dataSourceAttr handle [ "owner_id" ]
    , ownerUuid: dataSourceAttr handle [ "owner_uuid" ]
    , purpose: dataSourceAttr handle [ "purpose" ]
    , resources: dataSourceAttr handle [ "resources" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    }
