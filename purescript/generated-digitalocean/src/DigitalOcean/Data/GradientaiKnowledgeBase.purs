module DigitalOcean.Data.GradientaiKnowledgeBase
  ( Args
  , Required
  , GradientaiKnowledgeBase
  , GradientaiKnowledgeBaseDataSource
  , args
  , read
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

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data GradientaiKnowledgeBaseDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

addedToAgentAt :: Input String -> Args -> Args
addedToAgentAt value (Args values) = Args (Object.insert "added_to_agent_at" (inputJson value) values)

databaseId :: Input String -> Args -> Args
databaseId value (Args values) = Args (Object.insert "database_id" (inputJson value) values)

embeddingModelUuid :: Input String -> Args -> Args
embeddingModelUuid value (Args values) = Args (Object.insert "embedding_model_uuid" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

isPublic :: Input Boolean -> Args -> Args
isPublic value (Args values) = Args (Object.insert "is_public" (inputJson value) values)

lastIndexingJob :: Input (Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String })) -> Args -> Args
lastIndexingJob value (Args values) = Args (Object.insert "last_indexing_job" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (Object.insert "project_id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

userId :: Input String -> Args -> Args
userId value (Args values) = Args (Object.insert "user_id" (inputJson value) values)

uuid :: Input String -> Args -> Args
uuid value (Args values) = Args (Object.insert "uuid" (inputJson value) values)

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
