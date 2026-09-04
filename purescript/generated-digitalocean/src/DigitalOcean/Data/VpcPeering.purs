module DigitalOcean.Data.VpcPeering
  ( Args
  , Required
  , VpcPeering
  , VpcPeeringDataSource
  , args
  , read
  , id
  , name
  , vpcIds
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data VpcPeeringDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

vpcIds :: Input (Array String) -> Args -> Args
vpcIds value (Args values) = Args (Object.insert "vpc_ids" (inputJson value) values)

type VpcPeering =
  { dataSource :: DataSource VpcPeeringDataSource
  , createdAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , status :: Expr String
  , vpcIds :: Expr (Array String)
  }

read :: String -> Args -> Infra VpcPeering
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_vpc_peering" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , status: dataSourceAttr handle [ "status" ]
    , vpcIds: dataSourceAttr handle [ "vpc_ids" ]
    }
