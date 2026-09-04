module DigitalOcean.Resource.VpcNatGateway
  ( Args
  , Required
  , VpcNatGateway
  , VpcNatGatewayResource
  , args
  , create
  , egresses
  , icmpTimeoutSeconds
  , projectId
  , tcpTimeoutSeconds
  , udpTimeoutSeconds
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data VpcNatGatewayResource

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input Number
  , type_ :: Input String
  , vpcs :: Input (Array ({ defaultGateway :: Boolean, gatewayIp :: String, subnetUuid :: String, vpcUuid :: String }))
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  , Tuple "type" (inputJson required.type_)
  , Tuple "vpcs" (inputJson required.vpcs)
  ])

egresses :: Input (Array ({ publicGateways :: Array ({ ipv4 :: String }) })) -> Args -> Args
egresses value (Args values) = Args (Object.insert "egresses" (inputJson value) values)

icmpTimeoutSeconds :: Input Number -> Args -> Args
icmpTimeoutSeconds value (Args values) = Args (Object.insert "icmp_timeout_seconds" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (Object.insert "project_id" (inputJson value) values)

tcpTimeoutSeconds :: Input Number -> Args -> Args
tcpTimeoutSeconds value (Args values) = Args (Object.insert "tcp_timeout_seconds" (inputJson value) values)

udpTimeoutSeconds :: Input Number -> Args -> Args
udpTimeoutSeconds value (Args values) = Args (Object.insert "udp_timeout_seconds" (inputJson value) values)

type VpcNatGateway =
  { resource :: Resource VpcNatGatewayResource
  , createdAt :: Expr String
  , icmpTimeoutSeconds :: Expr Number
  , id :: Expr String
  , name :: Expr String
  , projectId :: Expr String
  , region :: Expr String
  , size :: Expr Number
  , state :: Expr String
  , tcpTimeoutSeconds :: Expr Number
  , type_ :: Expr String
  , udpTimeoutSeconds :: Expr Number
  , updatedAt :: Expr String
  }

create :: String -> Args -> Infra VpcNatGateway
create logicalName (Args values) = do
  handle <- addResource "digitalocean_vpc_nat_gateway" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , icmpTimeoutSeconds: resourceAttr handle [ "icmp_timeout_seconds" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , state: resourceAttr handle [ "state" ]
    , tcpTimeoutSeconds: resourceAttr handle [ "tcp_timeout_seconds" ]
    , type_: resourceAttr handle [ "type" ]
    , udpTimeoutSeconds: resourceAttr handle [ "udp_timeout_seconds" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    }
