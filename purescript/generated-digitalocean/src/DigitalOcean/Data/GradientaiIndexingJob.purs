module DigitalOcean.Data.GradientaiIndexingJob
  ( Args
  , Required
  , GradientaiIndexingJob
  , GradientaiIndexingJobDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data GradientaiIndexingJobDataSource

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

type GradientaiIndexingJob =
  { dataSource :: DataSource GradientaiIndexingJobDataSource
  , completedDatasources :: Expr Number
  , createdAt :: Expr String
  , dataSourceUuids :: Expr (Array String)
  , finishedAt :: Expr String
  , id :: Expr String
  , knowledgeBaseUuid :: Expr String
  , phase :: Expr String
  , startedAt :: Expr String
  , status :: Expr String
  , tokens :: Expr Number
  , totalDatasources :: Expr Number
  , totalItemsFailed :: Expr String
  , totalItemsIndexed :: Expr String
  , totalItemsSkipped :: Expr String
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra GradientaiIndexingJob
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_indexing_job" logicalName values
  pure
    { dataSource: handle
    , completedDatasources: dataSourceAttr handle [ "completed_datasources" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , dataSourceUuids: dataSourceAttr handle [ "data_source_uuids" ]
    , finishedAt: dataSourceAttr handle [ "finished_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , knowledgeBaseUuid: dataSourceAttr handle [ "knowledge_base_uuid" ]
    , phase: dataSourceAttr handle [ "phase" ]
    , startedAt: dataSourceAttr handle [ "started_at" ]
    , status: dataSourceAttr handle [ "status" ]
    , tokens: dataSourceAttr handle [ "tokens" ]
    , totalDatasources: dataSourceAttr handle [ "total_datasources" ]
    , totalItemsFailed: dataSourceAttr handle [ "total_items_failed" ]
    , totalItemsIndexed: dataSourceAttr handle [ "total_items_indexed" ]
    , totalItemsSkipped: dataSourceAttr handle [ "total_items_skipped" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
