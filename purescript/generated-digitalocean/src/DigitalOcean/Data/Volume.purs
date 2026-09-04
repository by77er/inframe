module DigitalOcean.Data.Volume
  ( Args
  , Required
  , Volume
  , VolumeDataSource
  , args
  , read
  , description
  , id
  , region
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data VolumeDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

description :: Input String -> Args -> Args
description value (Args values) = Args (insertInputField "description" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

region :: Input String -> Args -> Args
region value (Args values) = Args (insertInputField "region" (inputJson value) values)

type Volume =
  { dataSource :: DataSource VolumeDataSource
  , description :: Expr String
  , dropletIds :: Expr (Array Number)
  , filesystemLabel :: Expr String
  , filesystemType :: Expr String
  , id :: Expr String
  , name :: Expr String
  , region :: Expr String
  , size :: Expr Number
  , tags :: Expr (Array String)
  , urn :: Expr String
  }

read :: String -> Args -> Infra Volume
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_volume" logicalName values
  pure
    { dataSource: handle
    , description: dataSourceAttr handle [ "description" ]
    , dropletIds: dataSourceAttr handle [ "droplet_ids" ]
    , filesystemLabel: dataSourceAttr handle [ "filesystem_label" ]
    , filesystemType: dataSourceAttr handle [ "filesystem_type" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , region: dataSourceAttr handle [ "region" ]
    , size: dataSourceAttr handle [ "size" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
