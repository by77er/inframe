module DigitalOcean.Data.DedicatedInferenceTokens
  ( Args
  , Required
  , DedicatedInferenceTokens
  , DedicatedInferenceTokensDataSource
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

data DedicatedInferenceTokensDataSource

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
  { dedicatedInferenceId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "dedicated_inference_id" (inputJson required.dedicatedInferenceId)
  ])

filter :: Array Filter -> Args -> Args
filter value (Args values) = Args (insertInputField "filter" (arrayExprJson (map filterJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

sort :: Array Sort -> Args -> Args
sort value (Args values) = Args (insertInputField "sort" (arrayExprJson (map sortJson value)) values)

type DedicatedInferenceTokens =
  { dataSource :: DataSource DedicatedInferenceTokensDataSource
  , dedicatedInferenceId :: Expr String
  , id :: Expr String
  , tokens :: Expr (Array ({ createdAt :: String, id :: String, name :: String }))
  }

read :: String -> Args -> Infra DedicatedInferenceTokens
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_dedicated_inference_tokens" logicalName values
  pure
    { dataSource: handle
    , dedicatedInferenceId: dataSourceAttr handle [ "dedicated_inference_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , tokens: dataSourceAttr handle [ "tokens" ]
    }
