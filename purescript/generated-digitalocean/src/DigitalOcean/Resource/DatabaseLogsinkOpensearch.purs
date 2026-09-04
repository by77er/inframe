module DigitalOcean.Resource.DatabaseLogsinkOpensearch
  ( Args
  , Required
  , DatabaseLogsinkOpensearch
  , DatabaseLogsinkOpensearchResource
  , args
  , create
  , caCert
  , indexDaysMax
  , timeoutSeconds
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseLogsinkOpensearchResource

type Required =
  { clusterId :: Input String
  , endpoint :: Input String
  , indexPrefix :: Input String
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "endpoint" (inputJson required.endpoint)
  , Tuple "index_prefix" (inputJson required.indexPrefix)
  , Tuple "name" (inputJson required.name)
  ])

caCert :: Input String -> Args -> Args
caCert value (Args values) = Args (insertInputField "ca_cert" (inputJson value) values)

indexDaysMax :: Input Number -> Args -> Args
indexDaysMax value (Args values) = Args (insertInputField "index_days_max" (inputJson value) values)

timeoutSeconds :: Input Number -> Args -> Args
timeoutSeconds value (Args values) = Args (insertInputField "timeout_seconds" (inputJson value) values)

type DatabaseLogsinkOpensearch =
  { resource :: Resource DatabaseLogsinkOpensearchResource
  , caCert :: Expr String
  , clusterId :: Expr String
  , endpoint :: Expr String
  , id :: Expr String
  , indexDaysMax :: Expr Number
  , indexPrefix :: Expr String
  , logsinkId :: Expr String
  , name :: Expr String
  , timeoutSeconds :: Expr Number
  }

create :: String -> Args -> Infra DatabaseLogsinkOpensearch
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_logsink_opensearch" logicalName values
  pure
    { resource: handle
    , caCert: resourceAttr handle [ "ca_cert" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , endpoint: resourceAttr handle [ "endpoint" ]
    , id: resourceAttr handle [ "id" ]
    , indexDaysMax: resourceAttr handle [ "index_days_max" ]
    , indexPrefix: resourceAttr handle [ "index_prefix" ]
    , logsinkId: resourceAttr handle [ "logsink_id" ]
    , name: resourceAttr handle [ "name" ]
    , timeoutSeconds: resourceAttr handle [ "timeout_seconds" ]
    }
