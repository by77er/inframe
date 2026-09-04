module DigitalOcean.Resource.Volume
  ( Args
  , Required
  , Volume
  , VolumeResource
  , args
  , create
  , description
  , filesystemType
  , id
  , initialFilesystemLabel
  , initialFilesystemType
  , snapshotId
  , tags
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data VolumeResource

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input Number
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "region" (inputJson required.region)
  , Tuple "size" (inputJson required.size)
  ])

description :: Input String -> Args -> Args
description value (Args values) = Args (insertInputField "description" (inputJson value) values)

filesystemType :: Input String -> Args -> Args
filesystemType value (Args values) = Args (insertInputField "filesystem_type" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

initialFilesystemLabel :: Input String -> Args -> Args
initialFilesystemLabel value (Args values) = Args (insertInputField "initial_filesystem_label" (inputJson value) values)

initialFilesystemType :: Input String -> Args -> Args
initialFilesystemType value (Args values) = Args (insertInputField "initial_filesystem_type" (inputJson value) values)

snapshotId :: Input String -> Args -> Args
snapshotId value (Args values) = Args (insertInputField "snapshot_id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

type Volume =
  { resource :: Resource VolumeResource
  , description :: Expr String
  , dropletIds :: Expr (Array Number)
  , filesystemLabel :: Expr String
  , filesystemType :: Expr String
  , id :: Expr String
  , initialFilesystemLabel :: Expr String
  , initialFilesystemType :: Expr String
  , name :: Expr String
  , region :: Expr String
  , size :: Expr Number
  , snapshotId :: Expr String
  , tags :: Expr (Array String)
  , urn :: Expr String
  }

create :: String -> Args -> Infra Volume
create logicalName (Args values) = do
  handle <- addResource "digitalocean_volume" logicalName values
  pure
    { resource: handle
    , description: resourceAttr handle [ "description" ]
    , dropletIds: resourceAttr handle [ "droplet_ids" ]
    , filesystemLabel: resourceAttr handle [ "filesystem_label" ]
    , filesystemType: resourceAttr handle [ "filesystem_type" ]
    , id: resourceAttr handle [ "id" ]
    , initialFilesystemLabel: resourceAttr handle [ "initial_filesystem_label" ]
    , initialFilesystemType: resourceAttr handle [ "initial_filesystem_type" ]
    , name: resourceAttr handle [ "name" ]
    , region: resourceAttr handle [ "region" ]
    , size: resourceAttr handle [ "size" ]
    , snapshotId: resourceAttr handle [ "snapshot_id" ]
    , tags: resourceAttr handle [ "tags" ]
    , urn: resourceAttr handle [ "urn" ]
    }
