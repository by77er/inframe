module DigitalOcean.Data.KubernetesCluster
  ( Args
  , Required
  , KubernetesCluster
  , KubernetesClusterDataSource
  , args
  , read
  , AmdGpuDeviceMetricsExporterPlugin
  , AmdGpuDeviceMetricsExporterPluginRequired
  , amdGpuDeviceMetricsExporterPluginArgs
  , AmdGpuDevicePlugin
  , AmdGpuDevicePluginRequired
  , amdGpuDevicePluginArgs
  , AmdGpuDraDriver
  , AmdGpuDraDriverRequired
  , amdGpuDraDriverArgs
  , ClusterAutoscalerConfiguration
  , ClusterAutoscalerConfigurationRequired
  , clusterAutoscalerConfigurationArgs
  , clusterAutoscalerConfigurationExpanders
  , clusterAutoscalerConfigurationScaleDownUnneededTime
  , clusterAutoscalerConfigurationScaleDownUtilizationThreshold
  , CorednsAutoscaler
  , CorednsAutoscalerRequired
  , corednsAutoscalerArgs
  , NvidiaGpuDevicePlugin
  , NvidiaGpuDevicePluginRequired
  , nvidiaGpuDevicePluginArgs
  , NvidiaGpuDraDriver
  , NvidiaGpuDraDriverRequired
  , nvidiaGpuDraDriverArgs
  , P2pOciRegistryPlugin
  , P2pOciRegistryPluginRequired
  , p2pOciRegistryPluginArgs
  , RdmaSharedDevicePlugin
  , RdmaSharedDevicePluginRequired
  , rdmaSharedDevicePluginArgs
  , RoutingAgent
  , RoutingAgentRequired
  , routingAgentArgs
  , Sso
  , SsoRequired
  , ssoArgs
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data KubernetesClusterDataSource

newtype AmdGpuDeviceMetricsExporterPlugin = AmdGpuDeviceMetricsExporterPlugin InputObject

type AmdGpuDeviceMetricsExporterPluginRequired =
  {
  }

amdGpuDeviceMetricsExporterPluginArgs :: AmdGpuDeviceMetricsExporterPluginRequired -> AmdGpuDeviceMetricsExporterPlugin
amdGpuDeviceMetricsExporterPluginArgs _ = AmdGpuDeviceMetricsExporterPlugin (inputObject
  [
  ])

amdGpuDeviceMetricsExporterPluginJson :: AmdGpuDeviceMetricsExporterPlugin -> Json
amdGpuDeviceMetricsExporterPluginJson (AmdGpuDeviceMetricsExporterPlugin values) = inputObjectJson values

newtype AmdGpuDevicePlugin = AmdGpuDevicePlugin InputObject

type AmdGpuDevicePluginRequired =
  {
  }

amdGpuDevicePluginArgs :: AmdGpuDevicePluginRequired -> AmdGpuDevicePlugin
amdGpuDevicePluginArgs _ = AmdGpuDevicePlugin (inputObject
  [
  ])

amdGpuDevicePluginJson :: AmdGpuDevicePlugin -> Json
amdGpuDevicePluginJson (AmdGpuDevicePlugin values) = inputObjectJson values

newtype AmdGpuDraDriver = AmdGpuDraDriver InputObject

type AmdGpuDraDriverRequired =
  {
  }

amdGpuDraDriverArgs :: AmdGpuDraDriverRequired -> AmdGpuDraDriver
amdGpuDraDriverArgs _ = AmdGpuDraDriver (inputObject
  [
  ])

amdGpuDraDriverJson :: AmdGpuDraDriver -> Json
amdGpuDraDriverJson (AmdGpuDraDriver values) = inputObjectJson values

newtype ClusterAutoscalerConfiguration = ClusterAutoscalerConfiguration InputObject

type ClusterAutoscalerConfigurationRequired =
  {
  }

clusterAutoscalerConfigurationArgs :: ClusterAutoscalerConfigurationRequired -> ClusterAutoscalerConfiguration
clusterAutoscalerConfigurationArgs _ = ClusterAutoscalerConfiguration (inputObject
  [
  ])

clusterAutoscalerConfigurationExpanders :: Input (Array String) -> ClusterAutoscalerConfiguration -> ClusterAutoscalerConfiguration
clusterAutoscalerConfigurationExpanders value (ClusterAutoscalerConfiguration values) = ClusterAutoscalerConfiguration (insertInputField "expanders" (inputJson value) values)

clusterAutoscalerConfigurationScaleDownUnneededTime :: Input String -> ClusterAutoscalerConfiguration -> ClusterAutoscalerConfiguration
clusterAutoscalerConfigurationScaleDownUnneededTime value (ClusterAutoscalerConfiguration values) = ClusterAutoscalerConfiguration (insertInputField "scale_down_unneeded_time" (inputJson value) values)

clusterAutoscalerConfigurationScaleDownUtilizationThreshold :: Input Number -> ClusterAutoscalerConfiguration -> ClusterAutoscalerConfiguration
clusterAutoscalerConfigurationScaleDownUtilizationThreshold value (ClusterAutoscalerConfiguration values) = ClusterAutoscalerConfiguration (insertInputField "scale_down_utilization_threshold" (inputJson value) values)

clusterAutoscalerConfigurationJson :: ClusterAutoscalerConfiguration -> Json
clusterAutoscalerConfigurationJson (ClusterAutoscalerConfiguration values) = inputObjectJson values

newtype CorednsAutoscaler = CorednsAutoscaler InputObject

type CorednsAutoscalerRequired =
  {
  }

corednsAutoscalerArgs :: CorednsAutoscalerRequired -> CorednsAutoscaler
corednsAutoscalerArgs _ = CorednsAutoscaler (inputObject
  [
  ])

corednsAutoscalerJson :: CorednsAutoscaler -> Json
corednsAutoscalerJson (CorednsAutoscaler values) = inputObjectJson values

newtype NvidiaGpuDevicePlugin = NvidiaGpuDevicePlugin InputObject

type NvidiaGpuDevicePluginRequired =
  {
  }

nvidiaGpuDevicePluginArgs :: NvidiaGpuDevicePluginRequired -> NvidiaGpuDevicePlugin
nvidiaGpuDevicePluginArgs _ = NvidiaGpuDevicePlugin (inputObject
  [
  ])

nvidiaGpuDevicePluginJson :: NvidiaGpuDevicePlugin -> Json
nvidiaGpuDevicePluginJson (NvidiaGpuDevicePlugin values) = inputObjectJson values

newtype NvidiaGpuDraDriver = NvidiaGpuDraDriver InputObject

type NvidiaGpuDraDriverRequired =
  {
  }

nvidiaGpuDraDriverArgs :: NvidiaGpuDraDriverRequired -> NvidiaGpuDraDriver
nvidiaGpuDraDriverArgs _ = NvidiaGpuDraDriver (inputObject
  [
  ])

nvidiaGpuDraDriverJson :: NvidiaGpuDraDriver -> Json
nvidiaGpuDraDriverJson (NvidiaGpuDraDriver values) = inputObjectJson values

newtype P2pOciRegistryPlugin = P2pOciRegistryPlugin InputObject

type P2pOciRegistryPluginRequired =
  {
  }

p2pOciRegistryPluginArgs :: P2pOciRegistryPluginRequired -> P2pOciRegistryPlugin
p2pOciRegistryPluginArgs _ = P2pOciRegistryPlugin (inputObject
  [
  ])

p2pOciRegistryPluginJson :: P2pOciRegistryPlugin -> Json
p2pOciRegistryPluginJson (P2pOciRegistryPlugin values) = inputObjectJson values

newtype RdmaSharedDevicePlugin = RdmaSharedDevicePlugin InputObject

type RdmaSharedDevicePluginRequired =
  {
  }

rdmaSharedDevicePluginArgs :: RdmaSharedDevicePluginRequired -> RdmaSharedDevicePlugin
rdmaSharedDevicePluginArgs _ = RdmaSharedDevicePlugin (inputObject
  [
  ])

rdmaSharedDevicePluginJson :: RdmaSharedDevicePlugin -> Json
rdmaSharedDevicePluginJson (RdmaSharedDevicePlugin values) = inputObjectJson values

newtype RoutingAgent = RoutingAgent InputObject

type RoutingAgentRequired =
  {
  }

routingAgentArgs :: RoutingAgentRequired -> RoutingAgent
routingAgentArgs _ = RoutingAgent (inputObject
  [
  ])

routingAgentJson :: RoutingAgent -> Json
routingAgentJson (RoutingAgent values) = inputObjectJson values

newtype Sso = Sso InputObject

type SsoRequired =
  {
  }

ssoArgs :: SsoRequired -> Sso
ssoArgs _ = Sso (inputObject
  [
  ])

ssoJson :: Sso -> Json
ssoJson (Sso values) = inputObjectJson values

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

amdGpuDeviceMetricsExporterPlugin :: Array AmdGpuDeviceMetricsExporterPlugin -> Args -> Args
amdGpuDeviceMetricsExporterPlugin value (Args values) = Args (insertInputField "amd_gpu_device_metrics_exporter_plugin" (arrayExprJson (map amdGpuDeviceMetricsExporterPluginJson value)) values)

amdGpuDevicePlugin :: Array AmdGpuDevicePlugin -> Args -> Args
amdGpuDevicePlugin value (Args values) = Args (insertInputField "amd_gpu_device_plugin" (arrayExprJson (map amdGpuDevicePluginJson value)) values)

amdGpuDraDriver :: Array AmdGpuDraDriver -> Args -> Args
amdGpuDraDriver value (Args values) = Args (insertInputField "amd_gpu_dra_driver" (arrayExprJson (map amdGpuDraDriverJson value)) values)

clusterAutoscalerConfiguration :: Array ClusterAutoscalerConfiguration -> Args -> Args
clusterAutoscalerConfiguration value (Args values) = Args (insertInputField "cluster_autoscaler_configuration" (arrayExprJson (map clusterAutoscalerConfigurationJson value)) values)

corednsAutoscaler :: Array CorednsAutoscaler -> Args -> Args
corednsAutoscaler value (Args values) = Args (insertInputField "coredns_autoscaler" (arrayExprJson (map corednsAutoscalerJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

kubeconfigExpireSeconds :: Input Number -> Args -> Args
kubeconfigExpireSeconds value (Args values) = Args (insertInputField "kubeconfig_expire_seconds" (inputJson value) values)

nvidiaGpuDevicePlugin :: Array NvidiaGpuDevicePlugin -> Args -> Args
nvidiaGpuDevicePlugin value (Args values) = Args (insertInputField "nvidia_gpu_device_plugin" (arrayExprJson (map nvidiaGpuDevicePluginJson value)) values)

nvidiaGpuDraDriver :: Array NvidiaGpuDraDriver -> Args -> Args
nvidiaGpuDraDriver value (Args values) = Args (insertInputField "nvidia_gpu_dra_driver" (arrayExprJson (map nvidiaGpuDraDriverJson value)) values)

p2pOciRegistryPlugin :: Array P2pOciRegistryPlugin -> Args -> Args
p2pOciRegistryPlugin value (Args values) = Args (insertInputField "p2p_oci_registry_plugin" (arrayExprJson (map p2pOciRegistryPluginJson value)) values)

rdmaSharedDevicePlugin :: Array RdmaSharedDevicePlugin -> Args -> Args
rdmaSharedDevicePlugin value (Args values) = Args (insertInputField "rdma_shared_device_plugin" (arrayExprJson (map rdmaSharedDevicePluginJson value)) values)

routingAgent :: Array RoutingAgent -> Args -> Args
routingAgent value (Args values) = Args (insertInputField "routing_agent" (arrayExprJson (map routingAgentJson value)) values)

sso :: Array Sso -> Args -> Args
sso value (Args values) = Args (insertInputField "sso" (arrayExprJson (map ssoJson value)) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

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
