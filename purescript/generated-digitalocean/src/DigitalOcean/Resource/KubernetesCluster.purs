module DigitalOcean.Resource.KubernetesCluster
  ( Args
  , Required
  , KubernetesCluster
  , KubernetesClusterResource
  , args
  , create
  , amdGpuDeviceMetricsExporterPlugin
  , amdGpuDevicePlugin
  , amdGpuDraDriver
  , autoUpgrade
  , clusterAutoscalerConfiguration
  , clusterSubnet
  , controlPlaneFirewall
  , corednsAutoscaler
  , destroyAllAssociatedResources
  , ha
  , id
  , isolatedWorkers
  , kubeconfigExpireSeconds
  , maintenancePolicy
  , nvidiaGpuDevicePlugin
  , nvidiaGpuDraDriver
  , p2pOciRegistryPlugin
  , rdmaSharedDevicePlugin
  , registryIntegration
  , routingAgent
  , serviceSubnet
  , sso
  , surgeUpgrade
  , tags
  , timeouts
  , vpcUuid
  , workerSubnetUuid
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data KubernetesClusterResource

type Required =
  { name :: Input String
  , nodePool :: Input (Array ({ actualNodeCount :: Number, autoScale :: Boolean, gpuPartitionMode :: String, id :: String, labels :: Json, maxNodes :: Number, minNodes :: Number, name :: String, nodeCount :: Number, nodes :: Array ({ createdAt :: String, dropletId :: String, id :: String, name :: String, status :: String, updatedAt :: String }), size :: String, tags :: Array String, taint :: Array ({ effect :: String, key :: String, value :: String }) }))
  , region :: Input String
  , version :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "node_pool" (inputJson required.nodePool)
  , Tuple "region" (inputJson required.region)
  , Tuple "version" (inputJson required.version)
  ])

amdGpuDeviceMetricsExporterPlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
amdGpuDeviceMetricsExporterPlugin value (Args values) = Args (Object.insert "amd_gpu_device_metrics_exporter_plugin" (inputJson value) values)

amdGpuDevicePlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
amdGpuDevicePlugin value (Args values) = Args (Object.insert "amd_gpu_device_plugin" (inputJson value) values)

amdGpuDraDriver :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
amdGpuDraDriver value (Args values) = Args (Object.insert "amd_gpu_dra_driver" (inputJson value) values)

autoUpgrade :: Input Boolean -> Args -> Args
autoUpgrade value (Args values) = Args (Object.insert "auto_upgrade" (inputJson value) values)

clusterAutoscalerConfiguration :: Input (Array ({ expanders :: Array String, scaleDownUnneededTime :: String, scaleDownUtilizationThreshold :: Number })) -> Args -> Args
clusterAutoscalerConfiguration value (Args values) = Args (Object.insert "cluster_autoscaler_configuration" (inputJson value) values)

clusterSubnet :: Input String -> Args -> Args
clusterSubnet value (Args values) = Args (Object.insert "cluster_subnet" (inputJson value) values)

controlPlaneFirewall :: Input (Array ({ allowedAddresses :: Array String, enabled :: Boolean })) -> Args -> Args
controlPlaneFirewall value (Args values) = Args (Object.insert "control_plane_firewall" (inputJson value) values)

corednsAutoscaler :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
corednsAutoscaler value (Args values) = Args (Object.insert "coredns_autoscaler" (inputJson value) values)

destroyAllAssociatedResources :: Input Boolean -> Args -> Args
destroyAllAssociatedResources value (Args values) = Args (Object.insert "destroy_all_associated_resources" (inputJson value) values)

