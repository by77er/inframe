module DigitalOcean.Data.NfsAccessPoint
  ( Args
  , Required
  , NfsAccessPoint
  , NfsAccessPointDataSource
  , args
  , read
  , id
  , name
  , shareId
  , vpcId
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data NfsAccessPointDataSource

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

shareId :: Input String -> Args -> Args
shareId value (Args values) = Args (insertInputField "share_id" (inputJson value) values)

vpcId :: Input String -> Args -> Args
vpcId value (Args values) = Args (insertInputField "vpc_id" (inputJson value) values)

type NfsAccessPoint =
  { dataSource :: DataSource NfsAccessPointDataSource
  , accessPolicy :: Expr (Array ({ anongid :: Number, anonuid :: Number, identityEnforcementEnabled :: Boolean, protocols :: Array String, squashConfig :: String }))
  , createdAt :: Expr String
  , id :: Expr String
  , isDefault :: Expr Boolean
  , name :: Expr String
  , path :: Expr String
  , shareId :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  , vpcId :: Expr String
  }

read :: String -> Args -> Infra NfsAccessPoint
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_nfs_access_point" logicalName values
  pure
    { dataSource: handle
    , accessPolicy: dataSourceAttr handle [ "access_policy" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , isDefault: dataSourceAttr handle [ "is_default" ]
    , name: dataSourceAttr handle [ "name" ]
    , path: dataSourceAttr handle [ "path" ]
    , shareId: dataSourceAttr handle [ "share_id" ]
    , status: dataSourceAttr handle [ "status" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , vpcId: dataSourceAttr handle [ "vpc_id" ]
    }
