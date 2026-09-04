module DigitalOcean.Resource.DatabasePostgresqlConfig
  ( Args
  , Required
  , DatabasePostgresqlConfig
  , DatabasePostgresqlConfigResource
  , args
  , create
  , Pgbouncer
  , PgbouncerRequired
  , pgbouncerArgs
  , pgbouncerAutodbIdleTimeout
  , pgbouncerAutodbMaxDbConnections
  , pgbouncerAutodbPoolMode
  , pgbouncerAutodbPoolSize
  , pgbouncerIgnoreStartupParameters
  , pgbouncerMinPoolSize
  , pgbouncerServerIdleTimeout
  , pgbouncerServerLifetime
  , pgbouncerServerResetQueryAlways
  , Timescaledb
  , TimescaledbRequired
  , timescaledbArgs
  , timescaledbMaxBackgroundWorkers
  , autovacuumAnalyzeScaleFactor
  , autovacuumAnalyzeThreshold
  , autovacuumFreezeMaxAge
  , autovacuumMaxWorkers
  , autovacuumNaptime
  , autovacuumVacuumCostDelay
  , autovacuumVacuumCostLimit
  , autovacuumVacuumScaleFactor
  , autovacuumVacuumThreshold
  , backupHour
  , backupMinute
  , bgwriterDelay
  , bgwriterFlushAfter
  , bgwriterLruMaxpages
  , bgwriterLruMultiplier
  , deadlockTimeout
  , defaultToastCompression
  , id
  , idleInTransactionSessionTimeout
  , jit
  , logAutovacuumMinDuration
  , logErrorVerbosity
  , logLinePrefix
  , logMinDurationStatement
  , maxFilesPerProcess
  , maxLocksPerTransaction
  , maxLogicalReplicationWorkers
  , maxParallelWorkers
  , maxParallelWorkersPerGather
  , maxPredLocksPerTransaction
  , maxPreparedTransactions
  , maxReplicationSlots
  , maxStackDepth
  , maxStandbyArchiveDelay
  , maxStandbyStreamingDelay
  , maxWalSenders
  , maxWorkerProcesses
  , pgPartmanBgwInterval
  , pgPartmanBgwRole
  , pgStatStatementsTrack
  , pgbouncer
  , sharedBuffersPercentage
  , tempFileLimit
  , timescaledb
  , timezone
  , trackActivityQuerySize
  , trackCommitTimestamp
  , trackFunctions
  , trackIoTiming
  , walSenderTimeout
  , walWriterDelay
  , workMem
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DatabasePostgresqlConfigResource

newtype Pgbouncer = Pgbouncer InputObject

type PgbouncerRequired =
  {
  }

pgbouncerArgs :: PgbouncerRequired -> Pgbouncer
pgbouncerArgs _ = Pgbouncer (inputObject
  [
  ])

pgbouncerAutodbIdleTimeout :: Input Number -> Pgbouncer -> Pgbouncer
pgbouncerAutodbIdleTimeout value (Pgbouncer values) = Pgbouncer (insertInputField "autodb_idle_timeout" (inputJson value) values)

pgbouncerAutodbMaxDbConnections :: Input Number -> Pgbouncer -> Pgbouncer
pgbouncerAutodbMaxDbConnections value (Pgbouncer values) = Pgbouncer (insertInputField "autodb_max_db_connections" (inputJson value) values)

pgbouncerAutodbPoolMode :: Input String -> Pgbouncer -> Pgbouncer
pgbouncerAutodbPoolMode value (Pgbouncer values) = Pgbouncer (insertInputField "autodb_pool_mode" (inputJson value) values)

pgbouncerAutodbPoolSize :: Input Number -> Pgbouncer -> Pgbouncer
pgbouncerAutodbPoolSize value (Pgbouncer values) = Pgbouncer (insertInputField "autodb_pool_size" (inputJson value) values)

pgbouncerIgnoreStartupParameters :: Input (Array String) -> Pgbouncer -> Pgbouncer
pgbouncerIgnoreStartupParameters value (Pgbouncer values) = Pgbouncer (insertInputField "ignore_startup_parameters" (inputJson value) values)

pgbouncerMinPoolSize :: Input Number -> Pgbouncer -> Pgbouncer
pgbouncerMinPoolSize value (Pgbouncer values) = Pgbouncer (insertInputField "min_pool_size" (inputJson value) values)

pgbouncerServerIdleTimeout :: Input Number -> Pgbouncer -> Pgbouncer
pgbouncerServerIdleTimeout value (Pgbouncer values) = Pgbouncer (insertInputField "server_idle_timeout" (inputJson value) values)

pgbouncerServerLifetime :: Input Number -> Pgbouncer -> Pgbouncer
pgbouncerServerLifetime value (Pgbouncer values) = Pgbouncer (insertInputField "server_lifetime" (inputJson value) values)

pgbouncerServerResetQueryAlways :: Input Boolean -> Pgbouncer -> Pgbouncer
pgbouncerServerResetQueryAlways value (Pgbouncer values) = Pgbouncer (insertInputField "server_reset_query_always" (inputJson value) values)

pgbouncerJson :: Pgbouncer -> Json
pgbouncerJson (Pgbouncer values) = inputObjectJson values

newtype Timescaledb = Timescaledb InputObject

type TimescaledbRequired =
  {
  }

timescaledbArgs :: TimescaledbRequired -> Timescaledb
timescaledbArgs _ = Timescaledb (inputObject
  [
  ])

timescaledbMaxBackgroundWorkers :: Input Number -> Timescaledb -> Timescaledb
timescaledbMaxBackgroundWorkers value (Timescaledb values) = Timescaledb (insertInputField "max_background_workers" (inputJson value) values)

timescaledbJson :: Timescaledb -> Json
timescaledbJson (Timescaledb values) = inputObjectJson values

type Required =
  { clusterId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

autovacuumAnalyzeScaleFactor :: Input Number -> Args -> Args
autovacuumAnalyzeScaleFactor value (Args values) = Args (insertInputField "autovacuum_analyze_scale_factor" (inputJson value) values)

autovacuumAnalyzeThreshold :: Input Number -> Args -> Args
autovacuumAnalyzeThreshold value (Args values) = Args (insertInputField "autovacuum_analyze_threshold" (inputJson value) values)

autovacuumFreezeMaxAge :: Input Number -> Args -> Args
autovacuumFreezeMaxAge value (Args values) = Args (insertInputField "autovacuum_freeze_max_age" (inputJson value) values)

autovacuumMaxWorkers :: Input Number -> Args -> Args
autovacuumMaxWorkers value (Args values) = Args (insertInputField "autovacuum_max_workers" (inputJson value) values)

autovacuumNaptime :: Input Number -> Args -> Args
autovacuumNaptime value (Args values) = Args (insertInputField "autovacuum_naptime" (inputJson value) values)

autovacuumVacuumCostDelay :: Input Number -> Args -> Args
autovacuumVacuumCostDelay value (Args values) = Args (insertInputField "autovacuum_vacuum_cost_delay" (inputJson value) values)

autovacuumVacuumCostLimit :: Input Number -> Args -> Args
autovacuumVacuumCostLimit value (Args values) = Args (insertInputField "autovacuum_vacuum_cost_limit" (inputJson value) values)

autovacuumVacuumScaleFactor :: Input Number -> Args -> Args
autovacuumVacuumScaleFactor value (Args values) = Args (insertInputField "autovacuum_vacuum_scale_factor" (inputJson value) values)

autovacuumVacuumThreshold :: Input Number -> Args -> Args
autovacuumVacuumThreshold value (Args values) = Args (insertInputField "autovacuum_vacuum_threshold" (inputJson value) values)

backupHour :: Input Number -> Args -> Args
backupHour value (Args values) = Args (insertInputField "backup_hour" (inputJson value) values)

backupMinute :: Input Number -> Args -> Args
backupMinute value (Args values) = Args (insertInputField "backup_minute" (inputJson value) values)

bgwriterDelay :: Input Number -> Args -> Args
bgwriterDelay value (Args values) = Args (insertInputField "bgwriter_delay" (inputJson value) values)

bgwriterFlushAfter :: Input Number -> Args -> Args
bgwriterFlushAfter value (Args values) = Args (insertInputField "bgwriter_flush_after" (inputJson value) values)

bgwriterLruMaxpages :: Input Number -> Args -> Args
bgwriterLruMaxpages value (Args values) = Args (insertInputField "bgwriter_lru_maxpages" (inputJson value) values)

bgwriterLruMultiplier :: Input Number -> Args -> Args
bgwriterLruMultiplier value (Args values) = Args (insertInputField "bgwriter_lru_multiplier" (inputJson value) values)

deadlockTimeout :: Input Number -> Args -> Args
deadlockTimeout value (Args values) = Args (insertInputField "deadlock_timeout" (inputJson value) values)

defaultToastCompression :: Input String -> Args -> Args
defaultToastCompression value (Args values) = Args (insertInputField "default_toast_compression" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

idleInTransactionSessionTimeout :: Input Number -> Args -> Args
idleInTransactionSessionTimeout value (Args values) = Args (insertInputField "idle_in_transaction_session_timeout" (inputJson value) values)

jit :: Input Boolean -> Args -> Args
jit value (Args values) = Args (insertInputField "jit" (inputJson value) values)

logAutovacuumMinDuration :: Input Number -> Args -> Args
logAutovacuumMinDuration value (Args values) = Args (insertInputField "log_autovacuum_min_duration" (inputJson value) values)

logErrorVerbosity :: Input String -> Args -> Args
logErrorVerbosity value (Args values) = Args (insertInputField "log_error_verbosity" (inputJson value) values)

logLinePrefix :: Input String -> Args -> Args
logLinePrefix value (Args values) = Args (insertInputField "log_line_prefix" (inputJson value) values)

logMinDurationStatement :: Input Number -> Args -> Args
logMinDurationStatement value (Args values) = Args (insertInputField "log_min_duration_statement" (inputJson value) values)

maxFilesPerProcess :: Input Number -> Args -> Args
maxFilesPerProcess value (Args values) = Args (insertInputField "max_files_per_process" (inputJson value) values)

maxLocksPerTransaction :: Input Number -> Args -> Args
maxLocksPerTransaction value (Args values) = Args (insertInputField "max_locks_per_transaction" (inputJson value) values)

maxLogicalReplicationWorkers :: Input Number -> Args -> Args
maxLogicalReplicationWorkers value (Args values) = Args (insertInputField "max_logical_replication_workers" (inputJson value) values)

maxParallelWorkers :: Input Number -> Args -> Args
maxParallelWorkers value (Args values) = Args (insertInputField "max_parallel_workers" (inputJson value) values)

maxParallelWorkersPerGather :: Input Number -> Args -> Args
maxParallelWorkersPerGather value (Args values) = Args (insertInputField "max_parallel_workers_per_gather" (inputJson value) values)

maxPredLocksPerTransaction :: Input Number -> Args -> Args
maxPredLocksPerTransaction value (Args values) = Args (insertInputField "max_pred_locks_per_transaction" (inputJson value) values)

maxPreparedTransactions :: Input Number -> Args -> Args
maxPreparedTransactions value (Args values) = Args (insertInputField "max_prepared_transactions" (inputJson value) values)

maxReplicationSlots :: Input Number -> Args -> Args
maxReplicationSlots value (Args values) = Args (insertInputField "max_replication_slots" (inputJson value) values)

maxStackDepth :: Input Number -> Args -> Args
maxStackDepth value (Args values) = Args (insertInputField "max_stack_depth" (inputJson value) values)

maxStandbyArchiveDelay :: Input Number -> Args -> Args
maxStandbyArchiveDelay value (Args values) = Args (insertInputField "max_standby_archive_delay" (inputJson value) values)

maxStandbyStreamingDelay :: Input Number -> Args -> Args
maxStandbyStreamingDelay value (Args values) = Args (insertInputField "max_standby_streaming_delay" (inputJson value) values)

maxWalSenders :: Input Number -> Args -> Args
maxWalSenders value (Args values) = Args (insertInputField "max_wal_senders" (inputJson value) values)

maxWorkerProcesses :: Input Number -> Args -> Args
maxWorkerProcesses value (Args values) = Args (insertInputField "max_worker_processes" (inputJson value) values)

pgPartmanBgwInterval :: Input Number -> Args -> Args
pgPartmanBgwInterval value (Args values) = Args (insertInputField "pg_partman_bgw_interval" (inputJson value) values)

pgPartmanBgwRole :: Input String -> Args -> Args
pgPartmanBgwRole value (Args values) = Args (insertInputField "pg_partman_bgw_role" (inputJson value) values)

pgStatStatementsTrack :: Input String -> Args -> Args
pgStatStatementsTrack value (Args values) = Args (insertInputField "pg_stat_statements_track" (inputJson value) values)

pgbouncer :: Array Pgbouncer -> Args -> Args
pgbouncer value (Args values) = Args (insertInputField "pgbouncer" (arrayExprJson (map pgbouncerJson value)) values)

sharedBuffersPercentage :: Input Number -> Args -> Args
sharedBuffersPercentage value (Args values) = Args (insertInputField "shared_buffers_percentage" (inputJson value) values)

tempFileLimit :: Input Number -> Args -> Args
tempFileLimit value (Args values) = Args (insertInputField "temp_file_limit" (inputJson value) values)

timescaledb :: Array Timescaledb -> Args -> Args
timescaledb value (Args values) = Args (insertInputField "timescaledb" (arrayExprJson (map timescaledbJson value)) values)

timezone :: Input String -> Args -> Args
timezone value (Args values) = Args (insertInputField "timezone" (inputJson value) values)

trackActivityQuerySize :: Input Number -> Args -> Args
trackActivityQuerySize value (Args values) = Args (insertInputField "track_activity_query_size" (inputJson value) values)

trackCommitTimestamp :: Input String -> Args -> Args
trackCommitTimestamp value (Args values) = Args (insertInputField "track_commit_timestamp" (inputJson value) values)

trackFunctions :: Input String -> Args -> Args
trackFunctions value (Args values) = Args (insertInputField "track_functions" (inputJson value) values)

trackIoTiming :: Input String -> Args -> Args
trackIoTiming value (Args values) = Args (insertInputField "track_io_timing" (inputJson value) values)

walSenderTimeout :: Input Number -> Args -> Args
walSenderTimeout value (Args values) = Args (insertInputField "wal_sender_timeout" (inputJson value) values)

walWriterDelay :: Input Number -> Args -> Args
walWriterDelay value (Args values) = Args (insertInputField "wal_writer_delay" (inputJson value) values)

workMem :: Input Number -> Args -> Args
workMem value (Args values) = Args (insertInputField "work_mem" (inputJson value) values)

type DatabasePostgresqlConfig =
  { resource :: Resource DatabasePostgresqlConfigResource
  , autovacuumAnalyzeScaleFactor :: Expr Number
  , autovacuumAnalyzeThreshold :: Expr Number
  , autovacuumFreezeMaxAge :: Expr Number
  , autovacuumMaxWorkers :: Expr Number
  , autovacuumNaptime :: Expr Number
  , autovacuumVacuumCostDelay :: Expr Number
  , autovacuumVacuumCostLimit :: Expr Number
  , autovacuumVacuumScaleFactor :: Expr Number
  , autovacuumVacuumThreshold :: Expr Number
  , backupHour :: Expr Number
  , backupMinute :: Expr Number
  , bgwriterDelay :: Expr Number
  , bgwriterFlushAfter :: Expr Number
  , bgwriterLruMaxpages :: Expr Number
  , bgwriterLruMultiplier :: Expr Number
  , clusterId :: Expr String
  , deadlockTimeout :: Expr Number
  , defaultToastCompression :: Expr String
  , id :: Expr String
  , idleInTransactionSessionTimeout :: Expr Number
  , jit :: Expr Boolean
  , logAutovacuumMinDuration :: Expr Number
  , logErrorVerbosity :: Expr String
  , logLinePrefix :: Expr String
  , logMinDurationStatement :: Expr Number
  , maxFilesPerProcess :: Expr Number
  , maxLocksPerTransaction :: Expr Number
  , maxLogicalReplicationWorkers :: Expr Number
  , maxParallelWorkers :: Expr Number
  , maxParallelWorkersPerGather :: Expr Number
  , maxPredLocksPerTransaction :: Expr Number
  , maxPreparedTransactions :: Expr Number
  , maxReplicationSlots :: Expr Number
  , maxStackDepth :: Expr Number
  , maxStandbyArchiveDelay :: Expr Number
  , maxStandbyStreamingDelay :: Expr Number
  , maxWalSenders :: Expr Number
  , maxWorkerProcesses :: Expr Number
  , pgPartmanBgwInterval :: Expr Number
  , pgPartmanBgwRole :: Expr String
  , pgStatStatementsTrack :: Expr String
  , sharedBuffersPercentage :: Expr Number
  , tempFileLimit :: Expr Number
  , timezone :: Expr String
  , trackActivityQuerySize :: Expr Number
  , trackCommitTimestamp :: Expr String
  , trackFunctions :: Expr String
  , trackIoTiming :: Expr String
  , walSenderTimeout :: Expr Number
  , walWriterDelay :: Expr Number
  , workMem :: Expr Number
  }

create :: String -> Args -> Infra DatabasePostgresqlConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_postgresql_config" logicalName values
  pure
    { resource: handle
    , autovacuumAnalyzeScaleFactor: resourceAttr handle [ "autovacuum_analyze_scale_factor" ]
    , autovacuumAnalyzeThreshold: resourceAttr handle [ "autovacuum_analyze_threshold" ]
    , autovacuumFreezeMaxAge: resourceAttr handle [ "autovacuum_freeze_max_age" ]
    , autovacuumMaxWorkers: resourceAttr handle [ "autovacuum_max_workers" ]
    , autovacuumNaptime: resourceAttr handle [ "autovacuum_naptime" ]
    , autovacuumVacuumCostDelay: resourceAttr handle [ "autovacuum_vacuum_cost_delay" ]
    , autovacuumVacuumCostLimit: resourceAttr handle [ "autovacuum_vacuum_cost_limit" ]
    , autovacuumVacuumScaleFactor: resourceAttr handle [ "autovacuum_vacuum_scale_factor" ]
    , autovacuumVacuumThreshold: resourceAttr handle [ "autovacuum_vacuum_threshold" ]
    , backupHour: resourceAttr handle [ "backup_hour" ]
    , backupMinute: resourceAttr handle [ "backup_minute" ]
    , bgwriterDelay: resourceAttr handle [ "bgwriter_delay" ]
    , bgwriterFlushAfter: resourceAttr handle [ "bgwriter_flush_after" ]
    , bgwriterLruMaxpages: resourceAttr handle [ "bgwriter_lru_maxpages" ]
    , bgwriterLruMultiplier: resourceAttr handle [ "bgwriter_lru_multiplier" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , deadlockTimeout: resourceAttr handle [ "deadlock_timeout" ]
    , defaultToastCompression: resourceAttr handle [ "default_toast_compression" ]
    , id: resourceAttr handle [ "id" ]
    , idleInTransactionSessionTimeout: resourceAttr handle [ "idle_in_transaction_session_timeout" ]
    , jit: resourceAttr handle [ "jit" ]
    , logAutovacuumMinDuration: resourceAttr handle [ "log_autovacuum_min_duration" ]
    , logErrorVerbosity: resourceAttr handle [ "log_error_verbosity" ]
    , logLinePrefix: resourceAttr handle [ "log_line_prefix" ]
    , logMinDurationStatement: resourceAttr handle [ "log_min_duration_statement" ]
    , maxFilesPerProcess: resourceAttr handle [ "max_files_per_process" ]
    , maxLocksPerTransaction: resourceAttr handle [ "max_locks_per_transaction" ]
    , maxLogicalReplicationWorkers: resourceAttr handle [ "max_logical_replication_workers" ]
    , maxParallelWorkers: resourceAttr handle [ "max_parallel_workers" ]
    , maxParallelWorkersPerGather: resourceAttr handle [ "max_parallel_workers_per_gather" ]
    , maxPredLocksPerTransaction: resourceAttr handle [ "max_pred_locks_per_transaction" ]
    , maxPreparedTransactions: resourceAttr handle [ "max_prepared_transactions" ]
    , maxReplicationSlots: resourceAttr handle [ "max_replication_slots" ]
    , maxStackDepth: resourceAttr handle [ "max_stack_depth" ]
    , maxStandbyArchiveDelay: resourceAttr handle [ "max_standby_archive_delay" ]
    , maxStandbyStreamingDelay: resourceAttr handle [ "max_standby_streaming_delay" ]
    , maxWalSenders: resourceAttr handle [ "max_wal_senders" ]
    , maxWorkerProcesses: resourceAttr handle [ "max_worker_processes" ]
    , pgPartmanBgwInterval: resourceAttr handle [ "pg_partman_bgw_interval" ]
    , pgPartmanBgwRole: resourceAttr handle [ "pg_partman_bgw_role" ]
    , pgStatStatementsTrack: resourceAttr handle [ "pg_stat_statements_track" ]
    , sharedBuffersPercentage: resourceAttr handle [ "shared_buffers_percentage" ]
    , tempFileLimit: resourceAttr handle [ "temp_file_limit" ]
    , timezone: resourceAttr handle [ "timezone" ]
    , trackActivityQuerySize: resourceAttr handle [ "track_activity_query_size" ]
    , trackCommitTimestamp: resourceAttr handle [ "track_commit_timestamp" ]
    , trackFunctions: resourceAttr handle [ "track_functions" ]
    , trackIoTiming: resourceAttr handle [ "track_io_timing" ]
    , walSenderTimeout: resourceAttr handle [ "wal_sender_timeout" ]
    , walWriterDelay: resourceAttr handle [ "wal_writer_delay" ]
    , workMem: resourceAttr handle [ "work_mem" ]
    }
