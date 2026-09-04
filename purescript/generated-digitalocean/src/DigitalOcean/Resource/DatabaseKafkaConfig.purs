module DigitalOcean.Resource.DatabaseKafkaConfig
  ( Args
  , Required
  , DatabaseKafkaConfig
  , DatabaseKafkaConfigResource
  , args
  , create
  , autoCreateTopicsEnable
  , groupInitialRebalanceDelayMs
  , groupMaxSessionTimeoutMs
  , groupMinSessionTimeoutMs
  , id
  , logCleanerDeleteRetentionMs
  , logCleanerMinCompactionLagMs
  , logFlushIntervalMs
  , logIndexIntervalBytes
  , logMessageDownconversionEnable
  , logMessageTimestampDifferenceMaxMs
  , logPreallocate
  , logRetentionBytes
  , logRetentionHours
  , logRetentionMs
  , logRollJitterMs
  , logSegmentDeleteDelayMs
  , messageMaxBytes
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseKafkaConfigResource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

autoCreateTopicsEnable :: Input Boolean -> Args -> Args
autoCreateTopicsEnable value (Args values) = Args (insertInputField "auto_create_topics_enable" (inputJson value) values)

groupInitialRebalanceDelayMs :: Input Number -> Args -> Args
groupInitialRebalanceDelayMs value (Args values) = Args (insertInputField "group_initial_rebalance_delay_ms" (inputJson value) values)

groupMaxSessionTimeoutMs :: Input Number -> Args -> Args
groupMaxSessionTimeoutMs value (Args values) = Args (insertInputField "group_max_session_timeout_ms" (inputJson value) values)

groupMinSessionTimeoutMs :: Input Number -> Args -> Args
groupMinSessionTimeoutMs value (Args values) = Args (insertInputField "group_min_session_timeout_ms" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

logCleanerDeleteRetentionMs :: Input Number -> Args -> Args
logCleanerDeleteRetentionMs value (Args values) = Args (insertInputField "log_cleaner_delete_retention_ms" (inputJson value) values)

logCleanerMinCompactionLagMs :: Input String -> Args -> Args
logCleanerMinCompactionLagMs value (Args values) = Args (insertInputField "log_cleaner_min_compaction_lag_ms" (inputJson value) values)

logFlushIntervalMs :: Input String -> Args -> Args
logFlushIntervalMs value (Args values) = Args (insertInputField "log_flush_interval_ms" (inputJson value) values)

logIndexIntervalBytes :: Input Number -> Args -> Args
logIndexIntervalBytes value (Args values) = Args (insertInputField "log_index_interval_bytes" (inputJson value) values)

logMessageDownconversionEnable :: Input Boolean -> Args -> Args
logMessageDownconversionEnable value (Args values) = Args (insertInputField "log_message_downconversion_enable" (inputJson value) values)

logMessageTimestampDifferenceMaxMs :: Input String -> Args -> Args
logMessageTimestampDifferenceMaxMs value (Args values) = Args (insertInputField "log_message_timestamp_difference_max_ms" (inputJson value) values)

logPreallocate :: Input Boolean -> Args -> Args
logPreallocate value (Args values) = Args (insertInputField "log_preallocate" (inputJson value) values)

logRetentionBytes :: Input String -> Args -> Args
logRetentionBytes value (Args values) = Args (insertInputField "log_retention_bytes" (inputJson value) values)

logRetentionHours :: Input Number -> Args -> Args
logRetentionHours value (Args values) = Args (insertInputField "log_retention_hours" (inputJson value) values)

logRetentionMs :: Input String -> Args -> Args
logRetentionMs value (Args values) = Args (insertInputField "log_retention_ms" (inputJson value) values)

logRollJitterMs :: Input String -> Args -> Args
logRollJitterMs value (Args values) = Args (insertInputField "log_roll_jitter_ms" (inputJson value) values)

logSegmentDeleteDelayMs :: Input Number -> Args -> Args
logSegmentDeleteDelayMs value (Args values) = Args (insertInputField "log_segment_delete_delay_ms" (inputJson value) values)

messageMaxBytes :: Input Number -> Args -> Args
messageMaxBytes value (Args values) = Args (insertInputField "message_max_bytes" (inputJson value) values)

type DatabaseKafkaConfig =
  { resource :: Resource DatabaseKafkaConfigResource
  , autoCreateTopicsEnable :: Expr Boolean
  , clusterId :: Expr String
  , groupInitialRebalanceDelayMs :: Expr Number
  , groupMaxSessionTimeoutMs :: Expr Number
  , groupMinSessionTimeoutMs :: Expr Number
  , id :: Expr String
  , logCleanerDeleteRetentionMs :: Expr Number
  , logCleanerMinCompactionLagMs :: Expr String
  , logFlushIntervalMs :: Expr String
  , logIndexIntervalBytes :: Expr Number
  , logMessageDownconversionEnable :: Expr Boolean
  , logMessageTimestampDifferenceMaxMs :: Expr String
  , logPreallocate :: Expr Boolean
  , logRetentionBytes :: Expr String
  , logRetentionHours :: Expr Number
  , logRetentionMs :: Expr String
  , logRollJitterMs :: Expr String
  , logSegmentDeleteDelayMs :: Expr Number
  , messageMaxBytes :: Expr Number
  }

create :: String -> Args -> Infra DatabaseKafkaConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_kafka_config" logicalName values
  pure
    { resource: handle
    , autoCreateTopicsEnable: resourceAttr handle [ "auto_create_topics_enable" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , groupInitialRebalanceDelayMs: resourceAttr handle [ "group_initial_rebalance_delay_ms" ]
    , groupMaxSessionTimeoutMs: resourceAttr handle [ "group_max_session_timeout_ms" ]
    , groupMinSessionTimeoutMs: resourceAttr handle [ "group_min_session_timeout_ms" ]
    , id: resourceAttr handle [ "id" ]
    , logCleanerDeleteRetentionMs: resourceAttr handle [ "log_cleaner_delete_retention_ms" ]
    , logCleanerMinCompactionLagMs: resourceAttr handle [ "log_cleaner_min_compaction_lag_ms" ]
    , logFlushIntervalMs: resourceAttr handle [ "log_flush_interval_ms" ]
    , logIndexIntervalBytes: resourceAttr handle [ "log_index_interval_bytes" ]
    , logMessageDownconversionEnable: resourceAttr handle [ "log_message_downconversion_enable" ]
    , logMessageTimestampDifferenceMaxMs: resourceAttr handle [ "log_message_timestamp_difference_max_ms" ]
    , logPreallocate: resourceAttr handle [ "log_preallocate" ]
    , logRetentionBytes: resourceAttr handle [ "log_retention_bytes" ]
    , logRetentionHours: resourceAttr handle [ "log_retention_hours" ]
    , logRetentionMs: resourceAttr handle [ "log_retention_ms" ]
    , logRollJitterMs: resourceAttr handle [ "log_roll_jitter_ms" ]
    , logSegmentDeleteDelayMs: resourceAttr handle [ "log_segment_delete_delay_ms" ]
    , messageMaxBytes: resourceAttr handle [ "message_max_bytes" ]
    }
