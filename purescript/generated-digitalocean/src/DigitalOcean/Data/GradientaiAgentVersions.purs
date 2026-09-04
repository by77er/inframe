module DigitalOcean.Data.GradientaiAgentVersions
  ( Args
  , Required
  , GradientaiAgentVersions
  , GradientaiAgentVersionsDataSource
  , args
  , read
  , Filter
  , FilterRequired
  , filterArgs
  , filterAll
  , filterMatchBy
  , Sort
  , SortRequired
  , sortArgs
  , sortDirection
  , filter
  , id
  , sort
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data GradientaiAgentVersionsDataSource

newtype Filter = Filter InputObject

type FilterRequired =
  { key :: Input String
  , values :: Input (Array String)
  }

filterArgs :: FilterRequired -> Filter
filterArgs required = Filter (inputObject
  [ Tuple "key" (inputJson required.key)
  , Tuple "values" (inputJson required.values)
  ])

filterAll :: Input Boolean -> Filter -> Filter
filterAll value (Filter values) = Filter (insertInputField "all" (inputJson value) values)

filterMatchBy :: Input String -> Filter -> Filter
filterMatchBy value (Filter values) = Filter (insertInputField "match_by" (inputJson value) values)

filterJson :: Filter -> Json
filterJson (Filter values) = inputObjectJson values

newtype Sort = Sort InputObject

type SortRequired =
  { key :: Input String
  }

sortArgs :: SortRequired -> Sort
sortArgs required = Sort (inputObject
  [ Tuple "key" (inputJson required.key)
  ])

sortDirection :: Input String -> Sort -> Sort
sortDirection value (Sort values) = Sort (insertInputField "direction" (inputJson value) values)

sortJson :: Sort -> Json
sortJson (Sort values) = inputObjectJson values

type Required =
  { agentId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "agent_id" (inputJson required.agentId)
  ])

filter :: Array Filter -> Args -> Args
filter value (Args values) = Args (insertInputField "filter" (arrayExprJson (map filterJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

sort :: Array Sort -> Args -> Args
sort value (Args values) = Args (insertInputField "sort" (arrayExprJson (map sortJson value)) values)

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
