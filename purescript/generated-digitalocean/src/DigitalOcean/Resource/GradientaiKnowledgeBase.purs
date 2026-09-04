module DigitalOcean.Resource.GradientaiKnowledgeBase
  ( Args
  , Required
  , GradientaiKnowledgeBase
  , GradientaiKnowledgeBaseResource
  , args
  , create
  , Datasources
  , DatasourcesRequired
  , datasourcesArgs
  , datasourcesFileUploadDataSource
  , datasourcesLastIndexingJob
  , datasourcesSpacesDataSource
  , datasourcesUuid
  , datasourcesWebCrawlerDataSource
  , DatasourcesFileUploadDataSource
  , DatasourcesFileUploadDataSourceRequired
  , datasourcesFileUploadDataSourceArgs
  , datasourcesFileUploadDataSourceOriginalFileName
  , datasourcesFileUploadDataSourceSizeInBytes
  , datasourcesFileUploadDataSourceStoredObjectKey
  , DatasourcesLastIndexingJob
  , DatasourcesLastIndexingJobRequired
  , datasourcesLastIndexingJobArgs
  , datasourcesLastIndexingJobCompletedDatasources
  , datasourcesLastIndexingJobDataSourceUuids
  , datasourcesLastIndexingJobPhase
  , datasourcesLastIndexingJobTokens
  , datasourcesLastIndexingJobTotalDatasources
  , datasourcesLastIndexingJobUuid
  , DatasourcesSpacesDataSource
  , DatasourcesSpacesDataSourceRequired
  , datasourcesSpacesDataSourceArgs
  , datasourcesSpacesDataSourceBucketName
  , datasourcesSpacesDataSourceItemPath
  , datasourcesSpacesDataSourceRegion
  , DatasourcesWebCrawlerDataSource
  , DatasourcesWebCrawlerDataSourceRequired
  , datasourcesWebCrawlerDataSourceArgs
  , datasourcesWebCrawlerDataSourceBaseUrl
  , datasourcesWebCrawlerDataSourceCrawlingOption
  , datasourcesWebCrawlerDataSourceEmbedMedia
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
  , id
  , isPublic
  , lastIndexingJob
  , tags
  , vpcUuid
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data GradientaiKnowledgeBaseResource

newtype Datasources = Datasources InputObject

type DatasourcesRequired =
  {
  }

datasourcesArgs :: DatasourcesRequired -> Datasources
datasourcesArgs _ = Datasources (inputObject
  [
  ])

datasourcesFileUploadDataSource :: Array DatasourcesFileUploadDataSource -> Datasources -> Datasources
datasourcesFileUploadDataSource value (Datasources values) = Datasources (insertInputField "file_upload_data_source" (arrayExprJson (map datasourcesFileUploadDataSourceJson value)) values)

datasourcesLastIndexingJob :: Array DatasourcesLastIndexingJob -> Datasources -> Datasources
datasourcesLastIndexingJob value (Datasources values) = Datasources (insertInputField "last_indexing_job" (arrayExprJson (map datasourcesLastIndexingJobJson value)) values)

datasourcesSpacesDataSource :: Array DatasourcesSpacesDataSource -> Datasources -> Datasources
datasourcesSpacesDataSource value (Datasources values) = Datasources (insertInputField "spaces_data_source" (arrayExprJson (map datasourcesSpacesDataSourceJson value)) values)

datasourcesUuid :: Input String -> Datasources -> Datasources
datasourcesUuid value (Datasources values) = Datasources (insertInputField "uuid" (inputJson value) values)

datasourcesWebCrawlerDataSource :: Array DatasourcesWebCrawlerDataSource -> Datasources -> Datasources
datasourcesWebCrawlerDataSource value (Datasources values) = Datasources (insertInputField "web_crawler_data_source" (arrayExprJson (map datasourcesWebCrawlerDataSourceJson value)) values)

datasourcesJson :: Datasources -> Json
datasourcesJson (Datasources values) = inputObjectJson values

newtype DatasourcesFileUploadDataSource = DatasourcesFileUploadDataSource InputObject

type DatasourcesFileUploadDataSourceRequired =
  {
  }

datasourcesFileUploadDataSourceArgs :: DatasourcesFileUploadDataSourceRequired -> DatasourcesFileUploadDataSource
datasourcesFileUploadDataSourceArgs _ = DatasourcesFileUploadDataSource (inputObject
  [
  ])

datasourcesFileUploadDataSourceOriginalFileName :: Input String -> DatasourcesFileUploadDataSource -> DatasourcesFileUploadDataSource
datasourcesFileUploadDataSourceOriginalFileName value (DatasourcesFileUploadDataSource values) = DatasourcesFileUploadDataSource (insertInputField "original_file_name" (inputJson value) values)

datasourcesFileUploadDataSourceSizeInBytes :: Input String -> DatasourcesFileUploadDataSource -> DatasourcesFileUploadDataSource
datasourcesFileUploadDataSourceSizeInBytes value (DatasourcesFileUploadDataSource values) = DatasourcesFileUploadDataSource (insertInputField "size_in_bytes" (inputJson value) values)

datasourcesFileUploadDataSourceStoredObjectKey :: Input String -> DatasourcesFileUploadDataSource -> DatasourcesFileUploadDataSource
datasourcesFileUploadDataSourceStoredObjectKey value (DatasourcesFileUploadDataSource values) = DatasourcesFileUploadDataSource (insertInputField "stored_object_key" (inputJson value) values)

datasourcesFileUploadDataSourceJson :: DatasourcesFileUploadDataSource -> Json
datasourcesFileUploadDataSourceJson (DatasourcesFileUploadDataSource values) = inputObjectJson values

newtype DatasourcesLastIndexingJob = DatasourcesLastIndexingJob InputObject

type DatasourcesLastIndexingJobRequired =
  {
  }

datasourcesLastIndexingJobArgs :: DatasourcesLastIndexingJobRequired -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobArgs _ = DatasourcesLastIndexingJob (inputObject
  [
  ])

datasourcesLastIndexingJobCompletedDatasources :: Input Number -> DatasourcesLastIndexingJob -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobCompletedDatasources value (DatasourcesLastIndexingJob values) = DatasourcesLastIndexingJob (insertInputField "completed_datasources" (inputJson value) values)

datasourcesLastIndexingJobDataSourceUuids :: Input (Array String) -> DatasourcesLastIndexingJob -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobDataSourceUuids value (DatasourcesLastIndexingJob values) = DatasourcesLastIndexingJob (insertInputField "data_source_uuids" (inputJson value) values)

datasourcesLastIndexingJobPhase :: Input String -> DatasourcesLastIndexingJob -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobPhase value (DatasourcesLastIndexingJob values) = DatasourcesLastIndexingJob (insertInputField "phase" (inputJson value) values)

datasourcesLastIndexingJobTokens :: Input Number -> DatasourcesLastIndexingJob -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobTokens value (DatasourcesLastIndexingJob values) = DatasourcesLastIndexingJob (insertInputField "tokens" (inputJson value) values)

datasourcesLastIndexingJobTotalDatasources :: Input Number -> DatasourcesLastIndexingJob -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobTotalDatasources value (DatasourcesLastIndexingJob values) = DatasourcesLastIndexingJob (insertInputField "total_datasources" (inputJson value) values)

datasourcesLastIndexingJobUuid :: Input String -> DatasourcesLastIndexingJob -> DatasourcesLastIndexingJob
datasourcesLastIndexingJobUuid value (DatasourcesLastIndexingJob values) = DatasourcesLastIndexingJob (insertInputField "uuid" (inputJson value) values)

datasourcesLastIndexingJobJson :: DatasourcesLastIndexingJob -> Json
datasourcesLastIndexingJobJson (DatasourcesLastIndexingJob values) = inputObjectJson values

newtype DatasourcesSpacesDataSource = DatasourcesSpacesDataSource InputObject

type DatasourcesSpacesDataSourceRequired =
  {
  }

datasourcesSpacesDataSourceArgs :: DatasourcesSpacesDataSourceRequired -> DatasourcesSpacesDataSource
datasourcesSpacesDataSourceArgs _ = DatasourcesSpacesDataSource (inputObject
  [
  ])

datasourcesSpacesDataSourceBucketName :: Input String -> DatasourcesSpacesDataSource -> DatasourcesSpacesDataSource
datasourcesSpacesDataSourceBucketName value (DatasourcesSpacesDataSource values) = DatasourcesSpacesDataSource (insertInputField "bucket_name" (inputJson value) values)

datasourcesSpacesDataSourceItemPath :: Input String -> DatasourcesSpacesDataSource -> DatasourcesSpacesDataSource
datasourcesSpacesDataSourceItemPath value (DatasourcesSpacesDataSource values) = DatasourcesSpacesDataSource (insertInputField "item_path" (inputJson value) values)

datasourcesSpacesDataSourceRegion :: Input String -> DatasourcesSpacesDataSource -> DatasourcesSpacesDataSource
datasourcesSpacesDataSourceRegion value (DatasourcesSpacesDataSource values) = DatasourcesSpacesDataSource (insertInputField "region" (inputJson value) values)

datasourcesSpacesDataSourceJson :: DatasourcesSpacesDataSource -> Json
datasourcesSpacesDataSourceJson (DatasourcesSpacesDataSource values) = inputObjectJson values

newtype DatasourcesWebCrawlerDataSource = DatasourcesWebCrawlerDataSource InputObject

type DatasourcesWebCrawlerDataSourceRequired =
  {
  }

datasourcesWebCrawlerDataSourceArgs :: DatasourcesWebCrawlerDataSourceRequired -> DatasourcesWebCrawlerDataSource
datasourcesWebCrawlerDataSourceArgs _ = DatasourcesWebCrawlerDataSource (inputObject
  [
  ])

datasourcesWebCrawlerDataSourceBaseUrl :: Input String -> DatasourcesWebCrawlerDataSource -> DatasourcesWebCrawlerDataSource
datasourcesWebCrawlerDataSourceBaseUrl value (DatasourcesWebCrawlerDataSource values) = DatasourcesWebCrawlerDataSource (insertInputField "base_url" (inputJson value) values)

datasourcesWebCrawlerDataSourceCrawlingOption :: Input String -> DatasourcesWebCrawlerDataSource -> DatasourcesWebCrawlerDataSource
datasourcesWebCrawlerDataSourceCrawlingOption value (DatasourcesWebCrawlerDataSource values) = DatasourcesWebCrawlerDataSource (insertInputField "crawling_option" (inputJson value) values)

datasourcesWebCrawlerDataSourceEmbedMedia :: Input Boolean -> DatasourcesWebCrawlerDataSource -> DatasourcesWebCrawlerDataSource
datasourcesWebCrawlerDataSourceEmbedMedia value (DatasourcesWebCrawlerDataSource values) = DatasourcesWebCrawlerDataSource (insertInputField "embed_media" (inputJson value) values)

datasourcesWebCrawlerDataSourceJson :: DatasourcesWebCrawlerDataSource -> Json
datasourcesWebCrawlerDataSourceJson (DatasourcesWebCrawlerDataSource values) = inputObjectJson values

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
  { datasources :: Array Datasources
  , embeddingModelUuid :: Input String
  , name :: Input String
  , projectId :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "datasources" (arrayExprJson (map datasourcesJson required.datasources))
  , Tuple "embedding_model_uuid" (inputJson required.embeddingModelUuid)
  , Tuple "name" (inputJson required.name)
  , Tuple "project_id" (inputJson required.projectId)
  , Tuple "region" (inputJson required.region)
  ])

addedToAgentAt :: Input String -> Args -> Args
addedToAgentAt value (Args values) = Args (insertInputField "added_to_agent_at" (inputJson value) values)

databaseId :: Input String -> Args -> Args
databaseId value (Args values) = Args (insertInputField "database_id" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

isPublic :: Input Boolean -> Args -> Args
isPublic value (Args values) = Args (insertInputField "is_public" (inputJson value) values)

lastIndexingJob :: Array LastIndexingJob -> Args -> Args
lastIndexingJob value (Args values) = Args (insertInputField "last_indexing_job" (arrayExprJson (map lastIndexingJobJson value)) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (insertInputField "vpc_uuid" (inputJson value) values)

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
