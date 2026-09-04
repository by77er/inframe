module DigitalOcean.Data.GradientaiIndexingJobDataSources
  ( Args
  , Required
  , GradientaiIndexingJobDataSources
  , GradientaiIndexingJobDataSourcesDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data GradientaiIndexingJobDataSourcesDataSource

type Required =
  { indexingJobUuid :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "indexing_job_uuid" (inputJson required.indexingJobUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type GradientaiIndexingJobDataSources =
  { dataSource :: DataSource GradientaiIndexingJobDataSourcesDataSource
  , id :: Expr String
  , indexedDataSources :: Expr (Array ({ completedAt :: String, dataSourceUuid :: String, errorDetails :: String, errorMsg :: String, failedItemCount :: String, indexedFileCount :: String, indexedItemCount :: String, removedItemCount :: String, skippedItemCount :: String, startedAt :: String, status :: String, totalBytes :: String, totalBytesIndexed :: String, totalFileCount :: String }))
  , indexingJobUuid :: Expr String
  }

read :: String -> Args -> Infra GradientaiIndexingJobDataSources
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_indexing_job_data_sources" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , indexedDataSources: dataSourceAttr handle [ "indexed_data_sources" ]
    , indexingJobUuid: dataSourceAttr handle [ "indexing_job_uuid" ]
    }
