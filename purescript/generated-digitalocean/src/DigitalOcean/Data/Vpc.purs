module DigitalOcean.Data.Vpc
  ( Args
  , Required
  , Vpc
  , VpcDataSource
  , args
  , read
  , id
  , name
  , region
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data VpcDataSource

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

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

type Vpc =
  { dataSource :: DataSource VpcDataSource
  , createdAt :: Expr String
  , default :: Expr Boolean
  , description :: Expr String
  , id :: Expr String
  , ipRange :: Expr String
  , name :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

read :: String -> Args -> Infra Vpc
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_vpc" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , default: dataSourceAttr handle [ "default" ]
    , description: dataSourceAttr handle [ "description" ]
    , id: dataSourceAttr handle [ "id" ]
    , ipRange: dataSourceAttr handle [ "ip_range" ]
    , name: dataSourceAttr handle [ "name" ]
    , region: dataSourceAttr handle [ "region" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
