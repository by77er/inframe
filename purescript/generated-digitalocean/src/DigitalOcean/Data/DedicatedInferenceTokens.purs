module DigitalOcean.Data.DedicatedInferenceTokens
  ( Args
  , Required
  , DedicatedInferenceTokens
  , DedicatedInferenceTokensDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DedicatedInferenceTokensDataSource

type Required =
  { dedicatedInferenceId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "dedicated_inference_id" (inputJson required.dedicatedInferenceId)
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type DedicatedInferenceTokens =
  { dataSource :: DataSource DedicatedInferenceTokensDataSource
  , dedicatedInferenceId :: Expr String
  , id :: Expr String
  , tokens :: Expr (Array ({ createdAt :: String, id :: String, name :: String }))
  }

read :: String -> Args -> Infra DedicatedInferenceTokens
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_dedicated_inference_tokens" logicalName values
  pure
    { dataSource: handle
    , dedicatedInferenceId: dataSourceAttr handle [ "dedicated_inference_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , tokens: dataSourceAttr handle [ "tokens" ]
    }
