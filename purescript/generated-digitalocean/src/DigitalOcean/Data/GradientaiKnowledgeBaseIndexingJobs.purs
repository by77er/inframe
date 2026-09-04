module DigitalOcean.Data.GradientaiKnowledgeBaseIndexingJobs
  ( Args
  , Required
  , GradientaiKnowledgeBaseIndexingJobs
  , GradientaiKnowledgeBaseIndexingJobsDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data GradientaiKnowledgeBaseIndexingJobsDataSource

type Required =
  { knowledgeBaseUuid :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "knowledge_base_uuid" (inputJson required.knowledgeBaseUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type GradientaiKnowledgeBaseIndexingJobs =
  { dataSource :: DataSource GradientaiKnowledgeBaseIndexingJobsDataSource
  , id :: Expr String
  , jobs :: Expr (Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, status :: String, tokens :: Number, totalDatasources :: Number, totalItemsFailed :: String, totalItemsIndexed :: String, totalItemsSkipped :: String, updatedAt :: String, uuid :: String }))
  , knowledgeBaseUuid :: Expr String
  , meta :: Expr (Array ({ page :: Number, pages :: Number, total :: Number }))
  }

read :: String -> Args -> Infra GradientaiKnowledgeBaseIndexingJobs
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_knowledge_base_indexing_jobs" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , jobs: dataSourceAttr handle [ "jobs" ]
    , knowledgeBaseUuid: dataSourceAttr handle [ "knowledge_base_uuid" ]
    , meta: dataSourceAttr handle [ "meta" ]
    }
