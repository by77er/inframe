module DigitalOcean.Data.Account
  ( Args
  , Required
  , Account
  , AccountDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data AccountDataSource

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

type Account =
  { dataSource :: DataSource AccountDataSource
  , dropletLimit :: Expr Number
  , email :: Expr String
  , emailVerified :: Expr Boolean
  , floatingIpLimit :: Expr Number
  , id :: Expr String
  , status :: Expr String
  , statusMessage :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra Account
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_account" logicalName values
  pure
    { dataSource: handle
    , dropletLimit: dataSourceAttr handle [ "droplet_limit" ]
    , email: dataSourceAttr handle [ "email" ]
    , emailVerified: dataSourceAttr handle [ "email_verified" ]
    , floatingIpLimit: dataSourceAttr handle [ "floating_ip_limit" ]
    , id: dataSourceAttr handle [ "id" ]
    , status: dataSourceAttr handle [ "status" ]
    , statusMessage: dataSourceAttr handle [ "status_message" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
