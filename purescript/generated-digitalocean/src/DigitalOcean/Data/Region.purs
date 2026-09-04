module DigitalOcean.Data.Region
  ( Args
  , Required
  , Region
  , RegionDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data RegionDataSource

type Required =
  { slug :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "slug" (inputJson required.slug)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type Region =
  { dataSource :: DataSource RegionDataSource
  , available :: Expr Boolean
  , features :: Expr (Array String)
  , id :: Expr String
  , name :: Expr String
  , sizes :: Expr (Array String)
  , slug :: Expr String
  }

read :: String -> Args -> Infra Region
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_region" logicalName values
  pure
    { dataSource: handle
    , available: dataSourceAttr handle [ "available" ]
    , features: dataSourceAttr handle [ "features" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , sizes: dataSourceAttr handle [ "sizes" ]
    , slug: dataSourceAttr handle [ "slug" ]
    }
