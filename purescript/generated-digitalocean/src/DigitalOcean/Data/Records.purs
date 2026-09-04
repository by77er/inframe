module DigitalOcean.Data.Records
  ( Args
  , Required
  , Records
  , RecordsDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data RecordsDataSource

type Required =
  { domain :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "domain" (inputJson required.domain)
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type Records =
  { dataSource :: DataSource RecordsDataSource
  , domain :: Expr String
  , id :: Expr String
  , records :: Expr (Array ({ domain :: String, flags :: Number, id :: Number, name :: String, port :: Number, priority :: Number, tag :: String, ttl :: Number, type_ :: String, value :: String, weight :: Number }))
  }

read :: String -> Args -> Infra Records
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_records" logicalName values
  pure
    { dataSource: handle
    , domain: dataSourceAttr handle [ "domain" ]
    , id: dataSourceAttr handle [ "id" ]
    , records: dataSourceAttr handle [ "records" ]
    }
