module DigitalOcean.Resource.Loadbalancer
  ( Args
  , Required
  , Loadbalancer
  , LoadbalancerResource
  , args
  , create
  , algorithm
  , disableLetsEncryptDnsRecords
  , domains
  , dropletIds
  , dropletTag
  , enableBackendKeepalive
  , enableProxyProtocol
  , firewall
  , forwardingRule
  , glbSettings
  , healthcheck
  , httpIdleTimeoutSeconds
  , id
  , ip
  , network
  , networkStack
  , projectId
  , redirectHttpToHttps
  , region
  , size
  , sizeUnit
  , stickySessions
  , subnetUuid
  , targetLoadBalancerIds
  , tlsCipherPolicy
  , type_
  , vpcUuid
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data LoadbalancerResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

algorithm :: Input String -> Args -> Args
algorithm value (Args values) = Args (Object.insert "algorithm" (inputJson value) values)

disableLetsEncryptDnsRecords :: Input Boolean -> Args -> Args
disableLetsEncryptDnsRecords value (Args values) = Args (Object.insert "disable_lets_encrypt_dns_records" (inputJson value) values)

domains :: Input (Array ({ certificateId :: String, certificateName :: String, isManaged :: Boolean, name :: String, sslValidationErrorReasons :: Array String, verificationErrorReasons :: Array String })) -> Args -> Args
domains value (Args values) = Args (Object.insert "domains" (inputJson value) values)

dropletIds :: Input (Array Number) -> Args -> Args
dropletIds value (Args values) = Args (Object.insert "droplet_ids" (inputJson value) values)

dropletTag :: Input String -> Args -> Args
dropletTag value (Args values) = Args (Object.insert "droplet_tag" (inputJson value) values)

enableBackendKeepalive :: Input Boolean -> Args -> Args
enableBackendKeepalive value (Args values) = Args (Object.insert "enable_backend_keepalive" (inputJson value) values)

enableProxyProtocol :: Input Boolean -> Args -> Args
enableProxyProtocol value (Args values) = Args (Object.insert "enable_proxy_protocol" (inputJson value) values)

firewall :: Input (Array ({ allow :: Array String, deny :: Array String })) -> Args -> Args
firewall value (Args values) = Args (Object.insert "firewall" (inputJson value) values)

forwardingRule :: Input (Array ({ certificateId :: String, certificateName :: String, entryPort :: Number, entryProtocol :: String, targetPort :: Number, targetProtocol :: String, tlsPassthrough :: Boolean })) -> Args -> Args
forwardingRule value (Args values) = Args (Object.insert "forwarding_rule" (inputJson value) values)

glbSettings :: Input (Array ({ cdn :: Array ({ isEnabled :: Boolean }), failoverThreshold :: Number, regionPriorities :: Json, targetPort :: Number, targetProtocol :: String })) -> Args -> Args
glbSettings value (Args values) = Args (Object.insert "glb_settings" (inputJson value) values)

healthcheck :: Input (Array ({ checkIntervalSeconds :: Number, healthyThreshold :: Number, path :: String, port :: Number, protocol :: String, responseTimeoutSeconds :: Number, unhealthyThreshold :: Number })) -> Args -> Args
healthcheck value (Args values) = Args (Object.insert "healthcheck" (inputJson value) values)

httpIdleTimeoutSeconds :: Input Number -> Args -> Args
httpIdleTimeoutSeconds value (Args values) = Args (Object.insert "http_idle_timeout_seconds" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ip :: Input String -> Args -> Args
ip value (Args values) = Args (Object.insert "ip" (inputJson value) values)

network :: Input String -> Args -> Args
network value (Args values) = Args (Object.insert "network" (inputJson value) values)

networkStack :: Input String -> Args -> Args
networkStack value (Args values) = Args (Object.insert "network_stack" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (Object.insert "project_id" (inputJson value) values)

redirectHttpToHttps :: Input Boolean -> Args -> Args
redirectHttpToHttps value (Args values) = Args (Object.insert "redirect_http_to_https" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

size :: Input String -> Args -> Args
size value (Args values) = Args (Object.insert "size" (inputJson value) values)

sizeUnit :: Input Number -> Args -> Args
sizeUnit value (Args values) = Args (Object.insert "size_unit" (inputJson value) values)

stickySessions :: Input (Array ({ cookieName :: String, cookieTtlSeconds :: Number, type_ :: String })) -> Args -> Args
stickySessions value (Args values) = Args (Object.insert "sticky_sessions" (inputJson value) values)

subnetUuid :: Input String -> Args -> Args
subnetUuid value (Args values) = Args (Object.insert "subnet_uuid" (inputJson value) values)

targetLoadBalancerIds :: Input (Array String) -> Args -> Args
targetLoadBalancerIds value (Args values) = Args (Object.insert "target_load_balancer_ids" (inputJson value) values)

tlsCipherPolicy :: Input String -> Args -> Args
tlsCipherPolicy value (Args values) = Args (Object.insert "tls_cipher_policy" (inputJson value) values)

type_ :: Input String -> Args -> Args
type_ value (Args values) = Args (Object.insert "type" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (Object.insert "vpc_uuid" (inputJson value) values)

type Loadbalancer =
  { resource :: Resource LoadbalancerResource
  , algorithm :: Expr String
  , disableLetsEncryptDnsRecords :: Expr Boolean
  , dropletIds :: Expr (Array Number)
  , dropletTag :: Expr String
  , enableBackendKeepalive :: Expr Boolean
  , enableProxyProtocol :: Expr Boolean
  , httpIdleTimeoutSeconds :: Expr Number
  , id :: Expr String
  , ip :: Expr String
  , ipv6 :: Expr String
  , name :: Expr String
  , network :: Expr String
  , networkStack :: Expr String
  , projectId :: Expr String
  , redirectHttpToHttps :: Expr Boolean
  , region :: Expr String
  , size :: Expr String
  , sizeUnit :: Expr Number
  , status :: Expr String
  , subnetUuid :: Expr String
  , targetLoadBalancerIds :: Expr (Array String)
  , tlsCipherPolicy :: Expr String
  , type_ :: Expr String
  , urn :: Expr String
  , vpcUuid :: Expr String
  }

create :: String -> Args -> Infra Loadbalancer
create logicalName (Args values) = do
  handle <- addResource "digitalocean_loadbalancer" logicalName values
  pure
    { resource: handle
    , algorithm: resourceAttr handle [ "algorithm" ]
    , disableLetsEncryptDnsRecords: resourceAttr handle [ "disable_lets_encrypt_dns_records" ]
    , dropletIds: resourceAttr handle [ "droplet_ids" ]
    , dropletTag: resourceAttr handle [ "droplet_tag" ]
    , enableBackendKeepalive: resourceAttr handle [ "enable_backend_keepalive" ]
    , enableProxyProtocol: resourceAttr handle [ "enable_proxy_protocol" ]
    , httpIdleTimeoutSeconds: resourceAttr handle [ "http_idle_timeout_seconds" ]
    , id: resourceAttr handle [ "id" ]
    , ip: resourceAttr handle [ "ip" ]
    , ipv6: resourceAttr handle [ "ipv6" ]
    , name: resourceAttr handle [ "name" ]
    , network: resourceAttr handle [ "network" ]
    , networkStack: resourceAttr handle [ "network_stack" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , redirectHttpToHttps: resourceAttr handle [ "redirect_http_to_https" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , sizeUnit: resourceAttr handle [ "size_unit" ]
    , status: resourceAttr handle [ "status" ]
    , subnetUuid: resourceAttr handle [ "subnet_uuid" ]
    , targetLoadBalancerIds: resourceAttr handle [ "target_load_balancer_ids" ]
    , tlsCipherPolicy: resourceAttr handle [ "tls_cipher_policy" ]
    , type_: resourceAttr handle [ "type" ]
    , urn: resourceAttr handle [ "urn" ]
    , vpcUuid: resourceAttr handle [ "vpc_uuid" ]
    }
