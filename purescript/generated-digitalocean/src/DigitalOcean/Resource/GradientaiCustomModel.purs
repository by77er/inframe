module DigitalOcean.Resource.GradientaiCustomModel
  ( Args
  , Required
  , GradientaiCustomModel
  , GradientaiCustomModelResource
  , args
  , create
  , acceptTermsAndConditions
  , description
  , id
  , inputModalities
  , license
  , outputModalities
  , parameters
  , preferredGpuRegion
  , tags
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data GradientaiCustomModelResource

type Required =
  { name :: Input String
  , sourceRef :: Input (Array ({ accessType :: String, bucket :: String, commitSha :: String, hfToken :: String, prefix :: String, region :: String, repoId :: String }))
  , sourceType :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "source_ref" (inputJson required.sourceRef)
  , Tuple "source_type" (inputJson required.sourceType)
  ])

acceptTermsAndConditions :: Input Boolean -> Args -> Args
acceptTermsAndConditions value (Args values) = Args (Object.insert "accept_terms_and_conditions" (inputJson value) values)

description :: Input String -> Args -> Args
description value (Args values) = Args (Object.insert "description" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

inputModalities :: Input (Array String) -> Args -> Args
inputModalities value (Args values) = Args (Object.insert "input_modalities" (inputJson value) values)

license :: Input String -> Args -> Args
license value (Args values) = Args (Object.insert "license" (inputJson value) values)

outputModalities :: Input (Array String) -> Args -> Args
outputModalities value (Args values) = Args (Object.insert "output_modalities" (inputJson value) values)

parameters :: Input String -> Args -> Args
parameters value (Args values) = Args (Object.insert "parameters" (inputJson value) values)

preferredGpuRegion :: Input String -> Args -> Args
preferredGpuRegion value (Args values) = Args (Object.insert "preferred_gpu_region" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

timeouts :: Input ({ create :: String, delete :: String, update :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

type GradientaiCustomModel =
  { resource :: Resource GradientaiCustomModelResource
  , acceptTermsAndConditions :: Expr Boolean
  , activeDeployments :: Expr (Array ({ createdAt :: String, endpoints :: Array ({ privateEndpointFqdn :: String, publicEndpointFqdn :: String }), id :: String, name :: String, regionSlug :: String, state :: String, updatedAt :: String }))
  , architecture :: Expr String
  , contextLength :: Expr Number
  , costEstimatePerMonth :: Expr Number
  , createdAt :: Expr String
  , description :: Expr String
  , errorMessage :: Expr String
  , fileCount :: Expr Number
  , id :: Expr String
  , inputModalities :: Expr (Array String)
  , license :: Expr String
  , name :: Expr String
  , outputModalities :: Expr (Array String)
  , parameters :: Expr String
  , preferredGpuRegion :: Expr String
  , sourceType :: Expr String
  , status :: Expr String
  , storageRegion :: Expr String
  , tags :: Expr (Array String)
  , teamId :: Expr String
  , totalSizeBytes :: Expr String
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiCustomModel
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_custom_model" logicalName values
  pure
    { resource: handle
    , acceptTermsAndConditions: resourceAttr handle [ "accept_terms_and_conditions" ]
    , activeDeployments: resourceAttr handle [ "active_deployments" ]
    , architecture: resourceAttr handle [ "architecture" ]
    , contextLength: resourceAttr handle [ "context_length" ]
    , costEstimatePerMonth: resourceAttr handle [ "cost_estimate_per_month" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , description: resourceAttr handle [ "description" ]
    , errorMessage: resourceAttr handle [ "error_message" ]
    , fileCount: resourceAttr handle [ "file_count" ]
    , id: resourceAttr handle [ "id" ]
    , inputModalities: resourceAttr handle [ "input_modalities" ]
    , license: resourceAttr handle [ "license" ]
    , name: resourceAttr handle [ "name" ]
    , outputModalities: resourceAttr handle [ "output_modalities" ]
    , parameters: resourceAttr handle [ "parameters" ]
    , preferredGpuRegion: resourceAttr handle [ "preferred_gpu_region" ]
    , sourceType: resourceAttr handle [ "source_type" ]
    , status: resourceAttr handle [ "status" ]
    , storageRegion: resourceAttr handle [ "storage_region" ]
    , tags: resourceAttr handle [ "tags" ]
    , teamId: resourceAttr handle [ "team_id" ]
    , totalSizeBytes: resourceAttr handle [ "total_size_bytes" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
