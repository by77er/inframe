module DigitalOcean.Resource.DatabaseUser
  ( Args
  , Required
  , DatabaseUser
  , DatabaseUserResource
  , args
  , create
  , id
  , mysqlAuthPlugin
  , settings
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseUserResource

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

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

mysqlAuthPlugin :: Input String -> Args -> Args
mysqlAuthPlugin value (Args values) = Args (Object.insert "mysql_auth_plugin" (inputJson value) values)

settings :: Input (Array ({ acl :: Array ({ id :: String, permission :: String, topic :: String }), opensearchAcl :: Array ({ index :: String, permission :: String }) })) -> Args -> Args
settings value (Args values) = Args (Object.insert "settings" (inputJson value) values)

type DatabaseUser =
  { resource :: Resource DatabaseUserResource
  , accessCert :: Expr String
  , accessKey :: Expr String
  , clusterId :: Expr String
  , id :: Expr String
  , mysqlAuthPlugin :: Expr String
  , name :: Expr String
  , password :: Expr String
  , role_ :: Expr String
  }

create :: String -> Args -> Infra DatabaseUser
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_user" logicalName values
  pure
    { resource: handle
    , accessCert: resourceAttr handle [ "access_cert" ]
    , accessKey: resourceAttr handle [ "access_key" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , mysqlAuthPlugin: resourceAttr handle [ "mysql_auth_plugin" ]
    , name: resourceAttr handle [ "name" ]
    , password: resourceAttr handle [ "password" ]
    , role_: resourceAttr handle [ "role" ]
    }