ha :: Input Boolean -> Args -> Args
ha value (Args values) = Args (Object.insert "ha" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

isolatedWorkers :: Input Boolean -> Args -> Args
isolatedWorkers value (Args values) = Args (Object.insert "isolated_workers" (inputJson value) values)

kubeconfigExpireSeconds :: Input Number -> Args -> Args
kubeconfigExpireSeconds value (Args values) = Args (Object.insert "kubeconfig_expire_seconds" (inputJson value) values)

maintenancePolicy :: Input (Array ({ day :: String, duration :: String, startTime :: String })) -> Args -> Args
maintenancePolicy value (Args values) = Args (Object.insert "maintenance_policy" (inputJson value) values)

nvidiaGpuDevicePlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
nvidiaGpuDevicePlugin value (Args values) = Args (Object.insert "nvidia_gpu_device_plugin" (inputJson value) values)

nvidiaGpuDraDriver :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
nvidiaGpuDraDriver value (Args values) = Args (Object.insert "nvidia_gpu_dra_driver" (inputJson value) values)

p2pOciRegistryPlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
p2pOciRegistryPlugin value (Args values) = Args (Object.insert "p2p_oci_registry_plugin" (inputJson value) values)

rdmaSharedDevicePlugin :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
rdmaSharedDevicePlugin value (Args values) = Args (Object.insert "rdma_shared_device_plugin" (inputJson value) values)

registryIntegration :: Input Boolean -> Args -> Args
registryIntegration value (Args values) = Args (Object.insert "registry_integration" (inputJson value) values)

routingAgent :: Input (Array ({ enabled :: Boolean })) -> Args -> Args
routingAgent value (Args values) = Args (Object.insert "routing_agent" (inputJson value) values)

serviceSubnet :: Input String -> Args -> Args
serviceSubnet value (Args values) = Args (Object.insert "service_subnet" (inputJson value) values)

sso :: Input (Array ({ clientId :: String, enabled :: Boolean, issuerUrl :: String, required :: Boolean })) -> Args -> Args
sso value (Args values) = Args (Object.insert "sso" (inputJson value) values)

surgeUpgrade :: Input Boolean -> Args -> Args
surgeUpgrade value (Args values) = Args (Object.insert "surge_upgrade" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

timeouts :: Input ({ create :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (Object.insert "vpc_uuid" (inputJson value) values)

workerSubnetUuid :: Input String -> Args -> Args
workerSubnetUuid value (Args values) = Args (Object.insert "worker_subnet_uuid" (inputJson value) values)

type KubernetesCluster =
  { resource :: Resource KubernetesClusterResource
  , autoUpgrade :: Expr Boolean
  , clusterSubnet :: Expr String
  , createdAt :: Expr String
  , destroyAllAssociatedResources :: Expr Boolean
  , endpoint :: Expr String
  , ha :: Expr Boolean
  , id :: Expr String
  , ipv4Address :: Expr String
  , isolatedWorkers :: Expr Boolean
  , kubeConfig :: Expr (Array ({ clientCertificate :: String, clientKey :: String, clusterCaCertificate :: String, expiresAt :: String, host :: String, rawConfig :: String, token :: String }))
  , kubeconfigExpireSeconds :: Expr Number
  , name :: Expr String
  , region :: Expr String
  , registryIntegration :: Expr Boolean
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

create :: String -> Args -> Infra KubernetesCluster
create logicalName (Args values) = do
  handle <- addResource "digitalocean_kubernetes_cluster" logicalName values
  pure
    { resource: handle
    , autoUpgrade: resourceAttr handle [ "auto_upgrade" ]
    , clusterSubnet: resourceAttr handle [ "cluster_subnet" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , destroyAllAssociatedResources: resourceAttr handle [ "destroy_all_associated_resources" ]
    , endpoint: resourceAttr handle [ "endpoint" ]
    , ha: resourceAttr handle [ "ha" ]
    , id: resourceAttr handle [ "id" ]
    , ipv4Address: resourceAttr handle [ "ipv4_address" ]
    , isolatedWorkers: resourceAttr handle [ "isolated_workers" ]
    , kubeConfig: resourceAttr handle [ "kube_config" ]
    , kubeconfigExpireSeconds: resourceAttr handle [ "kubeconfig_expire_seconds" ]
    , name: resourceAttr handle [ "name" ]
    , region: resourceAttr handle [ "region" ]
    , registryIntegration: resourceAttr handle [ "registry_integration" ]
    , serviceSubnet: resourceAttr handle [ "service_subnet" ]
    , status: resourceAttr handle [ "status" ]
    , surgeUpgrade: resourceAttr handle [ "surge_upgrade" ]
    , tags: resourceAttr handle [ "tags" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , urn: resourceAttr handle [ "urn" ]
    , version: resourceAttr handle [ "version" ]
    , vpcUuid: resourceAttr handle [ "vpc_uuid" ]
    , workerSubnetUuid: resourceAttr handle [ "worker_subnet_uuid" ]
    }
