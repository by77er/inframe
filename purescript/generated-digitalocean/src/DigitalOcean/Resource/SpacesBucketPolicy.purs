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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data SpacesBucketPolicyResource

type Required =
  { bucket :: Input String
  , policy :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "policy" (inputJson required.policy)
  , Tuple "region" (inputJson required.region)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
