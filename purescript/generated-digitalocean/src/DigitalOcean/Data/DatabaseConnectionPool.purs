module DigitalOcean.Data.DatabaseConnectionPool
  ( Args
  , Required
  , DatabaseConnectionPool
  , DatabaseConnectionPoolDataSource
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

data DatabaseConnectionPoolDataSource

type Required =
  { clusterId :: Input String
  , name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type DatabaseConnectionPool =
  { dataSource :: DataSource DatabaseConnectionPoolDataSource
  , clusterId :: Expr String
  , dbName :: Expr String
  , host :: Expr String
  , id :: Expr String
  , mode :: Expr String
  , name :: Expr String
  , password :: Expr String
  , port :: Expr Number
  , privateHost :: Expr String
  , privateUri :: Expr String
  , size :: Expr Number
  , uri :: Expr String
  , user :: Expr String
  }

read :: String -> Args -> Infra DatabaseConnectionPool
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_database_connection_pool" logicalName values
  pure
    { dataSource: handle
    , clusterId: dataSourceAttr handle [ "cluster_id" ]
    , dbName: dataSourceAttr handle [ "db_name" ]
    , host: dataSourceAttr handle [ "host" ]
    , id: dataSourceAttr handle [ "id" ]
    , mode: dataSourceAttr handle [ "mode" ]
    , name: dataSourceAttr handle [ "name" ]
    , password: dataSourceAttr handle [ "password" ]
    , port: dataSourceAttr handle [ "port" ]
    , privateHost: dataSourceAttr handle [ "private_host" ]
    , privateUri: dataSourceAttr handle [ "private_uri" ]
    , size: dataSourceAttr handle [ "size" ]
    , uri: dataSourceAttr handle [ "uri" ]
    , user: dataSourceAttr handle [ "user" ]
    }
