module DigitalOcean.Resource.MonitorAlert
  ( Args
  , Required
  , MonitorAlert
  , MonitorAlertResource
  , args
  , create
  , Alerts
  , AlertsRequired
  , alertsArgs
  , alertsEmail
  , alertsSlack
  , AlertsSlack
  , AlertsSlackRequired
  , alertsSlackArgs
  , enabled
  , entities
  , id
  , tags
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data MonitorAlertResource

newtype Alerts = Alerts InputObject

type AlertsRequired =
  {
  }

alertsArgs :: AlertsRequired -> Alerts
alertsArgs _ = Alerts (inputObject
  [
  ])

alertsEmail :: Input (Array String) -> Alerts -> Alerts
alertsEmail value (Alerts values) = Alerts (insertInputField "email" (inputJson value) values)

alertsSlack :: Array AlertsSlack -> Alerts -> Alerts
alertsSlack value (Alerts values) = Alerts (insertInputField "slack" (arrayExprJson (map alertsSlackJson value)) values)

alertsJson :: Alerts -> Json
alertsJson (Alerts values) = inputObjectJson values

newtype AlertsSlack = AlertsSlack InputObject

type AlertsSlackRequired =
  { channel :: Input String
  , url :: Input String
  }

alertsSlackArgs :: AlertsSlackRequired -> AlertsSlack
alertsSlackArgs required = AlertsSlack (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

alertsSlackJson :: AlertsSlack -> Json
alertsSlackJson (AlertsSlack values) = inputObjectJson values

type Required =
  { alerts :: Array Alerts
  , compare :: Input String
  , description :: Input String
  , type_ :: Input String
  , value :: Input Number
  , window :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "alerts" (arrayExprJson (map alertsJson required.alerts))
  , Tuple "compare" (inputJson required.compare)
  , Tuple "description" (inputJson required.description)
  , Tuple "type" (inputJson required.type_)
  , Tuple "value" (inputJson required.value)
  , Tuple "window" (inputJson required.window)
  ])

enabled :: Input Boolean -> Args -> Args
enabled value (Args values) = Args (insertInputField "enabled" (inputJson value) values)

entities :: Input (Array String) -> Args -> Args
entities value (Args values) = Args (insertInputField "entities" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

type MonitorAlert =
  { resource :: Resource MonitorAlertResource
  , compare :: Expr String
  , description :: Expr String
  , enabled :: Expr Boolean
  , entities :: Expr (Array String)
  , id :: Expr String
  , tags :: Expr (Array String)
  , type_ :: Expr String
  , uuid :: Expr String
  , value :: Expr Number
  , window :: Expr String
  }

create :: String -> Args -> Infra MonitorAlert
create logicalName (Args values) = do
  handle <- addResource "digitalocean_monitor_alert" logicalName values
  pure
    { resource: handle
    , compare: resourceAttr handle [ "compare" ]
    , description: resourceAttr handle [ "description" ]
    , enabled: resourceAttr handle [ "enabled" ]
    , entities: resourceAttr handle [ "entities" ]
    , id: resourceAttr handle [ "id" ]
    , tags: resourceAttr handle [ "tags" ]
    , type_: resourceAttr handle [ "type" ]
    , uuid: resourceAttr handle [ "uuid" ]
    , value: resourceAttr handle [ "value" ]
    , window: resourceAttr handle [ "window" ]
    }
