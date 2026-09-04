module DigitalOcean.Data.SpacesBucket
  ( Args
  , Required
  , SpacesBucket
  , SpacesBucketDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data SpacesBucketDataSource

type Required =
  { name :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type SpacesBucket =
  { dataSource :: DataSource SpacesBucketDataSource
  , bucketDomainName :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

read :: String -> Args -> Infra SpacesBucket
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_spaces_bucket" logicalName values
  pure
    { dataSource: handle
    , bucketDomainName: dataSourceAttr handle [ "bucket_domain_name" ]
    , endpoint: dataSourceAttr handle [ "endpoint" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , region: dataSourceAttr handle [ "region" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
