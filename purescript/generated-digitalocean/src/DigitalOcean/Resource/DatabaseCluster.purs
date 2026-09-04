module DigitalOcean.Resource.DatabaseCluster
  ( Args
  , Required
  , DatabaseCluster
  , DatabaseClusterResource
  , args
  , create
  , backupRestore
  , evictionPolicy
  , id
  , maintenanceWindow
  , privateNetworkUuid
  , projectId
  , sqlMode
  , storageAutoscale
  , storageSizeMib
  , tags
  , timeouts
  , version
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseClusterResource

type Required =
  { engine :: Input String
  , name :: Input String
  , nodeCount :: Input Number
  , region :: Input String
  , size :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "engine" (inputJson required.engine)
  , Tuple "name" (inputJson required.name)
  , Tuple "node_count" (inputJson required.nodeCount)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  ])

backupRestore :: Input (Array ({ backupCreatedAt :: String, databaseName :: String })) -> Args -> Args
backupRestore value (Args values) = Args (Object.insert "backup_restore" (inputJson value) values)

evictionPolicy :: Input String -> Args -> Args
evictionPolicy value (Args values) = Args (Object.insert "eviction_policy" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

maintenanceWindow :: Input (Array ({ day :: String, hour :: String })) -> Args -> Args
maintenanceWindow value (Args values) = Args (Object.insert "maintenance_window" (inputJson value) values)

privateNetworkUuid :: Input String -> Args -> Args
privateNetworkUuid value (Args values) = Args (Object.insert "private_network_uuid" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (Object.insert "project_id" (inputJson value) values)

sqlMode :: Input String -> Args -> Args
sqlMode value (Args values) = Args (Object.insert "sql_mode" (inputJson value) values)

storageAutoscale :: Input (Array ({ enabled :: Boolean, incrementGib :: Number, thresholdPercent :: Number })) -> Args -> Args
storageAutoscale value (Args values) = Args (Object.insert "storage_autoscale" (inputJson value) values)

storageSizeMib :: Input String -> Args -> Args
storageSizeMib value (Args values) = Args (Object.insert "storage_size_mib" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

timeouts :: Input ({ create :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

version :: Input String -> Args -> Args
version value (Args values) = Args (Object.insert "version" (inputJson value) values)

type DatabaseCluster =
  { resource :: Resource DatabaseClusterResource
  , database :: Expr String
  , engine :: Expr String
  , evictionPolicy :: Expr String
  , host :: Expr String
  , id :: Expr String
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
  , sqlMode :: Expr String
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

create :: String -> Args -> Infra DatabaseCluster
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_cluster" logicalName values
  pure
    { resource: handle
    , database: resourceAttr handle [ "database" ]
    , engine: resourceAttr handle [ "engine" ]
    , evictionPolicy: resourceAttr handle [ "eviction_policy" ]
    , host: resourceAttr handle [ "host" ]
    , id: resourceAttr handle [ "id" ]
    , metricsEndpoints: resourceAttr handle [ "metrics_endpoints" ]
    , name: resourceAttr handle [ "name" ]
    , nodeCount: resourceAttr handle [ "node_count" ]
    , password: resourceAttr handle [ "password" ]
    , port: resourceAttr handle [ "port" ]
    , privateHost: resourceAttr handle [ "private_host" ]
    , privateNetworkUuid: resourceAttr handle [ "private_network_uuid" ]
    , privateUri: resourceAttr handle [ "private_uri" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , sqlMode: resourceAttr handle [ "sql_mode" ]
    , storageSizeMib: resourceAttr handle [ "storage_size_mib" ]
    , tags: resourceAttr handle [ "tags" ]
    , uiDatabase: resourceAttr handle [ "ui_database" ]
    , uiHost: resourceAttr handle [ "ui_host" ]
    , uiPassword: resourceAttr handle [ "ui_password" ]
    , uiPort: resourceAttr handle [ "ui_port" ]
    , uiUri: resourceAttr handle [ "ui_uri" ]
    , uiUser: resourceAttr handle [ "ui_user" ]
    , uri: resourceAttr handle [ "uri" ]
    , urn: resourceAttr handle [ "urn" ]
    , user: resourceAttr handle [ "user" ]
    , version: resourceAttr handle [ "version" ]
    }
