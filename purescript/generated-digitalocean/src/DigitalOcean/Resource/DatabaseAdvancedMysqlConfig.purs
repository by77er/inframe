module DigitalOcean.Resource.DatabaseAdvancedMysqlConfig
  ( Args
  , Required
  , DatabaseAdvancedMysqlConfig
  , DatabaseAdvancedMysqlConfigResource
  , args
  , create
  , id
  , mysqlParameters
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data DatabaseAdvancedMysqlConfigResource

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

mysqlParameters :: Input Json -> Args -> Args
mysqlParameters value (Args values) = Args (Object.insert "mysql_parameters" (inputJson value) values)

type DatabaseAdvancedMysqlConfig =
  { resource :: Resource DatabaseAdvancedMysqlConfigResource
  , clusterId :: Expr String
  , id :: Expr String
  , mysqlParameters :: Expr Json
  }

create :: String -> Args -> Infra DatabaseAdvancedMysqlConfig
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_advanced_mysql_config" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , mysqlParameters: resourceAttr handle [ "mysql_parameters" ]
    }
