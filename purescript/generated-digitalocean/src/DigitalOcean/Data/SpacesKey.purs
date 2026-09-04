module DigitalOcean.Data.SpacesKey
  ( Args
  , Required
  , SpacesKey
  , SpacesKeyDataSource
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

data SpacesKeyDataSource

type Required =
  { accessKey :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "access_key" (inputJson required.accessKey)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type SpacesKey =
  { dataSource :: DataSource SpacesKeyDataSource
  , accessKey :: Expr String
  , createdAt :: Expr String
  , grant :: Expr (Array ({ bucket :: String, permission :: String }))
  , id :: Expr String
  , name :: Expr String
  }

read :: String -> Args -> Infra SpacesKey
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_spaces_key" logicalName values
  pure
    { dataSource: handle
    , accessKey: dataSourceAttr handle [ "access_key" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , grant: dataSourceAttr handle [ "grant" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    }
