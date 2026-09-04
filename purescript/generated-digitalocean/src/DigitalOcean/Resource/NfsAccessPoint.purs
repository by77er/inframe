module DigitalOcean.Resource.NfsAccessPoint
  ( Args
  , Required
  , NfsAccessPoint
  , NfsAccessPointResource
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

data NfsAccessPointResource

type Required =
  { accessPolicy :: Input (Array ({ anongid :: Number, anonuid :: Number, identityEnforcementEnabled :: Boolean, protocols :: Array String, squashConfig :: String }))
  , name :: Input String
  , path :: Input String
  , shareId :: Input String
  , vpcId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "access_policy" (inputJson required.accessPolicy)
  , Tuple "name" (inputJson required.name)
  , Tuple "path" (inputJson required.path)
  , Tuple "share_id" (inputJson required.shareId)
  , Tuple "vpc_id" (inputJson required.vpcId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type NfsAccessPoint =
  { resource :: Resource NfsAccessPointResource
  , createdAt :: Expr String
  , id :: Expr String
  , isDefault :: Expr Boolean
  , name :: Expr String
  , path :: Expr String
  , shareId :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  , vpcId :: Expr String
  }

create :: String -> Args -> Infra NfsAccessPoint
create logicalName (Args values) = do
  handle <- addResource "digitalocean_nfs_access_point" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , isDefault: resourceAttr handle [ "is_default" ]
    , name: resourceAttr handle [ "name" ]
    , path: resourceAttr handle [ "path" ]
    , shareId: resourceAttr handle [ "share_id" ]
    , status: resourceAttr handle [ "status" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , vpcId: resourceAttr handle [ "vpc_id" ]
    }
