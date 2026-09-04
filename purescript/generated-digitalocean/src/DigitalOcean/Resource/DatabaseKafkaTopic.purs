module DigitalOcean.Resource.DatabaseKafkaTopic
  ( Args
  , Required
  , DatabaseKafkaTopic
  , DatabaseKafkaTopicResource
  , args
  , create
  , config
  , id
  , partitionCount
  , replicationFactor
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseKafkaTopicResource

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

config :: Input (Array ({ cleanupPolicy :: String, compressionType :: String, deleteRetentionMs :: String, fileDeleteDelayMs :: String, flushMessages :: String, flushMs :: String, indexIntervalBytes :: String, maxCompactionLagMs :: String, maxMessageBytes :: String, messageDownConversionEnable :: Boolean, messageFormatVersion :: String, messageTimestampDifferenceMaxMs :: String, messageTimestampType :: String, minCleanableDirtyRatio :: Number, minCompactionLagMs :: String, minInsyncReplicas :: Number, preallocate :: Boolean, retentionBytes :: String, retentionMs :: String, segmentBytes :: String, segmentIndexBytes :: String, segmentJitterMs :: String, segmentMs :: String })) -> Args -> Args
config value (Args values) = Args (Object.insert "config" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

partitionCount :: Input Number -> Args -> Args
partitionCount value (Args values) = Args (Object.insert "partition_count" (inputJson value) values)

replicationFactor :: Input Number -> Args -> Args
replicationFactor value (Args values) = Args (Object.insert "replication_factor" (inputJson value) values)

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
