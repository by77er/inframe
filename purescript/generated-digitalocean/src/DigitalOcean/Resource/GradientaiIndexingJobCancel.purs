module DigitalOcean.Resource.GradientaiIndexingJobCancel
  ( Args
  , Required
  , GradientaiIndexingJobCancel
  , GradientaiIndexingJobCancelResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data GradientaiIndexingJobCancelResource

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

type GradientaiIndexingJobCancel =
  { resource :: Resource GradientaiIndexingJobCancelResource
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
  , totalItemsFailed :: Expr Number
  , totalItemsIndexed :: Expr Number
  , totalItemsSkipped :: Expr Number
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiIndexingJobCancel
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_indexing_job_cancel" logicalName values
  pure
    { resource: handle
    , completedDatasources: resourceAttr handle [ "completed_datasources" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , dataSourceUuids: resourceAttr handle [ "data_source_uuids" ]
    , finishedAt: resourceAttr handle [ "finished_at" ]
    , id: resourceAttr handle [ "id" ]
    , knowledgeBaseUuid: resourceAttr handle [ "knowledge_base_uuid" ]
    , phase: resourceAttr handle [ "phase" ]
    , startedAt: resourceAttr handle [ "started_at" ]
    , status: resourceAttr handle [ "status" ]
    , tokens: resourceAttr handle [ "tokens" ]
    , totalDatasources: resourceAttr handle [ "total_datasources" ]
    , totalItemsFailed: resourceAttr handle [ "total_items_failed" ]
    , totalItemsIndexed: resourceAttr handle [ "total_items_indexed" ]
    , totalItemsSkipped: resourceAttr handle [ "total_items_skipped" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
