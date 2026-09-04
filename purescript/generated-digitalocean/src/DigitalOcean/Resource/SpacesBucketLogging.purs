module DigitalOcean.Resource.SpacesBucketLogging
  ( Args
  , Required
  , SpacesBucketLogging
  , SpacesBucketLoggingResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data SpacesBucketLoggingResource

type Required =
  { bucket :: Input String
  , region :: Input String
  , targetBucket :: Input String
  , targetPrefix :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "region" (inputJson required.region)
  , Tuple "target_bucket" (inputJson required.targetBucket)
  , Tuple "target_prefix" (inputJson required.targetPrefix)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type SpacesBucketLogging =
  { resource :: Resource SpacesBucketLoggingResource
  , bucket :: Expr String
  , id :: Expr String
  , region :: Expr String
  , targetBucket :: Expr String
  , targetPrefix :: Expr String
  }

create :: String -> Args -> Infra SpacesBucketLogging
create logicalName (Args values) = do
  handle <- addResource "digitalocean_spaces_bucket_logging" logicalName values
  pure
    { resource: handle
    , bucket: resourceAttr handle [ "bucket" ]
    , id: resourceAttr handle [ "id" ]
    , region: resourceAttr handle [ "region" ]
    , targetBucket: resourceAttr handle [ "target_bucket" ]
    , targetPrefix: resourceAttr handle [ "target_prefix" ]
    }
