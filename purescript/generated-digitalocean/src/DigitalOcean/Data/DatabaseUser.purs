module DigitalOcean.Data.DatabaseUser
  ( Args
  , Required
  , DatabaseUser
  , DatabaseUserDataSource
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

data DatabaseUserDataSource

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

type DatabaseUser =
  { dataSource :: DataSource DatabaseUserDataSource
  , accessCert :: Expr String
  , accessKey :: Expr String
  , clusterId :: Expr String
  , id :: Expr String
  , mysqlAuthPlugin :: Expr String
  , name :: Expr String
  , password :: Expr String
  , role_ :: Expr String
  , settings :: Expr (Array ({ acl :: Array ({ id :: String, permission :: String, topic :: String }), opensearchAcl :: Array ({ index :: String, permission :: String }) }))
  }

read :: String -> Args -> Infra DatabaseUser
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_database_user" logicalName values
  pure
    { dataSource: handle
    , accessCert: dataSourceAttr handle [ "access_cert" ]
    , accessKey: dataSourceAttr handle [ "access_key" ]
    , clusterId: dataSourceAttr handle [ "cluster_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , mysqlAuthPlugin: dataSourceAttr handle [ "mysql_auth_plugin" ]
    , name: dataSourceAttr handle [ "name" ]
    , password: dataSourceAttr handle [ "password" ]
    , role_: dataSourceAttr handle [ "role" ]
    , settings: dataSourceAttr handle [ "settings" ]
    }
