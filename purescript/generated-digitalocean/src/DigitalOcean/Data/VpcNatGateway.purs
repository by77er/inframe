module DigitalOcean.Data.VpcNatGateway
  ( Args
  , Required
  , VpcNatGateway
  , VpcNatGatewayDataSource
  , args
  , read
  , id
  , name
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data VpcNatGatewayDataSource

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

type VpcNatGateway =
  { dataSource :: DataSource VpcNatGatewayDataSource
  , createdAt :: Expr String
  , egresses :: Expr (Array ({ publicGateways :: Array ({ ipv4 :: String }) }))
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
  , vpcs :: Expr (Array ({ defaultGateway :: Boolean, gatewayIp :: String, subnetUuid :: String, vpcUuid :: String }))
  }

read :: String -> Args -> Infra VpcNatGateway
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_vpc_nat_gateway" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , egresses: dataSourceAttr handle [ "egresses" ]
    , icmpTimeoutSeconds: dataSourceAttr handle [ "icmp_timeout_seconds" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , projectId: dataSourceAttr handle [ "project_id" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , state: dataSourceAttr handle [ "state" ]
    , tcpTimeoutSeconds: dataSourceAttr handle [ "tcp_timeout_seconds" ]
    , type_: dataSourceAttr handle [ "type" ]
    , udpTimeoutSeconds: dataSourceAttr handle [ "udp_timeout_seconds" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , vpcs: dataSourceAttr handle [ "vpcs" ]
    }
