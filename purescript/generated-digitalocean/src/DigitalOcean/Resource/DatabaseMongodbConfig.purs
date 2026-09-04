module DigitalOcean.Resource.DatabaseMongodbConfig
  ( Args
  , Required
  , DatabaseMongodbConfig
  , DatabaseMongodbConfigResource
  , args
  , create
  , defaultReadConcern
  , defaultWriteConcern
  , id
  , slowOpThresholdMs
  , transactionLifetimeLimitSeconds
  , verbosity
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseMongodbConfigResource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

defaultReadConcern :: Input String -> Args -> Args
defaultReadConcern value (Args values) = Args (Object.insert "default_read_concern" (inputJson value) values)

defaultWriteConcern :: Input String -> Args -> Args
defaultWriteConcern value (Args values) = Args (Object.insert "default_write_concern" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

slowOpThresholdMs :: Input Number -> Args -> Args
slowOpThresholdMs value (Args values) = Args (Object.insert "slow_op_threshold_ms" (inputJson value) values)

transactionLifetimeLimitSeconds :: Input Number -> Args -> Args
transactionLifetimeLimitSeconds value (Args values) = Args (Object.insert "transaction_lifetime_limit_seconds" (inputJson value) values)

verbosity :: Input Number -> Args -> Args
verbosity value (Args values) = Args (Object.insert "verbosity" (inputJson value) values)

type DatabaseMongodbConfig =
  { resource :: Resource DatabaseMongodbConfigResource
  , clusterId :: Expr String
  , defaultReadConcern :: Expr String
  , defaultWriteConcern :: Expr String
  , id :: Expr String
  , slowOpThresholdMs :: Expr Number
  , transactionLifetimeLimitSeconds :: Expr Number
  , verbosity :: Expr Number
  }

create :: String -> Args -> Infra DatabaseMongodbConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_mongodb_config" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , defaultReadConcern: resourceAttr handle [ "default_read_concern" ]
    , defaultWriteConcern: resourceAttr handle [ "default_write_concern" ]
    , id: resourceAttr handle [ "id" ]
    , slowOpThresholdMs: resourceAttr handle [ "slow_op_threshold_ms" ]
    , transactionLifetimeLimitSeconds: resourceAttr handle [ "transaction_lifetime_limit_seconds" ]
    , verbosity: resourceAttr handle [ "verbosity" ]
    }
