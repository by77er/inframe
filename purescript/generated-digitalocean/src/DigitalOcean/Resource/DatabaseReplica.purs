module DigitalOcean.Resource.DatabaseReplica
  ( Args
  , Required
  , DatabaseReplica
  , DatabaseReplicaResource
  , args
  , create
  , id
  , privateNetworkUuid
  , region
  , size
  , storageSizeMib
  , tags
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseReplicaResource

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

privateNetworkUuid :: Input String -> Args -> Args
privateNetworkUuid value (Args values) = Args (insertInputField "private_network_uuid" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

size :: Input String -> Args -> Args
size value (Args values) = Args (insertInputField "size" (inputJson value) values)

storageSizeMib :: Input String -> Args -> Args
storageSizeMib value (Args values) = Args (insertInputField "storage_size_mib" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

type DatabaseReplica =
  { resource :: Resource DatabaseReplicaResource
  , clusterId :: Expr String
  , database :: Expr String
  , host :: Expr String
  , id :: Expr String
  , name :: Expr String
  , password :: Expr String
  , port :: Expr Number
  , privateHost :: Expr String
  , privateNetworkUuid :: Expr String
  , privateUri :: Expr String
  , region :: Expr String
  , size :: Expr String
  , storageSizeMib :: Expr String
  , tags :: Expr (Array String)
  , uri :: Expr String
  , user :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra DatabaseReplica
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_replica" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , database: resourceAttr handle [ "database" ]
    , host: resourceAttr handle [ "host" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , password: resourceAttr handle [ "password" ]
    , port: resourceAttr handle [ "port" ]
    , privateHost: resourceAttr handle [ "private_host" ]
    , privateNetworkUuid: resourceAttr handle [ "private_network_uuid" ]
    , privateUri: resourceAttr handle [ "private_uri" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , storageSizeMib: resourceAttr handle [ "storage_size_mib" ]
    , tags: resourceAttr handle [ "tags" ]
    , uri: resourceAttr handle [ "uri" ]
    , user: resourceAttr handle [ "user" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
