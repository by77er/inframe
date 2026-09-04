module DigitalOcean.Resource.UptimeAlert
  ( Args
  , Required
  , UptimeAlert
  , UptimeAlertResource
  , args
  , create
  , Notifications
  , NotificationsRequired
  , notificationsArgs
  , notificationsEmail
  , notificationsSlack
  , NotificationsSlack
  , NotificationsSlackRequired
  , notificationsSlackArgs
  , comparison
  , period
  , threshold
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data UptimeAlertResource

newtype Notifications = Notifications InputObject

type NotificationsRequired =
  {
  }

notificationsArgs :: NotificationsRequired -> Notifications
notificationsArgs _ = Notifications (inputObject
  [
  ])

notificationsEmail :: Input (Array String) -> Notifications -> Notifications
notificationsEmail value (Notifications values) = Notifications (insertInputField "email" (inputJson value) values)

notificationsSlack :: Array NotificationsSlack -> Notifications -> Notifications
notificationsSlack value (Notifications values) = Notifications (insertInputField "slack" (arrayExprJson (map notificationsSlackJson value)) values)

notificationsJson :: Notifications -> Json
notificationsJson (Notifications values) = inputObjectJson values

newtype NotificationsSlack = NotificationsSlack InputObject

type NotificationsSlackRequired =
  { channel :: Input String
  , url :: Input String
  }

notificationsSlackArgs :: NotificationsSlackRequired -> NotificationsSlack
notificationsSlackArgs required = NotificationsSlack (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

notificationsSlackJson :: NotificationsSlack -> Json
notificationsSlackJson (NotificationsSlack values) = inputObjectJson values

type Required =
  { checkId :: Input String
  , name :: Input String
  , notifications :: Array Notifications
  , type_ :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "check_id" (inputJson required.checkId)
  , Tuple "name" (inputJson required.name)
  , Tuple "notifications" (arrayExprJson (map notificationsJson required.notifications))
  , Tuple "type" (inputJson required.type_)
  ])

comparison :: Input String -> Args -> Args
comparison value (Args values) = Args (insertInputField "comparison" (inputJson value) values)

period :: Input String -> Args -> Args
period value (Args values) = Args (insertInputField "period" (inputJson value) values)

threshold :: Input Number -> Args -> Args
threshold value (Args values) = Args (insertInputField "threshold" (inputJson value) values)

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
