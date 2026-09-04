module DigitalOcean.Resource.DatabaseFirewall
  ( Args
  , Required
  , DatabaseFirewall
  , DatabaseFirewallResource
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

data DatabaseFirewallResource

type Required =
  { clusterId :: Input String
  , rule :: Input (Array ({ createdAt :: String, type_ :: String, uuid :: String, value :: String }))
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "rule" (inputJson required.rule)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
