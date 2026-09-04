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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DatabaseCaDataSource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
