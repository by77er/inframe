module DigitalOcean.Resource.DatabaseLogsinkRsyslog
  ( Args
  , Required
  , DatabaseLogsinkRsyslog
  , DatabaseLogsinkRsyslogResource
  , args
  , create
  , caCert
  , clientCert
  , clientKey
  , format
  , logline
  , structuredData
  , tls
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseLogsinkRsyslogResource

type Required =
  { clusterId :: Input String
  , name :: Input String
  , port :: Input Number
  , server :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "name" (inputJson required.name)
  , Tuple "port" (inputJson required.port)
  , Tuple "server" (inputJson required.server)
  ])

caCert :: Input String -> Args -> Args
caCert value (Args values) = Args (insertInputField "ca_cert" (inputJson value) values)

clientCert :: Input String -> Args -> Args
clientCert value (Args values) = Args (insertInputField "client_cert" (inputJson value) values)

clientKey :: Input String -> Args -> Args
clientKey value (Args values) = Args (insertInputField "client_key" (inputJson value) values)

format :: Input String -> Args -> Args
format value (Args values) = Args (insertInputField "format" (inputJson value) values)

logline :: Input String -> Args -> Args
logline value (Args values) = Args (insertInputField "logline" (inputJson value) values)

structuredData :: Input String -> Args -> Args
structuredData value (Args values) = Args (insertInputField "structured_data" (inputJson value) values)

tls :: Input Boolean -> Args -> Args
tls value (Args values) = Args (insertInputField "tls" (inputJson value) values)

type DatabaseLogsinkRsyslog =
  { resource :: Resource DatabaseLogsinkRsyslogResource
  , caCert :: Expr String
  , clientCert :: Expr String
  , clientKey :: Expr String
  , clusterId :: Expr String
  , format :: Expr String
  , id :: Expr String
  , logline :: Expr String
  , logsinkId :: Expr String
  , name :: Expr String
  , port :: Expr Number
  , server :: Expr String
  , structuredData :: Expr String
  , tls :: Expr Boolean
  }

create :: String -> Args -> Infra DatabaseLogsinkRsyslog
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_logsink_rsyslog" logicalName values
  pure
    { resource: handle
    , caCert: resourceAttr handle [ "ca_cert" ]
    , clientCert: resourceAttr handle [ "client_cert" ]
    , clientKey: resourceAttr handle [ "client_key" ]
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , format: resourceAttr handle [ "format" ]
    , id: resourceAttr handle [ "id" ]
    , logline: resourceAttr handle [ "logline" ]
    , logsinkId: resourceAttr handle [ "logsink_id" ]
    , name: resourceAttr handle [ "name" ]
    , port: resourceAttr handle [ "port" ]
    , server: resourceAttr handle [ "server" ]
    , structuredData: resourceAttr handle [ "structured_data" ]
    , tls: resourceAttr handle [ "tls" ]
    }
