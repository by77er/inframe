module Test.Main where

import Prelude

import Data.String.CodeUnits (contains)
import Data.String.Pattern (Pattern(..))
import Data.Tuple (Tuple(..))
import Effect (Effect)
import Test.Assert (assert)
import Inframe.Builder (Infra, createBeforeDestroy, dependsOn, output, replaceTriggeredBy, resourceOptions, sensitiveOutput)
import Inframe.Core (ExprNode, ifThenElse, interpolate, lit, secretEnv, template, text, unsafeArgument, unsafeCall)
import Inframe.Internal.Builder (InputObject, addResource, inputObject, insertInputField, requireProvider)
import Inframe.Internal.Core (inputNode, resourceAttr)
import Inframe.Json (renderGraph)

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

appendField :: String -> ExprNode -> InputObject -> InputObject
appendField = insertInputField
