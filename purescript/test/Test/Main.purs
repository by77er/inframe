module Test.Main where

import Prelude

import Data.Array (null)
import Data.Maybe (Maybe(..))
import Data.String.CodeUnits (contains)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Test.Assert (assert)
import Inframe.Builder (Infra, adopt, buildGraph, createBeforeDestroy, dependsOn, output, replaceTriggeredBy, resourceOptions, sensitiveOutput)
import Inframe.Core (ExprNode, Input, attribute, computed, ifThenElse, index, interpolate, lit, secretEnv, splat, template, text, unsafeArgument, unsafeCall)
import Inframe.Internal.Builder (InputObject, addResource, inputObject, insertInputField, requireProvider)
import Inframe.Internal.Core (inputNode, resourceAttr)
import Inframe.Json (renderGraph)
import Inframe.Policy (Outcome(..))
import Inframe.Policy as Policy

data TagResource

program :: Infra Unit
program = do
  requireProvider "digitalocean" "digitalocean/digitalocean" "= 2.100.0"
  network <- addResource resourceOptions "digitalocean_vpc" "network" $ inputObject
    [ Tuple "name" (inputNode (lit "network")) ]
  tag <- addResource
    (resourceOptions # dependsOn network # replaceTriggeredBy network # createBeforeDestroy true)
    "digitalocean_tag"
    "app"
    $ inputObject
    [ Tuple "name" (inputNode (lit "app")) ]
    # appendField "description" (inputNode (template
        [ text "token-"
        , interpolate (secretEnv "DIGITALOCEAN_TOKEN")
        ]))
    # appendField "purpose" (inputNode (ifThenElse (lit true) (lit "prod") (lit "dev")))
    # appendField "normalized" (inputNode (unsafeCall "lower" [ unsafeArgument (lit "APP") ]))
  sensitiveOutput "tag_id" (resourceAttr tag [ "id" ])
  output "literal" (lit "known-now")
  let
    interfaces = computed (resourceAttr tag [ "network_interface" ]) :: Input (Array String)
  output "first_ip" (attribute (index interfaces (lit 1.0)) "network_ip" :: Input String)
  output "all_ips" (attribute (splat interfaces) "network_ip" :: Input (Array String))
  output "team" (attribute (computed (resourceAttr tag [ "meta" ]) :: Input String) "team" :: Input String)
  adopt tag "existing-tag-id"

main :: Effect Unit
main = do
  let rendered = renderGraph program
  assert $ contains (Pattern "digitalocean_tag.app") rendered
  assert $ contains (Pattern "resource_attr") rendered
  assert $ contains (Pattern "required_providers") rendered
  assert $ contains (Pattern "create_before_destroy") rendered
  assert $ contains (Pattern "replace_triggered_by") rendered
  assert $ contains (Pattern "secret_env") rendered
  assert $ contains (Pattern "conditional") rendered
  assert $ contains (Pattern "function") rendered
  assert $ contains (Pattern "\"sensitive\": true") rendered
  assert $ contains (Pattern "known-now") rendered
  assert $ contains (Pattern "\"kind\": \"attribute\"") rendered
  assert $ contains (Pattern "\"kind\": \"splat\"") rendered
  assert $ contains (Pattern "\"name\": \"network_ip\"") rendered
  -- A plain reference keeps the attribute in its path rather than wrapping it.
  assert $ contains (Pattern "\"team\"\n") rendered
  assert $ contains (Pattern "\"id\": \"existing-tag-id\"") rendered
  policies

-- | Policies report violations at their resource, a value only the plan knows as unknown
-- | rather than passing, and compose with `all`.
policies :: Effect Unit
policies = do
  let
    graph = buildGraph program
    tagsAreNamed = Policy.resourcesOfType "tags-are-named" "digitalocean_tag" \resource ->
      if resource.name == "app" then Nothing else Just "unexpected tag"
    noApp = Policy.resourcesOfType "no-app" "digitalocean_tag" \_ -> Just "no tags allowed"
    purposes = Policy.argumentValues "purpose" "purpose" \_ -> Nothing
    names = Policy.argumentValues "names" "name" \known ->
      if null known then Just "no known names" else Nothing
  assert $ Policy.holds tagsAreNamed graph
  assert $ Policy.holds names graph
  assert $ map _.address (Policy.violations noApp graph) == [ "digitalocean_tag.app" ]
  assert $ map _.outcome (Policy.violations purposes graph) == [ Unknown ]
  assert $ not (Policy.holds (Policy.all "both" [ tagsAreNamed, noApp ]) graph)
  assert $ contains (Pattern "policy `both` is violated:\n  [no-app] digitalocean_tag.app: no tags allowed")
    (Policy.report (Policy.all "both" [ tagsAreNamed, noApp ]) graph)
  assert $ contains (Pattern "cannot be decided from the graph") (Policy.report purposes graph)
  assert $ map _.outcome (Policy.violations noApp graph) == [ Violated ]

appendField :: String -> ExprNode -> InputObject -> InputObject
appendField = insertInputField
