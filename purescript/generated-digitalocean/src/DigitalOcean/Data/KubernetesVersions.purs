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

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data KubernetesVersionsDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

versionPrefix :: Input String -> Args -> Args
versionPrefix value (Args values) = Args (insertInputField "version_prefix" (inputJson value) values)

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
