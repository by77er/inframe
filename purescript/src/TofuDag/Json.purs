module TofuDag.Json (renderGraph) where

import Prelude

import Data.Argonaut.Core (stringifyWithIndent)
import TofuDag.Builder (Infra, buildGraph)

renderGraph :: forall a. Infra a -> String
renderGraph = stringifyWithIndent 2 <<< buildGraph

