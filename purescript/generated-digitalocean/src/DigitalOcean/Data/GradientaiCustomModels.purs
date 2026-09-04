module DigitalOcean.Data.GradientaiCustomModels
  ( Args
  , Required
  , GradientaiCustomModels
  , GradientaiCustomModelsDataSource
  , args
  , read
  , Filter
  , FilterRequired
  , filterArgs
  , filterAll
  , filterMatchBy
  , Sort
  , SortRequired
  , sortArgs
  , sortDirection
  , filter
  , id
  , sort
  , status
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data GradientaiCustomModelsDataSource

newtype Filter = Filter InputObject

type FilterRequired =
  { key :: Input String
  , values :: Input (Array String)
  }

filterArgs :: FilterRequired -> Filter
filterArgs required = Filter (inputObject
  [ Tuple "key" (inputJson required.key)
  , Tuple "values" (inputJson required.values)
  ])

filterAll :: Input Boolean -> Filter -> Filter
filterAll value (Filter values) = Filter (insertInputField "all" (inputJson value) values)

filterMatchBy :: Input String -> Filter -> Filter
filterMatchBy value (Filter values) = Filter (insertInputField "match_by" (inputJson value) values)

filterJson :: Filter -> Json
filterJson (Filter values) = inputObjectJson values

newtype Sort = Sort InputObject

type SortRequired =
  { key :: Input String
  }

sortArgs :: SortRequired -> Sort
sortArgs required = Sort (inputObject
  [ Tuple "key" (inputJson required.key)
  ])

sortDirection :: Input String -> Sort -> Sort
sortDirection value (Sort values) = Sort (insertInputField "direction" (inputJson value) values)

sortJson :: Sort -> Json
sortJson (Sort values) = inputObjectJson values

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

filter :: Array Filter -> Args -> Args
filter value (Args values) = Args (insertInputField "filter" (arrayExprJson (map filterJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

sort :: Array Sort -> Args -> Args
sort value (Args values) = Args (insertInputField "sort" (arrayExprJson (map sortJson value)) values)

status :: Input String -> Args -> Args
status value (Args values) = Args (insertInputField "status" (inputJson value) values)

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
