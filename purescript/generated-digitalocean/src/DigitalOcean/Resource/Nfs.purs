module DigitalOcean.Resource.Nfs
  ( Args
  , Required
  , Nfs
  , NfsResource
  , args
  , create
  , id
  , performanceTier
  , tags
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data NfsResource

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input Number
  , vpcId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  , Tuple "vpc_id" (inputJson required.vpcId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

performanceTier :: Input String -> Args -> Args
performanceTier value (Args values) = Args (insertInputField "performance_tier" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

type Nfs =
  { resource :: Resource NfsResource
  , host :: Expr String
  , id :: Expr String
  , mountPath :: Expr String
  , name :: Expr String
  , performanceTier :: Expr String
  , region :: Expr String
  , size :: Expr Number
  , status :: Expr String
  , tags :: Expr (Array String)
  , vpcId :: Expr String
  , vpcIds :: Expr (Array String)
  }

create :: String -> Args -> Infra Nfs
create logicalName (Args values) = do
  handle <- addResource "digitalocean_nfs" logicalName values
  pure
    { resource: handle
    , host: resourceAttr handle [ "host" ]
    , id: resourceAttr handle [ "id" ]
    , mountPath: resourceAttr handle [ "mount_path" ]
    , name: resourceAttr handle [ "name" ]
    , performanceTier: resourceAttr handle [ "performance_tier" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , status: resourceAttr handle [ "status" ]
    , tags: resourceAttr handle [ "tags" ]
    , vpcId: resourceAttr handle [ "vpc_id" ]
    , vpcIds: resourceAttr handle [ "vpc_ids" ]
    }
