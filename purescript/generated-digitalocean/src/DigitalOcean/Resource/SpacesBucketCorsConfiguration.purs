module DigitalOcean.Resource.SpacesBucketCorsConfiguration
  ( Args
  , Required
  , SpacesBucketCorsConfiguration
  , SpacesBucketCorsConfigurationResource
  , args
  , create
  , CorsRule
  , CorsRuleRequired
  , corsRuleArgs
  , corsRuleAllowedHeaders
  , corsRuleExposeHeaders
  , corsRuleId
  , corsRuleMaxAgeSeconds
  , id
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data SpacesBucketCorsConfigurationResource

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

corsRuleExposeHeaders :: Input (Array String) -> CorsRule -> CorsRule
corsRuleExposeHeaders value (CorsRule values) = CorsRule (insertInputField "expose_headers" (inputJson value) values)

corsRuleId :: Input String -> CorsRule -> CorsRule
corsRuleId value (CorsRule values) = CorsRule (insertInputField "id" (inputJson value) values)

corsRuleMaxAgeSeconds :: Input Number -> CorsRule -> CorsRule
corsRuleMaxAgeSeconds value (CorsRule values) = CorsRule (insertInputField "max_age_seconds" (inputJson value) values)

corsRuleJson :: CorsRule -> Json
corsRuleJson (CorsRule values) = inputObjectJson values

type Required =
  { bucket :: Input String
  , corsRule :: Array CorsRule
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "bucket" (inputJson required.bucket)
  , Tuple "cors_rule" (arrayExprJson (map corsRuleJson required.corsRule))
  , Tuple "region" (inputJson required.region)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
