module DigitalOcean.Data.Certificate
  ( Args
  , Required
  , Certificate
  , CertificateDataSource
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

data CertificateDataSource

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

type Certificate =
  { dataSource :: DataSource CertificateDataSource
  , domains :: Expr (Array String)
  , id :: Expr String
  , name :: Expr String
  , notAfter :: Expr String
  , sha1Fingerprint :: Expr String
  , state :: Expr String
  , type_ :: Expr String
  , uuid :: Expr String
  }

read :: String -> Args -> Infra Certificate
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_certificate" logicalName values
  pure
    { dataSource: handle
    , domains: dataSourceAttr handle [ "domains" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , notAfter: dataSourceAttr handle [ "not_after" ]
    , sha1Fingerprint: dataSourceAttr handle [ "sha1_fingerprint" ]
    , state: dataSourceAttr handle [ "state" ]
    , type_: dataSourceAttr handle [ "type" ]
    , uuid: dataSourceAttr handle [ "uuid" ]
    }
