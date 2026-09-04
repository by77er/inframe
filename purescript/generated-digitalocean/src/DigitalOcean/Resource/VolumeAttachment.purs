module DigitalOcean.Resource.VolumeAttachment
  ( Args
  , Required
  , VolumeAttachment
  , VolumeAttachmentResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data VolumeAttachmentResource

type Required =
  { dropletId :: Input Number
  , volumeId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "droplet_id" (inputJson required.dropletId)
  , Tuple "volume_id" (inputJson required.volumeId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type VolumeAttachment =
  { resource :: Resource VolumeAttachmentResource
  , dropletId :: Expr Number
  , id :: Expr String
  , volumeId :: Expr String
  }

create :: String -> Args -> Infra VolumeAttachment
create logicalName (Args values) = do
  handle <- addResource "digitalocean_volume_attachment" logicalName values
  pure
    { resource: handle
    , dropletId: resourceAttr handle [ "droplet_id" ]
    , id: resourceAttr handle [ "id" ]
    , volumeId: resourceAttr handle [ "volume_id" ]
    }
