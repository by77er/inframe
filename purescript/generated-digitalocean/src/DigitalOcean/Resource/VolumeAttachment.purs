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

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data VolumeAttachmentResource

type Required =
  { dropletId :: Input Number
  , volumeId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "droplet_id" (inputJson required.dropletId)
  , Tuple "volume_id" (inputJson required.volumeId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
