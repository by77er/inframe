module DigitalOcean.Resource.DedicatedInference
  ( Args
  , Required
  , DedicatedInference
  , DedicatedInferenceResource
  , args
  , create
  , enablePublicEndpoint
  , huggingFaceToken
  , id
  , timeouts
  , vpcUuid
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DedicatedInferenceResource

type Required =
  { modelDeployments :: Input (Array ({ accelerators :: Array ({ acceleratorSlug :: String, scale :: Number, type_ :: String }), modelId :: String, modelProvider :: String, modelSlug :: String, providerModelId :: String }))
  , name :: Input String
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "model_deployments" (inputJson required.modelDeployments)
  , Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  ])

enablePublicEndpoint :: Input Boolean -> Args -> Args
enablePublicEndpoint value (Args values) = Args (Object.insert "enable_public_endpoint" (inputJson value) values)

huggingFaceToken :: Input String -> Args -> Args
huggingFaceToken value (Args values) = Args (Object.insert "hugging_face_token" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

timeouts :: Input ({ create :: String, delete :: String, update :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (Object.insert "vpc_uuid" (inputJson value) values)

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
