module DigitalOcean.Resource.GradientaiCustomModel
  ( Args
  , Required
  , GradientaiCustomModel
  , GradientaiCustomModelResource
  , args
  , create
  , SourceRef
  , SourceRefRequired
  , sourceRefArgs
  , sourceRefAccessType
  , sourceRefBucket
  , sourceRefCommitSha
  , sourceRefHfToken
  , sourceRefPrefix
  , sourceRefRegion
  , sourceRefRepoId
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , timeoutsDelete
  , timeoutsUpdate
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data GradientaiCustomModelResource

newtype SourceRef = SourceRef InputObject

type SourceRefRequired =
  {
  }

sourceRefArgs :: SourceRefRequired -> SourceRef
sourceRefArgs _ = SourceRef (inputObject
  [
  ])

sourceRefAccessType :: Input String -> SourceRef -> SourceRef
sourceRefAccessType value (SourceRef values) = SourceRef (insertInputField "access_type" (inputJson value) values)

sourceRefBucket :: Input String -> SourceRef -> SourceRef
sourceRefBucket value (SourceRef values) = SourceRef (insertInputField "bucket" (inputJson value) values)

sourceRefCommitSha :: Input String -> SourceRef -> SourceRef
sourceRefCommitSha value (SourceRef values) = SourceRef (insertInputField "commit_sha" (inputJson value) values)

sourceRefHfToken :: Input String -> SourceRef -> SourceRef
sourceRefHfToken value (SourceRef values) = SourceRef (insertInputField "hf_token" (inputJson value) values)

sourceRefPrefix :: Input String -> SourceRef -> SourceRef
sourceRefPrefix value (SourceRef values) = SourceRef (insertInputField "prefix" (inputJson value) values)

sourceRefRegion :: Input String -> SourceRef -> SourceRef
sourceRefRegion value (SourceRef values) = SourceRef (insertInputField "region" (inputJson value) values)

sourceRefRepoId :: Input String -> SourceRef -> SourceRef
sourceRefRepoId value (SourceRef values) = SourceRef (insertInputField "repo_id" (inputJson value) values)

sourceRefJson :: SourceRef -> Json
sourceRefJson (SourceRef values) = inputObjectJson values

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsDelete :: Input String -> Timeouts -> Timeouts
timeoutsDelete value (Timeouts values) = Timeouts (insertInputField "delete" (inputJson value) values)

timeoutsUpdate :: Input String -> Timeouts -> Timeouts
timeoutsUpdate value (Timeouts values) = Timeouts (insertInputField "update" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  , sourceRef :: Array SourceRef
  , sourceType :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "source_ref" (arrayExprJson (map sourceRefJson required.sourceRef))
  , Tuple "source_type" (inputJson required.sourceType)
  ])

acceptTermsAndConditions :: Input Boolean -> Args -> Args
acceptTermsAndConditions value (Args values) = Args (insertInputField "accept_terms_and_conditions" (inputJson value) values)

description :: Input String -> Args -> Args
description value (Args values) = Args (insertInputField "description" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

inputModalities :: Input (Array String) -> Args -> Args
inputModalities value (Args values) = Args (insertInputField "input_modalities" (inputJson value) values)

license :: Input String -> Args -> Args
license value (Args values) = Args (insertInputField "license" (inputJson value) values)

outputModalities :: Input (Array String) -> Args -> Args
outputModalities value (Args values) = Args (insertInputField "output_modalities" (inputJson value) values)

parameters :: Input String -> Args -> Args
parameters value (Args values) = Args (insertInputField "parameters" (inputJson value) values)

preferredGpuRegion :: Input String -> Args -> Args
preferredGpuRegion value (Args values) = Args (insertInputField "preferred_gpu_region" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

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
