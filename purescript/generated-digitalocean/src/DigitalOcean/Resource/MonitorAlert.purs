module DigitalOcean.Resource.MonitorAlert
  ( Args
  , Required
  , MonitorAlert
  , MonitorAlertResource
  , args
  , create
  , enabled
  , entities
  , id
  , tags
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data MonitorAlertResource

type Required =
  { alerts :: Input (Array ({ email :: Array String, slack :: Array ({ channel :: String, url :: String }) }))
  , compare :: Input String
  , description :: Input String
  , type_ :: Input String
  , value :: Input Number
  , window :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "alerts" (inputJson required.alerts)
  , Tuple "compare" (inputJson required.compare)
  , Tuple "description" (inputJson required.description)
  , Tuple "type" (inputJson required.type_)
  , Tuple "value" (inputJson required.value)
  , Tuple "window" (inputJson required.window)
  ])

enabled :: Input Boolean -> Args -> Args
enabled value (Args values) = Args (Object.insert "enabled" (inputJson value) values)

entities :: Input (Array String) -> Args -> Args
entities value (Args values) = Args (Object.insert "entities" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

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
