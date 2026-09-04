module DigitalOcean.Data.GradientaiAgent
  ( Args
  , Required
  , GradientaiAgent
  , GradientaiAgentDataSource
  , args
  , read
  , agentGuardrail
  , anthropicApiKey
  , apiKeyInfos
  , apiKeys
  , chatbot
  , chatbotIdentifiers
  , deployment
  , description
  , functions
  , id
  , ifCase
  , k
  , knowledgeBases
  , maxTokens
  , model
  , openAiApiKey
  , retrievalMethod
  , routeCreatedBy
  , routeName
  , routeUuid
  , tags
  , temperature
  , template
  , topP
  , url
  , userId
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data GradientaiAgentDataSource

type Required =
  { agentId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "agent_id" (inputJson required.agentId)
  ])

agentGuardrail :: Input (Array ({ agentUuid :: String, createdAt :: String, defaultResponse :: String, description :: String, guardrailUuid :: String, isAttached :: Boolean, isDefault :: Boolean, name :: String, priority :: Number, type_ :: String, updatedAt :: String, uuid :: String })) -> Args -> Args
agentGuardrail value (Args values) = Args (Object.insert "agent_guardrail" (inputJson value) values)

anthropicApiKey :: Input (Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String })) -> Args -> Args
anthropicApiKey value (Args values) = Args (Object.insert "anthropic_api_key" (inputJson value) values)

apiKeyInfos :: Input (Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String })) -> Args -> Args
apiKeyInfos value (Args values) = Args (Object.insert "api_key_infos" (inputJson value) values)

apiKeys :: Input (Array ({ apiKey :: String })) -> Args -> Args
apiKeys value (Args values) = Args (Object.insert "api_keys" (inputJson value) values)

chatbot :: Input (Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String })) -> Args -> Args
chatbot value (Args values) = Args (Object.insert "chatbot" (inputJson value) values)

chatbotIdentifiers :: Input (Array ({ chatbotId :: String })) -> Args -> Args
chatbotIdentifiers value (Args values) = Args (Object.insert "chatbot_identifiers" (inputJson value) values)

deployment :: Input (Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String })) -> Args -> Args
deployment value (Args values) = Args (Object.insert "deployment" (inputJson value) values)

description :: Input String -> Args -> Args
description value (Args values) = Args (Object.insert "description" (inputJson value) values)

functions :: Input (Array ({ apiKey :: String, createdAt :: String, description :: String, faasname :: String, faasnamespace :: String, guardrailUuid :: String, name :: String, updatedAt :: String, url :: String, uuid :: String })) -> Args -> Args
functions value (Args values) = Args (Object.insert "functions" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

ifCase :: Input String -> Args -> Args
ifCase value (Args values) = Args (Object.insert "if_case" (inputJson value) values)

k :: Input Number -> Args -> Args
k value (Args values) = Args (Object.insert "k" (inputJson value) values)

knowledgeBases :: Input (Array ({ addedToAgentAt :: String, createdAt :: String, databaseId :: String, embeddingModelUuid :: String, isPublic :: Boolean, lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), name :: String, projectId :: String, region :: String, tags :: Array String, updatedAt :: String, userId :: String, uuid :: String })) -> Args -> Args
knowledgeBases value (Args values) = Args (Object.insert "knowledge_bases" (inputJson value) values)

maxTokens :: Input Number -> Args -> Args
maxTokens value (Args values) = Args (Object.insert "max_tokens" (inputJson value) values)

model :: Input (Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) })) -> Args -> Args
model value (Args values) = Args (Object.insert "model" (inputJson value) values)

openAiApiKey :: Input (Array ({ apiKey :: String })) -> Args -> Args
openAiApiKey value (Args values) = Args (Object.insert "open_ai_api_key" (inputJson value) values)

retrievalMethod :: Input String -> Args -> Args
retrievalMethod value (Args values) = Args (Object.insert "retrieval_method" (inputJson value) values)

routeCreatedBy :: Input String -> Args -> Args
routeCreatedBy value (Args values) = Args (Object.insert "route_created_by" (inputJson value) values)

