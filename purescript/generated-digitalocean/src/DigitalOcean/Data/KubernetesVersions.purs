module DigitalOcean.Data.KubernetesVersions
  ( Args
  , Required
  , KubernetesVersions
  , KubernetesVersionsDataSource
  , args
  , read
  , id
  , versionPrefix
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data KubernetesVersionsDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

versionPrefix :: Input String -> Args -> Args
versionPrefix value (Args values) = Args (Object.insert "version_prefix" (inputJson value) values)

type KubernetesVersions =
  { dataSource :: DataSource KubernetesVersionsDataSource
  , id :: Expr String
  , latestVersion :: Expr String
  , validVersions :: Expr (Array String)
  , versionPrefix :: Expr String
  }

read :: String -> Args -> Infra KubernetesVersions
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_kubernetes_versions" logicalName values
  pure
    { dataSource: handle
    , id: dataSourceAttr handle [ "id" ]
    , latestVersion: dataSourceAttr handle [ "latest_version" ]
    , validVersions: dataSourceAttr handle [ "valid_versions" ]
    , versionPrefix: dataSourceAttr handle [ "version_prefix" ]
    }
