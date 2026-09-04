module DigitalOcean.Data.VectorDatabase
  ( Args
  , Required
  , VectorDatabase
  , VectorDatabaseDataSource
  , args
  , read
  , id
  , name
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data VectorDatabaseDataSource

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

type VectorDatabase =
  { dataSource :: DataSource VectorDatabaseDataSource
  , config :: Expr (Array ({ defaultQuantization :: String, enableAutoSchema :: Boolean, weaviateVersion :: String }))
  , createdAt :: Expr String
  , endpoints :: Expr (Array ({ grpc :: String, http :: String }))
  , id :: Expr String
  , name :: Expr String
  , ownerUuid :: Expr String
  , region :: Expr String
  , size :: Expr String
  , status :: Expr String
  , tags :: Expr (Array String)
  , updatedAt :: Expr String
  }

read :: String -> Args -> Infra VectorDatabase
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_vector_database" logicalName values
  pure
    { dataSource: handle
    , config: dataSourceAttr handle [ "config" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , endpoints: dataSourceAttr handle [ "endpoints" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , ownerUuid: dataSourceAttr handle [ "owner_uuid" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , status: dataSourceAttr handle [ "status" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    }
