module DigitalOcean.Data.DatabaseCluster
  ( Args
  , Required
  , DatabaseCluster
  , DatabaseClusterDataSource
  , args
  , read
  , id
  , tags
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DatabaseClusterDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

type DatabaseCluster =
  { dataSource :: DataSource DatabaseClusterDataSource
  , database :: Expr String
  , engine :: Expr String
  , host :: Expr String
  , id :: Expr String
  , maintenanceWindow :: Expr (Array ({ day :: String, hour :: String }))
  , metricsEndpoints :: Expr (Array String)
  , name :: Expr String
  , nodeCount :: Expr Number
  , password :: Expr String
  , port :: Expr Number
  , privateHost :: Expr String
  , privateNetworkUuid :: Expr String
  , privateUri :: Expr String
  , projectId :: Expr String
  , region :: Expr String
  , size :: Expr String
  , storageAutoscale :: Expr (Array ({ enabled :: Boolean, incrementGib :: Number, thresholdPercent :: Number }))
  , storageSizeMib :: Expr String
  , tags :: Expr (Array String)
  , uiDatabase :: Expr String
  , uiHost :: Expr String
  , uiPassword :: Expr String
  , uiPort :: Expr Number
  , uiUri :: Expr String
  , uiUser :: Expr String
  , uri :: Expr String
  , urn :: Expr String
  , user :: Expr String
  , version :: Expr String
  }

read :: String -> Args -> Infra DatabaseCluster
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_database_cluster" logicalName values
  pure
    { dataSource: handle
    , database: dataSourceAttr handle [ "database" ]
    , engine: dataSourceAttr handle [ "engine" ]
    , host: dataSourceAttr handle [ "host" ]
    , id: dataSourceAttr handle [ "id" ]
    , maintenanceWindow: dataSourceAttr handle [ "maintenance_window" ]
    , metricsEndpoints: dataSourceAttr handle [ "metrics_endpoints" ]
    , name: dataSourceAttr handle [ "name" ]
    , nodeCount: dataSourceAttr handle [ "node_count" ]
    , password: dataSourceAttr handle [ "password" ]
    , port: dataSourceAttr handle [ "port" ]
    , privateHost: dataSourceAttr handle [ "private_host" ]
    , privateNetworkUuid: dataSourceAttr handle [ "private_network_uuid" ]
    , privateUri: dataSourceAttr handle [ "private_uri" ]
    , projectId: dataSourceAttr handle [ "project_id" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , storageAutoscale: dataSourceAttr handle [ "storage_autoscale" ]
    , storageSizeMib: dataSourceAttr handle [ "storage_size_mib" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , uiDatabase: dataSourceAttr handle [ "ui_database" ]
    , uiHost: dataSourceAttr handle [ "ui_host" ]
    , uiPassword: dataSourceAttr handle [ "ui_password" ]
    , uiPort: dataSourceAttr handle [ "ui_port" ]
    , uiUri: dataSourceAttr handle [ "ui_uri" ]
    , uiUser: dataSourceAttr handle [ "ui_user" ]
    , uri: dataSourceAttr handle [ "uri" ]
    , urn: dataSourceAttr handle [ "urn" ]
    , user: dataSourceAttr handle [ "user" ]
    , version: dataSourceAttr handle [ "version" ]
    }
