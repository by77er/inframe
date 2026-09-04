module DigitalOcean.Resource.VpcNatGateway
  ( Args
  , Required
  , VpcNatGateway
  , VpcNatGatewayResource
  , args
  , create
  , Egresses
  , EgressesRequired
  , egressesArgs
  , egressesPublicGateways
  , EgressesPublicGateways
  , EgressesPublicGatewaysRequired
  , egressesPublicGatewaysArgs
  , egressesPublicGatewaysIpv4
  , Vpcs
  , VpcsRequired
  , vpcsArgs
  , vpcsDefaultGateway
  , vpcsSubnetUuid
  , egresses
  , icmpTimeoutSeconds
  , projectId
  , tcpTimeoutSeconds
  , udpTimeoutSeconds
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data VpcNatGatewayResource

newtype Egresses = Egresses InputObject

type EgressesRequired =
  {
  }

egressesArgs :: EgressesRequired -> Egresses
egressesArgs _ = Egresses (inputObject
  [
  ])

egressesPublicGateways :: Array EgressesPublicGateways -> Egresses -> Egresses
egressesPublicGateways value (Egresses values) = Egresses (insertInputField "public_gateways" (arrayExprJson (map egressesPublicGatewaysJson value)) values)

egressesJson :: Egresses -> Json
egressesJson (Egresses values) = inputObjectJson values

newtype EgressesPublicGateways = EgressesPublicGateways InputObject

type EgressesPublicGatewaysRequired =
  {
  }

egressesPublicGatewaysArgs :: EgressesPublicGatewaysRequired -> EgressesPublicGateways
egressesPublicGatewaysArgs _ = EgressesPublicGateways (inputObject
  [
  ])

egressesPublicGatewaysIpv4 :: Input String -> EgressesPublicGateways -> EgressesPublicGateways
egressesPublicGatewaysIpv4 value (EgressesPublicGateways values) = EgressesPublicGateways (insertInputField "ipv4" (inputJson value) values)

egressesPublicGatewaysJson :: EgressesPublicGateways -> Json
egressesPublicGatewaysJson (EgressesPublicGateways values) = inputObjectJson values

newtype Vpcs = Vpcs InputObject

type VpcsRequired =
  { vpcUuid :: Input String
  }

vpcsArgs :: VpcsRequired -> Vpcs
vpcsArgs required = Vpcs (inputObject
  [ Tuple "vpc_uuid" (inputJson required.vpcUuid)
  ])

vpcsDefaultGateway :: Input Boolean -> Vpcs -> Vpcs
vpcsDefaultGateway value (Vpcs values) = Vpcs (insertInputField "default_gateway" (inputJson value) values)

vpcsSubnetUuid :: Input String -> Vpcs -> Vpcs
vpcsSubnetUuid value (Vpcs values) = Vpcs (insertInputField "subnet_uuid" (inputJson value) values)

vpcsJson :: Vpcs -> Json
vpcsJson (Vpcs values) = inputObjectJson values

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input Number
  , type_ :: Input String
  , vpcs :: Array Vpcs
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  , Tuple "type" (inputJson required.type_)
  , Tuple "vpcs" (arrayExprJson (map vpcsJson required.vpcs))
  ])

egresses :: Array Egresses -> Args -> Args
egresses value (Args values) = Args (insertInputField "egresses" (arrayExprJson (map egressesJson value)) values)

icmpTimeoutSeconds :: Input Number -> Args -> Args
icmpTimeoutSeconds value (Args values) = Args (insertInputField "icmp_timeout_seconds" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (insertInputField "project_id" (inputJson value) values)

tcpTimeoutSeconds :: Input Number -> Args -> Args
tcpTimeoutSeconds value (Args values) = Args (insertInputField "tcp_timeout_seconds" (inputJson value) values)

udpTimeoutSeconds :: Input Number -> Args -> Args
udpTimeoutSeconds value (Args values) = Args (insertInputField "udp_timeout_seconds" (inputJson value) values)

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
