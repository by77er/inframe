module DigitalOcean.Resource.ContainerRegistryDockerCredentials
  ( Args
  , Required
  , ContainerRegistryDockerCredentials
  , ContainerRegistryDockerCredentialsResource
  , args
  , create
  , expirySeconds
  , id
  , write
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data ContainerRegistryDockerCredentialsResource

type Required =
  { registryName :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "registry_name" (inputJson required.registryName)
  ])

expirySeconds :: Input Number -> Args -> Args
expirySeconds value (Args values) = Args (Object.insert "expiry_seconds" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

write :: Input Boolean -> Args -> Args
write value (Args values) = Args (Object.insert "write" (inputJson value) values)

type ContainerRegistryDockerCredentials =
  { resource :: Resource ContainerRegistryDockerCredentialsResource
  , credentialExpirationTime :: Expr String
  , dockerCredentials :: Expr String
  , expirySeconds :: Expr Number
  , id :: Expr String
  , registryName :: Expr String
  , write :: Expr Boolean
  }

create :: String -> Args -> Infra ContainerRegistryDockerCredentials
create logicalName (Args values) = do
  handle <- addResource "digitalocean_container_registry_docker_credentials" logicalName values
  pure
    { resource: handle
    , credentialExpirationTime: resourceAttr handle [ "credential_expiration_time" ]
    , dockerCredentials: resourceAttr handle [ "docker_credentials" ]
    , expirySeconds: resourceAttr handle [ "expiry_seconds" ]
    , id: resourceAttr handle [ "id" ]
    , registryName: resourceAttr handle [ "registry_name" ]
    , write: resourceAttr handle [ "write" ]
    }
