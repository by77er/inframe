module DigitalOcean.Data.Image
  ( Args
  , Required
  , Image
  , ImageDataSource
  , args
  , read
  , id
  , name
  , slug
  , source
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data ImageDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input Number -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (insertInputField "name" (inputJson value) values)

slug :: Input String -> Args -> Args
slug value (Args values) = Args (insertInputField "slug" (inputJson value) values)

source :: Input String -> Args -> Args
source value (Args values) = Args (insertInputField "source" (inputJson value) values)

type Image =
  { dataSource :: DataSource ImageDataSource
  , created :: Expr String
  , description :: Expr String
  , distribution :: Expr String
  , errorMessage :: Expr String
  , id :: Expr Number
  , image :: Expr String
  , minDiskSize :: Expr Number
  , name :: Expr String
  , private :: Expr Boolean
  , regions :: Expr (Array String)
  , sizeGigabytes :: Expr Number
  , slug :: Expr String
  , source :: Expr String
  , status :: Expr String
  , tags :: Expr (Array String)
  , type_ :: Expr String
  }

read :: String -> Args -> Infra Image
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_image" logicalName values
  pure
    { dataSource: handle
    , created: dataSourceAttr handle [ "created" ]
    , description: dataSourceAttr handle [ "description" ]
    , distribution: dataSourceAttr handle [ "distribution" ]
    , errorMessage: dataSourceAttr handle [ "error_message" ]
    , id: dataSourceAttr handle [ "id" ]
    , image: dataSourceAttr handle [ "image" ]
    , minDiskSize: dataSourceAttr handle [ "min_disk_size" ]
    , name: dataSourceAttr handle [ "name" ]
    , private: dataSourceAttr handle [ "private" ]
    , regions: dataSourceAttr handle [ "regions" ]
    , sizeGigabytes: dataSourceAttr handle [ "size_gigabytes" ]
    , slug: dataSourceAttr handle [ "slug" ]
    , source: dataSourceAttr handle [ "source" ]
    , status: dataSourceAttr handle [ "status" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , type_: dataSourceAttr handle [ "type" ]
    }
