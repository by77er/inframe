module DigitalOcean.Resource.KubernetesNodePool
  ( Args
  , Required
  , KubernetesNodePool
  , KubernetesNodePoolResource
  , args
  , create
  , Taint
  , TaintRequired
  , taintArgs
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , timeoutsDelete
  , autoScale
  , gpuPartitionMode
  , id
  , labels
  , maxNodes
  , minNodes
  , nodeCount
  , tags
  , taint
  , timeouts
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data KubernetesNodePoolResource

newtype Taint = Taint InputObject

type TaintRequired =
  { effect :: Input String
  , key :: Input String
  , value :: Input String
  }

taintArgs :: TaintRequired -> Taint
taintArgs required = Taint (inputObject
  [ Tuple "effect" (inputJson required.effect)
  , Tuple "key" (inputJson required.key)
  , Tuple "value" (inputJson required.value)
  ])

taintJson :: Taint -> Json
taintJson (Taint values) = inputObjectJson values

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

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { clusterId :: Input String
  , name :: Input String
  , size :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  , Tuple "size" (inputJson required.size)
  ])

autoScale :: Input Boolean -> Args -> Args
autoScale value (Args values) = Args (insertInputField "auto_scale" (inputJson value) values)

gpuPartitionMode :: Input String -> Args -> Args
gpuPartitionMode value (Args values) = Args (insertInputField "gpu_partition_mode" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

labels :: Input Json -> Args -> Args
labels value (Args values) = Args (insertInputField "labels" (inputJson value) values)

maxNodes :: Input Number -> Args -> Args
maxNodes value (Args values) = Args (insertInputField "max_nodes" (inputJson value) values)

minNodes :: Input Number -> Args -> Args
minNodes value (Args values) = Args (insertInputField "min_nodes" (inputJson value) values)

nodeCount :: Input Number -> Args -> Args
nodeCount value (Args values) = Args (insertInputField "node_count" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

taint :: Array Taint -> Args -> Args
taint value (Args values) = Args (insertInputField "taint" (arrayExprJson (map taintJson value)) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

type KubernetesNodePool =
  { resource :: Resource KubernetesNodePoolResource
  , actualNodeCount :: Expr Number
  , autoScale :: Expr Boolean
  , clusterId :: Expr String
  , gpuPartitionMode :: Expr String
  , id :: Expr String
  , labels :: Expr Json
  , maxNodes :: Expr Number
  , minNodes :: Expr Number
  , name :: Expr String
  , nodeCount :: Expr Number
  , nodes :: Expr (Array ({ createdAt :: String, dropletId :: String, id :: String, name :: String, status :: String, updatedAt :: String }))
  , size :: Expr String
  , tags :: Expr (Array String)
  }

create :: String -> Args -> Infra KubernetesNodePool
create logicalName (Args values) = do
  handle <- addResource "digitalocean_kubernetes_node_pool" logicalName values
  pure
    { resource: handle
    , actualNodeCount: resourceAttr handle [ "actual_node_count" ]
    , autoScale: resourceAttr handle [ "auto_scale" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , gpuPartitionMode: resourceAttr handle [ "gpu_partition_mode" ]
    , id: resourceAttr handle [ "id" ]
    , labels: resourceAttr handle [ "labels" ]
    , maxNodes: resourceAttr handle [ "max_nodes" ]
    , minNodes: resourceAttr handle [ "min_nodes" ]
    , name: resourceAttr handle [ "name" ]
    , nodeCount: resourceAttr handle [ "node_count" ]
    , nodes: resourceAttr handle [ "nodes" ]
    , size: resourceAttr handle [ "size" ]
    , tags: resourceAttr handle [ "tags" ]
    }
