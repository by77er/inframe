module DigitalOcean.Resource.GradientaiKnowledgeBase
  ( Args
  , Required
  , GradientaiKnowledgeBase
  , GradientaiKnowledgeBaseResource
  , args
  , create
  , addedToAgentAt
  , databaseId
  , id
  , isPublic
  , lastIndexingJob
  , tags
  , vpcUuid
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data GradientaiKnowledgeBaseResource

type Required =
  { datasources :: Input (Array ({ createdAt :: String, fileUploadDataSource :: Array ({ originalFileName :: String, sizeInBytes :: String, storedObjectKey :: String }), lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), spacesDataSource :: Array ({ bucketName :: String, itemPath :: String, region :: String }), updatedAt :: String, uuid :: String, webCrawlerDataSource :: Array ({ baseUrl :: String, crawlingOption :: String, embedMedia :: Boolean }) }))
  , embeddingModelUuid :: Input String
  , name :: Input String
  , projectId :: Input String
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "datasources" (inputJson required.datasources)
  , Tuple "embedding_model_uuid" (inputJson required.embeddingModelUuid)
  , Tuple "name" (inputJson required.name)
  , Tuple "project_id" (inputJson required.projectId)
  , Tuple "region" (inputJson required.region)
  ])

addedToAgentAt :: Input String -> Args -> Args
addedToAgentAt value (Args values) = Args (Object.insert "added_to_agent_at" (inputJson value) values)

databaseId :: Input String -> Args -> Args
databaseId value (Args values) = Args (Object.insert "database_id" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

isPublic :: Input Boolean -> Args -> Args
isPublic value (Args values) = Args (Object.insert "is_public" (inputJson value) values)

lastIndexingJob :: Input (Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String })) -> Args -> Args
lastIndexingJob value (Args values) = Args (Object.insert "last_indexing_job" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (Object.insert "vpc_uuid" (inputJson value) values)

type GradientaiKnowledgeBase =
  { resource :: Resource GradientaiKnowledgeBaseResource
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
  , vpcUuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiKnowledgeBase
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_knowledge_base" logicalName values
  pure
    { resource: handle
    , addedToAgentAt: resourceAttr handle [ "added_to_agent_at" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , databaseId: resourceAttr handle [ "database_id" ]
    , embeddingModelUuid: resourceAttr handle [ "embedding_model_uuid" ]
    , id: resourceAttr handle [ "id" ]
    , isPublic: resourceAttr handle [ "is_public" ]
    , name: resourceAttr handle [ "name" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , region: resourceAttr handle [ "region" ]
    , tags: resourceAttr handle [ "tags" ]
    , vpcUuid: resourceAttr handle [ "vpc_uuid" ]
    }
