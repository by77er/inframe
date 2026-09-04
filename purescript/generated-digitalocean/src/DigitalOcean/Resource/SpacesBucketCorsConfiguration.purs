module DigitalOcean.Resource.SpacesBucketCorsConfiguration
  ( Args
  , Required
  , SpacesBucketCorsConfiguration
  , SpacesBucketCorsConfigurationResource
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

data SpacesBucketCorsConfigurationResource

type Required =
  { bucket :: Input String
  , corsRule :: Input (Array ({ allowedHeaders :: Array String, allowedMethods :: Array String, allowedOrigins :: Array String, exposeHeaders :: Array String, id :: String, maxAgeSeconds :: Number }))
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "cors_rule" (inputJson required.corsRule)
  , Tuple "region" (inputJson required.region)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type SpacesBucketCorsConfiguration =
  { resource :: Resource SpacesBucketCorsConfigurationResource
  , bucket :: Expr String
  , id :: Expr String
  , region :: Expr String
  }

create :: String -> Args -> Infra SpacesBucketCorsConfiguration
create logicalName (Args values) = do
  handle <- addResource "digitalocean_spaces_bucket_cors_configuration" logicalName values
  pure
    { resource: handle
    , bucket: resourceAttr handle [ "bucket" ]
    , id: resourceAttr handle [ "id" ]
    , region: resourceAttr handle [ "region" ]
    }
