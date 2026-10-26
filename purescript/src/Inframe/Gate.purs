module Inframe.Gate (gate) where

-- | The body of the module `inframe` writes for a PureScript stack's gate. The CLI
-- | names the program and the policy from `inframe.toml`, so the statement checked is
-- | the project's rather than the test module's; `gate` checks the policy against the
-- | program's graph and prints that graph, which the CLI requires to equal the graph
-- | the stack's `main` printed.

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Inframe.Builder (Infra, buildGraph)
import Inframe.Json (renderGraph)
import Inframe.Policy (Policy, holds, report)

gate :: forall a. Policy -> Infra a -> Effect Unit
gate policy program = do
  let completed = buildGraph program
  unless (holds policy completed) do
    throw (report policy completed)
  log (renderGraph program)
