module DigitalOcean.Data.KubernetesCluster
  ( Args
  , Required
  , KubernetesCluster
  , KubernetesClusterDataSource
  , args
  , read
  , amdGpuDeviceMetricsExporterPlugin
  , amdGpuDevicePlugin
  , amdGpuDraDriver
  , clusterAutoscalerConfiguration
  , corednsAutoscaler
  , id
  , kubeconfigExpireSeconds
  , nvidiaGpuDevicePlugin
  , nvidiaGpuDraDriver
  , p2pOciRegistryPlugin
  , rdmaSharedDevicePlugin
  , routingAgent
  , sso
  , tags
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data KubernetesClusterDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

amdGpuDeviceMetricsExporterPlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
amdGpuDeviceMetricsExporterPlugin value (Args values) = Args (Object.insert "amd_gpu_device_metrics_exporter_plugin" (inputJson value) values)

amdGpuDevicePlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
amdGpuDevicePlugin value (Args values) = Args (Object.insert "amd_gpu_device_plugin" (inputJson value) values)

amdGpuDraDriver :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
amdGpuDraDriver value (Args values) = Args (Object.insert "amd_gpu_dra_driver" (inputJson value) values)

clusterAutoscalerConfiguration :: Input (Array ({ expanders :: Array String, scaleDownUnneededTime :: String, scaleDownUtilizationThreshold :: Number })) -> Args -> Args
clusterAutoscalerConfiguration value (Args values) = Args (Object.insert "cluster_autoscaler_configuration" (inputJson value) values)

corednsAutoscaler :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
corednsAutoscaler value (Args values) = Args (Object.insert "coredns_autoscaler" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

kubeconfigExpireSeconds :: Input Number -> Args -> Args
kubeconfigExpireSeconds value (Args values) = Args (Object.insert "kubeconfig_expire_seconds" (inputJson value) values)

nvidiaGpuDevicePlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
nvidiaGpuDevicePlugin value (Args values) = Args (Object.insert "nvidia_gpu_device_plugin" (inputJson value) values)

nvidiaGpuDraDriver :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
nvidiaGpuDraDriver value (Args values) = Args (Object.insert "nvidia_gpu_dra_driver" (inputJson value) values)

p2pOciRegistryPlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
p2pOciRegistryPlugin value (Args values) = Args (Object.insert "p2p_oci_registry_plugin" (inputJson value) values)

rdmaSharedDevicePlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
rdmaSharedDevicePlugin value (Args values) = Args (Object.insert "rdma_shared_device_plugin" (inputJson value) values)

routingAgent :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
routingAgent value (Args values) = Args (Object.insert "routing_agent" (inputJson value) values)

sso :: Input (Array ({ clientId :: String, enabled :: Boolean, issuerUrl :: String, required :: Boolean })) -> Args -> Args
sso value (Args values) = Args (Object.insert "sso" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

type KubernetesCluster =
  { dataSource :: DataSource KubernetesClusterDataSource
  , autoUpgrade :: Expr Boolean
  , clusterSubnet :: Expr String
  , controlPlaneFirewall :: Expr (Array ({ allowedAddresses :: Array String, enabled :: Boolean }))
  , createdAt :: Expr String
  , endpoint :: Expr String
  , ha :: Expr Boolean
  , id :: Expr String
  , ipv4Address :: Expr String
  , isolatedWorkers :: Expr Boolean
  , kubeConfig :: Expr (Array ({ clientCertificate :: String, clientKey :: String, clusterCaCertificate :: String, expiresAt :: String, host :: String, rawConfig :: String, token :: String }))
  , kubeconfigExpireSeconds :: Expr Number
  , maintenancePolicy :: Expr (Array ({ day :: String, duration :: String, startTime :: String }))
  , name :: Expr String
  , nodePool :: Expr (Array ({ actualNodeCount :: Number, autoScale :: Boolean, gpuPartitionMode :: String, id :: String, labels :: Json, maxNodes :: Number, minNodes :: Number, name :: String, nodeCount :: Number, nodes :: Array ({ createdAt :: String, dropletId :: String, id :: String, name :: String, status :: String, updatedAt :: String }), size :: String, tags :: Array String, taint :: Array ({ effect :: String, key :: String, value :: String }) }))
  , region :: Expr String
  , serviceSubnet :: Expr String
  , status :: Expr String
  , surgeUpgrade :: Expr Boolean
  , tags :: Expr (Array String)
  , updatedAt :: Expr String
  , urn :: Expr String
  , version :: Expr String
  , vpcUuid :: Expr String
  , workerSubnetUuid :: Expr String
  }

read :: String -> Args -> Infra KubernetesCluster
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_kubernetes_cluster" logicalName values
  pure
    { dataSource: handle
    , autoUpgrade: dataSourceAttr handle [ "auto_upgrade" ]
    , clusterSubnet: dataSourceAttr handle [ "cluster_subnet" ]
    , controlPlaneFirewall: dataSourceAttr handle [ "control_plane_firewall" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , endpoint: dataSourceAttr handle [ "endpoint" ]
    , ha: dataSourceAttr handle [ "ha" ]
    , id: dataSourceAttr handle [ "id" ]
    , ipv4Address: dataSourceAttr handle [ "ipv4_address" ]
    , isolatedWorkers: dataSourceAttr handle [ "isolated_workers" ]
    , kubeConfig: dataSourceAttr handle [ "kube_config" ]
    , kubeconfigExpireSeconds: dataSourceAttr handle [ "kubeconfig_expire_seconds" ]
    , maintenancePolicy: dataSourceAttr handle [ "maintenance_policy" ]
    , name: dataSourceAttr handle [ "name" ]
    , nodePool: dataSourceAttr handle [ "node_pool" ]
    , region: dataSourceAttr handle [ "region" ]
    , serviceSubnet: dataSourceAttr handle [ "service_subnet" ]
    , status: dataSourceAttr handle [ "status" ]
    , surgeUpgrade: dataSourceAttr handle [ "surge_upgrade" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , urn: dataSourceAttr handle [ "urn" ]
    , version: dataSourceAttr handle [ "version" ]
    , vpcUuid: dataSourceAttr handle [ "vpc_uuid" ]
    , workerSubnetUuid: dataSourceAttr handle [ "worker_subnet_uuid" ]
    }
