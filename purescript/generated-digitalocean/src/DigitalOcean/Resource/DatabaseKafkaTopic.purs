module DigitalOcean.Resource.DatabaseKafkaTopic
  ( Args
  , Required
  , DatabaseKafkaTopic
  , DatabaseKafkaTopicResource
  , args
  , create
  , Config
  , ConfigRequired
  , configArgs
  , configCleanupPolicy
  , configCompressionType
  , configDeleteRetentionMs
  , configFileDeleteDelayMs
  , configFlushMessages
  , configFlushMs
  , configIndexIntervalBytes
  , configMaxCompactionLagMs
  , configMaxMessageBytes
  , configMessageDownConversionEnable
  , configMessageFormatVersion
  , configMessageTimestampDifferenceMaxMs
  , configMessageTimestampType
  , configMinCleanableDirtyRatio
  , configMinCompactionLagMs
  , configMinInsyncReplicas
  , configPreallocate
  , configRetentionBytes
  , configRetentionMs
  , configSegmentBytes
  , configSegmentIndexBytes
  , configSegmentJitterMs
  , configSegmentMs
  , config
  , id
  , partitionCount
  , replicationFactor
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DatabaseKafkaTopicResource

newtype Config = Config InputObject

type ConfigRequired =
  {
  }

configArgs :: ConfigRequired -> Config
configArgs _ = Config (inputObject
  [
  ])

configCleanupPolicy :: Input String -> Config -> Config
configCleanupPolicy value (Config values) = Config (insertInputField "cleanup_policy" (inputJson value) values)

configCompressionType :: Input String -> Config -> Config
configCompressionType value (Config values) = Config (insertInputField "compression_type" (inputJson value) values)

configDeleteRetentionMs :: Input String -> Config -> Config
configDeleteRetentionMs value (Config values) = Config (insertInputField "delete_retention_ms" (inputJson value) values)

configFileDeleteDelayMs :: Input String -> Config -> Config
configFileDeleteDelayMs value (Config values) = Config (insertInputField "file_delete_delay_ms" (inputJson value) values)

configFlushMessages :: Input String -> Config -> Config
configFlushMessages value (Config values) = Config (insertInputField "flush_messages" (inputJson value) values)

configFlushMs :: Input String -> Config -> Config
configFlushMs value (Config values) = Config (insertInputField "flush_ms" (inputJson value) values)

configIndexIntervalBytes :: Input String -> Config -> Config
configIndexIntervalBytes value (Config values) = Config (insertInputField "index_interval_bytes" (inputJson value) values)

configMaxCompactionLagMs :: Input String -> Config -> Config
configMaxCompactionLagMs value (Config values) = Config (insertInputField "max_compaction_lag_ms" (inputJson value) values)

configMaxMessageBytes :: Input String -> Config -> Config
configMaxMessageBytes value (Config values) = Config (insertInputField "max_message_bytes" (inputJson value) values)

configMessageDownConversionEnable :: Input Boolean -> Config -> Config
configMessageDownConversionEnable value (Config values) = Config (insertInputField "message_down_conversion_enable" (inputJson value) values)

configMessageFormatVersion :: Input String -> Config -> Config
configMessageFormatVersion value (Config values) = Config (insertInputField "message_format_version" (inputJson value) values)

configMessageTimestampDifferenceMaxMs :: Input String -> Config -> Config
configMessageTimestampDifferenceMaxMs value (Config values) = Config (insertInputField "message_timestamp_difference_max_ms" (inputJson value) values)

configMessageTimestampType :: Input String -> Config -> Config
configMessageTimestampType value (Config values) = Config (insertInputField "message_timestamp_type" (inputJson value) values)

configMinCleanableDirtyRatio :: Input Number -> Config -> Config
configMinCleanableDirtyRatio value (Config values) = Config (insertInputField "min_cleanable_dirty_ratio" (inputJson value) values)

configMinCompactionLagMs :: Input String -> Config -> Config
configMinCompactionLagMs value (Config values) = Config (insertInputField "min_compaction_lag_ms" (inputJson value) values)

configMinInsyncReplicas :: Input Number -> Config -> Config
configMinInsyncReplicas value (Config values) = Config (insertInputField "min_insync_replicas" (inputJson value) values)

configPreallocate :: Input Boolean -> Config -> Config
configPreallocate value (Config values) = Config (insertInputField "preallocate" (inputJson value) values)

configRetentionBytes :: Input String -> Config -> Config
configRetentionBytes value (Config values) = Config (insertInputField "retention_bytes" (inputJson value) values)

configRetentionMs :: Input String -> Config -> Config
configRetentionMs value (Config values) = Config (insertInputField "retention_ms" (inputJson value) values)

configSegmentBytes :: Input String -> Config -> Config
configSegmentBytes value (Config values) = Config (insertInputField "segment_bytes" (inputJson value) values)

configSegmentIndexBytes :: Input String -> Config -> Config
configSegmentIndexBytes value (Config values) = Config (insertInputField "segment_index_bytes" (inputJson value) values)

configSegmentJitterMs :: Input String -> Config -> Config
configSegmentJitterMs value (Config values) = Config (insertInputField "segment_jitter_ms" (inputJson value) values)

configSegmentMs :: Input String -> Config -> Config
configSegmentMs value (Config values) = Config (insertInputField "segment_ms" (inputJson value) values)

configJson :: Config -> Json
configJson (Config values) = inputObjectJson values

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

config :: Array Config -> Args -> Args
config value (Args values) = Args (insertInputField "config" (arrayExprJson (map configJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

partitionCount :: Input Number -> Args -> Args
partitionCount value (Args values) = Args (insertInputField "partition_count" (inputJson value) values)

replicationFactor :: Input Number -> Args -> Args
replicationFactor value (Args values) = Args (insertInputField "replication_factor" (inputJson value) values)

type DatabaseKafkaTopic =
  { resource :: Resource DatabaseKafkaTopicResource
  , clusterId :: Expr String
  , id :: Expr String
  , name :: Expr String
  , partitionCount :: Expr Number
  , replicationFactor :: Expr Number
  , state :: Expr String
  }

create :: String -> Args -> Infra DatabaseKafkaTopic
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_kafka_topic" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , partitionCount: resourceAttr handle [ "partition_count" ]
    , replicationFactor: resourceAttr handle [ "replication_factor" ]
    , state: resourceAttr handle [ "state" ]
    }
