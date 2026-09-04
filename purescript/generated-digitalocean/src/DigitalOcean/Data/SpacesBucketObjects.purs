module DigitalOcean.Data.SpacesBucketObjects
  ( Args
  , Required
  , SpacesBucketObjects
  , SpacesBucketObjectsDataSource
  , args
  , read
  , delimiter
  , encodingType
  , id
  , maxKeys
  , prefix
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data SpacesBucketObjectsDataSource

type Required =
  { bucket :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "region" (inputJson required.region)
  ])

delimiter :: Input String -> Args -> Args
delimiter value (Args values) = Args (insertInputField "delimiter" (inputJson value) values)

encodingType :: Input String -> Args -> Args
encodingType value (Args values) = Args (insertInputField "encoding_type" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

maxKeys :: Input Number -> Args -> Args
maxKeys value (Args values) = Args (insertInputField "max_keys" (inputJson value) values)

prefix :: Input String -> Args -> Args
prefix value (Args values) = Args (insertInputField "prefix" (inputJson value) values)

type SpacesBucketObjects =
  { dataSource :: DataSource SpacesBucketObjectsDataSource
  , bucket :: Expr String
  , commonPrefixes :: Expr (Array String)
  , delimiter :: Expr String
  , encodingType :: Expr String
  , id :: Expr String
  , keys :: Expr (Array String)
  , maxKeys :: Expr Number
  , owners :: Expr (Array String)
  , prefix :: Expr String
  , region :: Expr String
  }

read :: String -> Args -> Infra SpacesBucketObjects
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_spaces_bucket_objects" logicalName values
  pure
    { dataSource: handle
    , bucket: dataSourceAttr handle [ "bucket" ]
    , commonPrefixes: dataSourceAttr handle [ "common_prefixes" ]
    , delimiter: dataSourceAttr handle [ "delimiter" ]
    , encodingType: dataSourceAttr handle [ "encoding_type" ]
    , id: dataSourceAttr handle [ "id" ]
    , keys: dataSourceAttr handle [ "keys" ]
    , maxKeys: dataSourceAttr handle [ "max_keys" ]
    , owners: dataSourceAttr handle [ "owners" ]
    , prefix: dataSourceAttr handle [ "prefix" ]
    , region: dataSourceAttr handle [ "region" ]
    }
