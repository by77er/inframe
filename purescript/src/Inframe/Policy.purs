module Inframe.Policy
  ( Outcome(..)
  , Violation
  , Policy
  , violations
  , holds
  , resources
  , resourcesOfType
  , dataSources
  , outputs
  , graph
  , argumentValues
  , all
  , report
  , enforce
  , resourceAddress
  , dataSourceAddress
  ) where

-- | Policies over a completed graph, the PureScript twin of Lean's `Inframe.Policy`.
-- | A policy is a function from the graph to a list of violations, and it holds when
-- | the list is empty. A rule over symbolic values has a third outcome besides passing
-- | and failing: a value only OpenTofu's plan knows (an attribute of another node, a
-- | function of one, a secret) is an `Unknown` finding, which fails the policy like a
-- | violation, so a value the policy cannot see never passes.

import Prelude

import Data.Argonaut.Core (Json, isNull)
import Data.Array (any, concatMap, mapMaybe, null)
import Data.Maybe (Maybe(..))
import Data.String.Common (joinWith)
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Foreign.Object as Object
import Inframe.Internal.Builder (DataSourceSpec, Graph, OutputSpec, ResourceSpec)
import Inframe.Internal.Core (ExprNode(..))

-- | What a finding says about the graph.
data Outcome
  -- | The graph breaks the rule.
  = Violated
  -- | The rule cannot be decided from the graph: a value it checks is only known once
  -- | OpenTofu plans. It fails the policy like a violation.
  | Unknown

derive instance eqOutcome :: Eq Outcome

type Violation =
  { rule :: String
  , address :: String
  , message :: String
  , outcome :: Outcome
  }

type Policy =
  { name :: String
  , check :: Graph -> Array Violation
  }

violations :: Policy -> Graph -> Array Violation
violations policy = policy.check

-- | The policy reports no violation, and no unknown value, for the graph.
holds :: Policy -> Graph -> Boolean
holds policy = null <<< policy.check

resourceAddress :: ResourceSpec -> String
resourceAddress resource = resource.resourceType <> "." <> resource.name

dataSourceAddress :: DataSourceSpec -> String
dataSourceAddress dataSource = "data." <> dataSource.dataSourceType <> "." <> dataSource.name

-- | A rule evaluated against every managed resource. Return `Just message` to report a
-- | violation.
resources :: String -> (ResourceSpec -> Maybe String) -> Policy
resources name rule =
  { name
  , check: \completed -> completed.resources # mapMaybe \resource ->
      rule resource <#> \message ->
        { rule: name, address: resourceAddress resource, message, outcome: Violated }
  }

-- | A rule evaluated against every managed resource of one provider type.
resourcesOfType :: String -> String -> (ResourceSpec -> Maybe String) -> Policy
resourcesOfType name resourceType rule =
  resources name \resource ->
    if resource.resourceType == resourceType then rule resource else Nothing

-- | A rule evaluated against every data source.
dataSources :: String -> (DataSourceSpec -> Maybe String) -> Policy
dataSources name rule =
  { name
  , check: \completed -> completed.dataSources # mapMaybe \dataSource ->
      rule dataSource <#> \message ->
        { rule: name, address: dataSourceAddress dataSource, message, outcome: Violated }
  }

-- | A rule evaluated against every root output.
outputs :: String -> (String -> OutputSpec -> Maybe String) -> Policy
outputs name rule =
  { name
  , check: \completed -> Object.toUnfoldable completed.outputs # mapMaybe \(Tuple outputName spec) ->
      rule outputName spec <#> \message ->
        { rule: name, address: "output." <> outputName, message, outcome: Violated }
  }

-- | A rule over the whole graph.
graph :: String -> (Graph -> Maybe String) -> Policy
graph name rule =
  { name
  , check: \completed -> case rule completed of
      Nothing -> []
      Just message -> [ { rule: name, address: "graph", message, outcome: Violated } ]
  }

-- | A rule over the values one argument takes across the managed resources that set it
-- | (a null literal counts as unset, as it does for OpenTofu). `rule` sees the literal
-- | values with their resources; every resource whose argument is anything else is
-- | reported `Unknown` at its address instead of being left out.
argumentValues :: String -> String -> (Array (Tuple ResourceSpec Json) -> Maybe String) -> Policy
argumentValues name argument rule =
  { name
  , check: \completed ->
      let
        set = completed.resources # mapMaybe \resource ->
          case Object.lookup argument resource.arguments of
            Nothing -> Nothing
            Just (Literal value) | isNull value -> Nothing
            Just expression -> Just (Tuple resource expression)
        unknown = set # mapMaybe \(Tuple resource expression) -> case expression of
          Literal _ -> Nothing
          _ -> Just
            { rule: name
            , address: resourceAddress resource
            , message: argument <> " is only known once OpenTofu plans"
            , outcome: Unknown
            }
        known = set # mapMaybe \(Tuple resource expression) -> case expression of
          Literal value -> Just (Tuple resource value)
          _ -> Nothing
        found = case rule known of
          Nothing -> []
          Just message -> [ { rule: name, address: "graph", message, outcome: Violated } ]
      in
        unknown <> found
  }

-- | The conjunction of several policies.
all :: String -> Array Policy -> Policy
all name policies = { name, check: \completed -> concatMap (\policy -> policy.check completed) policies }

render :: Violation -> String
render violation = case violation.outcome of
  Violated -> "[" <> violation.rule <> "] " <> violation.address <> ": " <> violation.message
  Unknown -> "[" <> violation.rule <> "] " <> violation.address <> ": unknown until plan: " <> violation.message

-- | Human-readable outcome. A policy that only failed to decide is not called violated.
report :: Policy -> Graph -> String
report policy completed = case policy.check completed of
  [] -> "policy `" <> policy.name <> "` holds"
  found ->
    joinWith "\n  " $
      [ "policy `" <> policy.name <> "` " <> heading found <> ":" ] <> map render found
  where
  heading found
    | any (\violation -> violation.outcome == Violated) found = "is violated"
    | otherwise = "cannot be decided from the graph"

-- | Print the report and throw when the policy is violated or cannot be decided, so a
-- | stack's test entry point fails.
enforce :: Policy -> Graph -> Effect Unit
enforce policy completed = do
  log (report policy completed)
  unless (holds policy completed) do
    throw ("policy `" <> policy.name <> "` does not hold")
