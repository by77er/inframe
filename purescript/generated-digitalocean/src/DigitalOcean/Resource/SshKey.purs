module DigitalOcean.Resource.SshKey
  ( Args
  , Required
  , SshKey
  , SshKeyResource
  , args
  , create
  , id
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data SshKeyResource

type Required =
  { name :: Input String
  , publicKey :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "public_key" (inputJson required.publicKey)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

timeouts :: Input ({ create :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

type SshKey =
  { resource :: Resource SshKeyResource
  , fingerprint :: Expr String
  , id :: Expr String
  , name :: Expr String
  , publicKey :: Expr String
  }

create :: String -> Args -> Infra SshKey
create logicalName (Args values) = do
  handle <- addResource "digitalocean_ssh_key" logicalName values
  pure
    { resource: handle
    , fingerprint: resourceAttr handle [ "fingerprint" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , publicKey: resourceAttr handle [ "public_key" ]
    }
