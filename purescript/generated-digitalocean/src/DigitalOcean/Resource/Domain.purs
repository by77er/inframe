module DigitalOcean.Resource.Domain
  ( Args
  , Required
  , Domain
  , DomainResource
  , args
  , create
  , id
  , ipAddress
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DomainResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ipAddress :: Input String -> Args -> Args
ipAddress value (Args values) = Args (Object.insert "ip_address" (inputJson value) values)

type Domain =
  { resource :: Resource DomainResource
  , id :: Expr String
  , ipAddress :: Expr String
  , name :: Expr String
  , ttl :: Expr Number
  , urn :: Expr String
  }

create :: String -> Args -> Infra Domain
create logicalName (Args values) = do
  handle <- addResource "digitalocean_domain" logicalName values
  pure
    { resource: handle
    , id: resourceAttr handle [ "id" ]
    , ipAddress: resourceAttr handle [ "ip_address" ]
    , name: resourceAttr handle [ "name" ]
    , ttl: resourceAttr handle [ "ttl" ]
    , urn: resourceAttr handle [ "urn" ]
    }
