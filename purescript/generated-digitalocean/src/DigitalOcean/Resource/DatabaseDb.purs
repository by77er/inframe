module DigitalOcean.Resource.DatabaseDb
  ( Args
  , Required
  , DatabaseDb
  , DatabaseDbResource
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

data DatabaseDbResource

type Required =
  { clusterId :: Input String
  , name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type DatabaseDb =
  { resource :: Resource DatabaseDbResource
  , clusterId :: Expr String
  , id :: Expr String
  , name :: Expr String
  }

create :: String -> Args -> Infra DatabaseDb
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_db" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    }
