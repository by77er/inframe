module DigitalOcean.Resource.DatabaseConnectionPool
  ( Args
  , Required
  , DatabaseConnectionPool
  , DatabaseConnectionPoolResource
  , args
  , create
  , id
  , user
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseConnectionPoolResource

type Required =
  { clusterId :: Input String
  , dbName :: Input String
  , mode :: Input String
  , name :: Input String
  , size :: Input Number
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "db_name" (inputJson required.dbName)
  , Tuple "mode" (inputJson required.mode)
  , Tuple "name" (inputJson required.name)
  , Tuple "size" (inputJson required.size)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

user :: Input String -> Args -> Args
user value (Args values) = Args (Object.insert "user" (inputJson value) values)

type DatabaseConnectionPool =
  { resource :: Resource DatabaseConnectionPoolResource
  , clusterId :: Expr String
  , dbName :: Expr String
  , host :: Expr String
  , id :: Expr String
  , mode :: Expr String
  , name :: Expr String
  , password :: Expr String
  , port :: Expr Number
  , privateHost :: Expr String
  , privateUri :: Expr String
  , size :: Expr Number
  , uri :: Expr String
  , user :: Expr String
  }

create :: String -> Args -> Infra DatabaseConnectionPool
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_connection_pool" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , dbName: resourceAttr handle [ "db_name" ]
    , host: resourceAttr handle [ "host" ]
    , id: resourceAttr handle [ "id" ]
    , mode: resourceAttr handle [ "mode" ]
    , name: resourceAttr handle [ "name" ]
    , password: resourceAttr handle [ "password" ]
    , port: resourceAttr handle [ "port" ]
    , privateHost: resourceAttr handle [ "private_host" ]
    , privateUri: resourceAttr handle [ "private_uri" ]
    , size: resourceAttr handle [ "size" ]
    , uri: resourceAttr handle [ "uri" ]
    , user: resourceAttr handle [ "user" ]
    }
