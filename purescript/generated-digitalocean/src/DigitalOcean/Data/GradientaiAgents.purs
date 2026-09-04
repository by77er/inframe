module DigitalOcean.Data.GradientaiAgents
  ( Args
  , Required
  , GradientaiAgents
  , GradientaiAgentsDataSource
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
  , onlyDeployed
  , sort
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data GradientaiAgentsDataSource

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
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

filter :: Array Filter -> Args -> Args
filter value (Args values) = Args (insertInputField "filter" (arrayExprJson (map filterJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

onlyDeployed :: Input Boolean -> Args -> Args
onlyDeployed value (Args values) = Args (insertInputField "only_deployed" (inputJson value) values)

sort :: Array Sort -> Args -> Args
sort value (Args values) = Args (insertInputField "sort" (arrayExprJson (map sortJson value)) values)

type GradientaiAgents =
  { dataSource :: DataSource GradientaiAgentsDataSource
  , agents :: Expr (Array ({ agentGuardrail :: Array ({ agentUuid :: String, createdAt :: String, defaultResponse :: String, description :: String, guardrailUuid :: String, isAttached :: Boolean, isDefault :: Boolean, name :: String, priority :: Number, type_ :: String, updatedAt :: String, uuid :: String }), agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), childAgents :: Array ({ agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, instruction :: String, modelUuid :: String, name :: String, projectId :: String, region :: String }), createdAt :: String, deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, functions :: Array ({ apiKey :: String, createdAt :: String, description :: String, faasname :: String, faasnamespace :: String, guardrailUuid :: String, name :: String, updatedAt :: String, url :: String, uuid :: String }), ifCase :: String, instruction :: String, k :: Number, knowledgeBases :: Array ({ addedToAgentAt :: String, createdAt :: String, databaseId :: String, embeddingModelUuid :: String, isPublic :: Boolean, lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), name :: String, projectId :: String, region :: String, tags :: Array String, updatedAt :: String, userId :: String, uuid :: String }), maxTokens :: Number, model :: Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) }), modelUuid :: String, name :: String, openAiApiKey :: Array ({ apiKey :: String }), parentAgents :: Array ({ agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, instruction :: String, modelUuid :: String, name :: String, projectId :: String, region :: String }), projectId :: String, region :: String, retrievalMethod :: String, routeCreatedAt :: String, routeCreatedBy :: String, routeName :: String, routeUuid :: String, tags :: Array String, temperature :: Number, template :: Array ({ createdAt :: String, description :: String, instruction :: String, k :: Number, knowledgeBases :: Array ({ addedToAgentAt :: String, createdAt :: String, databaseId :: String, embeddingModelUuid :: String, isPublic :: Boolean, lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), name :: String, projectId :: String, region :: String, tags :: Array String, updatedAt :: String, userId :: String, uuid :: String }), maxTokens :: Number, model :: Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) }), name :: String, temperature :: Number, topP :: Number, updatedAt :: String, uuid :: String }), topP :: Number, updatedAt :: String, url :: String, userId :: String }))
  , id :: Expr String
  , onlyDeployed :: Expr Boolean
  }

read :: String -> Args -> Infra GradientaiAgents
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_agents" logicalName values
  pure
    { dataSource: handle
    , agents: dataSourceAttr handle [ "agents" ]
    , id: dataSourceAttr handle [ "id" ]
    , onlyDeployed: dataSourceAttr handle [ "only_deployed" ]
    }
