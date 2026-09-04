module DigitalOcean.Resource.Loadbalancer
  ( Args
  , Required
  , Loadbalancer
  , LoadbalancerResource
  , args
  , create
  , Domains
  , DomainsRequired
  , domainsArgs
  , domainsCertificateName
  , domainsIsManaged
  , Firewall
  , FirewallRequired
  , firewallArgs
  , firewallAllow
  , firewallDeny
  , ForwardingRule
  , ForwardingRuleRequired
  , forwardingRuleArgs
  , forwardingRuleCertificateId
  , forwardingRuleCertificateName
  , forwardingRuleTlsPassthrough
  , GlbSettings
  , GlbSettingsRequired
  , glbSettingsArgs
  , glbSettingsCdn
  , glbSettingsFailoverThreshold
  , glbSettingsRegionPriorities
  , GlbSettingsCdn
  , GlbSettingsCdnRequired
  , glbSettingsCdnArgs
  , glbSettingsCdnIsEnabled
  , Healthcheck
  , HealthcheckRequired
  , healthcheckArgs
  , healthcheckCheckIntervalSeconds
  , healthcheckHealthyThreshold
  , healthcheckPath
  , healthcheckResponseTimeoutSeconds
  , healthcheckUnhealthyThreshold
  , StickySessions
  , StickySessionsRequired
  , stickySessionsArgs
  , stickySessionsCookieName
  , stickySessionsCookieTtlSeconds
  , stickySessionsType
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data LoadbalancerResource

newtype Domains = Domains InputObject

type DomainsRequired =
  { name :: Input String
  }

domainsArgs :: DomainsRequired -> Domains
domainsArgs required = Domains (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

domainsCertificateName :: Input String -> Domains -> Domains
domainsCertificateName value (Domains values) = Domains (insertInputField "certificate_name" (inputJson value) values)

domainsIsManaged :: Input Boolean -> Domains -> Domains
domainsIsManaged value (Domains values) = Domains (insertInputField "is_managed" (inputJson value) values)

domainsJson :: Domains -> Json
domainsJson (Domains values) = inputObjectJson values

newtype Firewall = Firewall InputObject

type FirewallRequired =
  {
  }

firewallArgs :: FirewallRequired -> Firewall
firewallArgs _ = Firewall (inputObject
  [
  ])

firewallAllow :: Input (Array String) -> Firewall -> Firewall
firewallAllow value (Firewall values) = Firewall (insertInputField "allow" (inputJson value) values)

firewallDeny :: Input (Array String) -> Firewall -> Firewall
firewallDeny value (Firewall values) = Firewall (insertInputField "deny" (inputJson value) values)

firewallJson :: Firewall -> Json
firewallJson (Firewall values) = inputObjectJson values

newtype ForwardingRule = ForwardingRule InputObject

type ForwardingRuleRequired =
  { entryPort :: Input Number
  , entryProtocol :: Input String
  , targetPort :: Input Number
  , targetProtocol :: Input String
  }

forwardingRuleArgs :: ForwardingRuleRequired -> ForwardingRule
forwardingRuleArgs required = ForwardingRule (inputObject
  [ Tuple "entry_port" (inputJson required.entryPort)
  , Tuple "entry_protocol" (inputJson required.entryProtocol)
  , Tuple "target_port" (inputJson required.targetPort)
  , Tuple "target_protocol" (inputJson required.targetProtocol)
  ])

forwardingRuleCertificateId :: Input String -> ForwardingRule -> ForwardingRule
forwardingRuleCertificateId value (ForwardingRule values) = ForwardingRule (insertInputField "certificate_id" (inputJson value) values)

forwardingRuleCertificateName :: Input String -> ForwardingRule -> ForwardingRule
forwardingRuleCertificateName value (ForwardingRule values) = ForwardingRule (insertInputField "certificate_name" (inputJson value) values)

forwardingRuleTlsPassthrough :: Input Boolean -> ForwardingRule -> ForwardingRule
forwardingRuleTlsPassthrough value (ForwardingRule values) = ForwardingRule (insertInputField "tls_passthrough" (inputJson value) values)

forwardingRuleJson :: ForwardingRule -> Json
forwardingRuleJson (ForwardingRule values) = inputObjectJson values

newtype GlbSettings = GlbSettings InputObject

type GlbSettingsRequired =
  { targetPort :: Input Number
  , targetProtocol :: Input String
  }

glbSettingsArgs :: GlbSettingsRequired -> GlbSettings
glbSettingsArgs required = GlbSettings (inputObject
  [ Tuple "target_port" (inputJson required.targetPort)
  , Tuple "target_protocol" (inputJson required.targetProtocol)
  ])

glbSettingsCdn :: Array GlbSettingsCdn -> GlbSettings -> GlbSettings
glbSettingsCdn value (GlbSettings values) = GlbSettings (insertInputField "cdn" (arrayExprJson (map glbSettingsCdnJson value)) values)

glbSettingsFailoverThreshold :: Input Number -> GlbSettings -> GlbSettings
glbSettingsFailoverThreshold value (GlbSettings values) = GlbSettings (insertInputField "failover_threshold" (inputJson value) values)

glbSettingsRegionPriorities :: Input Json -> GlbSettings -> GlbSettings
glbSettingsRegionPriorities value (GlbSettings values) = GlbSettings (insertInputField "region_priorities" (inputJson value) values)

glbSettingsJson :: GlbSettings -> Json
glbSettingsJson (GlbSettings values) = inputObjectJson values

newtype GlbSettingsCdn = GlbSettingsCdn InputObject

type GlbSettingsCdnRequired =
  {
  }

glbSettingsCdnArgs :: GlbSettingsCdnRequired -> GlbSettingsCdn
glbSettingsCdnArgs _ = GlbSettingsCdn (inputObject
  [
  ])

glbSettingsCdnIsEnabled :: Input Boolean -> GlbSettingsCdn -> GlbSettingsCdn
glbSettingsCdnIsEnabled value (GlbSettingsCdn values) = GlbSettingsCdn (insertInputField "is_enabled" (inputJson value) values)

glbSettingsCdnJson :: GlbSettingsCdn -> Json
glbSettingsCdnJson (GlbSettingsCdn values) = inputObjectJson values

newtype Healthcheck = Healthcheck InputObject

type HealthcheckRequired =
  { port :: Input Number
  , protocol :: Input String
  }

healthcheckArgs :: HealthcheckRequired -> Healthcheck
healthcheckArgs required = Healthcheck (inputObject
  [ Tuple "port" (inputJson required.port)
  , Tuple "protocol" (inputJson required.protocol)
  ])

healthcheckCheckIntervalSeconds :: Input Number -> Healthcheck -> Healthcheck
healthcheckCheckIntervalSeconds value (Healthcheck values) = Healthcheck (insertInputField "check_interval_seconds" (inputJson value) values)

healthcheckHealthyThreshold :: Input Number -> Healthcheck -> Healthcheck
healthcheckHealthyThreshold value (Healthcheck values) = Healthcheck (insertInputField "healthy_threshold" (inputJson value) values)

healthcheckPath :: Input String -> Healthcheck -> Healthcheck
healthcheckPath value (Healthcheck values) = Healthcheck (insertInputField "path" (inputJson value) values)

healthcheckResponseTimeoutSeconds :: Input Number -> Healthcheck -> Healthcheck
healthcheckResponseTimeoutSeconds value (Healthcheck values) = Healthcheck (insertInputField "response_timeout_seconds" (inputJson value) values)

healthcheckUnhealthyThreshold :: Input Number -> Healthcheck -> Healthcheck
healthcheckUnhealthyThreshold value (Healthcheck values) = Healthcheck (insertInputField "unhealthy_threshold" (inputJson value) values)

healthcheckJson :: Healthcheck -> Json
healthcheckJson (Healthcheck values) = inputObjectJson values

newtype StickySessions = StickySessions InputObject

type StickySessionsRequired =
  {
  }

stickySessionsArgs :: StickySessionsRequired -> StickySessions
stickySessionsArgs _ = StickySessions (inputObject
  [
  ])

stickySessionsCookieName :: Input String -> StickySessions -> StickySessions
stickySessionsCookieName value (StickySessions values) = StickySessions (insertInputField "cookie_name" (inputJson value) values)

stickySessionsCookieTtlSeconds :: Input Number -> StickySessions -> StickySessions
stickySessionsCookieTtlSeconds value (StickySessions values) = StickySessions (insertInputField "cookie_ttl_seconds" (inputJson value) values)

stickySessionsType :: Input String -> StickySessions -> StickySessions
stickySessionsType value (StickySessions values) = StickySessions (insertInputField "type" (inputJson value) values)

stickySessionsJson :: StickySessions -> Json
stickySessionsJson (StickySessions values) = inputObjectJson values

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

algorithm :: Input String -> Args -> Args
algorithm value (Args values) = Args (insertInputField "algorithm" (inputJson value) values)

disableLetsEncryptDnsRecords :: Input Boolean -> Args -> Args
disableLetsEncryptDnsRecords value (Args values) = Args (insertInputField "disable_lets_encrypt_dns_records" (inputJson value) values)

domains :: Array Domains -> Args -> Args
domains value (Args values) = Args (insertInputField "domains" (arrayExprJson (map domainsJson value)) values)

dropletIds :: Input (Array Number) -> Args -> Args
dropletIds value (Args values) = Args (insertInputField "droplet_ids" (inputJson value) values)

dropletTag :: Input String -> Args -> Args
dropletTag value (Args values) = Args (insertInputField "droplet_tag" (inputJson value) values)

enableBackendKeepalive :: Input Boolean -> Args -> Args
enableBackendKeepalive value (Args values) = Args (insertInputField "enable_backend_keepalive" (inputJson value) values)

enableProxyProtocol :: Input Boolean -> Args -> Args
enableProxyProtocol value (Args values) = Args (insertInputField "enable_proxy_protocol" (inputJson value) values)

firewall :: Array Firewall -> Args -> Args
firewall value (Args values) = Args (insertInputField "firewall" (arrayExprJson (map firewallJson value)) values)

forwardingRule :: Array ForwardingRule -> Args -> Args
forwardingRule value (Args values) = Args (insertInputField "forwarding_rule" (arrayExprJson (map forwardingRuleJson value)) values)

glbSettings :: Array GlbSettings -> Args -> Args
glbSettings value (Args values) = Args (insertInputField "glb_settings" (arrayExprJson (map glbSettingsJson value)) values)

healthcheck :: Array Healthcheck -> Args -> Args
healthcheck value (Args values) = Args (insertInputField "healthcheck" (arrayExprJson (map healthcheckJson value)) values)

httpIdleTimeoutSeconds :: Input Number -> Args -> Args
httpIdleTimeoutSeconds value (Args values) = Args (insertInputField "http_idle_timeout_seconds" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ip :: Input String -> Args -> Args
ip value (Args values) = Args (insertInputField "ip" (inputJson value) values)

network :: Input String -> Args -> Args
network value (Args values) = Args (insertInputField "network" (inputJson value) values)

networkStack :: Input String -> Args -> Args
networkStack value (Args values) = Args (insertInputField "network_stack" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (insertInputField "project_id" (inputJson value) values)

redirectHttpToHttps :: Input Boolean -> Args -> Args
redirectHttpToHttps value (Args values) = Args (insertInputField "redirect_http_to_https" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

size :: Input String -> Args -> Args
size value (Args values) = Args (insertInputField "size" (inputJson value) values)

sizeUnit :: Input Number -> Args -> Args
sizeUnit value (Args values) = Args (insertInputField "size_unit" (inputJson value) values)

stickySessions :: Array StickySessions -> Args -> Args
stickySessions value (Args values) = Args (insertInputField "sticky_sessions" (arrayExprJson (map stickySessionsJson value)) values)

subnetUuid :: Input String -> Args -> Args
subnetUuid value (Args values) = Args (insertInputField "subnet_uuid" (inputJson value) values)

targetLoadBalancerIds :: Input (Array String) -> Args -> Args
targetLoadBalancerIds value (Args values) = Args (insertInputField "target_load_balancer_ids" (inputJson value) values)

tlsCipherPolicy :: Input String -> Args -> Args
tlsCipherPolicy value (Args values) = Args (insertInputField "tls_cipher_policy" (inputJson value) values)

type_ :: Input String -> Args -> Args
type_ value (Args values) = Args (insertInputField "type" (inputJson value) values)

vpcUuid :: Input String -> Args -> Args
vpcUuid value (Args values) = Args (insertInputField "vpc_uuid" (inputJson value) values)

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
