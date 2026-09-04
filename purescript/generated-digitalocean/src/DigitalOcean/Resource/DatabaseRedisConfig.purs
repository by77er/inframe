module DigitalOcean.Resource.DatabaseRedisConfig
  ( Args
  , Required
  , DatabaseRedisConfig
  , DatabaseRedisConfigResource
  , args
  , create
  , aclChannelsDefault
  , id
  , ioThreads
  , lfuDecayTime
  , lfuLogFactor
  , maxmemoryPolicy
  , notifyKeyspaceEvents
  , numberOfDatabases
  , persistence
  , pubsubClientOutputBufferLimit
  , ssl
  , timeout
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseRedisConfigResource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

aclChannelsDefault :: Input String -> Args -> Args
aclChannelsDefault value (Args values) = Args (Object.insert "acl_channels_default" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ioThreads :: Input Number -> Args -> Args
ioThreads value (Args values) = Args (Object.insert "io_threads" (inputJson value) values)

lfuDecayTime :: Input Number -> Args -> Args
lfuDecayTime value (Args values) = Args (Object.insert "lfu_decay_time" (inputJson value) values)

lfuLogFactor :: Input Number -> Args -> Args
lfuLogFactor value (Args values) = Args (Object.insert "lfu_log_factor" (inputJson value) values)

maxmemoryPolicy :: Input String -> Args -> Args
maxmemoryPolicy value (Args values) = Args (Object.insert "maxmemory_policy" (inputJson value) values)

notifyKeyspaceEvents :: Input String -> Args -> Args
notifyKeyspaceEvents value (Args values) = Args (Object.insert "notify_keyspace_events" (inputJson value) values)

numberOfDatabases :: Input Number -> Args -> Args
numberOfDatabases value (Args values) = Args (Object.insert "number_of_databases" (inputJson value) values)

persistence :: Input String -> Args -> Args
persistence value (Args values) = Args (Object.insert "persistence" (inputJson value) values)

pubsubClientOutputBufferLimit :: Input Number -> Args -> Args
pubsubClientOutputBufferLimit value (Args values) = Args (Object.insert "pubsub_client_output_buffer_limit" (inputJson value) values)

ssl :: Input Boolean -> Args -> Args
ssl value (Args values) = Args (Object.insert "ssl" (inputJson value) values)

timeout :: Input Number -> Args -> Args
timeout value (Args values) = Args (Object.insert "timeout" (inputJson value) values)

type DatabaseRedisConfig =
  { resource :: Resource DatabaseRedisConfigResource
  , aclChannelsDefault :: Expr String
  , clusterId :: Expr String
  , id :: Expr String
  , ioThreads :: Expr Number
  , lfuDecayTime :: Expr Number
  , lfuLogFactor :: Expr Number
  , maxmemoryPolicy :: Expr String
  , notifyKeyspaceEvents :: Expr String
  , numberOfDatabases :: Expr Number
  , persistence :: Expr String
  , pubsubClientOutputBufferLimit :: Expr Number
  , ssl :: Expr Boolean
  , timeout :: Expr Number
  }

create :: String -> Args -> Infra DatabaseRedisConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_redis_config" logicalName values
  pure
    { resource: handle
    , aclChannelsDefault: resourceAttr handle [ "acl_channels_default" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , ioThreads: resourceAttr handle [ "io_threads" ]
    , lfuDecayTime: resourceAttr handle [ "lfu_decay_time" ]
    , lfuLogFactor: resourceAttr handle [ "lfu_log_factor" ]
    , maxmemoryPolicy: resourceAttr handle [ "maxmemory_policy" ]
    , notifyKeyspaceEvents: resourceAttr handle [ "notify_keyspace_events" ]
    , numberOfDatabases: resourceAttr handle [ "number_of_databases" ]
    , persistence: resourceAttr handle [ "persistence" ]
    , pubsubClientOutputBufferLimit: resourceAttr handle [ "pubsub_client_output_buffer_limit" ]
    , ssl: resourceAttr handle [ "ssl" ]
    , timeout: resourceAttr handle [ "timeout" ]
    }
