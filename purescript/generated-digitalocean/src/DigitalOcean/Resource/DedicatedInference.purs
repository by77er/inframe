module DigitalOcean.Resource.DedicatedInference
  ( Args
  , Required
  , DedicatedInference
  , DedicatedInferenceResource
  , args
  , create
  , ModelDeployments
  , ModelDeploymentsRequired
  , modelDeploymentsArgs
  , modelDeploymentsModelId
  , modelDeploymentsProviderModelId
  , ModelDeploymentsAccelerators
  , ModelDeploymentsAcceleratorsRequired
  , modelDeploymentsAcceleratorsArgs
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , timeoutsDelete
  , timeoutsUpdate
  , enablePublicEndpoint
  , huggingFaceToken
  , id
  , timeouts
  , vpcUuid
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DedicatedInferenceResource

newtype ModelDeployments = ModelDeployments InputObject

type ModelDeploymentsRequired =
  { accelerators :: Array ModelDeploymentsAccelerators
  , modelProvider :: Input String
  , modelSlug :: Input String
  }

modelDeploymentsArgs :: ModelDeploymentsRequired -> ModelDeployments
modelDeploymentsArgs required = ModelDeployments (inputObject
  [ Tuple "accelerators" (arrayExprJson (map modelDeploymentsAcceleratorsJson required.accelerators))
  , Tuple "model_provider" (inputJson required.modelProvider)
  , Tuple "model_slug" (inputJson required.modelSlug)
  ])

modelDeploymentsModelId :: Input String -> ModelDeployments -> ModelDeployments
modelDeploymentsModelId value (ModelDeployments values) = ModelDeployments (insertInputField "model_id" (inputJson value) values)

modelDeploymentsProviderModelId :: Input String -> ModelDeployments -> ModelDeployments
modelDeploymentsProviderModelId value (ModelDeployments values) = ModelDeployments (insertInputField "provider_model_id" (inputJson value) values)

modelDeploymentsJson :: ModelDeployments -> Json
modelDeploymentsJson (ModelDeployments values) = inputObjectJson values

newtype ModelDeploymentsAccelerators = ModelDeploymentsAccelerators InputObject

type ModelDeploymentsAcceleratorsRequired =
  { acceleratorSlug :: Input String
  , scale :: Input Number
  , type_ :: Input String
  }

modelDeploymentsAcceleratorsArgs :: ModelDeploymentsAcceleratorsRequired -> ModelDeploymentsAccelerators
modelDeploymentsAcceleratorsArgs required = ModelDeploymentsAccelerators (inputObject
  [ Tuple "accelerator_slug" (inputJson required.acceleratorSlug)
  , Tuple "scale" (inputJson required.scale)
  , Tuple "type" (inputJson required.type_)
  ])

modelDeploymentsAcceleratorsJson :: ModelDeploymentsAccelerators -> Json
modelDeploymentsAcceleratorsJson (ModelDeploymentsAccelerators values) = inputObjectJson values

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
  { modelDeployments :: Array ModelDeployments
  , name :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "model_deployments" (arrayExprJson (map modelDeploymentsJson required.modelDeployments))
  , Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  ])

enablePublicEndpoint :: Input Boolean -> Args -> Args
enablePublicEndpoint value (Args values) = Args (insertInputField "enable_public_endpoint" (inputJson value) values)

huggingFaceToken :: Input String -> Args -> Args
huggingFaceToken value (Args values) = Args (insertInputField "hugging_face_token" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (insertInputField "vpc_uuid" (inputJson value) values)

type DedicatedInference =
  { resource :: Resource DedicatedInferenceResource
  , createdAt :: Expr String
  , enablePublicEndpoint :: Expr Boolean
  , huggingFaceToken :: Expr String
  , id :: Expr String
  , name :: Expr String
  , privateEndpointFqdn :: Expr String
  , publicEndpointFqdn :: Expr String
  , region :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  , vpcUuid :: Expr String
  }

create :: String -> Args -> Infra DedicatedInference
create logicalName (Args values) = do
  handle <- addResource "digitalocean_dedicated_inference" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , enablePublicEndpoint: resourceAttr handle [ "enable_public_endpoint" ]
    , huggingFaceToken: resourceAttr handle [ "hugging_face_token" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , privateEndpointFqdn: resourceAttr handle [ "private_endpoint_fqdn" ]
    , publicEndpointFqdn: resourceAttr handle [ "public_endpoint_fqdn" ]
    , region: resourceAttr handle [ "region" ]
    , status: resourceAttr handle [ "status" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , vpcUuid: resourceAttr handle [ "vpc_uuid" ]
    }
