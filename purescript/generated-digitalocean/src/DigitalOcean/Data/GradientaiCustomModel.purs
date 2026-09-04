module DigitalOcean.Data.GradientaiCustomModel
  ( Args
  , Required
  , GradientaiCustomModel
  , GradientaiCustomModelDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data GradientaiCustomModelDataSource

type Required =
  { uuid :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "uuid" (inputJson required.uuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type GradientaiCustomModel =
  { dataSource :: DataSource GradientaiCustomModelDataSource
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
  , sourceRef :: Expr (Array ({ accessType :: String, bucket :: String, commitSha :: String, prefix :: String, region :: String, repoId :: String }))
  , sourceType :: Expr String
  , status :: Expr String
  , storageRegion :: Expr String
  , tags :: Expr (Array String)
  , teamId :: Expr String
  , totalSizeBytes :: Expr String
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra GradientaiCustomModel
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_custom_model" logicalName values
  pure
    { dataSource: handle
    , activeDeployments: dataSourceAttr handle [ "active_deployments" ]
    , architecture: dataSourceAttr handle [ "architecture" ]
    , contextLength: dataSourceAttr handle [ "context_length" ]
    , costEstimatePerMonth: dataSourceAttr handle [ "cost_estimate_per_month" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , description: dataSourceAttr handle [ "description" ]
    , errorMessage: dataSourceAttr handle [ "error_message" ]
    , fileCount: dataSourceAttr handle [ "file_count" ]
    , id: dataSourceAttr handle [ "id" ]
    , inputModalities: dataSourceAttr handle [ "input_modalities" ]
    , license: dataSourceAttr handle [ "license" ]
    , name: dataSourceAttr handle [ "name" ]
    , outputModalities: dataSourceAttr handle [ "output_modalities" ]
    , parameters: dataSourceAttr handle [ "parameters" ]
    , sourceRef: dataSourceAttr handle [ "source_ref" ]
    , sourceType: dataSourceAttr handle [ "source_type" ]
    , status: dataSourceAttr handle [ "status" ]
    , storageRegion: dataSourceAttr handle [ "storage_region" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , teamId: dataSourceAttr handle [ "team_id" ]
    , totalSizeBytes: dataSourceAttr handle [ "total_size_bytes" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
