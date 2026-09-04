module DigitalOcean.Resource.KubernetesNodePool
  ( Args
  , Required
  , KubernetesNodePool
  , KubernetesNodePoolResource
  , args
  , create
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

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data KubernetesNodePoolResource

type Required =
  { clusterId :: Input String
  , name :: Input String
  , size :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  , Tuple "size" (inputJson required.size)
  ])

autoScale :: Input Boolean -> Args -> Args
autoScale value (Args values) = Args (Object.insert "auto_scale" (inputJson value) values)

gpuPartitionMode :: Input String -> Args -> Args
gpuPartitionMode value (Args values) = Args (Object.insert "gpu_partition_mode" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

labels :: Input Json -> Args -> Args
labels value (Args values) = Args (Object.insert "labels" (inputJson value) values)

maxNodes :: Input Number -> Args -> Args
maxNodes value (Args values) = Args (Object.insert "max_nodes" (inputJson value) values)

minNodes :: Input Number -> Args -> Args
minNodes value (Args values) = Args (Object.insert "min_nodes" (inputJson value) values)

nodeCount :: Input Number -> Args -> Args
nodeCount value (Args values) = Args (Object.insert "node_count" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

taint :: Input (Array ({ effect :: String, key :: String, value :: String })) -> Args -> Args
taint value (Args values) = Args (Object.insert "taint" (inputJson value) values)

timeouts :: Input ({ create :: String, delete :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

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
