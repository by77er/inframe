module DigitalOcean.Data.Domain
  ( Args
  , Required
  , Domain
  , DomainDataSource
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

data DomainDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type Domain =
  { dataSource :: DataSource DomainDataSource
  , id :: Expr String
  , name :: Expr String
  , ttl :: Expr Number
  , urn :: Expr String
  , zoneFile :: Expr String
  }

read :: String -> Args -> Infra Domain
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_domain" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , ttl: dataSourceAttr handle [ "ttl" ]
    , urn: dataSourceAttr handle [ "urn" ]
    , zoneFile: dataSourceAttr handle [ "zone_file" ]
    }
