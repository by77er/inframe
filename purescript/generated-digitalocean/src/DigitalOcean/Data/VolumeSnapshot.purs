module DigitalOcean.Data.VolumeSnapshot
  ( Args
  , Required
  , VolumeSnapshot
  , VolumeSnapshotDataSource
  , args
  , read
  , id
  , mostRecent
  , name
  , nameRegex
  , region
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data VolumeSnapshotDataSource

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

mostRecent :: Input Boolean -> Args -> Args
mostRecent value (Args values) = Args (Object.insert "most_recent" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (Object.insert "name" (inputJson value) values)

nameRegex :: Input String -> Args -> Args
nameRegex value (Args values) = Args (Object.insert "name_regex" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (Object.insert "region" (inputJson value) values)

type VolumeSnapshot =
  { dataSource :: DataSource VolumeSnapshotDataSource
  , createdAt :: Expr String
  , id :: Expr String
  , minDiskSize :: Expr Number
  , mostRecent :: Expr Boolean
  , name :: Expr String
  , nameRegex :: Expr String
  , region :: Expr String
  , regions :: Expr (Array String)
  , size :: Expr Number
  , tags :: Expr (Array String)
  , volumeId :: Expr String
  }

read :: String -> Args -> Infra VolumeSnapshot
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_volume_snapshot" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , minDiskSize: dataSourceAttr handle [ "min_disk_size" ]
    , mostRecent: dataSourceAttr handle [ "most_recent" ]
    , name: dataSourceAttr handle [ "name" ]
    , nameRegex: dataSourceAttr handle [ "name_regex" ]
    , region: dataSourceAttr handle [ "region" ]
    , regions: dataSourceAttr handle [ "regions" ]
    , size: dataSourceAttr handle [ "size" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , volumeId: dataSourceAttr handle [ "volume_id" ]
    }
