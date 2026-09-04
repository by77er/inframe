module DigitalOcean.Resource.DatabaseValkeyConfig
  ( Args
  , Required
  , DatabaseValkeyConfig
  , DatabaseValkeyConfigResource
  , args
  , create
  , aclChannelsDefault
  , frequentSnapshots
  , id
  , ioThreads
  , lfuDecayTime
  , lfuLogFactor
  , notifyKeyspaceEvents
  , numberOfDatabases
  , persistence
  , pubsubClientOutputBufferLimit
  , ssl
  , timeout
  , valkeyActiveExpireEffort
  , valkeyMaxmemoryPolicy
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseValkeyConfigResource

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

frequentSnapshots :: Input Boolean -> Args -> Args
frequentSnapshots value (Args values) = Args (Object.insert "frequent_snapshots" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ioThreads :: Input Number -> Args -> Args
ioThreads value (Args values) = Args (Object.insert "io_threads" (inputJson value) values)

lfuDecayTime :: Input Number -> Args -> Args
lfuDecayTime value (Args values) = Args (Object.insert "lfu_decay_time" (inputJson value) values)

lfuLogFactor :: Input Number -> Args -> Args
lfuLogFactor value (Args values) = Args (Object.insert "lfu_log_factor" (inputJson value) values)

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

valkeyActiveExpireEffort :: Input Number -> Args -> Args
valkeyActiveExpireEffort value (Args values) = Args (Object.insert "valkey_active_expire_effort" (inputJson value) values)

valkeyMaxmemoryPolicy :: Input String -> Args -> Args
valkeyMaxmemoryPolicy value (Args values) = Args (Object.insert "valkey_maxmemory_policy" (inputJson value) values)

type DatabaseValkeyConfig =
  { resource :: Resource DatabaseValkeyConfigResource
  , aclChannelsDefault :: Expr String
  , clusterId :: Expr String
  , frequentSnapshots :: Expr Boolean
  , id :: Expr String
  , ioThreads :: Expr Number
  , lfuDecayTime :: Expr Number
  , lfuLogFactor :: Expr Number
  , notifyKeyspaceEvents :: Expr String
  , numberOfDatabases :: Expr Number
  , persistence :: Expr String
  , pubsubClientOutputBufferLimit :: Expr Number
  , ssl :: Expr Boolean
  , timeout :: Expr Number
  , valkeyActiveExpireEffort :: Expr Number
  , valkeyMaxmemoryPolicy :: Expr String
  }

create :: String -> Args -> Infra DatabaseValkeyConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_valkey_config" logicalName values
  pure
    { resource: handle
    , aclChannelsDefault: resourceAttr handle [ "acl_channels_default" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , frequentSnapshots: resourceAttr handle [ "frequent_snapshots" ]
    , id: resourceAttr handle [ "id" ]
    , ioThreads: resourceAttr handle [ "io_threads" ]
    , lfuDecayTime: resourceAttr handle [ "lfu_decay_time" ]
    , lfuLogFactor: resourceAttr handle [ "lfu_log_factor" ]
    , notifyKeyspaceEvents: resourceAttr handle [ "notify_keyspace_events" ]
    , numberOfDatabases: resourceAttr handle [ "number_of_databases" ]
    , persistence: resourceAttr handle [ "persistence" ]
    , pubsubClientOutputBufferLimit: resourceAttr handle [ "pubsub_client_output_buffer_limit" ]
    , ssl: resourceAttr handle [ "ssl" ]
    , timeout: resourceAttr handle [ "timeout" ]
    , valkeyActiveExpireEffort: resourceAttr handle [ "valkey_active_expire_effort" ]
    , valkeyMaxmemoryPolicy: resourceAttr handle [ "valkey_maxmemory_policy" ]
    }
