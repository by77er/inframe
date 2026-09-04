module DigitalOcean.Data.DatabaseMetricsCredentials
  ( Args
  , Required
  , DatabaseMetricsCredentials
  , DatabaseMetricsCredentialsDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DatabaseMetricsCredentialsDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type DatabaseMetricsCredentials =
  { dataSource :: DataSource DatabaseMetricsCredentialsDataSource
  , id :: Expr String
  , password :: Expr String
  , username :: Expr String
  }

read :: String -> Args -> Infra DatabaseMetricsCredentials
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_database_metrics_credentials" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , password: dataSourceAttr handle [ "password" ]
    , username: dataSourceAttr handle [ "username" ]
    }
