module DigitalOcean.Resource.SpacesBucket
  ( Args
  , Required
  , SpacesBucket
  , SpacesBucketResource
  , args
  , create
  , acl
  , corsRule
  , forceDestroy
  , id
  , lifecycleRule
  , region
  , versioning
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data SpacesBucketResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

acl :: Input String -> Args -> Args
acl value (Args values) = Args (Object.insert "acl" (inputJson value) values)

corsRule :: Input (Array ({ allowedHeaders :: Array String, allowedMethods :: Array String, allowedOrigins :: Array String, maxAgeSeconds :: Number })) -> Args -> Args
corsRule value (Args values) = Args (Object.insert "cors_rule" (inputJson value) values)

forceDestroy :: Input Boolean -> Args -> Args
forceDestroy value (Args values) = Args (Object.insert "force_destroy" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

lifecycleRule :: Input (Array ({ abortIncompleteMultipartUploadDays :: Number, enabled :: Boolean, expiration :: Array ({ date :: String, days :: Number, expiredObjectDeleteMarker :: Boolean }), id :: String, noncurrentVersionExpiration :: Array ({ days :: Number }), prefix :: String })) -> Args -> Args
lifecycleRule value (Args values) = Args (Object.insert "lifecycle_rule" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

versioning :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
versioning value (Args values) = Args (Object.insert "versioning" (inputJson value) values)

type SpacesBucket =
  { resource :: Resource SpacesBucketResource
  , acl :: Expr String
  , bucketDomainName :: Expr String
  , endpoint :: Expr String
  , forceDestroy :: Expr Boolean
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , urn :: Expr String
  }

create :: String -> Args -> Infra SpacesBucket
create logicalName (Args values) = do
  handle <- addResource "digitalocean_spaces_bucket" logicalName values
  pure
    { resource: handle
    , acl: resourceAttr handle [ "acl" ]
    , bucketDomainName: resourceAttr handle [ "bucket_domain_name" ]
    , endpoint: resourceAttr handle [ "endpoint" ]
    , forceDestroy: resourceAttr handle [ "force_destroy" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , region: resourceAttr handle [ "region" ]
    , urn: resourceAttr handle [ "urn" ]
    }
