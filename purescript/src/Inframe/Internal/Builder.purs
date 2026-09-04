module Inframe.Internal.Builder
  ( Infra
  , Graph
  , ProviderRequirement
  , ProviderConfigSpec
  , ResourceSpec
  , DataSourceSpec
  , OutputSpec
  , LifecycleOptions
  , MoveSpec
  , class OutputValue
  , outputValueNode
  , InputObject
  , NodeOptions
  , ResourceScope
  , DataSourceScope
  , ResourceOptions
  , DataSourceOptions
  , inputObject
  , insertInputField
  , inputObjectNode
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

import Data.Array (elem, snoc)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Foreign.Object (Object)
import Foreign.Object as Object
import Inframe.Internal.Core (class Dependable, DataSource, Expr, ExprNode, Input, Provider, Resource, dataSourceHandle, dependencyAddress, exprNode, inputNode, objectExprNode, providerAddress, providerHandle, resourceHandle)

-- | Opaque arguments accumulated by generated provider builders.
newtype InputObject = InputObject (Object ExprNode)

class OutputValue value where
  outputValueNode :: value -> ExprNode

instance outputValueExpr :: OutputValue (Expr a) where
  outputValueNode = exprNode

instance outputValueInput :: OutputValue (Input a) where
  outputValueNode = inputNode

inputObject :: Array (Tuple String ExprNode) -> InputObject
inputObject = InputObject <<< Object.fromFoldable

insertInputField :: String -> ExprNode -> InputObject -> InputObject
insertInputField name value (InputObject fields) =
  InputObject (Object.insert name value fields)

inputObjectNode :: InputObject -> ExprNode
inputObjectNode (InputObject fields) = objectExprNode fields

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

type ProviderRequirement =
  { source :: String
  , version :: String
  }

type ProviderConfigSpec =
  { provider :: String
  , alias :: Maybe String
  , arguments :: Object ExprNode
  }

type ResourceSpec =
  { resourceType :: String
  , name :: String
  , arguments :: Object ExprNode
  , dependsOn :: Array String
  , provider :: Maybe String
  , lifecycle :: Maybe LifecycleOptions
  }

type DataSourceSpec =
  { dataSourceType :: String
  , name :: String
  , arguments :: Object ExprNode
  , dependsOn :: Array String
  , provider :: Maybe String
  }

type OutputSpec =
  { value :: ExprNode
  , sensitive :: Boolean
  }

type MoveSpec =
  { from :: String
  , to :: String
  }

type Graph =
  { requiredProviders :: Object ProviderRequirement
  , providerConfigs :: Array ProviderConfigSpec
  , resources :: Array ResourceSpec
  , dataSources :: Array DataSourceSpec
  , outputs :: Object OutputSpec
  , moves :: Array MoveSpec
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

replaceTriggeredBy :: forall provider resource. Resource resource -> ResourceOptions provider -> ResourceOptions provider
replaceTriggeredBy handle = updateLifecycle \lifecycle -> lifecycle
  { replaceTriggeredBy = appendUnique (dependencyAddress handle) lifecycle.replaceTriggeredBy }

initialGraph :: Graph
initialGraph =
  { requiredProviders: Object.empty
  , providerConfigs: []
  , resources: []
  , dataSources: []
  , outputs: Object.empty
  , moves: []
  }

modify :: (Graph -> Graph) -> Infra Unit
modify transform = Infra \graph -> Tuple unit (transform graph)

requireProvider :: String -> String -> String -> Infra Unit
requireProvider localName source version =
  modify \graph -> graph
    { requiredProviders = Object.insert localName { source, version } graph.requiredProviders }

addProvider :: forall provider. String -> String -> String -> Maybe String -> InputObject -> Infra (Provider provider)
addProvider provider source version alias (InputObject arguments) = Infra \graph ->
  Tuple (providerHandle address) (graph
    { requiredProviders = Object.insert provider { source, version } graph.requiredProviders
    , providerConfigs = snoc graph.providerConfigs { provider, alias, arguments }
    })
  where
  address = case alias of
    Nothing -> provider
    Just name -> provider <> "." <> name

addResource :: forall r provider. ResourceOptions provider -> String -> String -> InputObject -> Infra (Resource r)
addResource (NodeOptions options) resourceType name (InputObject arguments) = Infra \graph ->
  let
    spec =
      { resourceType
      , name
      , arguments
      , dependsOn: options.dependsOn
      , provider: options.provider
      , lifecycle: options.lifecycle
      }
  in
    Tuple (resourceHandle (resourceType <> "." <> name))
      (graph { resources = snoc graph.resources spec })

addDataSource :: forall r provider. DataSourceOptions provider -> String -> String -> InputObject -> Infra (DataSource r)
addDataSource (NodeOptions options) dataSourceType name (InputObject arguments) = Infra \graph ->
  let
    spec =
      { dataSourceType
      , name
      , arguments
      , dependsOn: options.dependsOn
      , provider: options.provider
      }
  in
    Tuple (dataSourceHandle ("data." <> dataSourceType <> "." <> name))
      (graph { dataSources = snoc graph.dataSources spec })

output :: forall value. OutputValue value => String -> value -> Infra Unit
output name expression = outputWithSensitivity false name expression

sensitiveOutput :: forall value. OutputValue value => String -> value -> Infra Unit
sensitiveOutput name expression = outputWithSensitivity true name expression

outputWithSensitivity :: forall value. OutputValue value => Boolean -> String -> value -> Infra Unit
outputWithSensitivity sensitive name expression =
  modify \graph -> graph
    { outputs = Object.insert name { value: outputValueNode expression, sensitive } graph.outputs }

buildGraph :: forall a. Infra a -> Graph
buildGraph (Infra run) =
  case run initialGraph of
    Tuple _ graph -> graph

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

appendUnique :: forall a. Eq a => a -> Array a -> Array a
appendUnique value values = if elem value values then values else snoc values value
