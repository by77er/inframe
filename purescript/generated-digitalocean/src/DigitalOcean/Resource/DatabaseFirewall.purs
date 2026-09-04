module DigitalOcean.Resource.DatabaseFirewall
  ( Args
  , Required
  , DatabaseFirewall
  , DatabaseFirewallResource
  , args
  , create
  , Rule
  , RuleRequired
  , ruleArgs
  , id
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data DatabaseFirewallResource

newtype Rule = Rule InputObject

type RuleRequired =
  { type_ :: Input String
  , value :: Input String
  }

ruleArgs :: RuleRequired -> Rule
ruleArgs required = Rule (inputObject
  [ Tuple "type" (inputJson required.type_)
  , Tuple "value" (inputJson required.value)
  ])

ruleJson :: Rule -> Json
ruleJson (Rule values) = inputObjectJson values

type Required =
  { clusterId :: Input String
  , rule :: Array Rule
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "rule" (arrayExprJson (map ruleJson required.rule))
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type DatabaseFirewall =
  { resource :: Resource DatabaseFirewallResource
  , clusterId :: Expr String
  , id :: Expr String
  }

create :: String -> Args -> Infra DatabaseFirewall
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_firewall" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    }
