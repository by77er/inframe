module DigitalOcean.Data.Nfs
  ( Args
  , Required
  , Nfs
  , NfsDataSource
  , args
  , read
  , id
  , region
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data NfsDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

type Nfs =
  { dataSource :: DataSource NfsDataSource
  , host :: Expr String
  , id :: Expr String
  , mountPath :: Expr String
  , name :: Expr String
  , performanceTier :: Expr String
  , region :: Expr String
  , size :: Expr Number
  , status :: Expr String
  , tags :: Expr (Array String)
  }

read :: String -> Args -> Infra Nfs
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_nfs" logicalName values
  pure
    { dataSource: handle
    , host: dataSourceAttr handle [ "host" ]
    , id: dataSourceAttr handle [ "id" ]
    , mountPath: dataSourceAttr handle [ "mount_path" ]
    , name: dataSourceAttr handle [ "name" ]
    , performanceTier: dataSourceAttr handle [ "performance_tier" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , status: dataSourceAttr handle [ "status" ]
    , tags: dataSourceAttr handle [ "tags" ]
    }
