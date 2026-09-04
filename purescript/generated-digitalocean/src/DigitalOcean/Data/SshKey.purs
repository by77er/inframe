module DigitalOcean.Data.SshKey
  ( Args
  , Required
  , SshKey
  , SshKeyDataSource
  , args
  , read
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data SshKeyDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
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
