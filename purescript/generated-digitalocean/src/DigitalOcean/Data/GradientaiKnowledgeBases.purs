module DigitalOcean.Data.GradientaiKnowledgeBases
  ( Args
  , Required
  , GradientaiKnowledgeBases
  , GradientaiKnowledgeBasesDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data GradientaiKnowledgeBasesDataSource

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
