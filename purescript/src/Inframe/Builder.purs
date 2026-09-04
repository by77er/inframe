module Inframe.Builder (module Public) where

-- Provider adapters use Inframe.Internal.Builder for low-level graph
-- construction. Infrastructure programs use this module to compose adapters,
-- select lifecycle behavior, declare outputs, and inspect the completed graph.
import Inframe.Internal.Builder
  ( DataSourceOptions
  , DataSourceScope
  , Graph
  , Infra
  , LifecycleOptions
  , MoveSpec
  , NodeOptions
  , OutputSpec
  , ProviderConfigSpec
  , ProviderRequirement
  , ResourceOptions
  , ResourceScope
  , ResourceSpec
  , DataSourceSpec
  , buildGraph
  , createBeforeDestroy
  , dataSourceOptions
  , dependsOn
  , ignoreChanges
  , output
  , preventDestroy
  , replaceTriggeredBy
  , resourceOptions
  , sensitiveOutput
  , withProvider
  ) as Public
