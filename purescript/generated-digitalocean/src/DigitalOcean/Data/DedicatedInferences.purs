module DigitalOcean.Data.DedicatedInferences
  ( Args
  , Required
  , DedicatedInferences
  , DedicatedInferencesDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DedicatedInferencesDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type DedicatedInferences =
  { dataSource :: DataSource DedicatedInferencesDataSource
  , dedicatedInferences :: Expr (Array ({ createdAt :: String, id :: String, name :: String, privateEndpointFqdn :: String, providerModelId :: Array String, publicEndpointFqdn :: String, region :: String, status :: String, updatedAt :: String, vpcUuid :: String }))
  , id :: Expr String
  }

read :: String -> Args -> Infra DedicatedInferences
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_dedicated_inferences" logicalName values
  pure
    { dataSource: handle
    , dedicatedInferences: dataSourceAttr handle [ "dedicated_inferences" ]
    , id: dataSourceAttr handle [ "id" ]
    }
