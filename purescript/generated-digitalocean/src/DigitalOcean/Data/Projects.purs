module DigitalOcean.Data.Projects
  ( Args
  , Required
  , Projects
  , ProjectsDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data ProjectsDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type Projects =
  { dataSource :: DataSource ProjectsDataSource
  , id :: Expr String
  , projects :: Expr (Array ({ createdAt :: String, description :: String, environment :: String, id :: String, isDefault :: Boolean, name :: String, ownerId :: Number, ownerUuid :: String, purpose :: String, resources :: Array String, updatedAt :: String }))
  }

read :: String -> Args -> Infra Projects
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_projects" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , projects: dataSourceAttr handle [ "projects" ]
    }
