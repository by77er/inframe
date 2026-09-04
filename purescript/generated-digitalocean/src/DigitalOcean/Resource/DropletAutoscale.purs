module DigitalOcean.Resource.DropletAutoscale
  ( Args
  , Required
  , DropletAutoscale
  , DropletAutoscaleResource
  , args
  , create
  , Config
  , ConfigRequired
  , configArgs
  , configCooldownMinutes
  , configMaxInstances
  , configMinInstances
  , configTargetCpuUtilization
  , configTargetMemoryUtilization
  , configTargetNumberInstances
  , DropletTemplate
  , DropletTemplateRequired
  , dropletTemplateArgs
  , dropletTemplateIpv6
  , dropletTemplateProjectId
  , dropletTemplatePublicNetworking
  , dropletTemplateTags
  , dropletTemplateUserData
  , dropletTemplateVpcUuid
  , dropletTemplateWithDropletAgent
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DropletAutoscaleResource

newtype Config = Config InputObject

type ConfigRequired =
  {
  }

configArgs :: ConfigRequired -> Config
configArgs _ = Config (inputObject
  [
  ])

configCooldownMinutes :: Input Number -> Config -> Config
configCooldownMinutes value (Config values) = Config (insertInputField "cooldown_minutes" (inputJson value) values)

configMaxInstances :: Input Number -> Config -> Config
configMaxInstances value (Config values) = Config (insertInputField "max_instances" (inputJson value) values)

configMinInstances :: Input Number -> Config -> Config
configMinInstances value (Config values) = Config (insertInputField "min_instances" (inputJson value) values)

configTargetCpuUtilization :: Input Number -> Config -> Config
configTargetCpuUtilization value (Config values) = Config (insertInputField "target_cpu_utilization" (inputJson value) values)

configTargetMemoryUtilization :: Input Number -> Config -> Config
configTargetMemoryUtilization value (Config values) = Config (insertInputField "target_memory_utilization" (inputJson value) values)

configTargetNumberInstances :: Input Number -> Config -> Config
configTargetNumberInstances value (Config values) = Config (insertInputField "target_number_instances" (inputJson value) values)

configJson :: Config -> Json
configJson (Config values) = inputObjectJson values

newtype DropletTemplate = DropletTemplate InputObject

type DropletTemplateRequired =
  { image :: Input String
  , region :: Input String
  , size :: Input String
  , sshKeys :: Input (Array String)
  }

dropletTemplateArgs :: DropletTemplateRequired -> DropletTemplate
dropletTemplateArgs required = DropletTemplate (inputObject
  [ Tuple "image" (inputJson required.image)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  , Tuple "ssh_keys" (inputJson required.sshKeys)
  ])

dropletTemplateIpv6 :: Input Boolean -> DropletTemplate -> DropletTemplate
dropletTemplateIpv6 value (DropletTemplate values) = DropletTemplate (insertInputField "ipv6" (inputJson value) values)

dropletTemplateProjectId :: Input String -> DropletTemplate -> DropletTemplate
dropletTemplateProjectId value (DropletTemplate values) = DropletTemplate (insertInputField "project_id" (inputJson value) values)

dropletTemplatePublicNetworking :: Input Boolean -> DropletTemplate -> DropletTemplate
dropletTemplatePublicNetworking value (DropletTemplate values) = DropletTemplate (insertInputField "public_networking" (inputJson value) values)

dropletTemplateTags :: Input (Array String) -> DropletTemplate -> DropletTemplate
dropletTemplateTags value (DropletTemplate values) = DropletTemplate (insertInputField "tags" (inputJson value) values)

dropletTemplateUserData :: Input String -> DropletTemplate -> DropletTemplate
dropletTemplateUserData value (DropletTemplate values) = DropletTemplate (insertInputField "user_data" (inputJson value) values)

dropletTemplateVpcUuid :: Input String -> DropletTemplate -> DropletTemplate
dropletTemplateVpcUuid value (DropletTemplate values) = DropletTemplate (insertInputField "vpc_uuid" (inputJson value) values)

dropletTemplateWithDropletAgent :: Input Boolean -> DropletTemplate -> DropletTemplate
dropletTemplateWithDropletAgent value (DropletTemplate values) = DropletTemplate (insertInputField "with_droplet_agent" (inputJson value) values)

dropletTemplateJson :: DropletTemplate -> Json
dropletTemplateJson (DropletTemplate values) = inputObjectJson values

type Required =
  { config :: Array Config
  , dropletTemplate :: Array DropletTemplate
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "config" (arrayExprJson (map configJson required.config))
  , Tuple "droplet_template" (arrayExprJson (map dropletTemplateJson required.dropletTemplate))
  , Tuple "name" (inputJson required.name)
  ])

type DropletAutoscale =
  { resource :: Resource DropletAutoscaleResource
  , createdAt :: Expr String
  , currentUtilization :: Expr (Array ({ cpu :: Number, memory :: Number }))
  , id :: Expr String
  , name :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  }

create :: String -> Args -> Infra DropletAutoscale
create logicalName (Args values) = do
  handle <- addResource "digitalocean_droplet_autoscale" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , currentUtilization: resourceAttr handle [ "current_utilization" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , status: resourceAttr handle [ "status" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    }
