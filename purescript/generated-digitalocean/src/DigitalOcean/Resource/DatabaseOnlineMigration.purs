module DigitalOcean.Resource.DatabaseOnlineMigration
  ( Args
  , Required
  , DatabaseOnlineMigration
  , DatabaseOnlineMigrationResource
  , args
  , create
  , disableSsl
  , ignoreDbs
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseOnlineMigrationResource

type Required =
  { clusterId :: Input String
  , source :: Input (Array ({ dbName :: String, host :: String, password :: String, port :: Number, username :: String }))
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "source" (inputJson required.source)
  ])

disableSsl :: Input Boolean -> Args -> Args
disableSsl value (Args values) = Args (Object.insert "disable_ssl" (inputJson value) values)

ignoreDbs :: Input (Array String) -> Args -> Args
ignoreDbs value (Args values) = Args (Object.insert "ignore_dbs" (inputJson value) values)

type DatabaseOnlineMigration =
  { resource :: Resource DatabaseOnlineMigrationResource
  , clusterId :: Expr String
  , createdAt :: Expr String
  , disableSsl :: Expr Boolean
  , id :: Expr String
  , ignoreDbs :: Expr (Array String)
  , status :: Expr String
  }

create :: String -> Args -> Infra DatabaseOnlineMigration
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_online_migration" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , disableSsl: resourceAttr handle [ "disable_ssl" ]
    , id: resourceAttr handle [ "id" ]
    , ignoreDbs: resourceAttr handle [ "ignore_dbs" ]
    , status: resourceAttr handle [ "status" ]
    }
