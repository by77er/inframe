module DigitalOcean.Data.GradientaiKnowledgeBase
  ( Args
  , Required
  , GradientaiKnowledgeBase
  , GradientaiKnowledgeBaseDataSource
  , args
  , read
  , LastIndexingJob
  , LastIndexingJobRequired
  , lastIndexingJobArgs
  , lastIndexingJobCompletedDatasources
  , lastIndexingJobDataSourceUuids
  , lastIndexingJobPhase
  , lastIndexingJobTokens
  , lastIndexingJobTotalDatasources
  , lastIndexingJobUuid
  , addedToAgentAt
  , databaseId
  , embeddingModelUuid
  , id
  , isPublic
  , lastIndexingJob
  , name
  , projectId
  , region
  , tags
  , userId
  , uuid
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data GradientaiKnowledgeBaseDataSource

newtype LastIndexingJob = LastIndexingJob InputObject

type LastIndexingJobRequired =
  {
  }

lastIndexingJobArgs :: LastIndexingJobRequired -> LastIndexingJob
lastIndexingJobArgs _ = LastIndexingJob (inputObject
  [
  ])

lastIndexingJobCompletedDatasources :: Input Number -> LastIndexingJob -> LastIndexingJob
lastIndexingJobCompletedDatasources value (LastIndexingJob values) = LastIndexingJob (insertInputField "completed_datasources" (inputJson value) values)

lastIndexingJobDataSourceUuids :: Input (Array String) -> LastIndexingJob -> LastIndexingJob
lastIndexingJobDataSourceUuids value (LastIndexingJob values) = LastIndexingJob (insertInputField "data_source_uuids" (inputJson value) values)

lastIndexingJobPhase :: Input String -> LastIndexingJob -> LastIndexingJob
lastIndexingJobPhase value (LastIndexingJob values) = LastIndexingJob (insertInputField "phase" (inputJson value) values)

lastIndexingJobTokens :: Input Number -> LastIndexingJob -> LastIndexingJob
lastIndexingJobTokens value (LastIndexingJob values) = LastIndexingJob (insertInputField "tokens" (inputJson value) values)

lastIndexingJobTotalDatasources :: Input Number -> LastIndexingJob -> LastIndexingJob
lastIndexingJobTotalDatasources value (LastIndexingJob values) = LastIndexingJob (insertInputField "total_datasources" (inputJson value) values)

lastIndexingJobUuid :: Input String -> LastIndexingJob -> LastIndexingJob
lastIndexingJobUuid value (LastIndexingJob values) = LastIndexingJob (insertInputField "uuid" (inputJson value) values)

lastIndexingJobJson :: LastIndexingJob -> Json
lastIndexingJobJson (LastIndexingJob values) = inputObjectJson values

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

addedToAgentAt :: Input String -> Args -> Args
addedToAgentAt value (Args values) = Args (insertInputField "added_to_agent_at" (inputJson value) values)

databaseId :: Input String -> Args -> Args
databaseId value (Args values) = Args (insertInputField "database_id" (inputJson value) values)

embeddingModelUuid :: Input String -> Args -> Args
embeddingModelUuid value (Args values) = Args (insertInputField "embedding_model_uuid" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

isPublic :: Input Boolean -> Args -> Args
isPublic value (Args values) = Args (insertInputField "is_public" (inputJson value) values)

lastIndexingJob :: Array LastIndexingJob -> Args -> Args
lastIndexingJob value (Args values) = Args (insertInputField "last_indexing_job" (arrayExprJson (map lastIndexingJobJson value)) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (insertInputField "name" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (insertInputField "project_id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

userId :: Input String -> Args -> Args
userId value (Args values) = Args (insertInputField "user_id" (inputJson value) values)

uuid :: Input String -> Args -> Args
uuid value (Args values) = Args (insertInputField "uuid" (inputJson value) values)

type GradientaiKnowledgeBase =
  { dataSource :: DataSource GradientaiKnowledgeBaseDataSource
  , addedToAgentAt :: Expr String
  , createdAt :: Expr String
  , databaseId :: Expr String
  , embeddingModelUuid :: Expr String
  , id :: Expr String
  , isPublic :: Expr Boolean
  , name :: Expr String
  , projectId :: Expr String
  , region :: Expr String
  , tags :: Expr (Array String)
  , updatedAt :: Expr String
  , userId :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra GradientaiKnowledgeBase
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_knowledge_base" logicalName values
  pure
    { dataSource: handle
    , addedToAgentAt: dataSourceAttr handle [ "added_to_agent_at" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , databaseId: dataSourceAttr handle [ "database_id" ]
    , embeddingModelUuid: dataSourceAttr handle [ "embedding_model_uuid" ]
    , id: dataSourceAttr handle [ "id" ]
    , isPublic: dataSourceAttr handle [ "is_public" ]
    , name: dataSourceAttr handle [ "name" ]
    , projectId: dataSourceAttr handle [ "project_id" ]
    , region: dataSourceAttr handle [ "region" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , userId: dataSourceAttr handle [ "user_id" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