routeName :: Input String -> Args -> Args
routeName value (Args values) = Args (Object.insert "route_name" (inputJson value) values)

routeUuid :: Input String -> Args -> Args
routeUuid value (Args values) = Args (Object.insert "route_uuid" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (Object.insert "tags" (inputJson value) values)

temperature :: Input Number -> Args -> Args
temperature value (Args values) = Args (Object.insert "temperature" (inputJson value) values)

template :: Input (Array ({ createdAt :: String, description :: String, instruction :: String, k :: Number, knowledgeBases :: Array ({ addedToAgentAt :: String, createdAt :: String, databaseId :: String, embeddingModelUuid :: String, isPublic :: Boolean, lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), name :: String, projectId :: String, region :: String, tags :: Array String, updatedAt :: String, userId :: String, uuid :: String }), maxTokens :: Number, model :: Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) }), name :: String, temperature :: Number, topP :: Number, updatedAt :: String, uuid :: String })) -> Args -> Args
template value (Args values) = Args (Object.insert "template" (inputJson value) values)

topP :: Input Number -> Args -> Args
topP value (Args values) = Args (Object.insert "top_p" (inputJson value) values)

url :: Input String -> Args -> Args
url value (Args values) = Args (Object.insert "url" (inputJson value) values)

userId :: Input String -> Args -> Args
userId value (Args values) = Args (Object.insert "user_id" (inputJson value) values)

type GradientaiAgent =
  { dataSource :: DataSource GradientaiAgentDataSource
  , agentId :: Expr String
  , childAgents :: Expr (Array ({ agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, instruction :: String, modelUuid :: String, name :: String, projectId :: String, region :: String }))
  , createdAt :: Expr String
  , description :: Expr String
  , id :: Expr String
  , ifCase :: Expr String
  , instruction :: Expr String
  , k :: Expr Number
  , maxTokens :: Expr Number
  , modelUuid :: Expr String
  , name :: Expr String
  , parentAgents :: Expr (Array ({ agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, instruction :: String, modelUuid :: String, name :: String, projectId :: String, region :: String }))
  , projectId :: Expr String
  , region :: Expr String
  , retrievalMethod :: Expr String
  , routeCreatedAt :: Expr String
  , routeCreatedBy :: Expr String
  , routeName :: Expr String
  , routeUuid :: Expr String
  , tags :: Expr (Array String)
  , temperature :: Expr Number
  , topP :: Expr Number
  , updatedAt :: Expr String
  , url :: Expr String
  , userId :: Expr String
  }

read :: String -> Args -> Infra GradientaiAgent
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_gradientai_agent" logicalName values
  pure
    { dataSource: handle
    , agentId: dataSourceAttr handle [ "agent_id" ]
    , childAgents: dataSourceAttr handle [ "child_agents" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , description: dataSourceAttr handle [ "description" ]
    , id: dataSourceAttr handle [ "id" ]
    , ifCase: dataSourceAttr handle [ "if_case" ]
    , instruction: dataSourceAttr handle [ "instruction" ]
    , k: dataSourceAttr handle [ "k" ]
    , maxTokens: dataSourceAttr handle [ "max_tokens" ]
    , modelUuid: dataSourceAttr handle [ "model_uuid" ]
    , name: dataSourceAttr handle [ "name" ]
    , parentAgents: dataSourceAttr handle [ "parent_agents" ]
    , projectId: dataSourceAttr handle [ "project_id" ]
    , region: dataSourceAttr handle [ "region" ]
    , retrievalMethod: dataSourceAttr handle [ "retrieval_method" ]
    , routeCreatedAt: dataSourceAttr handle [ "route_created_at" ]
    , routeCreatedBy: dataSourceAttr handle [ "route_created_by" ]
    , routeName: dataSourceAttr handle [ "route_name" ]
    , routeUuid: dataSourceAttr handle [ "route_uuid" ]
    , tags: dataSourceAttr handle [ "tags" ]
    , temperature: dataSourceAttr handle [ "temperature" ]
    , topP: dataSourceAttr handle [ "top_p" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , url: dataSourceAttr handle [ "url" ]
    , userId: dataSourceAttr handle [ "user_id" ]
    }
