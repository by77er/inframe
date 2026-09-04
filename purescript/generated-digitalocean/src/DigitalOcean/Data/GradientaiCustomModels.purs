module DigitalOcean.Data.GradientaiCustomModels
  ( Args
  , Required
  , GradientaiCustomModels
  , GradientaiCustomModelsDataSource
  , args
  , read
  , filter
  , id
  , sort
  , status
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data GradientaiCustomModelsDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

status :: Input String -> Args -> Args
status value (Args values) = Args (Object.insert "status" (inputJson value) values)

type GradientaiCustomModels =
  { dataSource :: DataSource GradientaiCustomModelsDataSource
  , customModels :: Expr (Array ({ activeDeployments :: Array ({ createdAt :: String, endpoints :: Array ({ privateEndpointFqdn :: String, publicEndpointFqdn :: String }), id :: String, name :: String, regionSlug :: String, state :: String, updatedAt :: String }), architecture :: String, contextLength :: Number, costEstimatePerMonth :: Number, createdAt :: String, description :: String, errorMessage :: String, fileCount :: Number, inputModalities :: Array String, license :: String, name :: String, outputModalities :: Array String, parameters :: String, sourceRef :: Array ({ accessType :: String, bucket :: String, commitSha :: String, prefix :: String, region :: String, repoId :: String }), sourceType :: String, status :: String, storageRegion :: String, tags :: Array String, teamId :: String, totalSizeBytes :: String, updatedAt :: String, uuid :: String }))
  , id :: Expr String
  , status :: Expr String
  }

read :: String -> Args -> Infra GradientaiCustomModels
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_custom_models" logicalName values
  pure
    { dataSource: handle
    , customModels: dataSourceAttr handle [ "custom_models" ]
    , id: dataSourceAttr handle [ "id" ]
    , status: dataSourceAttr handle [ "status" ]
    }
