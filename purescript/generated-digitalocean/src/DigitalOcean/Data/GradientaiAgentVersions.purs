module DigitalOcean.Data.GradientaiAgentVersions
  ( Args
  , Required
  , GradientaiAgentVersions
  , GradientaiAgentVersionsDataSource
  , args
  , read
  , filter
  , id
  , sort
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data GradientaiAgentVersionsDataSource

type Required =
  { agentId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "agent_id" (inputJson required.agentId)
  ])

filter :: Input (Array ({ all :: Boolean, key :: String, matchBy :: String, values :: Array String })) -> Args -> Args
filter value (Args values) = Args (Object.insert "filter" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

sort :: Input (Array ({ direction :: String, key :: String })) -> Args -> Args
sort value (Args values) = Args (Object.insert "sort" (inputJson value) values)

type GradientaiAgentVersions =
  { dataSource :: DataSource GradientaiAgentVersionsDataSource
  , agentId :: Expr String
  , agentVersions :: Expr (Array ({ agentUuid :: String, attachedChildAgents :: Array ({ agentName :: String, childAgentUuid :: String, ifCase :: String, isDeleted :: Boolean, routeName :: String }), attachedFunctions :: Array ({ description :: String, faasName :: String, faasNamespace :: String, isDeleted :: Boolean, name :: String }), attachedGuardrails :: Array ({ isDeleted :: Boolean, name :: String, priority :: Number, uuid :: String }), attachedKnowledgeBases :: Array ({ isDeleted :: Boolean, name :: String, uuid :: String }), canRollback :: Boolean, createdAt :: String, createdByEmail :: String, currentlyApplied :: Boolean, description :: String, id :: String, instruction :: String, k :: Number, maxTokens :: Number, modelName :: String, name :: String, provideCitations :: Boolean, retrievalMethod :: String, tags :: Array String, temperature :: Number, topP :: Number, triggerAction :: String, versionHash :: String }))
  , id :: Expr String
  }

read :: String -> Args -> Infra GradientaiAgentVersions
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_agent_versions" logicalName values
  pure
    { dataSource: handle
    , agentId: dataSourceAttr handle [ "agent_id" ]
    , agentVersions: dataSourceAttr handle [ "agent_versions" ]
    , id: dataSourceAttr handle [ "id" ]
    }
