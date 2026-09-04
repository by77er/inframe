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

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data SpacesBucketLoggingResource

type Required =
  { bucket :: Input String
  , region :: Input String
  , targetBucket :: Input String
  , targetPrefix :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "region" (inputJson required.region)
  , Tuple "target_bucket" (inputJson required.targetBucket)
  , Tuple "target_prefix" (inputJson required.targetPrefix)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
