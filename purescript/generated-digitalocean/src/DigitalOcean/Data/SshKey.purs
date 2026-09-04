module DigitalOcean.Data.SshKey
  ( Args
  , Required
  , SshKey
  , SshKeyDataSource
  , args
  , read
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data SshKeyDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

type SshKey =
  { dataSource :: DataSource SshKeyDataSource
  , fingerprint :: Expr String
  , id :: Expr Number
  , name :: Expr String
  , publicKey :: Expr String
  }

read :: String -> Args -> Infra SshKey
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_ssh_key" logicalName values
  pure
    { dataSource: handle
    , fingerprint: dataSourceAttr handle [ "fingerprint" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , publicKey: dataSourceAttr handle [ "public_key" ]
    }
