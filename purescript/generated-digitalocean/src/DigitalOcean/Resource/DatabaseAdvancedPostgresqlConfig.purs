module DigitalOcean.Resource.DatabaseAdvancedPostgresqlConfig
  ( Args
  , Required
  , DatabaseAdvancedPostgresqlConfig
  , DatabaseAdvancedPostgresqlConfigResource
  , args
  , create
  , id
  , pgParameters
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseAdvancedPostgresqlConfigResource

type Required =
  { clusterId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "cluster_id" (inputJson required.clusterId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

pgParameters :: Input Json -> Args -> Args
pgParameters value (Args values) = Args (Object.insert "pg_parameters" (inputJson value) values)

type DatabaseAdvancedPostgresqlConfig =
  { resource :: Resource DatabaseAdvancedPostgresqlConfigResource
  , clusterId :: Expr String
  , id :: Expr String
  , pgParameters :: Expr Json
  }

create :: String -> Args -> Infra DatabaseAdvancedPostgresqlConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_advanced_postgresql_config" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , pgParameters: resourceAttr handle [ "pg_parameters" ]
    }
