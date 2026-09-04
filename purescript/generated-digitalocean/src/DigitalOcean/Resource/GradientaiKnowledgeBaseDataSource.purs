module DigitalOcean.Resource.GradientaiKnowledgeBaseDataSource
  ( Args
  , Required
  , GradientaiKnowledgeBaseDataSource
  , GradientaiKnowledgeBaseDataSourceResource
  , args
  , create
  , id
  , spacesDataSource
  , webCrawlerDataSource
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data GradientaiKnowledgeBaseDataSourceResource

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

spacesDataSource :: Input (Array ({ bucketName :: String, itemPath :: String, region :: String })) -> Args -> Args
spacesDataSource value (Args values) = Args (Object.insert "spaces_data_source" (inputJson value) values)

webCrawlerDataSource :: Input (Array ({ baseUrl :: String, crawlingOption :: String, embedMedia :: Boolean })) -> Args -> Args
webCrawlerDataSource value (Args values) = Args (Object.insert "web_crawler_data_source" (inputJson value) values)

type GradientaiKnowledgeBaseDataSource =
  { resource :: Resource GradientaiKnowledgeBaseDataSourceResource
  , id :: Expr String
  , knowledgeBaseUuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiKnowledgeBaseDataSource
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_knowledge_base_data_source" logicalName values
  pure
    { resource: handle
    , id: resourceAttr handle [ "id" ]
    , knowledgeBaseUuid: resourceAttr handle [ "knowledge_base_uuid" ]
    }
