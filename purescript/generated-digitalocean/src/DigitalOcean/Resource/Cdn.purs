module DigitalOcean.Resource.Cdn
  ( Args
  , Required
  , Cdn
  , CdnResource
  , args
  , create
  , certificateId
  , certificateName
  , customDomain
  , id
  , ttl
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data CdnResource

type Required =
  { origin :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "origin" (inputJson required.origin)
  ])

certificateId :: Input String -> Args -> Args
certificateId value (Args values) = Args (Object.insert "certificate_id" (inputJson value) values)

certificateName :: Input String -> Args -> Args
certificateName value (Args values) = Args (Object.insert "certificate_name" (inputJson value) values)

customDomain :: Input String -> Args -> Args
customDomain value (Args values) = Args (Object.insert "custom_domain" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ttl :: Input Number -> Args -> Args
ttl value (Args values) = Args (Object.insert "ttl" (inputJson value) values)

type Cdn =
  { resource :: Resource CdnResource
  , certificateId :: Expr String
  , certificateName :: Expr String
  , createdAt :: Expr String
  , customDomain :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , origin :: Expr String
  , ttl :: Expr Number
  }

create :: String -> Args -> Infra Cdn
create logicalName (Args values) = do
  handle <- addResource "digitalocean_cdn" logicalName values
  pure
    { resource: handle
    , certificateId: resourceAttr handle [ "certificate_id" ]
    , certificateName: resourceAttr handle [ "certificate_name" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , customDomain: resourceAttr handle [ "custom_domain" ]
    , endpoint: resourceAttr handle [ "endpoint" ]
    , id: resourceAttr handle [ "id" ]
    , origin: resourceAttr handle [ "origin" ]
    , ttl: resourceAttr handle [ "ttl" ]
    }
