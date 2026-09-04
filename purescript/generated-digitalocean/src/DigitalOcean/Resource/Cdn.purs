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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data CdnResource

type Required =
  { origin :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "origin" (inputJson required.origin)
  ])

certificateId :: Input String -> Args -> Args
certificateId value (Args values) = Args (insertInputField "certificate_id" (inputJson value) values)

certificateName :: Input String -> Args -> Args
certificateName value (Args values) = Args (insertInputField "certificate_name" (inputJson value) values)

customDomain :: Input String -> Args -> Args
customDomain value (Args values) = Args (insertInputField "custom_domain" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ttl :: Input Number -> Args -> Args
ttl value (Args values) = Args (insertInputField "ttl" (inputJson value) values)

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
