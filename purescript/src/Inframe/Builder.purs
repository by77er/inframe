module Inframe.Builder
  ( Infra
  , Graph
  , class OutputValue
  , outputValueJson
  , InputObject
  , NodeOptions
  , ResourceScope
  , DataSourceScope
  , ResourceOptions
  , DataSourceOptions
  , inputObject
  , insertInputField
  , inputObjectJson
  , resourceOptions
  , dataSourceOptions
  , withProvider
  , dependsOn
  , createBeforeDestroy
  , preventDestroy
  , ignoreChanges
  , replaceTriggeredBy
  , addProvider
  , requireProvider
  , addResource
  , addDataSource
  , output
  , sensitiveOutput
  , buildGraph
  ) where

import Prelude

import Data.Argonaut.Core (Json, fromArray, fromBoolean, fromObject, fromString)
import Data.Array (elem, snoc)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Foreign.Object (Object)
import Foreign.Object as Object
import Inframe.Core (class Dependable, DataSource, Expr, Input, Provider, Resource, dataSourceHandle, dependencyAddress, exprJson, inputJson, objectExprJson, providerAddress, providerHandle, resourceHandle)

-- | Opaque arguments accumulated by generated provider builders.
newtype InputObject = InputObject (Object Json)

class OutputValue value where
  outputValueJson :: value -> Json

instance outputValueExpr :: OutputValue (Expr a) where
  outputValueJson = exprJson

instance outputValueInput :: OutputValue (Input a) where
  outputValueJson = inputJson

inputObject :: Array (Tuple String Json) -> InputObject
inputObject = InputObject <<< Object.fromFoldable

insertInputField :: String -> Json -> InputObject -> InputObject
insertInputField name value (InputObject fields) =
  InputObject (Object.insert name value fields)

inputObjectJson :: InputObject -> Json
inputObjectJson (InputObject fields) = objectExprJson fields

data ResourceScope
data DataSourceScope

type LifecycleOptions =
  { createBeforeDestroy :: Boolean
  , preventDestroy :: Boolean
  , ignoreChanges :: Array String
  , replaceTriggeredBy :: Array String
  }

newtype NodeOptions :: Type -> Type -> Type
newtype NodeOptions scope provider = NodeOptions
  { dependsOn :: Array String
  , provider :: Maybe String
  , lifecycle :: Maybe LifecycleOptions
  }

type ResourceOptions provider = NodeOptions ResourceScope provider
type DataSourceOptions provider = NodeOptions DataSourceScope provider

resourceOptions :: forall provider. ResourceOptions provider
resourceOptions = NodeOptions
  { dependsOn: []
  , provider: Nothing
  , lifecycle: Nothing
  }

dataSourceOptions :: forall provider. DataSourceOptions provider
dataSourceOptions = NodeOptions
  { dependsOn: []
  , provider: Nothing
  , lifecycle: Nothing
  }

withProvider :: forall scope provider. Provider provider -> NodeOptions scope provider -> NodeOptions scope provider
withProvider provider (NodeOptions options) =
  NodeOptions (options { provider = Just (providerAddress provider) })

dependsOn :: forall scope provider handle. Dependable handle => handle -> NodeOptions scope provider -> NodeOptions scope provider
dependsOn handle (NodeOptions options) =
  NodeOptions (options { dependsOn = appendUnique (dependencyAddress handle) options.dependsOn })

createBeforeDestroy :: forall provider. Boolean -> ResourceOptions provider -> ResourceOptions provider
createBeforeDestroy enabled = updateLifecycle \lifecycle -> lifecycle { createBeforeDestroy = enabled }

preventDestroy :: forall provider. Boolean -> ResourceOptions provider -> ResourceOptions provider
preventDestroy enabled = updateLifecycle \lifecycle -> lifecycle { preventDestroy = enabled }

ignoreChanges :: forall provider. Array String -> ResourceOptions provider -> ResourceOptions provider
ignoreChanges paths = updateLifecycle \lifecycle -> lifecycle { ignoreChanges = paths }

replaceTriggeredBy :: forall provider handle. Dependable handle => handle -> ResourceOptions provider -> ResourceOptions provider
replaceTriggeredBy handle = updateLifecycle \lifecycle -> lifecycle
  { replaceTriggeredBy = appendUnique (dependencyAddress handle) lifecycle.replaceTriggeredBy }

type Graph =
  { requiredProviders :: Object Json
  , providerConfigs :: Array Json
  , resources :: Array Json
  , dataSources :: Array Json
  , outputs :: Object Json
  }

newtype Infra a = Infra (Graph -> Tuple a Graph)

instance functorInfra :: Functor Infra where
  map transform (Infra run) = Infra \graph ->
    case run graph of
      Tuple value next -> Tuple (transform value) next

instance applyInfra :: Apply Infra where
  apply (Infra runFunction) (Infra runValue) = Infra \graph ->
    case runFunction graph of
      Tuple function next ->
        case runValue next of
          Tuple value final -> Tuple (function value) final

instance applicativeInfra :: Applicative Infra where
  pure value = Infra \graph -> Tuple value graph

instance bindInfra :: Bind Infra where
  bind (Infra run) next = Infra \graph ->
    case run graph of
      Tuple value nextGraph ->
        case next value of
          Infra runNext -> runNext nextGraph

instance monadInfra :: Monad Infra

initialGraph :: Graph
initialGraph =
  { requiredProviders: Object.empty
  , providerConfigs: []
  , resources: []
  , dataSources: []
  , outputs: Object.empty
  }

