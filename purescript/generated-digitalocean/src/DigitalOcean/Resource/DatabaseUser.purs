module DigitalOcean.Resource.DatabaseUser
  ( Args
  , Required
  , DatabaseUser
  , DatabaseUserResource
  , args
  , create
  , Settings
  , SettingsRequired
  , settingsArgs
  , settingsAcl
  , settingsOpensearchAcl
  , SettingsAcl
  , SettingsAclRequired
  , settingsAclArgs
  , SettingsOpensearchAcl
  , SettingsOpensearchAclRequired
  , settingsOpensearchAclArgs
  , id
  , mysqlAuthPlugin
  , settings
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DatabaseUserResource

newtype Settings = Settings InputObject

type SettingsRequired =
  {
  }

settingsArgs :: SettingsRequired -> Settings
settingsArgs _ = Settings (inputObject
  [
  ])

settingsAcl :: Array SettingsAcl -> Settings -> Settings
settingsAcl value (Settings values) = Settings (insertInputField "acl" (arrayExprJson (map settingsAclJson value)) values)

settingsOpensearchAcl :: Array SettingsOpensearchAcl -> Settings -> Settings
settingsOpensearchAcl value (Settings values) = Settings (insertInputField "opensearch_acl" (arrayExprJson (map settingsOpensearchAclJson value)) values)

settingsJson :: Settings -> Json
settingsJson (Settings values) = inputObjectJson values

newtype SettingsAcl = SettingsAcl InputObject

type SettingsAclRequired =
  { permission :: Input String
  , topic :: Input String
  }

settingsAclArgs :: SettingsAclRequired -> SettingsAcl
settingsAclArgs required = SettingsAcl (inputObject
  [ Tuple "permission" (inputJson required.permission)
  , Tuple "topic" (inputJson required.topic)
  ])

settingsAclJson :: SettingsAcl -> Json
settingsAclJson (SettingsAcl values) = inputObjectJson values

newtype SettingsOpensearchAcl = SettingsOpensearchAcl InputObject

type SettingsOpensearchAclRequired =
  { index :: Input String
  , permission :: Input String
  }

settingsOpensearchAclArgs :: SettingsOpensearchAclRequired -> SettingsOpensearchAcl
settingsOpensearchAclArgs required = SettingsOpensearchAcl (inputObject
  [ Tuple "index" (inputJson required.index)
  , Tuple "permission" (inputJson required.permission)
  ])

settingsOpensearchAclJson :: SettingsOpensearchAcl -> Json
settingsOpensearchAclJson (SettingsOpensearchAcl values) = inputObjectJson values

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

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

mysqlAuthPlugin :: Input String -> Args -> Args
mysqlAuthPlugin value (Args values) = Args (insertInputField "mysql_auth_plugin" (inputJson value) values)

settings :: Array Settings -> Args -> Args
settings value (Args values) = Args (insertInputField "settings" (arrayExprJson (map settingsJson value)) values)

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
