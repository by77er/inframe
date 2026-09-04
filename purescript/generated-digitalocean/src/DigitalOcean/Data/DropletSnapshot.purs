module DigitalOcean.Data.DropletSnapshot
  ( Args
  , Required
  , DropletSnapshot
  , DropletSnapshotDataSource
  , args
  , read
  , id
  , mostRecent
  , name
  , nameRegex
  , region
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DropletSnapshotDataSource

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

mostRecent :: Input Boolean -> Args -> Args
mostRecent value (Args values) = Args (insertInputField "most_recent" (inputJson value) values)

name :: Input String -> Args -> Args
name value (Args values) = Args (insertInputField "name" (inputJson value) values)

nameRegex :: Input String -> Args -> Args
nameRegex value (Args values) = Args (insertInputField "name_regex" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

type DropletSnapshot =
  { dataSource :: DataSource DropletSnapshotDataSource
  , createdAt :: Expr String
  , dropletId :: Expr String
  , id :: Expr String
  , minDiskSize :: Expr Number
  , mostRecent :: Expr Boolean
  , name :: Expr String
  , nameRegex :: Expr String
  , region :: Expr String
  , regions :: Expr (Array String)
  , size :: Expr Number
  }

read :: String -> Args -> Infra DropletSnapshot
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_droplet_snapshot" logicalName values
  pure
    { dataSource: handle
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , dropletId: dataSourceAttr handle [ "droplet_id" ]
    , id: dataSourceAttr handle [ "id" ]
    , minDiskSize: dataSourceAttr handle [ "min_disk_size" ]
    , mostRecent: dataSourceAttr handle [ "most_recent" ]
    , name: dataSourceAttr handle [ "name" ]
    , nameRegex: dataSourceAttr handle [ "name_regex" ]
    , region: dataSourceAttr handle [ "region" ]
    , regions: dataSourceAttr handle [ "regions" ]
    , size: dataSourceAttr handle [ "size" ]
    }
