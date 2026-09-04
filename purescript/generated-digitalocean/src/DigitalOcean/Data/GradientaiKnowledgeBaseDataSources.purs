module DigitalOcean.Data.GradientaiKnowledgeBaseDataSources
  ( Args
  , Required
  , GradientaiKnowledgeBaseDataSources
  , GradientaiKnowledgeBaseDataSourcesDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data GradientaiKnowledgeBaseDataSourcesDataSource

type Required =
  { knowledgeBaseUuid :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "knowledge_base_uuid" (inputJson required.knowledgeBaseUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type GradientaiKnowledgeBaseDataSources =
  { dataSource :: DataSource GradientaiKnowledgeBaseDataSourcesDataSource
  , datasources :: Expr (Array ({ createdAt :: String, fileUploadDataSource :: Array ({ originalFileName :: String, sizeInBytes :: String, storedObjectKey :: String }), lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), spacesDataSource :: Array ({ bucketName :: String, itemPath :: String, region :: String }), updatedAt :: String, uuid :: String, webCrawlerDataSource :: Array ({ baseUrl :: String, crawlingOption :: String, embedMedia :: Boolean }) }))
  , id :: Expr String
  , knowledgeBaseUuid :: Expr String
  }

read :: String -> Args -> Infra GradientaiKnowledgeBaseDataSources
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_knowledge_base_data_sources" logicalName values
  pure
    { dataSource: handle
    , datasources: dataSourceAttr handle [ "datasources" ]
    , id: dataSourceAttr handle [ "id" ]
    , knowledgeBaseUuid: dataSourceAttr handle [ "knowledge_base_uuid" ]
    }
