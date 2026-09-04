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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data NfsDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

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
