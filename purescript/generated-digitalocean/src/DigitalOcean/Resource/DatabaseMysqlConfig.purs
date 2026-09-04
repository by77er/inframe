module DigitalOcean.Resource.DatabaseMysqlConfig
  ( Args
  , Required
  , DatabaseMysqlConfig
  , DatabaseMysqlConfigResource
  , args
  , create
  , backupHour
  , backupMinute
  , binlogRetentionPeriod
  , connectTimeout
  , defaultTimeZone
  , groupConcatMaxLen
  , id
  , informationSchemaStatsExpiry
  , innodbFtMinTokenSize
  , innodbFtServerStopwordTable
  , innodbLockWaitTimeout
  , innodbLogBufferSize
  , innodbOnlineAlterLogMaxSize
  , innodbPrintAllDeadlocks
  , innodbRollbackOnTimeout
  , interactiveTimeout
  , internalTmpMemStorageEngine
  , longQueryTime
  , maxAllowedPacket
  , maxHeapTableSize
  , netReadTimeout
  , netWriteTimeout
  , slowQueryLog
  , sortBufferSize
  , sqlMode
  , sqlRequirePrimaryKey
  , tmpTableSize
  , waitTimeout
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseMysqlConfigResource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

backupHour :: Input Number -> Args -> Args
backupHour value (Args values) = Args (insertInputField "backup_hour" (inputJson value) values)

backupMinute :: Input Number -> Args -> Args
backupMinute value (Args values) = Args (insertInputField "backup_minute" (inputJson value) values)

binlogRetentionPeriod :: Input Number -> Args -> Args
binlogRetentionPeriod value (Args values) = Args (insertInputField "binlog_retention_period" (inputJson value) values)

connectTimeout :: Input Number -> Args -> Args
connectTimeout value (Args values) = Args (insertInputField "connect_timeout" (inputJson value) values)

defaultTimeZone :: Input String -> Args -> Args
defaultTimeZone value (Args values) = Args (insertInputField "default_time_zone" (inputJson value) values)

groupConcatMaxLen :: Input Number -> Args -> Args
groupConcatMaxLen value (Args values) = Args (insertInputField "group_concat_max_len" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

informationSchemaStatsExpiry :: Input Number -> Args -> Args
informationSchemaStatsExpiry value (Args values) = Args (insertInputField "information_schema_stats_expiry" (inputJson value) values)

innodbFtMinTokenSize :: Input Number -> Args -> Args
innodbFtMinTokenSize value (Args values) = Args (insertInputField "innodb_ft_min_token_size" (inputJson value) values)

innodbFtServerStopwordTable :: Input String -> Args -> Args
innodbFtServerStopwordTable value (Args values) = Args (insertInputField "innodb_ft_server_stopword_table" (inputJson value) values)

innodbLockWaitTimeout :: Input Number -> Args -> Args
innodbLockWaitTimeout value (Args values) = Args (insertInputField "innodb_lock_wait_timeout" (inputJson value) values)

innodbLogBufferSize :: Input Number -> Args -> Args
innodbLogBufferSize value (Args values) = Args (insertInputField "innodb_log_buffer_size" (inputJson value) values)

innodbOnlineAlterLogMaxSize :: Input Number -> Args -> Args
innodbOnlineAlterLogMaxSize value (Args values) = Args (insertInputField "innodb_online_alter_log_max_size" (inputJson value) values)

innodbPrintAllDeadlocks :: Input Boolean -> Args -> Args
innodbPrintAllDeadlocks value (Args values) = Args (insertInputField "innodb_print_all_deadlocks" (inputJson value) values)

innodbRollbackOnTimeout :: Input Boolean -> Args -> Args
innodbRollbackOnTimeout value (Args values) = Args (insertInputField "innodb_rollback_on_timeout" (inputJson value) values)

interactiveTimeout :: Input Number -> Args -> Args
interactiveTimeout value (Args values) = Args (insertInputField "interactive_timeout" (inputJson value) values)

internalTmpMemStorageEngine :: Input String -> Args -> Args
internalTmpMemStorageEngine value (Args values) = Args (insertInputField "internal_tmp_mem_storage_engine" (inputJson value) values)

longQueryTime :: Input Number -> Args -> Args
longQueryTime value (Args values) = Args (insertInputField "long_query_time" (inputJson value) values)

maxAllowedPacket :: Input Number -> Args -> Args
maxAllowedPacket value (Args values) = Args (insertInputField "max_allowed_packet" (inputJson value) values)

maxHeapTableSize :: Input Number -> Args -> Args
maxHeapTableSize value (Args values) = Args (insertInputField "max_heap_table_size" (inputJson value) values)

netReadTimeout :: Input Number -> Args -> Args
netReadTimeout value (Args values) = Args (insertInputField "net_read_timeout" (inputJson value) values)

netWriteTimeout :: Input Number -> Args -> Args
netWriteTimeout value (Args values) = Args (insertInputField "net_write_timeout" (inputJson value) values)

slowQueryLog :: Input Boolean -> Args -> Args
slowQueryLog value (Args values) = Args (insertInputField "slow_query_log" (inputJson value) values)

sortBufferSize :: Input Number -> Args -> Args
sortBufferSize value (Args values) = Args (insertInputField "sort_buffer_size" (inputJson value) values)

sqlMode :: Input String -> Args -> Args
sqlMode value (Args values) = Args (insertInputField "sql_mode" (inputJson value) values)

sqlRequirePrimaryKey :: Input Boolean -> Args -> Args
sqlRequirePrimaryKey value (Args values) = Args (insertInputField "sql_require_primary_key" (inputJson value) values)

tmpTableSize :: Input Number -> Args -> Args
tmpTableSize value (Args values) = Args (insertInputField "tmp_table_size" (inputJson value) values)

waitTimeout :: Input Number -> Args -> Args
waitTimeout value (Args values) = Args (insertInputField "wait_timeout" (inputJson value) values)

type DatabaseMysqlConfig =
  { resource :: Resource DatabaseMysqlConfigResource
  , backupHour :: Expr Number
  , backupMinute :: Expr Number
  , binlogRetentionPeriod :: Expr Number
  , clusterId :: Expr String
  , connectTimeout :: Expr Number
  , defaultTimeZone :: Expr String
  , groupConcatMaxLen :: Expr Number
  , id :: Expr String
  , informationSchemaStatsExpiry :: Expr Number
  , innodbFtMinTokenSize :: Expr Number
  , innodbFtServerStopwordTable :: Expr String
  , innodbLockWaitTimeout :: Expr Number
  , innodbLogBufferSize :: Expr Number
  , innodbOnlineAlterLogMaxSize :: Expr Number
  , innodbPrintAllDeadlocks :: Expr Boolean
  , innodbRollbackOnTimeout :: Expr Boolean
  , interactiveTimeout :: Expr Number
  , internalTmpMemStorageEngine :: Expr String
  , longQueryTime :: Expr Number
  , maxAllowedPacket :: Expr Number
  , maxHeapTableSize :: Expr Number
  , netReadTimeout :: Expr Number
  , netWriteTimeout :: Expr Number
  , slowQueryLog :: Expr Boolean
  , sortBufferSize :: Expr Number
  , sqlMode :: Expr String
  , sqlRequirePrimaryKey :: Expr Boolean
  , tmpTableSize :: Expr Number
  , waitTimeout :: Expr Number
  }

create :: String -> Args -> Infra DatabaseMysqlConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_mysql_config" logicalName values
  pure
    { resource: handle
    , backupHour: resourceAttr handle [ "backup_hour" ]
    , backupMinute: resourceAttr handle [ "backup_minute" ]
    , binlogRetentionPeriod: resourceAttr handle [ "binlog_retention_period" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , connectTimeout: resourceAttr handle [ "connect_timeout" ]
    , defaultTimeZone: resourceAttr handle [ "default_time_zone" ]
    , groupConcatMaxLen: resourceAttr handle [ "group_concat_max_len" ]
    , id: resourceAttr handle [ "id" ]
    , informationSchemaStatsExpiry: resourceAttr handle [ "information_schema_stats_expiry" ]
    , innodbFtMinTokenSize: resourceAttr handle [ "innodb_ft_min_token_size" ]
    , innodbFtServerStopwordTable: resourceAttr handle [ "innodb_ft_server_stopword_table" ]
    , innodbLockWaitTimeout: resourceAttr handle [ "innodb_lock_wait_timeout" ]
    , innodbLogBufferSize: resourceAttr handle [ "innodb_log_buffer_size" ]
    , innodbOnlineAlterLogMaxSize: resourceAttr handle [ "innodb_online_alter_log_max_size" ]
    , innodbPrintAllDeadlocks: resourceAttr handle [ "innodb_print_all_deadlocks" ]
    , innodbRollbackOnTimeout: resourceAttr handle [ "innodb_rollback_on_timeout" ]
    , interactiveTimeout: resourceAttr handle [ "interactive_timeout" ]
    , internalTmpMemStorageEngine: resourceAttr handle [ "internal_tmp_mem_storage_engine" ]
    , longQueryTime: resourceAttr handle [ "long_query_time" ]
    , maxAllowedPacket: resourceAttr handle [ "max_allowed_packet" ]
    , maxHeapTableSize: resourceAttr handle [ "max_heap_table_size" ]
    , netReadTimeout: resourceAttr handle [ "net_read_timeout" ]
    , netWriteTimeout: resourceAttr handle [ "net_write_timeout" ]
    , slowQueryLog: resourceAttr handle [ "slow_query_log" ]
    , sortBufferSize: resourceAttr handle [ "sort_buffer_size" ]
    , sqlMode: resourceAttr handle [ "sql_mode" ]
    , sqlRequirePrimaryKey: resourceAttr handle [ "sql_require_primary_key" ]
    , tmpTableSize: resourceAttr handle [ "tmp_table_size" ]
    , waitTimeout: resourceAttr handle [ "wait_timeout" ]
    }
