module DigitalOcean.Data.GradientaiKnowledgeBases
  ( Args
  , Required
  , GradientaiKnowledgeBases
  , GradientaiKnowledgeBasesDataSource
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

data GradientaiKnowledgeBasesDataSource

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

type GradientaiKnowledgeBases =
  { dataSource :: DataSource GradientaiKnowledgeBasesDataSource
  , id :: Expr String
  , knowledgeBases :: Expr (Array ({ addedToAgentAt :: String, createdAt :: String, databaseId :: String, embeddingModelUuid :: String, isPublic :: Boolean, lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), name :: String, projectId :: String, region :: String, tags :: Array String, updatedAt :: String, userId :: String, uuid :: String }))
  }

read :: String -> Args -> Infra GradientaiKnowledgeBases
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_knowledge_bases" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , knowledgeBases: dataSourceAttr handle [ "knowledge_bases" ]
    }
