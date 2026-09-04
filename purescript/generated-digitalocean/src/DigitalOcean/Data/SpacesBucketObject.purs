module DigitalOcean.Data.SpacesBucketObject
  ( Args
  , Required
  , SpacesBucketObject
  , SpacesBucketObjectDataSource
  , args
  , read
  , id
  , range
  , versionId
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data SpacesBucketObjectDataSource

type Required =
  { bucket :: Input String
  , key :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "key" (inputJson required.key)
  , Tuple "region" (inputJson required.region)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

range :: Input String -> Args -> Args
range value (Args values) = Args (insertInputField "range" (inputJson value) values)

versionId :: Input String -> Args -> Args
versionId value (Args values) = Args (insertInputField "version_id" (inputJson value) values)

type SpacesBucketObject =
  { dataSource :: DataSource SpacesBucketObjectDataSource
  , body :: Expr String
  , bucket :: Expr String
  , cacheControl :: Expr String
  , contentDisposition :: Expr String
  , contentEncoding :: Expr String
  , contentLanguage :: Expr String
  , contentLength :: Expr Number
  , contentType :: Expr String
  , etag :: Expr String
  , expiration :: Expr String
  , expires :: Expr String
  , id :: Expr String
  , key :: Expr String
  , lastModified :: Expr String
  , metadata :: Expr Json
  , range :: Expr String
  , region :: Expr String
  , versionId :: Expr String
  , websiteRedirectLocation :: Expr String
  }

read :: String -> Args -> Infra SpacesBucketObject
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_spaces_bucket_object" logicalName values
  pure
    { dataSource: handle
    , body: dataSourceAttr handle [ "body" ]
    , bucket: dataSourceAttr handle [ "bucket" ]
    , cacheControl: dataSourceAttr handle [ "cache_control" ]
    , contentDisposition: dataSourceAttr handle [ "content_disposition" ]
    , contentEncoding: dataSourceAttr handle [ "content_encoding" ]
    , contentLanguage: dataSourceAttr handle [ "content_language" ]
    , contentLength: dataSourceAttr handle [ "content_length" ]
    , contentType: dataSourceAttr handle [ "content_type" ]
    , etag: dataSourceAttr handle [ "etag" ]
    , expiration: dataSourceAttr handle [ "expiration" ]
    , expires: dataSourceAttr handle [ "expires" ]
    , id: dataSourceAttr handle [ "id" ]
    , key: dataSourceAttr handle [ "key" ]
    , lastModified: dataSourceAttr handle [ "last_modified" ]
    , metadata: dataSourceAttr handle [ "metadata" ]
    , range: dataSourceAttr handle [ "range" ]
    , region: dataSourceAttr handle [ "region" ]
    , versionId: dataSourceAttr handle [ "version_id" ]
    , websiteRedirectLocation: dataSourceAttr handle [ "website_redirect_location" ]
    }
