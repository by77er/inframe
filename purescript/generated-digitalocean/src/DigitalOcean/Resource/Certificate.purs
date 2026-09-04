module DigitalOcean.Resource.Certificate
  ( Args
  , Required
  , Certificate
  , CertificateResource
  , args
  , create
  , certificateChain
  , domains
  , id
  , leafCertificate
  , privateKey
  , timeouts
  , type_
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data CertificateResource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

certificateChain :: Input String -> Args -> Args
certificateChain value (Args values) = Args (Object.insert "certificate_chain" (inputJson value) values)

domains :: Input (Array String) -> Args -> Args
domains value (Args values) = Args (Object.insert "domains" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

leafCertificate :: Input String -> Args -> Args
leafCertificate value (Args values) = Args (Object.insert "leaf_certificate" (inputJson value) values)

privateKey :: Input String -> Args -> Args
privateKey value (Args values) = Args (Object.insert "private_key" (inputJson value) values)

timeouts :: Input ({ create :: String, delete :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

type_ :: Input String -> Args -> Args
type_ value (Args values) = Args (Object.insert "type" (inputJson value) values)

type Certificate =
  { resource :: Resource CertificateResource
  , certificateChain :: Expr String
  , domains :: Expr (Array String)
  , id :: Expr String
  , leafCertificate :: Expr String
  , name :: Expr String
  , notAfter :: Expr String
  , privateKey :: Expr String
  , sha1Fingerprint :: Expr String
  , state :: Expr String
  , type_ :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra Certificate
create logicalName (Args values) = do
  handle <- addResource "digitalocean_certificate" logicalName values
  pure
    { resource: handle
    , certificateChain: resourceAttr handle [ "certificate_chain" ]
    , domains: resourceAttr handle [ "domains" ]
    , id: resourceAttr handle [ "id" ]
    , leafCertificate: resourceAttr handle [ "leaf_certificate" ]
    , name: resourceAttr handle [ "name" ]
    , notAfter: resourceAttr handle [ "not_after" ]
    , privateKey: resourceAttr handle [ "private_key" ]
    , sha1Fingerprint: resourceAttr handle [ "sha1_fingerprint" ]
    , state: resourceAttr handle [ "state" ]
    , type_: resourceAttr handle [ "type" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
