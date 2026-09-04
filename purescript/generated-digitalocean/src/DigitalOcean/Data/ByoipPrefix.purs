module DigitalOcean.Data.ByoipPrefix
  ( Args
  , Required
  , ByoipPrefix
  , ByoipPrefixDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data ByoipPrefixDataSource

type Required =
  { uuid :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "uuid" (inputJson required.uuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type ByoipPrefix =
  { dataSource :: DataSource ByoipPrefixDataSource
  , advertised :: Expr Boolean
  , failureReason :: Expr String
  , id :: Expr String
  , prefix :: Expr String
  , region :: Expr String
  , status :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra ByoipPrefix
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_byoip_prefix" logicalName values
  pure
    { dataSource: handle
    , advertised: dataSourceAttr handle [ "advertised" ]
    , failureReason: dataSourceAttr handle [ "failure_reason" ]
    , id: dataSourceAttr handle [ "id" ]
    , prefix: dataSourceAttr handle [ "prefix" ]
    , region: dataSourceAttr handle [ "region" ]
    , status: dataSourceAttr handle [ "status" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
