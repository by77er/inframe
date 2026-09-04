module DigitalOcean.Resource.SshKey
  ( Args
  , Required
  , SshKey
  , SshKeyResource
  , args
  , create
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , id
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data SshKeyResource

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  { name :: Input String
  , publicKey :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  , Tuple "public_key" (inputJson required.publicKey)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

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
