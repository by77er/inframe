module DigitalOcean.Resource.SpacesBucketObject
  ( Args
  , Required
  , SpacesBucketObject
  , SpacesBucketObjectResource
  , args
  , create
  , acl
  , cacheControl
  , content
  , contentBase64
  , contentDisposition
  , contentEncoding
  , contentLanguage
  , contentType
  , etag
  , forceDestroy
  , id
  , metadata
  , source
  , websiteRedirect
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data SpacesBucketObjectResource

type Required =
  { bucket :: Input String
  , key :: Input String
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "key" (inputJson required.key)
  , Tuple "region" (inputJson required.region)
  ])

acl :: Input String -> Args -> Args
acl value (Args values) = Args (Object.insert "acl" (inputJson value) values)

cacheControl :: Input String -> Args -> Args
cacheControl value (Args values) = Args (Object.insert "cache_control" (inputJson value) values)

content :: Input String -> Args -> Args
content value (Args values) = Args (Object.insert "content" (inputJson value) values)

contentBase64 :: Input String -> Args -> Args
contentBase64 value (Args values) = Args (Object.insert "content_base64" (inputJson value) values)

contentDisposition :: Input String -> Args -> Args
contentDisposition value (Args values) = Args (Object.insert "content_disposition" (inputJson value) values)

contentEncoding :: Input String -> Args -> Args
contentEncoding value (Args values) = Args (Object.insert "content_encoding" (inputJson value) values)

contentLanguage :: Input String -> Args -> Args
contentLanguage value (Args values) = Args (Object.insert "content_language" (inputJson value) values)

contentType :: Input String -> Args -> Args
contentType value (Args values) = Args (Object.insert "content_type" (inputJson value) values)

etag :: Input String -> Args -> Args
etag value (Args values) = Args (Object.insert "etag" (inputJson value) values)

forceDestroy :: Input Boolean -> Args -> Args
forceDestroy value (Args values) = Args (Object.insert "force_destroy" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

metadata :: Input Json -> Args -> Args
metadata value (Args values) = Args (Object.insert "metadata" (inputJson value) values)

source :: Input String -> Args -> Args
source value (Args values) = Args (Object.insert "source" (inputJson value) values)

websiteRedirect :: Input String -> Args -> Args
websiteRedirect value (Args values) = Args (Object.insert "website_redirect" (inputJson value) values)

type SpacesBucketObject =
  { resource :: Resource SpacesBucketObjectResource
  , acl :: Expr String
  , bucket :: Expr String
  , cacheControl :: Expr String
  , content :: Expr String
  , contentBase64 :: Expr String
  , contentDisposition :: Expr String
  , contentEncoding :: Expr String
  , contentLanguage :: Expr String
  , contentType :: Expr String
  , etag :: Expr String
  , forceDestroy :: Expr Boolean
  , id :: Expr String
  , key :: Expr String
  , metadata :: Expr Json
  , region :: Expr String
  , source :: Expr String
  , versionId :: Expr String
  , websiteRedirect :: Expr String
  }

create :: String -> Args -> Infra SpacesBucketObject
create logicalName (Args values) = do
  handle <- addResource "digitalocean_spaces_bucket_object" logicalName values
  pure
    { resource: handle
    , acl: resourceAttr handle [ "acl" ]
    , bucket: resourceAttr handle [ "bucket" ]
    , cacheControl: resourceAttr handle [ "cache_control" ]
    , content: resourceAttr handle [ "content" ]
    , contentBase64: resourceAttr handle [ "content_base64" ]
    , contentDisposition: resourceAttr handle [ "content_disposition" ]
    , contentEncoding: resourceAttr handle [ "content_encoding" ]
    , contentLanguage: resourceAttr handle [ "content_language" ]
    , contentType: resourceAttr handle [ "content_type" ]
    , etag: resourceAttr handle [ "etag" ]
    , forceDestroy: resourceAttr handle [ "force_destroy" ]
    , id: resourceAttr handle [ "id" ]
    , key: resourceAttr handle [ "key" ]
    , metadata: resourceAttr handle [ "metadata" ]
    , region: resourceAttr handle [ "region" ]
    , source: resourceAttr handle [ "source" ]
    , versionId: resourceAttr handle [ "version_id" ]
    , websiteRedirect: resourceAttr handle [ "website_redirect" ]
    }
