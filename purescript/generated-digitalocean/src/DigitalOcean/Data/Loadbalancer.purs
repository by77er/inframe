module DigitalOcean.Data.Loadbalancer
  ( Args
  , Required
  , Loadbalancer
  , LoadbalancerDataSource
  , args
  , read
  , id
  , name
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data LoadbalancerDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (insertInputField "name" (inputJson value) values)

type Loadbalancer =
  { dataSource :: DataSource LoadbalancerDataSource
  , algorithm :: Expr String
  , disableLetsEncryptDnsRecords :: Expr Boolean
  , domains :: Expr (Array ({ certificateId :: String, certificateName :: String, isManaged :: Boolean, name :: String, sslValidationErrorReasons :: Array String, verificationErrorReasons :: Array String }))
  , dropletIds :: Expr (Array Number)
  , dropletTag :: Expr String
  , enableBackendKeepalive :: Expr Boolean
  , enableProxyProtocol :: Expr Boolean
  , firewall :: Expr (Array ({ allow :: Array String, deny :: Array String }))
  , forwardingRule :: Expr (Array ({ certificateId :: String, certificateName :: String, entryPort :: Number, entryProtocol :: String, targetPort :: Number, targetProtocol :: String, tlsPassthrough :: Boolean }))
  , glbSettings :: Expr (Array ({ cdn :: Array ({ isEnabled :: Boolean }), failoverThreshold :: Number, regionPriorities :: Json, targetPort :: Number, targetProtocol :: String }))
  , healthcheck :: Expr (Array ({ checkIntervalSeconds :: Number, healthyThreshold :: Number, path :: String, port :: Number, protocol :: String, responseTimeoutSeconds :: Number, unhealthyThreshold :: Number }))
  , httpIdleTimeoutSeconds :: Expr Number
  , id :: Expr String
  , ip :: Expr String
  , ipv6 :: Expr String
  , name :: Expr String
  , network :: Expr String
  , projectId :: Expr String
  , redirectHttpToHttps :: Expr Boolean
  , region :: Expr String
  , size :: Expr String
  , sizeUnit :: Expr Number
  , status :: Expr String
  , stickySessions :: Expr (Array ({ cookieName :: String, cookieTtlSeconds :: Number, type_ :: String }))
  , subnetUuid :: Expr String
  , targetLoadBalancerIds :: Expr (Array String)
  , type_ :: Expr String
  , urn :: Expr String
  , vpcUuid :: Expr String
  }

read :: String -> Args -> Infra Loadbalancer
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_loadbalancer" logicalName values
  pure
    { dataSource: handle
    , algorithm: dataSourceAttr handle [ "algorithm" ]
    , disableLetsEncryptDnsRecords: dataSourceAttr handle [ "disable_lets_encrypt_dns_records" ]
    , domains: dataSourceAttr handle [ "domains" ]
    , dropletIds: dataSourceAttr handle [ "droplet_ids" ]
    , dropletTag: dataSourceAttr handle [ "droplet_tag" ]
    , enableBackendKeepalive: dataSourceAttr handle [ "enable_backend_keepalive" ]
    , enableProxyProtocol: dataSourceAttr handle [ "enable_proxy_protocol" ]
    , firewall: dataSourceAttr handle [ "firewall" ]
    , forwardingRule: dataSourceAttr handle [ "forwarding_rule" ]
    , glbSettings: dataSourceAttr handle [ "glb_settings" ]
    , healthcheck: dataSourceAttr handle [ "healthcheck" ]
    , httpIdleTimeoutSeconds: dataSourceAttr handle [ "http_idle_timeout_seconds" ]
    , id: dataSourceAttr handle [ "id" ]
    , ip: dataSourceAttr handle [ "ip" ]
    , ipv6: dataSourceAttr handle [ "ipv6" ]
    , name: dataSourceAttr handle [ "name" ]
    , network: dataSourceAttr handle [ "network" ]
    , projectId: dataSourceAttr handle [ "project_id" ]
    , redirectHttpToHttps: dataSourceAttr handle [ "redirect_http_to_https" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , sizeUnit: dataSourceAttr handle [ "size_unit" ]
    , status: dataSourceAttr handle [ "status" ]
    , stickySessions: dataSourceAttr handle [ "sticky_sessions" ]
    , subnetUuid: dataSourceAttr handle [ "subnet_uuid" ]
    , targetLoadBalancerIds: dataSourceAttr handle [ "target_load_balancer_ids" ]
    , type_: dataSourceAttr handle [ "type" ]
    , urn: dataSourceAttr handle [ "urn" ]
    , vpcUuid: dataSourceAttr handle [ "vpc_uuid" ]
    }
