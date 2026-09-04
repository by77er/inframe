module DigitalOcean.Resource.GradientaiKnowledgeBaseDataSource
  ( Args
  , Required
  , GradientaiKnowledgeBaseDataSource
  , GradientaiKnowledgeBaseDataSourceResource
  , args
  , create
  , SpacesDataSource
  , SpacesDataSourceRequired
  , spacesDataSourceArgs
  , spacesDataSourceBucketName
  , spacesDataSourceItemPath
  , spacesDataSourceRegion
  , WebCrawlerDataSource
  , WebCrawlerDataSourceRequired
  , webCrawlerDataSourceArgs
  , webCrawlerDataSourceBaseUrl
  , webCrawlerDataSourceCrawlingOption
  , webCrawlerDataSourceEmbedMedia
  , id
  , spacesDataSource
  , webCrawlerDataSource
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data GradientaiKnowledgeBaseDataSourceResource

newtype SpacesDataSource = SpacesDataSource InputObject

type SpacesDataSourceRequired =
  {
  }

spacesDataSourceArgs :: SpacesDataSourceRequired -> SpacesDataSource
spacesDataSourceArgs _ = SpacesDataSource (inputObject
  [
  ])

spacesDataSourceBucketName :: Input String -> SpacesDataSource -> SpacesDataSource
spacesDataSourceBucketName value (SpacesDataSource values) = SpacesDataSource (insertInputField "bucket_name" (inputJson value) values)

spacesDataSourceItemPath :: Input String -> SpacesDataSource -> SpacesDataSource
spacesDataSourceItemPath value (SpacesDataSource values) = SpacesDataSource (insertInputField "item_path" (inputJson value) values)

spacesDataSourceRegion :: Input String -> SpacesDataSource -> SpacesDataSource
spacesDataSourceRegion value (SpacesDataSource values) = SpacesDataSource (insertInputField "region" (inputJson value) values)

spacesDataSourceJson :: SpacesDataSource -> Json
spacesDataSourceJson (SpacesDataSource values) = inputObjectJson values

newtype WebCrawlerDataSource = WebCrawlerDataSource InputObject

type WebCrawlerDataSourceRequired =
  {
  }

webCrawlerDataSourceArgs :: WebCrawlerDataSourceRequired -> WebCrawlerDataSource
webCrawlerDataSourceArgs _ = WebCrawlerDataSource (inputObject
  [
  ])

webCrawlerDataSourceBaseUrl :: Input String -> WebCrawlerDataSource -> WebCrawlerDataSource
webCrawlerDataSourceBaseUrl value (WebCrawlerDataSource values) = WebCrawlerDataSource (insertInputField "base_url" (inputJson value) values)

webCrawlerDataSourceCrawlingOption :: Input String -> WebCrawlerDataSource -> WebCrawlerDataSource
webCrawlerDataSourceCrawlingOption value (WebCrawlerDataSource values) = WebCrawlerDataSource (insertInputField "crawling_option" (inputJson value) values)

webCrawlerDataSourceEmbedMedia :: Input Boolean -> WebCrawlerDataSource -> WebCrawlerDataSource
webCrawlerDataSourceEmbedMedia value (WebCrawlerDataSource values) = WebCrawlerDataSource (insertInputField "embed_media" (inputJson value) values)

webCrawlerDataSourceJson :: WebCrawlerDataSource -> Json
webCrawlerDataSourceJson (WebCrawlerDataSource values) = inputObjectJson values

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

spacesDataSource :: Array SpacesDataSource -> Args -> Args
spacesDataSource value (Args values) = Args (insertInputField "spaces_data_source" (arrayExprJson (map spacesDataSourceJson value)) values)

webCrawlerDataSource :: Array WebCrawlerDataSource -> Args -> Args
webCrawlerDataSource value (Args values) = Args (insertInputField "web_crawler_data_source" (arrayExprJson (map webCrawlerDataSourceJson value)) values)

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
