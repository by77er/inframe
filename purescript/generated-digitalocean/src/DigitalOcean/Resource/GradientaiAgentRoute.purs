module DigitalOcean.Resource.GradientaiAgentRoute
  ( Args
  , Required
  , GradientaiAgentRoute
  , GradientaiAgentRouteResource
  , args
  , create
  , id
  , ifCase
  , rollback
  , routeName
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data GradientaiAgentRouteResource

type Required =
  { childAgentUuid :: Input String
  , parentAgentUuid :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "child_agent_uuid" (inputJson required.childAgentUuid)
  , Tuple "parent_agent_uuid" (inputJson required.parentAgentUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ifCase :: Input String -> Args -> Args
ifCase value (Args values) = Args (insertInputField "if_case" (inputJson value) values)

rollback :: Input Boolean -> Args -> Args
rollback value (Args values) = Args (insertInputField "rollback" (inputJson value) values)

routeName :: Input String -> Args -> Args
routeName value (Args values) = Args (insertInputField "route_name" (inputJson value) values)

type GradientaiAgentRoute =
  { resource :: Resource GradientaiAgentRouteResource
  , childAgentUuid :: Expr String
  , id :: Expr String
  , ifCase :: Expr String
  , parentAgentUuid :: Expr String
  , rollback :: Expr Boolean
  , routeName :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiAgentRoute
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_agent_route" logicalName values
  pure
    { resource: handle
    , childAgentUuid: resourceAttr handle [ "child_agent_uuid" ]
    , id: resourceAttr handle [ "id" ]
    , ifCase: resourceAttr handle [ "if_case" ]
    , parentAgentUuid: resourceAttr handle [ "parent_agent_uuid" ]
    , rollback: resourceAttr handle [ "rollback" ]
    , routeName: resourceAttr handle [ "route_name" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
