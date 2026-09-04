module DigitalOcean.Resource.SpacesBucketPolicy
  ( Args
  , Required
  , SpacesBucketPolicy
  , SpacesBucketPolicyResource
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

data SpacesBucketPolicyResource

type Required =
  { bucket :: Input String
  , policy :: Input String
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "policy" (inputJson required.policy)
  , Tuple "region" (inputJson required.region)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type SpacesBucketPolicy =
  { resource :: Resource SpacesBucketPolicyResource
  , bucket :: Expr String
  , id :: Expr String
  , policy :: Expr String
  , region :: Expr String
  }

create :: String -> Args -> Infra SpacesBucketPolicy
create logicalName (Args values) = do
  handle <- addResource "digitalocean_spaces_bucket_policy" logicalName values
  pure
    { resource: handle
    , bucket: resourceAttr handle [ "bucket" ]
    , id: resourceAttr handle [ "id" ]
    , policy: resourceAttr handle [ "policy" ]
    , region: resourceAttr handle [ "region" ]
    }
