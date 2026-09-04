module TofuDag.Builder
  ( Infra
  , Graph
  , addProvider
  , requireProvider
  , addResource
  , addDataSource
  , output
  , buildGraph
  ) where

import Prelude

import Data.Argonaut.Core (Json, fromArray, fromBoolean, fromObject, fromString)
import Data.Array (snoc)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Foreign.Object (Object)
import Foreign.Object as Object
import TofuDag.Core (DataSource, Expr, Resource, dataSourceHandle, exprJson, resourceHandle)

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

addProvider :: String -> Maybe String -> Object Json -> Infra Unit
addProvider provider alias arguments =
  modify \graph -> graph { providerConfigs = snoc graph.providerConfigs config }
  where
  base = Object.fromFoldable
    [ Tuple "provider" (fromString provider)
    , Tuple "arguments" (fromObject arguments)
    ]
  config = fromObject case alias of
    Nothing -> base
    Just name -> Object.insert "alias" (fromString name) base

addResource :: forall r. String -> String -> Object Json -> Infra (Resource r)
addResource resourceType name arguments = Infra \graph ->
  let
    address = resourceType <> "." <> name
    spec = fromObject $ Object.fromFoldable
      [ Tuple "type" (fromString resourceType)
      , Tuple "name" (fromString name)
      , Tuple "arguments" (fromObject arguments)
      , Tuple "depends_on" (fromArray [])
      ]
  in
    Tuple (resourceHandle address) (graph { resources = snoc graph.resources spec })

addDataSource :: forall r. String -> String -> Object Json -> Infra (DataSource r)
addDataSource dataSourceType name arguments = Infra \graph ->
  let
    address = "data." <> dataSourceType <> "." <> name
    spec = fromObject $ Object.fromFoldable
      [ Tuple "type" (fromString dataSourceType)
      , Tuple "name" (fromString name)
      , Tuple "arguments" (fromObject arguments)
      , Tuple "depends_on" (fromArray [])
      ]
  in
    Tuple (dataSourceHandle address) (graph { dataSources = snoc graph.dataSources spec })

output :: forall a. String -> Expr a -> Infra Unit
output name expression =
  modify \graph -> graph
    { outputs = Object.insert name value graph.outputs }
  where
  value = fromObject $ Object.fromFoldable
    [ Tuple "value" (exprJson expression)
    , Tuple "sensitive" (fromBoolean false)
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
