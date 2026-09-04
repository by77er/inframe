module DigitalOcean.Resource.DatabaseOnlineMigration
  ( Args
  , Required
  , DatabaseOnlineMigration
  , DatabaseOnlineMigrationResource
  , args
  , create
  , Source
  , SourceRequired
  , sourceArgs
  , disableSsl
  , ignoreDbs
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DatabaseOnlineMigrationResource

newtype Source = Source InputObject

type SourceRequired =
  { dbName :: Input String
  , host :: Input String
  , password :: Input String
  , port :: Input Number
  , username :: Input String
  }

sourceArgs :: SourceRequired -> Source
sourceArgs required = Source (inputObject
  [ Tuple "db_name" (inputJson required.dbName)
  , Tuple "host" (inputJson required.host)
  , Tuple "password" (inputJson required.password)
  , Tuple "port" (inputJson required.port)
  , Tuple "username" (inputJson required.username)
  ])

sourceJson :: Source -> Json
sourceJson (Source values) = inputObjectJson values

type Required =
  { clusterId :: Input String
  , source :: Array Source
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "source" (arrayExprJson (map sourceJson required.source))
  ])

disableSsl :: Input Boolean -> Args -> Args
disableSsl value (Args values) = Args (insertInputField "disable_ssl" (inputJson value) values)

ignoreDbs :: Input (Array String) -> Args -> Args
ignoreDbs value (Args values) = Args (insertInputField "ignore_dbs" (inputJson value) values)

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
