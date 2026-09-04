module DigitalOcean.Resource.SpacesBucket
  ( Args
  , Required
  , SpacesBucket
  , SpacesBucketResource
  , args
  , create
  , CorsRule
  , CorsRuleRequired
  , corsRuleArgs
  , corsRuleAllowedHeaders
  , corsRuleMaxAgeSeconds
  , LifecycleRule
  , LifecycleRuleRequired
  , lifecycleRuleArgs
  , lifecycleRuleAbortIncompleteMultipartUploadDays
  , lifecycleRuleExpiration
  , lifecycleRuleId
  , lifecycleRuleNoncurrentVersionExpiration
  , lifecycleRulePrefix
  , LifecycleRuleExpiration
  , LifecycleRuleExpirationRequired
  , lifecycleRuleExpirationArgs
  , lifecycleRuleExpirationDate
  , lifecycleRuleExpirationDays
  , lifecycleRuleExpirationExpiredObjectDeleteMarker
  , LifecycleRuleNoncurrentVersionExpiration
  , LifecycleRuleNoncurrentVersionExpirationRequired
  , lifecycleRuleNoncurrentVersionExpirationArgs
  , lifecycleRuleNoncurrentVersionExpirationDays
  , Versioning
  , VersioningRequired
  , versioningArgs
  , versioningEnabled
  , acl
  , corsRule
  , forceDestroy
  , id
  , lifecycleRule
  , region
  , versioning
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data SpacesBucketResource

newtype CorsRule = CorsRule InputObject

type CorsRuleRequired =
  { allowedMethods :: Input (Array String)
  , allowedOrigins :: Input (Array String)
  }

corsRuleArgs :: CorsRuleRequired -> CorsRule
corsRuleArgs required = CorsRule (inputObject
  [ Tuple "allowed_methods" (inputJson required.allowedMethods)
  , Tuple "allowed_origins" (inputJson required.allowedOrigins)
  ])

corsRuleAllowedHeaders :: Input (Array String) -> CorsRule -> CorsRule
corsRuleAllowedHeaders value (CorsRule values) = CorsRule (insertInputField "allowed_headers" (inputJson value) values)

corsRuleMaxAgeSeconds :: Input Number -> CorsRule -> CorsRule
corsRuleMaxAgeSeconds value (CorsRule values) = CorsRule (insertInputField "max_age_seconds" (inputJson value) values)

corsRuleJson :: CorsRule -> Json
corsRuleJson (CorsRule values) = inputObjectJson values

newtype LifecycleRule = LifecycleRule InputObject

type LifecycleRuleRequired =
  { enabled :: Input Boolean
  }

lifecycleRuleArgs :: LifecycleRuleRequired -> LifecycleRule
lifecycleRuleArgs required = LifecycleRule (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

lifecycleRuleAbortIncompleteMultipartUploadDays :: Input Number -> LifecycleRule -> LifecycleRule
lifecycleRuleAbortIncompleteMultipartUploadDays value (LifecycleRule values) = LifecycleRule (insertInputField "abort_incomplete_multipart_upload_days" (inputJson value) values)

lifecycleRuleExpiration :: Array LifecycleRuleExpiration -> LifecycleRule -> LifecycleRule
lifecycleRuleExpiration value (LifecycleRule values) = LifecycleRule (insertInputField "expiration" (arrayExprJson (map lifecycleRuleExpirationJson value)) values)

lifecycleRuleId :: Input String -> LifecycleRule -> LifecycleRule
lifecycleRuleId value (LifecycleRule values) = LifecycleRule (insertInputField "id" (inputJson value) values)

lifecycleRuleNoncurrentVersionExpiration :: Array LifecycleRuleNoncurrentVersionExpiration -> LifecycleRule -> LifecycleRule
lifecycleRuleNoncurrentVersionExpiration value (LifecycleRule values) = LifecycleRule (insertInputField "noncurrent_version_expiration" (arrayExprJson (map lifecycleRuleNoncurrentVersionExpirationJson value)) values)

lifecycleRulePrefix :: Input String -> LifecycleRule -> LifecycleRule
lifecycleRulePrefix value (LifecycleRule values) = LifecycleRule (insertInputField "prefix" (inputJson value) values)

lifecycleRuleJson :: LifecycleRule -> Json
lifecycleRuleJson (LifecycleRule values) = inputObjectJson values

newtype LifecycleRuleExpiration = LifecycleRuleExpiration InputObject

type LifecycleRuleExpirationRequired =
  {
  }

lifecycleRuleExpirationArgs :: LifecycleRuleExpirationRequired -> LifecycleRuleExpiration
lifecycleRuleExpirationArgs _ = LifecycleRuleExpiration (inputObject
  [
  ])

lifecycleRuleExpirationDate :: Input String -> LifecycleRuleExpiration -> LifecycleRuleExpiration
lifecycleRuleExpirationDate value (LifecycleRuleExpiration values) = LifecycleRuleExpiration (insertInputField "date" (inputJson value) values)

lifecycleRuleExpirationDays :: Input Number -> LifecycleRuleExpiration -> LifecycleRuleExpiration
lifecycleRuleExpirationDays value (LifecycleRuleExpiration values) = LifecycleRuleExpiration (insertInputField "days" (inputJson value) values)

lifecycleRuleExpirationExpiredObjectDeleteMarker :: Input Boolean -> LifecycleRuleExpiration -> LifecycleRuleExpiration
lifecycleRuleExpirationExpiredObjectDeleteMarker value (LifecycleRuleExpiration values) = LifecycleRuleExpiration (insertInputField "expired_object_delete_marker" (inputJson value) values)

lifecycleRuleExpirationJson :: LifecycleRuleExpiration -> Json
lifecycleRuleExpirationJson (LifecycleRuleExpiration values) = inputObjectJson values

newtype LifecycleRuleNoncurrentVersionExpiration = LifecycleRuleNoncurrentVersionExpiration InputObject

type LifecycleRuleNoncurrentVersionExpirationRequired =
  {
  }

lifecycleRuleNoncurrentVersionExpirationArgs :: LifecycleRuleNoncurrentVersionExpirationRequired -> LifecycleRuleNoncurrentVersionExpiration
lifecycleRuleNoncurrentVersionExpirationArgs _ = LifecycleRuleNoncurrentVersionExpiration (inputObject
  [
  ])

lifecycleRuleNoncurrentVersionExpirationDays :: Input Number -> LifecycleRuleNoncurrentVersionExpiration -> LifecycleRuleNoncurrentVersionExpiration
lifecycleRuleNoncurrentVersionExpirationDays value (LifecycleRuleNoncurrentVersionExpiration values) = LifecycleRuleNoncurrentVersionExpiration (insertInputField "days" (inputJson value) values)

lifecycleRuleNoncurrentVersionExpirationJson :: LifecycleRuleNoncurrentVersionExpiration -> Json
lifecycleRuleNoncurrentVersionExpirationJson (LifecycleRuleNoncurrentVersionExpiration values) = inputObjectJson values

newtype Versioning = Versioning InputObject

type VersioningRequired =
  {
  }

versioningArgs :: VersioningRequired -> Versioning
versioningArgs _ = Versioning (inputObject
  [
  ])

versioningEnabled :: Input Boolean -> Versioning -> Versioning
versioningEnabled value (Versioning values) = Versioning (insertInputField "enabled" (inputJson value) values)

versioningJson :: Versioning -> Json
versioningJson (Versioning values) = inputObjectJson values

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

acl :: Input String -> Args -> Args
acl value (Args values) = Args (insertInputField "acl" (inputJson value) values)

corsRule :: Array CorsRule -> Args -> Args
corsRule value (Args values) = Args (insertInputField "cors_rule" (arrayExprJson (map corsRuleJson value)) values)

forceDestroy :: Input Boolean -> Args -> Args
forceDestroy value (Args values) = Args (insertInputField "force_destroy" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

lifecycleRule :: Array LifecycleRule -> Args -> Args
lifecycleRule value (Args values) = Args (insertInputField "lifecycle_rule" (arrayExprJson (map lifecycleRuleJson value)) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

versioning :: Array Versioning -> Args -> Args
versioning value (Args values) = Args (insertInputField "versioning" (arrayExprJson (map versioningJson value)) values)

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
