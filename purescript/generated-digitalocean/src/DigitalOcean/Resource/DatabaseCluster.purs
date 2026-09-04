module DigitalOcean.Resource.DatabaseCluster
  ( Args
  , Required
  , DatabaseCluster
  , DatabaseClusterResource
  , args
  , create
  , BackupRestore
  , BackupRestoreRequired
  , backupRestoreArgs
  , backupRestoreBackupCreatedAt
  , MaintenanceWindow
  , MaintenanceWindowRequired
  , maintenanceWindowArgs
  , StorageAutoscale
  , StorageAutoscaleRequired
  , storageAutoscaleArgs
  , storageAutoscaleIncrementGib
  , storageAutoscaleThresholdPercent
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DatabaseClusterResource

newtype BackupRestore = BackupRestore InputObject

type BackupRestoreRequired =
  { databaseName :: Input String
  }

backupRestoreArgs :: BackupRestoreRequired -> BackupRestore
backupRestoreArgs required = BackupRestore (inputObject
  [ Tuple "database_name" (inputJson required.databaseName)
  ])

backupRestoreBackupCreatedAt :: Input String -> BackupRestore -> BackupRestore
backupRestoreBackupCreatedAt value (BackupRestore values) = BackupRestore (insertInputField "backup_created_at" (inputJson value) values)

backupRestoreJson :: BackupRestore -> Json
backupRestoreJson (BackupRestore values) = inputObjectJson values

newtype MaintenanceWindow = MaintenanceWindow InputObject

type MaintenanceWindowRequired =
  { day :: Input String
  , hour :: Input String
  }

maintenanceWindowArgs :: MaintenanceWindowRequired -> MaintenanceWindow
maintenanceWindowArgs required = MaintenanceWindow (inputObject
  [ Tuple "day" (inputJson required.day)
  , Tuple "hour" (inputJson required.hour)
  ])

maintenanceWindowJson :: MaintenanceWindow -> Json
maintenanceWindowJson (MaintenanceWindow values) = inputObjectJson values

newtype StorageAutoscale = StorageAutoscale InputObject

type StorageAutoscaleRequired =
  { enabled :: Input Boolean
  }

storageAutoscaleArgs :: StorageAutoscaleRequired -> StorageAutoscale
storageAutoscaleArgs required = StorageAutoscale (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

storageAutoscaleIncrementGib :: Input Number -> StorageAutoscale -> StorageAutoscale
storageAutoscaleIncrementGib value (StorageAutoscale values) = StorageAutoscale (insertInputField "increment_gib" (inputJson value) values)

storageAutoscaleThresholdPercent :: Input Number -> StorageAutoscale -> StorageAutoscale
storageAutoscaleThresholdPercent value (StorageAutoscale values) = StorageAutoscale (insertInputField "threshold_percent" (inputJson value) values)

storageAutoscaleJson :: StorageAutoscale -> Json
storageAutoscaleJson (StorageAutoscale values) = inputObjectJson values

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { engine :: Input String
  , name :: Input String
  , nodeCount :: Input Number
  , region :: Input String
  , size :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "engine" (inputJson required.engine)
  , Tuple "name" (inputJson required.name)
  , Tuple "node_count" (inputJson required.nodeCount)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  ])

backupRestore :: Array BackupRestore -> Args -> Args
backupRestore value (Args values) = Args (insertInputField "backup_restore" (arrayExprJson (map backupRestoreJson value)) values)

evictionPolicy :: Input String -> Args -> Args
evictionPolicy value (Args values) = Args (insertInputField "eviction_policy" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

maintenanceWindow :: Array MaintenanceWindow -> Args -> Args
maintenanceWindow value (Args values) = Args (insertInputField "maintenance_window" (arrayExprJson (map maintenanceWindowJson value)) values)

privateNetworkUuid :: Input String -> Args -> Args
privateNetworkUuid value (Args values) = Args (insertInputField "private_network_uuid" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (insertInputField "project_id" (inputJson value) values)

sqlMode :: Input String -> Args -> Args
sqlMode value (Args values) = Args (insertInputField "sql_mode" (inputJson value) values)

storageAutoscale :: Array StorageAutoscale -> Args -> Args
storageAutoscale value (Args values) = Args (insertInputField "storage_autoscale" (arrayExprJson (map storageAutoscaleJson value)) values)

storageSizeMib :: Input String -> Args -> Args
storageSizeMib value (Args values) = Args (insertInputField "storage_size_mib" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

version :: Input String -> Args -> Args
version value (Args values) = Args (insertInputField "version" (inputJson value) values)

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
