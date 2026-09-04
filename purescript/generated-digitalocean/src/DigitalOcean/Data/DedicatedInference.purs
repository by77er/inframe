module DigitalOcean.Data.DedicatedInference
  ( Args
  , Required
  , DedicatedInference
  , DedicatedInferenceDataSource
  , args
  , read
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DedicatedInferenceDataSource

type Required =
  { id :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "id" (inputJson required.id)
  ])

type DedicatedInference =
  { dataSource :: DataSource DedicatedInferenceDataSource
  , createdAt :: Expr String
  , enablePublicEndpoint :: Expr Boolean
  , id :: Expr String
  , modelDeployments :: Expr (Array ({ accelerators :: Array ({ acceleratorSlug :: String, scale :: Number, type_ :: String }), modelId :: String, modelProvider :: String, modelSlug :: String, providerModelId :: String }))
  , name :: Expr String
  , privateEndpointFqdn :: Expr String
  , publicEndpointFqdn :: Expr String
  , region :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  , vpcUuid :: Expr String
  }

read :: String -> Args -> Infra DedicatedInference
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_dedicated_inference" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , enablePublicEndpoint: dataSourceAttr handle [ "enable_public_endpoint" ]
    , id: dataSourceAttr handle [ "id" ]
    , modelDeployments: dataSourceAttr handle [ "model_deployments" ]
    , name: dataSourceAttr handle [ "name" ]
    , privateEndpointFqdn: dataSourceAttr handle [ "private_endpoint_fqdn" ]
    , publicEndpointFqdn: dataSourceAttr handle [ "public_endpoint_fqdn" ]
    , region: dataSourceAttr handle [ "region" ]
    , status: dataSourceAttr handle [ "status" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , vpcUuid: dataSourceAttr handle [ "vpc_uuid" ]
    }
