module Inframe.Json (encodeGraph, renderGraph) where

import Prelude

import Data.Argonaut.Core (Json, fromArray, fromBoolean, fromObject, fromString, stringifyWithIndent)
import Data.Argonaut.Encode (encodeJson)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Foreign.Object (Object)
import Foreign.Object as Object
import Inframe.Builder (DataSourceSpec, Graph, Infra, LifecycleOptions, MoveSpec, OutputSpec, ProviderConfigSpec, ProviderRequirement, ResourceSpec, buildGraph)
import Inframe.Internal.Core (ExprNode(..), TemplatePart(..))

encodeGraph :: Graph -> Json
encodeGraph graph = fromObject $ Object.fromFoldable
  [ Tuple "format_version" (fromString "1.0")
  , Tuple "required_providers" (fromObject (map encodeProviderRequirement graph.requiredProviders))
  , Tuple "provider_configs" (fromArray (map encodeProviderConfig graph.providerConfigs))
  , Tuple "resources" (fromArray (map encodeResource graph.resources))
  , Tuple "data_sources" (fromArray (map encodeDataSource graph.dataSources))
  , Tuple "outputs" (fromObject (map encodeOutput graph.outputs))
  , Tuple "moves" (fromArray (map encodeMove graph.moves))
  ]

renderGraph :: forall a. Infra a -> String
renderGraph = stringifyWithIndent 2 <<< encodeGraph <<< buildGraph

encodeProviderRequirement :: ProviderRequirement -> Json
encodeProviderRequirement requirement = fromObject $ Object.fromFoldable
  [ Tuple "source" (fromString requirement.source)
  , Tuple "version" (fromString requirement.version)
  ]

encodeProviderConfig :: ProviderConfigSpec -> Json
encodeProviderConfig config = fromObject $ insertOptional "alias" fromString config.alias $ Object.fromFoldable
  [ Tuple "provider" (fromString config.provider)
  , Tuple "arguments" (encodeArguments config.arguments)
  ]

encodeResource :: ResourceSpec -> Json
encodeResource resource = fromObject
  $ insertOptional "lifecycle" encodeLifecycle resource.lifecycle
  $ insertOptional "provider" fromString resource.provider
  $ Object.fromFoldable
      [ Tuple "type" (fromString resource.resourceType)
      , Tuple "name" (fromString resource.name)
      , Tuple "arguments" (encodeArguments resource.arguments)
      , Tuple "depends_on" (fromArray (map fromString resource.dependsOn))
      ]

encodeDataSource :: DataSourceSpec -> Json
encodeDataSource dataSource = fromObject
  $ insertOptional "provider" fromString dataSource.provider
  $ Object.fromFoldable
      [ Tuple "type" (fromString dataSource.dataSourceType)
      , Tuple "name" (fromString dataSource.name)
      , Tuple "arguments" (encodeArguments dataSource.arguments)
      , Tuple "depends_on" (fromArray (map fromString dataSource.dependsOn))
      ]

encodeOutput :: OutputSpec -> Json
encodeOutput output = fromObject $ Object.fromFoldable
  [ Tuple "value" (encodeExprNode output.value)
  , Tuple "sensitive" (fromBoolean output.sensitive)
  ]

encodeLifecycle :: LifecycleOptions -> Json
encodeLifecycle lifecycle = fromObject $ Object.fromFoldable
  [ Tuple "create_before_destroy" (fromBoolean lifecycle.createBeforeDestroy)
  , Tuple "prevent_destroy" (fromBoolean lifecycle.preventDestroy)
  , Tuple "ignore_changes" (fromArray (map fromString lifecycle.ignoreChanges))
  , Tuple "replace_triggered_by" (fromArray (map fromString lifecycle.replaceTriggeredBy))
  ]

encodeMove :: MoveSpec -> Json
encodeMove movement = fromObject $ Object.fromFoldable
  [ Tuple "from" (fromString movement.from)
  , Tuple "to" (fromString movement.to)
  ]

encodeArguments :: Object ExprNode -> Json
encodeArguments = fromObject <<< map encodeExprNode

encodeExprNode :: ExprNode -> Json
encodeExprNode expression = case expression of
  Literal value -> tagged "literal"
    [ Tuple "value" value ]
  ResourceAttribute address path -> reference "resource_attr" address path
  DataSourceAttribute address path -> reference "data_source_attr" address path
  ArrayExpression items -> tagged "array"
    [ Tuple "items" (fromArray (map encodeExprNode items)) ]
  ObjectExpression fields -> tagged "object"
    [ Tuple "fields" (fromObject (map encodeExprNode fields)) ]
  IndexExpression collection key -> tagged "index"
    [ Tuple "collection" (encodeExprNode collection)
    , Tuple "key" (encodeExprNode key)
    ]
  ConditionalExpression condition whenTrue whenFalse -> tagged "conditional"
    [ Tuple "condition" (encodeExprNode condition)
    , Tuple "when_true" (encodeExprNode whenTrue)
    , Tuple "when_false" (encodeExprNode whenFalse)
    ]
  FunctionExpression name arguments -> tagged "function"
    [ Tuple "name" (fromString name)
    , Tuple "args" (fromArray (map encodeExprNode arguments))
    ]
  TemplateExpression parts -> tagged "template"
    [ Tuple "parts" (fromArray (map encodeTemplatePart parts)) ]
  SecretEnvironment name -> tagged "secret_env"
    [ Tuple "name" (fromString name) ]

encodeTemplatePart :: TemplatePart -> Json
encodeTemplatePart part = case part of
  TextPart value -> tagged "literal"
    [ Tuple "value" (fromString value) ]
  InterpolationPart expression -> tagged "interpolation"
    [ Tuple "expression" (encodeExprNode expression) ]

reference :: String -> String -> Array String -> Json
reference kind address path = tagged kind
  [ Tuple "address" (fromString address)
  , Tuple "path" (encodeJson path)
  ]

tagged :: String -> Array (Tuple String Json) -> Json
tagged kind fields = fromObject $ Object.fromFoldable $
  [ Tuple "kind" (fromString kind) ] <> fields

insertOptional :: forall a. String -> (a -> Json) -> Maybe a -> Object Json -> Object Json
insertOptional name encode value fields = case value of
  Nothing -> fields
  Just present -> Object.insert name (encode present) fields
