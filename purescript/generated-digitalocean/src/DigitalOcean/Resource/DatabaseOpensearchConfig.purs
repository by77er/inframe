module DigitalOcean.Resource.DatabaseOpensearchConfig
  ( Args
  , Required
  , DatabaseOpensearchConfig
  , DatabaseOpensearchConfigResource
  , args
  , create
  , actionAutoCreateIndexEnabled
  , actionDestructiveRequiresName
  , clusterMaxShardsPerNode
  , clusterRoutingAllocationNodeConcurrentRecoveries
  , enableSecurityAudit
  , httpMaxContentLengthBytes
  , httpMaxHeaderSizeBytes
  , httpMaxInitialLineLengthBytes
  , id
  , indicesFielddataCacheSizePercentage
  , indicesMemoryIndexBufferSizePercentage
  , indicesMemoryMaxIndexBufferSizeMb
  , indicesMemoryMinIndexBufferSizeMb
  , indicesQueriesCacheSizePercentage
  , indicesQueryBoolMaxClauseCount
  , indicesRecoveryMaxConcurrentFileChunks
  , indicesRecoveryMaxMbPerSec
  , ismEnabled
  , ismHistoryEnabled
  , ismHistoryMaxAgeHours
  , ismHistoryMaxDocs
  , ismHistoryRolloverCheckPeriodHours
  , ismHistoryRolloverRetentionPeriodDays
  , overrideMainResponseVersion
  , pluginsAlertingFilterByBackendRolesEnabled
  , reindexRemoteWhitelist
  , scriptMaxCompilationsRate
  , searchMaxBuckets
  , threadPoolAnalyzeQueueSize
  , threadPoolAnalyzeSize
  , threadPoolForceMergeSize
  , threadPoolGetQueueSize
  , threadPoolGetSize
  , threadPoolSearchQueueSize
  , threadPoolSearchSize
  , threadPoolSearchThrottledQueueSize
  , threadPoolSearchThrottledSize
  , threadPoolWriteQueueSize
  , threadPoolWriteSize
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseOpensearchConfigResource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

actionAutoCreateIndexEnabled :: Input Boolean -> Args -> Args
actionAutoCreateIndexEnabled value (Args values) = Args (Object.insert "action_auto_create_index_enabled" (inputJson value) values)

actionDestructiveRequiresName :: Input Boolean -> Args -> Args
actionDestructiveRequiresName value (Args values) = Args (Object.insert "action_destructive_requires_name" (inputJson value) values)

clusterMaxShardsPerNode :: Input Number -> Args -> Args
clusterMaxShardsPerNode value (Args values) = Args (Object.insert "cluster_max_shards_per_node" (inputJson value) values)

clusterRoutingAllocationNodeConcurrentRecoveries :: Input Number -> Args -> Args
clusterRoutingAllocationNodeConcurrentRecoveries value (Args values) = Args (Object.insert "cluster_routing_allocation_node_concurrent_recoveries" (inputJson value) values)

enableSecurityAudit :: Input Boolean -> Args -> Args
enableSecurityAudit value (Args values) = Args (Object.insert "enable_security_audit" (inputJson value) values)

httpMaxContentLengthBytes :: Input Number -> Args -> Args
httpMaxContentLengthBytes value (Args values) = Args (Object.insert "http_max_content_length_bytes" (inputJson value) values)

httpMaxHeaderSizeBytes :: Input Number -> Args -> Args
httpMaxHeaderSizeBytes value (Args values) = Args (Object.insert "http_max_header_size_bytes" (inputJson value) values)

httpMaxInitialLineLengthBytes :: Input Number -> Args -> Args
httpMaxInitialLineLengthBytes value (Args values) = Args (Object.insert "http_max_initial_line_length_bytes" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

indicesFielddataCacheSizePercentage :: Input Number -> Args -> Args
indicesFielddataCacheSizePercentage value (Args values) = Args (Object.insert "indices_fielddata_cache_size_percentage" (inputJson value) values)

indicesMemoryIndexBufferSizePercentage :: Input Number -> Args -> Args
indicesMemoryIndexBufferSizePercentage value (Args values) = Args (Object.insert "indices_memory_index_buffer_size_percentage" (inputJson value) values)

indicesMemoryMaxIndexBufferSizeMb :: Input Number -> Args -> Args
indicesMemoryMaxIndexBufferSizeMb value (Args values) = Args (Object.insert "indices_memory_max_index_buffer_size_mb" (inputJson value) values)

indicesMemoryMinIndexBufferSizeMb :: Input Number -> Args -> Args
indicesMemoryMinIndexBufferSizeMb value (Args values) = Args (Object.insert "indices_memory_min_index_buffer_size_mb" (inputJson value) values)

indicesQueriesCacheSizePercentage :: Input Number -> Args -> Args
indicesQueriesCacheSizePercentage value (Args values) = Args (Object.insert "indices_queries_cache_size_percentage" (inputJson value) values)

indicesQueryBoolMaxClauseCount :: Input Number -> Args -> Args
indicesQueryBoolMaxClauseCount value (Args values) = Args (Object.insert "indices_query_bool_max_clause_count" (inputJson value) values)

indicesRecoveryMaxConcurrentFileChunks :: Input Number -> Args -> Args
indicesRecoveryMaxConcurrentFileChunks value (Args values) = Args (Object.insert "indices_recovery_max_concurrent_file_chunks" (inputJson value) values)

indicesRecoveryMaxMbPerSec :: Input Number -> Args -> Args
indicesRecoveryMaxMbPerSec value (Args values) = Args (Object.insert "indices_recovery_max_mb_per_sec" (inputJson value) values)

ismEnabled :: Input Boolean -> Args -> Args
ismEnabled value (Args values) = Args (Object.insert "ism_enabled" (inputJson value) values)

ismHistoryEnabled :: Input Boolean -> Args -> Args
ismHistoryEnabled value (Args values) = Args (Object.insert "ism_history_enabled" (inputJson value) values)

ismHistoryMaxAgeHours :: Input Number -> Args -> Args
ismHistoryMaxAgeHours value (Args values) = Args (Object.insert "ism_history_max_age_hours" (inputJson value) values)

ismHistoryMaxDocs :: Input Number -> Args -> Args
ismHistoryMaxDocs value (Args values) = Args (Object.insert "ism_history_max_docs" (inputJson value) values)

ismHistoryRolloverCheckPeriodHours :: Input Number -> Args -> Args
ismHistoryRolloverCheckPeriodHours value (Args values) = Args (Object.insert "ism_history_rollover_check_period_hours" (inputJson value) values)

ismHistoryRolloverRetentionPeriodDays :: Input Number -> Args -> Args
ismHistoryRolloverRetentionPeriodDays value (Args values) = Args (Object.insert "ism_history_rollover_retention_period_days" (inputJson value) values)

overrideMainResponseVersion :: Input Boolean -> Args -> Args
overrideMainResponseVersion value (Args values) = Args (Object.insert "override_main_response_version" (inputJson value) values)

pluginsAlertingFilterByBackendRolesEnabled :: Input Boolean -> Args -> Args
pluginsAlertingFilterByBackendRolesEnabled value (Args values) = Args (Object.insert "plugins_alerting_filter_by_backend_roles_enabled" (inputJson value) values)

reindexRemoteWhitelist :: Input (Array String) -> Args -> Args
reindexRemoteWhitelist value (Args values) = Args (Object.insert "reindex_remote_whitelist" (inputJson value) values)

scriptMaxCompilationsRate :: Input String -> Args -> Args
scriptMaxCompilationsRate value (Args values) = Args (Object.insert "script_max_compilations_rate" (inputJson value) values)

searchMaxBuckets :: Input Number -> Args -> Args
searchMaxBuckets value (Args values) = Args (Object.insert "search_max_buckets" (inputJson value) values)

threadPoolAnalyzeQueueSize :: Input Number -> Args -> Args
threadPoolAnalyzeQueueSize value (Args values) = Args (Object.insert "thread_pool_analyze_queue_size" (inputJson value) values)

threadPoolAnalyzeSize :: Input Number -> Args -> Args
threadPoolAnalyzeSize value (Args values) = Args (Object.insert "thread_pool_analyze_size" (inputJson value) values)

threadPoolForceMergeSize :: Input Number -> Args -> Args
threadPoolForceMergeSize value (Args values) = Args (Object.insert "thread_pool_force_merge_size" (inputJson value) values)

threadPoolGetQueueSize :: Input Number -> Args -> Args
threadPoolGetQueueSize value (Args values) = Args (Object.insert "thread_pool_get_queue_size" (inputJson value) values)

threadPoolGetSize :: Input Number -> Args -> Args
threadPoolGetSize value (Args values) = Args (Object.insert "thread_pool_get_size" (inputJson value) values)

threadPoolSearchQueueSize :: Input Number -> Args -> Args
threadPoolSearchQueueSize value (Args values) = Args (Object.insert "thread_pool_search_queue_size" (inputJson value) values)

threadPoolSearchSize :: Input Number -> Args -> Args
threadPoolSearchSize value (Args values) = Args (Object.insert "thread_pool_search_size" (inputJson value) values)

threadPoolSearchThrottledQueueSize :: Input Number -> Args -> Args
threadPoolSearchThrottledQueueSize value (Args values) = Args (Object.insert "thread_pool_search_throttled_queue_size" (inputJson value) values)

threadPoolSearchThrottledSize :: Input Number -> Args -> Args
threadPoolSearchThrottledSize value (Args values) = Args (Object.insert "thread_pool_search_throttled_size" (inputJson value) values)

threadPoolWriteQueueSize :: Input Number -> Args -> Args
threadPoolWriteQueueSize value (Args values) = Args (Object.insert "thread_pool_write_queue_size" (inputJson value) values)

threadPoolWriteSize :: Input Number -> Args -> Args
threadPoolWriteSize value (Args values) = Args (Object.insert "thread_pool_write_size" (inputJson value) values)

type DatabaseOpensearchConfig =
  { resource :: Resource DatabaseOpensearchConfigResource
  , actionAutoCreateIndexEnabled :: Expr Boolean
  , actionDestructiveRequiresName :: Expr Boolean
  , clusterId :: Expr String
  , clusterMaxShardsPerNode :: Expr Number
  , clusterRoutingAllocationNodeConcurrentRecoveries :: Expr Number
  , enableSecurityAudit :: Expr Boolean
  , httpMaxContentLengthBytes :: Expr Number
  , httpMaxHeaderSizeBytes :: Expr Number
  , httpMaxInitialLineLengthBytes :: Expr Number
  , id :: Expr String
  , indicesFielddataCacheSizePercentage :: Expr Number
  , indicesMemoryIndexBufferSizePercentage :: Expr Number
  , indicesMemoryMaxIndexBufferSizeMb :: Expr Number
  , indicesMemoryMinIndexBufferSizeMb :: Expr Number
  , indicesQueriesCacheSizePercentage :: Expr Number
  , indicesQueryBoolMaxClauseCount :: Expr Number
  , indicesRecoveryMaxConcurrentFileChunks :: Expr Number
  , indicesRecoveryMaxMbPerSec :: Expr Number
  , ismEnabled :: Expr Boolean
  , ismHistoryEnabled :: Expr Boolean
  , ismHistoryMaxAgeHours :: Expr Number
  , ismHistoryMaxDocs :: Expr Number
  , ismHistoryRolloverCheckPeriodHours :: Expr Number
  , ismHistoryRolloverRetentionPeriodDays :: Expr Number
  , overrideMainResponseVersion :: Expr Boolean
  , pluginsAlertingFilterByBackendRolesEnabled :: Expr Boolean
  , reindexRemoteWhitelist :: Expr (Array String)
  , scriptMaxCompilationsRate :: Expr String
  , searchMaxBuckets :: Expr Number
  , threadPoolAnalyzeQueueSize :: Expr Number
  , threadPoolAnalyzeSize :: Expr Number
  , threadPoolForceMergeSize :: Expr Number
  , threadPoolGetQueueSize :: Expr Number
  , threadPoolGetSize :: Expr Number
  , threadPoolSearchQueueSize :: Expr Number
  , threadPoolSearchSize :: Expr Number
  , threadPoolSearchThrottledQueueSize :: Expr Number
  , threadPoolSearchThrottledSize :: Expr Number
  , threadPoolWriteQueueSize :: Expr Number
  , threadPoolWriteSize :: Expr Number
  }

create :: String -> Args -> Infra DatabaseOpensearchConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_opensearch_config" logicalName values
  pure
    { resource: handle
    , actionAutoCreateIndexEnabled: resourceAttr handle [ "action_auto_create_index_enabled" ]
    , actionDestructiveRequiresName: resourceAttr handle [ "action_destructive_requires_name" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , clusterMaxShardsPerNode: resourceAttr handle [ "cluster_max_shards_per_node" ]
    , clusterRoutingAllocationNodeConcurrentRecoveries: resourceAttr handle [ "cluster_routing_allocation_node_concurrent_recoveries" ]
    , enableSecurityAudit: resourceAttr handle [ "enable_security_audit" ]
    , httpMaxContentLengthBytes: resourceAttr handle [ "http_max_content_length_bytes" ]
    , httpMaxHeaderSizeBytes: resourceAttr handle [ "http_max_header_size_bytes" ]
    , httpMaxInitialLineLengthBytes: resourceAttr handle [ "http_max_initial_line_length_bytes" ]
    , id: resourceAttr handle [ "id" ]
    , indicesFielddataCacheSizePercentage: resourceAttr handle [ "indices_fielddata_cache_size_percentage" ]
    , indicesMemoryIndexBufferSizePercentage: resourceAttr handle [ "indices_memory_index_buffer_size_percentage" ]
    , indicesMemoryMaxIndexBufferSizeMb: resourceAttr handle [ "indices_memory_max_index_buffer_size_mb" ]
    , indicesMemoryMinIndexBufferSizeMb: resourceAttr handle [ "indices_memory_min_index_buffer_size_mb" ]
    , indicesQueriesCacheSizePercentage: resourceAttr handle [ "indices_queries_cache_size_percentage" ]
    , indicesQueryBoolMaxClauseCount: resourceAttr handle [ "indices_query_bool_max_clause_count" ]
    , indicesRecoveryMaxConcurrentFileChunks: resourceAttr handle [ "indices_recovery_max_concurrent_file_chunks" ]
    , indicesRecoveryMaxMbPerSec: resourceAttr handle [ "indices_recovery_max_mb_per_sec" ]
    , ismEnabled: resourceAttr handle [ "ism_enabled" ]
    , ismHistoryEnabled: resourceAttr handle [ "ism_history_enabled" ]
    , ismHistoryMaxAgeHours: resourceAttr handle [ "ism_history_max_age_hours" ]
    , ismHistoryMaxDocs: resourceAttr handle [ "ism_history_max_docs" ]
    , ismHistoryRolloverCheckPeriodHours: resourceAttr handle [ "ism_history_rollover_check_period_hours" ]
    , ismHistoryRolloverRetentionPeriodDays: resourceAttr handle [ "ism_history_rollover_retention_period_days" ]
    , overrideMainResponseVersion: resourceAttr handle [ "override_main_response_version" ]
    , pluginsAlertingFilterByBackendRolesEnabled: resourceAttr handle [ "plugins_alerting_filter_by_backend_roles_enabled" ]
    , reindexRemoteWhitelist: resourceAttr handle [ "reindex_remote_whitelist" ]
    , scriptMaxCompilationsRate: resourceAttr handle [ "script_max_compilations_rate" ]
    , searchMaxBuckets: resourceAttr handle [ "search_max_buckets" ]
    , threadPoolAnalyzeQueueSize: resourceAttr handle [ "thread_pool_analyze_queue_size" ]
    , threadPoolAnalyzeSize: resourceAttr handle [ "thread_pool_analyze_size" ]
    , threadPoolForceMergeSize: resourceAttr handle [ "thread_pool_force_merge_size" ]
    , threadPoolGetQueueSize: resourceAttr handle [ "thread_pool_get_queue_size" ]
    , threadPoolGetSize: resourceAttr handle [ "thread_pool_get_size" ]
    , threadPoolSearchQueueSize: resourceAttr handle [ "thread_pool_search_queue_size" ]
    , threadPoolSearchSize: resourceAttr handle [ "thread_pool_search_size" ]
    , threadPoolSearchThrottledQueueSize: resourceAttr handle [ "thread_pool_search_throttled_queue_size" ]
    , threadPoolSearchThrottledSize: resourceAttr handle [ "thread_pool_search_throttled_size" ]
    , threadPoolWriteQueueSize: resourceAttr handle [ "thread_pool_write_queue_size" ]
    , threadPoolWriteSize: resourceAttr handle [ "thread_pool_write_size" ]
    }
