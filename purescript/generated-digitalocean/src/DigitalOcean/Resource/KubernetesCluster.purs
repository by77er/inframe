module DigitalOcean.Resource.KubernetesCluster
  ( Args
  , Required
  , KubernetesCluster
  , KubernetesClusterResource
  , args
  , create
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
  , ControlPlaneFirewall
  , ControlPlaneFirewallRequired
  , controlPlaneFirewallArgs
  , CorednsAutoscaler
  , CorednsAutoscalerRequired
  , corednsAutoscalerArgs
  , MaintenancePolicy
  , MaintenancePolicyRequired
  , maintenancePolicyArgs
  , maintenancePolicyDay
  , maintenancePolicyStartTime
  , NodePool
  , NodePoolRequired
  , nodePoolArgs
  , nodePoolAutoScale
  , nodePoolGpuPartitionMode
  , nodePoolLabels
  , nodePoolMaxNodes
  , nodePoolMinNodes
  , nodePoolNodeCount
  , nodePoolTags
  , nodePoolTaint
  , NodePoolTaint
  , NodePoolTaintRequired
  , nodePoolTaintArgs
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
  , ssoClientId
  , ssoIssuerUrl
  , ssoRequired
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data KubernetesClusterResource

newtype AmdGpuDeviceMetricsExporterPlugin = AmdGpuDeviceMetricsExporterPlugin InputObject

type AmdGpuDeviceMetricsExporterPluginRequired =
  { enabled :: Input Boolean
  }

amdGpuDeviceMetricsExporterPluginArgs :: AmdGpuDeviceMetricsExporterPluginRequired -> AmdGpuDeviceMetricsExporterPlugin
amdGpuDeviceMetricsExporterPluginArgs required = AmdGpuDeviceMetricsExporterPlugin (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

amdGpuDeviceMetricsExporterPluginJson :: AmdGpuDeviceMetricsExporterPlugin -> Json
amdGpuDeviceMetricsExporterPluginJson (AmdGpuDeviceMetricsExporterPlugin values) = inputObjectJson values

newtype AmdGpuDevicePlugin = AmdGpuDevicePlugin InputObject

type AmdGpuDevicePluginRequired =
  { enabled :: Input Boolean
  }

amdGpuDevicePluginArgs :: AmdGpuDevicePluginRequired -> AmdGpuDevicePlugin
amdGpuDevicePluginArgs required = AmdGpuDevicePlugin (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

amdGpuDevicePluginJson :: AmdGpuDevicePlugin -> Json
amdGpuDevicePluginJson (AmdGpuDevicePlugin values) = inputObjectJson values

newtype AmdGpuDraDriver = AmdGpuDraDriver InputObject

type AmdGpuDraDriverRequired =
  { enabled :: Input Boolean
  }

amdGpuDraDriverArgs :: AmdGpuDraDriverRequired -> AmdGpuDraDriver
amdGpuDraDriverArgs required = AmdGpuDraDriver (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
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

newtype ControlPlaneFirewall = ControlPlaneFirewall InputObject

type ControlPlaneFirewallRequired =
  { allowedAddresses :: Input (Array String)
  , enabled :: Input Boolean
  }

controlPlaneFirewallArgs :: ControlPlaneFirewallRequired -> ControlPlaneFirewall
controlPlaneFirewallArgs required = ControlPlaneFirewall (inputObject
  [ Tuple "allowed_addresses" (inputJson required.allowedAddresses)
  , Tuple "enabled" (inputJson required.enabled)
  ])

controlPlaneFirewallJson :: ControlPlaneFirewall -> Json
controlPlaneFirewallJson (ControlPlaneFirewall values) = inputObjectJson values

newtype CorednsAutoscaler = CorednsAutoscaler InputObject

type CorednsAutoscalerRequired =
  { enabled :: Input Boolean
  }

corednsAutoscalerArgs :: CorednsAutoscalerRequired -> CorednsAutoscaler
corednsAutoscalerArgs required = CorednsAutoscaler (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

corednsAutoscalerJson :: CorednsAutoscaler -> Json
corednsAutoscalerJson (CorednsAutoscaler values) = inputObjectJson values

newtype MaintenancePolicy = MaintenancePolicy InputObject

type MaintenancePolicyRequired =
  {
  }

maintenancePolicyArgs :: MaintenancePolicyRequired -> MaintenancePolicy
maintenancePolicyArgs _ = MaintenancePolicy (inputObject
  [
  ])

maintenancePolicyDay :: Input String -> MaintenancePolicy -> MaintenancePolicy
maintenancePolicyDay value (MaintenancePolicy values) = MaintenancePolicy (insertInputField "day" (inputJson value) values)

maintenancePolicyStartTime :: Input String -> MaintenancePolicy -> MaintenancePolicy
maintenancePolicyStartTime value (MaintenancePolicy values) = MaintenancePolicy (insertInputField "start_time" (inputJson value) values)

maintenancePolicyJson :: MaintenancePolicy -> Json
maintenancePolicyJson (MaintenancePolicy values) = inputObjectJson values

newtype NodePool = NodePool InputObject

type NodePoolRequired =
  { name :: Input String
  , size :: Input String
  }

nodePoolArgs :: NodePoolRequired -> NodePool
nodePoolArgs required = NodePool (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "size" (inputJson required.size)
  ])

nodePoolAutoScale :: Input Boolean -> NodePool -> NodePool
nodePoolAutoScale value (NodePool values) = NodePool (insertInputField "auto_scale" (inputJson value) values)

nodePoolGpuPartitionMode :: Input String -> NodePool -> NodePool
nodePoolGpuPartitionMode value (NodePool values) = NodePool (insertInputField "gpu_partition_mode" (inputJson value) values)

nodePoolLabels :: Input Json -> NodePool -> NodePool
nodePoolLabels value (NodePool values) = NodePool (insertInputField "labels" (inputJson value) values)

nodePoolMaxNodes :: Input Number -> NodePool -> NodePool
nodePoolMaxNodes value (NodePool values) = NodePool (insertInputField "max_nodes" (inputJson value) values)

nodePoolMinNodes :: Input Number -> NodePool -> NodePool
nodePoolMinNodes value (NodePool values) = NodePool (insertInputField "min_nodes" (inputJson value) values)

nodePoolNodeCount :: Input Number -> NodePool -> NodePool
nodePoolNodeCount value (NodePool values) = NodePool (insertInputField "node_count" (inputJson value) values)

nodePoolTags :: Input (Array String) -> NodePool -> NodePool
nodePoolTags value (NodePool values) = NodePool (insertInputField "tags" (inputJson value) values)

nodePoolTaint :: Array NodePoolTaint -> NodePool -> NodePool
nodePoolTaint value (NodePool values) = NodePool (insertInputField "taint" (arrayExprJson (map nodePoolTaintJson value)) values)

nodePoolJson :: NodePool -> Json
nodePoolJson (NodePool values) = inputObjectJson values

newtype NodePoolTaint = NodePoolTaint InputObject

type NodePoolTaintRequired =
  { effect :: Input String
  , key :: Input String
  , value :: Input String
  }

nodePoolTaintArgs :: NodePoolTaintRequired -> NodePoolTaint
nodePoolTaintArgs required = NodePoolTaint (inputObject
  [ Tuple "effect" (inputJson required.effect)
  , Tuple "key" (inputJson required.key)
  , Tuple "value" (inputJson required.value)
  ])

nodePoolTaintJson :: NodePoolTaint -> Json
nodePoolTaintJson (NodePoolTaint values) = inputObjectJson values

newtype NvidiaGpuDevicePlugin = NvidiaGpuDevicePlugin InputObject

type NvidiaGpuDevicePluginRequired =
  { enabled :: Input Boolean
  }

nvidiaGpuDevicePluginArgs :: NvidiaGpuDevicePluginRequired -> NvidiaGpuDevicePlugin
nvidiaGpuDevicePluginArgs required = NvidiaGpuDevicePlugin (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

nvidiaGpuDevicePluginJson :: NvidiaGpuDevicePlugin -> Json
nvidiaGpuDevicePluginJson (NvidiaGpuDevicePlugin values) = inputObjectJson values

newtype NvidiaGpuDraDriver = NvidiaGpuDraDriver InputObject

type NvidiaGpuDraDriverRequired =
  { enabled :: Input Boolean
  }

nvidiaGpuDraDriverArgs :: NvidiaGpuDraDriverRequired -> NvidiaGpuDraDriver
nvidiaGpuDraDriverArgs required = NvidiaGpuDraDriver (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

nvidiaGpuDraDriverJson :: NvidiaGpuDraDriver -> Json
nvidiaGpuDraDriverJson (NvidiaGpuDraDriver values) = inputObjectJson values

newtype P2pOciRegistryPlugin = P2pOciRegistryPlugin InputObject

type P2pOciRegistryPluginRequired =
  { enabled :: Input Boolean
  }

p2pOciRegistryPluginArgs :: P2pOciRegistryPluginRequired -> P2pOciRegistryPlugin
p2pOciRegistryPluginArgs required = P2pOciRegistryPlugin (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

p2pOciRegistryPluginJson :: P2pOciRegistryPlugin -> Json
p2pOciRegistryPluginJson (P2pOciRegistryPlugin values) = inputObjectJson values

newtype RdmaSharedDevicePlugin = RdmaSharedDevicePlugin InputObject

type RdmaSharedDevicePluginRequired =
  { enabled :: Input Boolean
  }

rdmaSharedDevicePluginArgs :: RdmaSharedDevicePluginRequired -> RdmaSharedDevicePlugin
rdmaSharedDevicePluginArgs required = RdmaSharedDevicePlugin (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

rdmaSharedDevicePluginJson :: RdmaSharedDevicePlugin -> Json
rdmaSharedDevicePluginJson (RdmaSharedDevicePlugin values) = inputObjectJson values

newtype RoutingAgent = RoutingAgent InputObject

type RoutingAgentRequired =
  { enabled :: Input Boolean
  }

routingAgentArgs :: RoutingAgentRequired -> RoutingAgent
routingAgentArgs required = RoutingAgent (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

routingAgentJson :: RoutingAgent -> Json
routingAgentJson (RoutingAgent values) = inputObjectJson values

newtype Sso = Sso InputObject

type SsoRequired =
  { enabled :: Input Boolean
  }

ssoArgs :: SsoRequired -> Sso
ssoArgs required = Sso (inputObject
  [ Tuple "enabled" (inputJson required.enabled)
  ])

ssoClientId :: Input String -> Sso -> Sso
ssoClientId value (Sso values) = Sso (insertInputField "client_id" (inputJson value) values)

ssoIssuerUrl :: Input String -> Sso -> Sso
ssoIssuerUrl value (Sso values) = Sso (insertInputField "issuer_url" (inputJson value) values)

ssoRequired :: Input Boolean -> Sso -> Sso
ssoRequired value (Sso values) = Sso (insertInputField "required" (inputJson value) values)

ssoJson :: Sso -> Json
ssoJson (Sso values) = inputObjectJson values

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

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  , nodePool :: Array NodePool
  , region :: Input String
  , version :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "node_pool" (arrayExprJson (map nodePoolJson required.nodePool))
  , Tuple "region" (inputJson required.region)
  , Tuple "version" (inputJson required.version)
  ])

amdGpuDeviceMetricsExporterPlugin :: Array AmdGpuDeviceMetricsExporterPlugin -> Args -> Args
amdGpuDeviceMetricsExporterPlugin value (Args values) = Args (insertInputField "amd_gpu_device_metrics_exporter_plugin" (arrayExprJson (map amdGpuDeviceMetricsExporterPluginJson value)) values)

amdGpuDevicePlugin :: Array AmdGpuDevicePlugin -> Args -> Args
amdGpuDevicePlugin value (Args values) = Args (insertInputField "amd_gpu_device_plugin" (arrayExprJson (map amdGpuDevicePluginJson value)) values)

amdGpuDraDriver :: Array AmdGpuDraDriver -> Args -> Args
amdGpuDraDriver value (Args values) = Args (insertInputField "amd_gpu_dra_driver" (arrayExprJson (map amdGpuDraDriverJson value)) values)

autoUpgrade :: Input Boolean -> Args -> Args
autoUpgrade value (Args values) = Args (insertInputField "auto_upgrade" (inputJson value) values)

clusterAutoscalerConfiguration :: Array ClusterAutoscalerConfiguration -> Args -> Args
clusterAutoscalerConfiguration value (Args values) = Args (insertInputField "cluster_autoscaler_configuration" (arrayExprJson (map clusterAutoscalerConfigurationJson value)) values)

clusterSubnet :: Input String -> Args -> Args
clusterSubnet value (Args values) = Args (insertInputField "cluster_subnet" (inputJson value) values)

controlPlaneFirewall :: Array ControlPlaneFirewall -> Args -> Args
controlPlaneFirewall value (Args values) = Args (insertInputField "control_plane_firewall" (arrayExprJson (map controlPlaneFirewallJson value)) values)

corednsAutoscaler :: Array CorednsAutoscaler -> Args -> Args
corednsAutoscaler value (Args values) = Args (insertInputField "coredns_autoscaler" (arrayExprJson (map corednsAutoscalerJson value)) values)

destroyAllAssociatedResources :: Input Boolean -> Args -> Args
destroyAllAssociatedResources value (Args values) = Args (insertInputField "destroy_all_associated_resources" (inputJson value) values)

ha :: Input Boolean -> Args -> Args
ha value (Args values) = Args (insertInputField "ha" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

isolatedWorkers :: Input Boolean -> Args -> Args
isolatedWorkers value (Args values) = Args (insertInputField "isolated_workers" (inputJson value) values)

kubeconfigExpireSeconds :: Input Number -> Args -> Args
kubeconfigExpireSeconds value (Args values) = Args (insertInputField "kubeconfig_expire_seconds" (inputJson value) values)

maintenancePolicy :: Array MaintenancePolicy -> Args -> Args
maintenancePolicy value (Args values) = Args (insertInputField "maintenance_policy" (arrayExprJson (map maintenancePolicyJson value)) values)

nvidiaGpuDevicePlugin :: Array NvidiaGpuDevicePlugin -> Args -> Args
nvidiaGpuDevicePlugin value (Args values) = Args (insertInputField "nvidia_gpu_device_plugin" (arrayExprJson (map nvidiaGpuDevicePluginJson value)) values)

nvidiaGpuDraDriver :: Array NvidiaGpuDraDriver -> Args -> Args
nvidiaGpuDraDriver value (Args values) = Args (insertInputField "nvidia_gpu_dra_driver" (arrayExprJson (map nvidiaGpuDraDriverJson value)) values)

p2pOciRegistryPlugin :: Array P2pOciRegistryPlugin -> Args -> Args
p2pOciRegistryPlugin value (Args values) = Args (insertInputField "p2p_oci_registry_plugin" (arrayExprJson (map p2pOciRegistryPluginJson value)) values)

rdmaSharedDevicePlugin :: Array RdmaSharedDevicePlugin -> Args -> Args
rdmaSharedDevicePlugin value (Args values) = Args (insertInputField "rdma_shared_device_plugin" (arrayExprJson (map rdmaSharedDevicePluginJson value)) values)

registryIntegration :: Input Boolean -> Args -> Args
registryIntegration value (Args values) = Args (insertInputField "registry_integration" (inputJson value) values)

routingAgent :: Array RoutingAgent -> Args -> Args
routingAgent value (Args values) = Args (insertInputField "routing_agent" (arrayExprJson (map routingAgentJson value)) values)

serviceSubnet :: Input String -> Args -> Args
serviceSubnet value (Args values) = Args (insertInputField "service_subnet" (inputJson value) values)

sso :: Array Sso -> Args -> Args
sso value (Args values) = Args (insertInputField "sso" (arrayExprJson (map ssoJson value)) values)

surgeUpgrade :: Input Boolean -> Args -> Args
surgeUpgrade value (Args values) = Args (insertInputField "surge_upgrade" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (insertInputField "vpc_uuid" (inputJson value) values)

workerSubnetUuid :: Input String -> Args -> Args
workerSubnetUuid value (Args values) = Args (insertInputField "worker_subnet_uuid" (inputJson value) values)

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
