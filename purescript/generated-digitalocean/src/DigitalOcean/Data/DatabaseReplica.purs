module DigitalOcean.Data.DatabaseReplica
  ( Args
  , Required
  , DatabaseReplica
  , DatabaseReplicaDataSource
  , args
  , read
  , id
  , tags
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DatabaseReplicaDataSource

type Required =
  { clusterId :: Input String
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

type DatabaseReplica =
  { dataSource :: DataSource DatabaseReplicaDataSource
  , clusterId :: Expr String
  , database :: Expr String
  , host :: Expr String
  , id :: Expr String
  , name :: Expr String
  , password :: Expr String
  , port :: Expr Number
  , privateHost :: Expr String
  , privateNetworkUuid :: Expr String
  , privateUri :: Expr String
  , region :: Expr String
  , storageSizeMib :: Expr String
  , tags :: Expr (Array String)
  , uri :: Expr String
  , user :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra DatabaseReplica
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_database_replica" logicalName values
  pure
    { dataSource: handle
    , clusterId: dataSourceAttr handle [ "cluster_id" ]
    , database: dataSourceAttr handle [ "database" ]
    , host: dataSourceAttr handle [ "host" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , password: dataSourceAttr handle [ "password" ]
    , port: dataSourceAttr handle [ "port" ]
    , privateHost: dataSourceAttr handle [ "private_host" ]
    , privateNetworkUuid: dataSourceAttr handle [ "private_network_uuid" ]
    , privateUri: dataSourceAttr handle [ "private_uri" ]
    , region: dataSourceAttr handle [ "region" ]
    , storageSizeMib: dataSourceAttr handle [ "storage_size_mib" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , uri: dataSourceAttr handle [ "uri" ]
    , user: dataSourceAttr handle [ "user" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
