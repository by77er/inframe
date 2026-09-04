module DigitalOcean.Resource.DatabaseKafkaSchemaRegistry
  ( Args
  , Required
  , DatabaseKafkaSchemaRegistry
  , DatabaseKafkaSchemaRegistryResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data DatabaseKafkaSchemaRegistryResource

type Required =
  { clusterId :: Input String
  , schema :: Input String
  , schemaType :: Input String
  , subjectName :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "cluster_id" (inputJson required.clusterId)
  , Tuple "schema" (inputJson required.schema)
  , Tuple "schema_type" (inputJson required.schemaType)
  , Tuple "subject_name" (inputJson required.subjectName)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type DatabaseKafkaSchemaRegistry =
  { resource :: Resource DatabaseKafkaSchemaRegistryResource
  , clusterId :: Expr String
  , id :: Expr String
  , schema :: Expr String
  , schemaType :: Expr String
  , subjectName :: Expr String
  }

create :: String -> Args -> Infra DatabaseKafkaSchemaRegistry
create logicalName (Args values) = do
  handle <- addResource "digitalocean_database_kafka_schema_registry" logicalName values
  pure
    { resource: handle
    , clusterId: resourceAttr handle [ "cluster_id" ]
    , id: resourceAttr handle [ "id" ]
    , schema: resourceAttr handle [ "schema" ]
    , schemaType: resourceAttr handle [ "schema_type" ]
    , subjectName: resourceAttr handle [ "subject_name" ]
    }
