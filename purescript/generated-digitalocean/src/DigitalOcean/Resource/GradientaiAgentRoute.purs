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

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data GradientaiAgentRouteResource

type Required =
  { childAgentUuid :: Input String
  , parentAgentUuid :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "child_agent_uuid" (inputJson required.childAgentUuid)
  , Tuple "parent_agent_uuid" (inputJson required.parentAgentUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ifCase :: Input String -> Args -> Args
ifCase value (Args values) = Args (Object.insert "if_case" (inputJson value) values)

rollback :: Input Boolean -> Args -> Args
rollback value (Args values) = Args (Object.insert "rollback" (inputJson value) values)

routeName :: Input String -> Args -> Args
routeName value (Args values) = Args (Object.insert "route_name" (inputJson value) values)

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
