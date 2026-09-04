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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseDbResource

type Required =
  { clusterId :: Input String
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
