module DigitalOcean.Data.DatabaseCa
  ( Args
  , Required
  , DatabaseCa
  , DatabaseCaDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DatabaseCaDataSource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type DatabaseCa =
  { dataSource :: DataSource DatabaseCaDataSource
  , certificate :: Expr String
  , clusterId :: Expr String
  , id :: Expr String
  }

read :: String -> Args -> Infra DatabaseCa
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_database_ca" logicalName values
  pure
    { dataSource: handle
    , certificate: dataSourceAttr handle [ "certificate" ]
    , clusterId: dataSourceAttr handle [ "cluster_id" ]
    , id: dataSourceAttr handle [ "id" ]
    }
