module DigitalOcean.Data.GradientaiModels
  ( Args
  , Required
  , GradientaiModels
  , GradientaiModelsDataSource
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
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data GradientaiModelsDataSource

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

type GradientaiModels =
  { dataSource :: DataSource GradientaiModelsDataSource
  , id :: Expr String
  , models :: Expr (Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, id :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, uuid :: String, version :: Array ({ major :: Number, minor :: Number, patch :: Number }) }))
  }

read :: String -> Args -> Infra GradientaiModels
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_models" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , models: dataSourceAttr handle [ "models" ]
    }
