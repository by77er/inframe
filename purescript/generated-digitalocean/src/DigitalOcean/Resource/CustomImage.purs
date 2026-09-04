module DigitalOcean.Resource.CustomImage
  ( Args
  , Required
  , CustomImage
  , CustomImageResource
  , args
  , create
  , description
  , distribution
  , id
  , tags
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data CustomImageResource

type Required =
  { name :: Input String
  , regions :: Input (Array String)
  , url :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "regions" (inputJson required.regions)
  , Tuple "url" (inputJson required.url)
  ])

description :: Input String -> Args -> Args
description value (Args values) = Args (Object.insert "description" (inputJson value) values)

distribution :: Input String -> Args -> Args
distribution value (Args values) = Args (Object.insert "distribution" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

timeouts :: Input ({ create :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

type CustomImage =
  { resource :: Resource CustomImageResource
  , createdAt :: Expr String
  , description :: Expr String
  , distribution :: Expr String
  , id :: Expr String
  , imageId :: Expr Number
  , minDiskSize :: Expr Number
  , name :: Expr String
  , public :: Expr Boolean
  , regions :: Expr (Array String)
  , sizeGigabytes :: Expr Number
  , slug :: Expr String
  , status :: Expr String
  , tags :: Expr (Array String)
  , type_ :: Expr String
  , url :: Expr String
  }

create :: String -> Args -> Infra CustomImage
create logicalName (Args values) = do
  handle <- addResource "digitalocean_custom_image" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , description: resourceAttr handle [ "description" ]
    , distribution: resourceAttr handle [ "distribution" ]
    , id: resourceAttr handle [ "id" ]
    , imageId: resourceAttr handle [ "image_id" ]
    , minDiskSize: resourceAttr handle [ "min_disk_size" ]
    , name: resourceAttr handle [ "name" ]
    , public: resourceAttr handle [ "public" ]
    , regions: resourceAttr handle [ "regions" ]
    , sizeGigabytes: resourceAttr handle [ "size_gigabytes" ]
    , slug: resourceAttr handle [ "slug" ]
    , status: resourceAttr handle [ "status" ]
    , tags: resourceAttr handle [ "tags" ]
    , type_: resourceAttr handle [ "type" ]
    , url: resourceAttr handle [ "url" ]
    }
