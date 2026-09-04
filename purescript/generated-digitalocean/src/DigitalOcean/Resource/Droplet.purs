module DigitalOcean.Resource.Droplet
  ( Args
  , Required
  , Droplet
  , DropletResource
  , args
  , create
  , BackupPolicy
  , BackupPolicyRequired
  , backupPolicyArgs
  , backupPolicyHour
  , backupPolicyPlan
  , backupPolicyWeekday
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , timeoutsDelete
  , timeoutsUpdate
  , backupPolicy
  , backups
  , dropletAgent
  , gpuPartitionMode
  , gracefulShutdown
  , id
  , ipv6
  , ipv6Address
  , monitoring
  , privateNetworking
  , publicNetworking
  , region
  , resizeDisk
  , sshKeys
  , tags
  , timeouts
  , userData
  , volumeIds
  , vpcUuid
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DropletResource

newtype BackupPolicy = BackupPolicy InputObject

type BackupPolicyRequired =
  {
  }

backupPolicyArgs :: BackupPolicyRequired -> BackupPolicy
backupPolicyArgs _ = BackupPolicy (inputObject
  [
  ])

backupPolicyHour :: Input Number -> BackupPolicy -> BackupPolicy
backupPolicyHour value (BackupPolicy values) = BackupPolicy (insertInputField "hour" (inputJson value) values)

backupPolicyPlan :: Input String -> BackupPolicy -> BackupPolicy
backupPolicyPlan value (BackupPolicy values) = BackupPolicy (insertInputField "plan" (inputJson value) values)

backupPolicyWeekday :: Input String -> BackupPolicy -> BackupPolicy
backupPolicyWeekday value (BackupPolicy values) = BackupPolicy (insertInputField "weekday" (inputJson value) values)

backupPolicyJson :: BackupPolicy -> Json
backupPolicyJson (BackupPolicy values) = inputObjectJson values

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsDelete :: Input String -> Timeouts -> Timeouts
timeoutsDelete value (Timeouts values) = Timeouts (insertInputField "delete" (inputJson value) values)

timeoutsUpdate :: Input String -> Timeouts -> Timeouts
timeoutsUpdate value (Timeouts values) = Timeouts (insertInputField "update" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { image :: Input String
  , name :: Input String
  , size :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "image" (inputJson required.image)
  , Tuple "name" (inputJson required.name)
  , Tuple "size" (inputJson required.size)
  ])

backupPolicy :: Array BackupPolicy -> Args -> Args
backupPolicy value (Args values) = Args (insertInputField "backup_policy" (arrayExprJson (map backupPolicyJson value)) values)

backups :: Input Boolean -> Args -> Args
backups value (Args values) = Args (insertInputField "backups" (inputJson value) values)

dropletAgent :: Input Boolean -> Args -> Args
dropletAgent value (Args values) = Args (insertInputField "droplet_agent" (inputJson value) values)

gpuPartitionMode :: Input String -> Args -> Args
gpuPartitionMode value (Args values) = Args (insertInputField "gpu_partition_mode" (inputJson value) values)

gracefulShutdown :: Input Boolean -> Args -> Args
gracefulShutdown value (Args values) = Args (insertInputField "graceful_shutdown" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ipv6 :: Input Boolean -> Args -> Args
ipv6 value (Args values) = Args (insertInputField "ipv6" (inputJson value) values)

ipv6Address :: Input String -> Args -> Args
ipv6Address value (Args values) = Args (insertInputField "ipv6_address" (inputJson value) values)

monitoring :: Input Boolean -> Args -> Args
monitoring value (Args values) = Args (insertInputField "monitoring" (inputJson value) values)

privateNetworking :: Input Boolean -> Args -> Args
privateNetworking value (Args values) = Args (insertInputField "private_networking" (inputJson value) values)

publicNetworking :: Input Boolean -> Args -> Args
publicNetworking value (Args values) = Args (insertInputField "public_networking" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

resizeDisk :: Input Boolean -> Args -> Args
resizeDisk value (Args values) = Args (insertInputField "resize_disk" (inputJson value) values)

sshKeys :: Input (Array String) -> Args -> Args
sshKeys value (Args values) = Args (insertInputField "ssh_keys" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

userData :: Input String -> Args -> Args
userData value (Args values) = Args (insertInputField "user_data" (inputJson value) values)

volumeIds :: Input (Array String) -> Args -> Args
volumeIds value (Args values) = Args (insertInputField "volume_ids" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (insertInputField "vpc_uuid" (inputJson value) values)

type Droplet =
  { resource :: Resource DropletResource
  , backups :: Expr Boolean
  , createdAt :: Expr String
  , disk :: Expr Number
  , dropletAgent :: Expr Boolean
  , gpuPartitionMode :: Expr String
  , gracefulShutdown :: Expr Boolean
  , id :: Expr String
  , image :: Expr String
  , ipv4Address :: Expr String
  , ipv4AddressPrivate :: Expr String
  , ipv6 :: Expr Boolean
  , ipv6Address :: Expr String
  , locked :: Expr Boolean
  , memory :: Expr Number
  , monitoring :: Expr Boolean
  , name :: Expr String
  , priceHourly :: Expr Number
  , priceMonthly :: Expr Number
  , privateNetworking :: Expr Boolean
  , publicNetworking :: Expr Boolean
  , region :: Expr String
  , resizeDisk :: Expr Boolean
  , size :: Expr String
  , sshKeys :: Expr (Array String)
  , status :: Expr String
  , tags :: Expr (Array String)
  , urn :: Expr String
  , userData :: Expr String
  , vcpus :: Expr Number
  , volumeIds :: Expr (Array String)
  , vpcUuid :: Expr String
  }

create :: String -> Args -> Infra Droplet
create logicalName (Args values) = do
  handle <- addResource "digitalocean_droplet" logicalName values
  pure
    { resource: handle
    , backups: resourceAttr handle [ "backups" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , disk: resourceAttr handle [ "disk" ]
    , dropletAgent: resourceAttr handle [ "droplet_agent" ]
    , gpuPartitionMode: resourceAttr handle [ "gpu_partition_mode" ]
    , gracefulShutdown: resourceAttr handle [ "graceful_shutdown" ]
    , id: resourceAttr handle [ "id" ]
    , image: resourceAttr handle [ "image" ]
    , ipv4Address: resourceAttr handle [ "ipv4_address" ]
    , ipv4AddressPrivate: resourceAttr handle [ "ipv4_address_private" ]
    , ipv6: resourceAttr handle [ "ipv6" ]
    , ipv6Address: resourceAttr handle [ "ipv6_address" ]
    , locked: resourceAttr handle [ "locked" ]
    , memory: resourceAttr handle [ "memory" ]
    , monitoring: resourceAttr handle [ "monitoring" ]
    , name: resourceAttr handle [ "name" ]
    , priceHourly: resourceAttr handle [ "price_hourly" ]
    , priceMonthly: resourceAttr handle [ "price_monthly" ]
    , privateNetworking: resourceAttr handle [ "private_networking" ]
    , publicNetworking: resourceAttr handle [ "public_networking" ]
    , region: resourceAttr handle [ "region" ]
    , resizeDisk: resourceAttr handle [ "resize_disk" ]
    , size: resourceAttr handle [ "size" ]
    , sshKeys: resourceAttr handle [ "ssh_keys" ]
    , status: resourceAttr handle [ "status" ]
    , tags: resourceAttr handle [ "tags" ]
    , urn: resourceAttr handle [ "urn" ]
    , userData: resourceAttr handle [ "user_data" ]
    , vcpus: resourceAttr handle [ "vcpus" ]
    , volumeIds: resourceAttr handle [ "volume_ids" ]
    , vpcUuid: resourceAttr handle [ "vpc_uuid" ]
    }
