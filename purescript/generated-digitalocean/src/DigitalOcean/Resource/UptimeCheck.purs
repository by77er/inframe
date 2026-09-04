module DigitalOcean.Resource.UptimeCheck
  ( Args
  , Required
  , UptimeCheck
  , UptimeCheckResource
  , args
  , create
  , enabled
  , regions
  , type_
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data UptimeCheckResource

type Required =
  { name :: Input String
  , target :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  , Tuple "target" (inputJson required.target)
  ])

enabled :: Input Boolean -> Args -> Args
enabled value (Args values) = Args (Object.insert "enabled" (inputJson value) values)

regions :: Input (Array String) -> Args -> Args
regions value (Args values) = Args (Object.insert "regions" (inputJson value) values)

type_ :: Input String -> Args -> Args
type_ value (Args values) = Args (Object.insert "type" (inputJson value) values)

type UptimeCheck =
  { resource :: Resource UptimeCheckResource
  , enabled :: Expr Boolean
  , id :: Expr String
  , name :: Expr String
  , regions :: Expr (Array String)
  , target :: Expr String
  , type_ :: Expr String
  }

create :: String -> Args -> Infra UptimeCheck
create logicalName (Args values) = do
  handle <- addResource "digitalocean_uptime_check" logicalName values
  pure
    { resource: handle
    , enabled: resourceAttr handle [ "enabled" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , regions: resourceAttr handle [ "regions" ]
    , target: resourceAttr handle [ "target" ]
    , type_: resourceAttr handle [ "type" ]
    }
