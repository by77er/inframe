module DigitalOcean.Resource.ProjectResources
  ( Args
  , Required
  , ProjectResources
  , ProjectResourcesResource
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

data ProjectResourcesResource

type Required =
  { project :: Input String
  , resources :: Input (Array String)
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "project" (inputJson required.project)
  , Tuple "resources" (inputJson required.resources)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type ProjectResources =
  { resource :: Resource ProjectResourcesResource
  , id :: Expr String
  , project :: Expr String
  , resources :: Expr (Array String)
  }

create :: String -> Args -> Infra ProjectResources
create logicalName (Args values) = do
  handle <- addResource "digitalocean_project_resources" logicalName values
  pure
    { resource: handle
    , id: resourceAttr handle [ "id" ]
    , project: resourceAttr handle [ "project" ]
    , resources: resourceAttr handle [ "resources" ]
    }
