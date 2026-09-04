module DigitalOcean.Data.NfsSnapshot
  ( Args
  , Required
  , NfsSnapshot
  , NfsSnapshotDataSource
  , args
  , read
  , id
  , name
  , nameRegex
  , region
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data NfsSnapshotDataSource

type Required =
  { shareId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "share_id" (inputJson required.shareId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

nameRegex :: Input String -> Args -> Args
nameRegex value (Args values) = Args (Object.insert "name_regex" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

type NfsSnapshot =
  { dataSource :: DataSource NfsSnapshotDataSource
  , createdAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , nameRegex :: Expr String
  , region :: Expr String
  , shareId :: Expr String
  , size :: Expr Number
  , status :: Expr Number
  , tags :: Expr (Array String)
  }

read :: String -> Args -> Infra NfsSnapshot
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_nfs_snapshot" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , nameRegex: dataSourceAttr handle [ "name_regex" ]
    , region: dataSourceAttr handle [ "region" ]
    , shareId: dataSourceAttr handle [ "share_id" ]
    , size: dataSourceAttr handle [ "size" ]
    , status: dataSourceAttr handle [ "status" ]
    , tags: dataSourceAttr handle [ "tags" ]
    }
