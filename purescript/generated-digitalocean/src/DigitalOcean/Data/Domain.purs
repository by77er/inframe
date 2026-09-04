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

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DomainDataSource

type Required =
  { name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

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
