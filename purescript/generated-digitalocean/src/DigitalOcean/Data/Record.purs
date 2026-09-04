module DigitalOcean.Data.Record
  ( Args
  , Required
  , RecordHandle
  , RecordDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data RecordDataSource

type Required =
  { domain :: Input String
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "domain" (inputJson required.domain)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type RecordHandle =
  { dataSource :: DataSource RecordDataSource
  , data_ :: Expr String
  , domain :: Expr String
  , flags :: Expr Number
  , id :: Expr String
  , name :: Expr String
  , port :: Expr Number
  , priority :: Expr Number
  , tag :: Expr String
  , ttl :: Expr Number
  , type_ :: Expr String
  , weight :: Expr Number
  }

read :: String -> Args -> Infra RecordHandle
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_record" logicalName values
  pure
    { dataSource: handle
    , data_: dataSourceAttr handle [ "data" ]
    , domain: dataSourceAttr handle [ "domain" ]
    , flags: dataSourceAttr handle [ "flags" ]
    , id: dataSourceAttr handle [ "id" ]
    , name: dataSourceAttr handle [ "name" ]
    , port: dataSourceAttr handle [ "port" ]
    , priority: dataSourceAttr handle [ "priority" ]
    , tag: dataSourceAttr handle [ "tag" ]
    , ttl: dataSourceAttr handle [ "ttl" ]
    , type_: dataSourceAttr handle [ "type" ]
    , weight: dataSourceAttr handle [ "weight" ]
    }
