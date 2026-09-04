module DigitalOcean.Resource.UptimeAlert
  ( Args
  , Required
  , UptimeAlert
  , UptimeAlertResource
  , args
  , create
  , comparison
  , period
  , threshold
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data UptimeAlertResource

type Required =
  { checkId :: Input String
  , name :: Input String
  , notifications :: Input (Array ({ email :: Array String, slack :: Array ({ channel :: String, url :: String }) }))
  , type_ :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "check_id" (inputJson required.checkId)
  , Tuple "name" (inputJson required.name)
  , Tuple "notifications" (inputJson required.notifications)
  , Tuple "type" (inputJson required.type_)
  ])

comparison :: Input String -> Args -> Args
comparison value (Args values) = Args (Object.insert "comparison" (inputJson value) values)

period :: Input String -> Args -> Args
period value (Args values) = Args (Object.insert "period" (inputJson value) values)

threshold :: Input Number -> Args -> Args
threshold value (Args values) = Args (Object.insert "threshold" (inputJson value) values)

type UptimeAlert =
  { resource :: Resource UptimeAlertResource
  , checkId :: Expr String
  , comparison :: Expr String
  , id :: Expr String
  , name :: Expr String
  , period :: Expr String
  , threshold :: Expr Number
  , type_ :: Expr String
  }

create :: String -> Args -> Infra UptimeAlert
create logicalName (Args values) = do
  handle <- addResource "digitalocean_uptime_alert" logicalName values
  pure
    { resource: handle
    , checkId: resourceAttr handle [ "check_id" ]
    , comparison: resourceAttr handle [ "comparison" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , period: resourceAttr handle [ "period" ]
    , threshold: resourceAttr handle [ "threshold" ]
    , type_: resourceAttr handle [ "type" ]
    }