modify :: (Graph -> Graph) -> Infra Unit
modify transform = Infra \graph -> Tuple unit (transform graph)

requireProvider :: String -> String -> String -> Infra Unit
requireProvider localName source version =
  modify \graph -> graph
    { requiredProviders = Object.insert localName requirement graph.requiredProviders }
  where
  requirement = fromObject $ Object.fromFoldable
    [ Tuple "source" (fromString source)
    , Tuple "version" (fromString version)
    ]

addProvider :: forall provider. String -> String -> String -> Maybe String -> InputObject -> Infra (Provider provider)
addProvider provider source version alias (InputObject arguments) = Infra \graph ->
  Tuple (providerHandle address) (graph
    { requiredProviders = Object.insert provider requirement graph.requiredProviders
    , providerConfigs = snoc graph.providerConfigs config
    })
  where
  address = case alias of
    Nothing -> provider
    Just name -> provider <> "." <> name
  requirement = fromObject $ Object.fromFoldable
    [ Tuple "source" (fromString source)
    , Tuple "version" (fromString version)
    ]
  base = Object.fromFoldable
    [ Tuple "provider" (fromString provider)
    , Tuple "arguments" (fromObject arguments)
    ]
  config = fromObject case alias of
    Nothing -> base
    Just name -> Object.insert "alias" (fromString name) base

addResource :: forall r provider. ResourceOptions provider -> String -> String -> InputObject -> Infra (Resource r)
addResource (NodeOptions options) resourceType name (InputObject arguments) = Infra \graph ->
  let
    address = resourceType <> "." <> name
    base = Object.fromFoldable
      [ Tuple "type" (fromString resourceType)
      , Tuple "name" (fromString name)
      , Tuple "arguments" (fromObject arguments)
      , Tuple "depends_on" (fromArray (map fromString options.dependsOn))
      ]
    withConfiguredProvider = case options.provider of
      Nothing -> base
      Just provider -> Object.insert "provider" (fromString provider) base
    withLifecycle = case options.lifecycle of
      Nothing -> withConfiguredProvider
      Just lifecycle -> Object.insert "lifecycle" (lifecycleJson lifecycle) withConfiguredProvider
    spec = fromObject withLifecycle
  in
    Tuple (resourceHandle address) (graph { resources = snoc graph.resources spec })

addDataSource :: forall r provider. DataSourceOptions provider -> String -> String -> InputObject -> Infra (DataSource r)
addDataSource (NodeOptions options) dataSourceType name (InputObject arguments) = Infra \graph ->
  let
    address = "data." <> dataSourceType <> "." <> name
    base = Object.fromFoldable
      [ Tuple "type" (fromString dataSourceType)
      , Tuple "name" (fromString name)
      , Tuple "arguments" (fromObject arguments)
      , Tuple "depends_on" (fromArray (map fromString options.dependsOn))
      ]
    spec = fromObject case options.provider of
      Nothing -> base
      Just provider -> Object.insert "provider" (fromString provider) base
  in
    Tuple (dataSourceHandle address) (graph { dataSources = snoc graph.dataSources spec })

output :: forall value. OutputValue value => String -> value -> Infra Unit
output name expression = outputWithSensitivity false name expression

sensitiveOutput :: forall value. OutputValue value => String -> value -> Infra Unit
sensitiveOutput name expression = outputWithSensitivity true name expression

outputWithSensitivity :: forall value. OutputValue value => Boolean -> String -> value -> Infra Unit
outputWithSensitivity sensitive name expression =
  modify \graph -> graph
    { outputs = Object.insert name value graph.outputs }
  where
  value = fromObject $ Object.fromFoldable
    [ Tuple "value" (outputValueJson expression)
    , Tuple "sensitive" (fromBoolean sensitive)
    ]

buildGraph :: forall a. Infra a -> Json
buildGraph (Infra run) =
  case run initialGraph of
    Tuple _ graph -> fromObject $ Object.fromFoldable
      [ Tuple "format_version" (fromString "1.0")
      , Tuple "required_providers" (fromObject graph.requiredProviders)
      , Tuple "provider_configs" (fromArray graph.providerConfigs)
      , Tuple "resources" (fromArray graph.resources)
      , Tuple "data_sources" (fromArray graph.dataSources)
      , Tuple "outputs" (fromObject graph.outputs)
      , Tuple "moves" (fromArray [])
      ]

emptyLifecycle :: LifecycleOptions
emptyLifecycle =
  { createBeforeDestroy: false
  , preventDestroy: false
  , ignoreChanges: []
  , replaceTriggeredBy: []
  }

updateLifecycle :: forall provider. (LifecycleOptions -> LifecycleOptions) -> ResourceOptions provider -> ResourceOptions provider
updateLifecycle transform (NodeOptions options) =
  NodeOptions (options { lifecycle = Just (transform current) })
  where
  current = case options.lifecycle of
    Nothing -> emptyLifecycle
    Just lifecycle -> lifecycle

lifecycleJson :: LifecycleOptions -> Json
lifecycleJson lifecycle = fromObject $ Object.fromFoldable
  [ Tuple "create_before_destroy" (fromBoolean lifecycle.createBeforeDestroy)
  , Tuple "prevent_destroy" (fromBoolean lifecycle.preventDestroy)
  , Tuple "ignore_changes" (fromArray (map fromString lifecycle.ignoreChanges))
  , Tuple "replace_triggered_by" (fromArray (map fromString lifecycle.replaceTriggeredBy))
  ]

appendUnique :: forall a. Eq a => a -> Array a -> Array a
appendUnique value values = if elem value values then values else snoc values value
