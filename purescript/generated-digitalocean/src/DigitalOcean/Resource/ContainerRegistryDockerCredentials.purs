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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data ContainerRegistryDockerCredentialsResource

type Required =
  { registryName :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "registry_name" (inputJson required.registryName)
  ])

expirySeconds :: Input Number -> Args -> Args
expirySeconds value (Args values) = Args (insertInputField "expiry_seconds" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

write :: Input Boolean -> Args -> Args
write value (Args values) = Args (insertInputField "write" (inputJson value) values)

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
