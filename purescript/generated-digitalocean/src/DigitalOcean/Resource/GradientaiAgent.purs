module DigitalOcean.Resource.GradientaiAgent
  ( Args
  , Required
  , GradientaiAgent
  , GradientaiAgentResource
  , args
  , create
  , agentGuardrail
  , anthropicApiKey
  , anthropicKeyUuid
  , apiKeyInfos
  , apiKeys
  , chatbot
  , chatbotIdentifiers
  , childAgents
  , createdAt
  , deployment
  , description
  , functions
  , id
  , ifCase
  , k
  , knowledgeBaseUuid
  , knowledgeBases
  , maxTokens
  , model
  , openAiApiKey
  , openAiKeyUuid
  , parentAgents
  , provideCitations
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
  , workspaceUuid
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data GradientaiAgentResource

type Required =
  { instruction :: Input String
  , modelUuid :: Input String
  , name :: Input String
  , projectId :: Input String
  , region :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "instruction" (inputJson required.instruction)
  , Tuple "model_uuid" (inputJson required.modelUuid)
  , Tuple "name" (inputJson required.name)
  , Tuple "project_id" (inputJson required.projectId)
  , Tuple "region" (inputJson required.region)
  ])

agentGuardrail :: Input (Array ({ agentUuid :: String, createdAt :: String, defaultResponse :: String, description :: String, guardrailUuid :: String, isAttached :: Boolean, isDefault :: Boolean, name :: String, priority :: Number, type_ :: String, updatedAt :: String, uuid :: String })) -> Args -> Args
agentGuardrail value (Args values) = Args (Object.insert "agent_guardrail" (inputJson value) values)

anthropicApiKey :: Input (Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String })) -> Args -> Args
anthropicApiKey value (Args values) = Args (Object.insert "anthropic_api_key" (inputJson value) values)

anthropicKeyUuid :: Input String -> Args -> Args
anthropicKeyUuid value (Args values) = Args (Object.insert "anthropic_key_uuid" (inputJson value) values)

apiKeyInfos :: Input (Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String })) -> Args -> Args
apiKeyInfos value (Args values) = Args (Object.insert "api_key_infos" (inputJson value) values)

apiKeys :: Input (Array ({ apiKey :: String })) -> Args -> Args
apiKeys value (Args values) = Args (Object.insert "api_keys" (inputJson value) values)

chatbot :: Input (Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String })) -> Args -> Args
chatbot value (Args values) = Args (Object.insert "chatbot" (inputJson value) values)

chatbotIdentifiers :: Input (Array ({ chatbotId :: String })) -> Args -> Args
chatbotIdentifiers value (Args values) = Args (Object.insert "chatbot_identifiers" (inputJson value) values)

childAgents :: Input (Array ({ agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, instruction :: String, modelUuid :: String, name :: String, projectId :: String, region :: String })) -> Args -> Args
childAgents value (Args values) = Args (Object.insert "child_agents" (inputJson value) values)

createdAt :: Input String -> Args -> Args
createdAt value (Args values) = Args (Object.insert "created_at" (inputJson value) values)

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

knowledgeBaseUuid :: Input (Array String) -> Args -> Args
knowledgeBaseUuid value (Args values) = Args (Object.insert "knowledge_base_uuid" (inputJson value) values)

knowledgeBases :: Input (Array ({ addedToAgentAt :: String, createdAt :: String, databaseId :: String, embeddingModelUuid :: String, isPublic :: Boolean, lastIndexingJob :: Array ({ completedDatasources :: Number, createdAt :: String, dataSourceUuids :: Array String, finishedAt :: String, knowledgeBaseUuid :: String, phase :: String, startedAt :: String, tokens :: Number, totalDatasources :: Number, updatedAt :: String, uuid :: String }), name :: String, projectId :: String, region :: String, tags :: Array String, updatedAt :: String, userId :: String, uuid :: String })) -> Args -> Args
knowledgeBases value (Args values) = Args (Object.insert "knowledge_bases" (inputJson value) values)

maxTokens :: Input Number -> Args -> Args
maxTokens value (Args values) = Args (Object.insert "max_tokens" (inputJson value) values)

model :: Input (Array ({ agreement :: Array ({ description :: String, name :: String, url :: String, uuid :: String }), createdAt :: String, inferenceName :: String, inferenceVersion :: String, isFoundational :: Boolean, name :: String, parentUuid :: String, provider :: String, updatedAt :: String, uploadComplete :: Boolean, url :: String, usecases :: Array String, versions :: Array ({ major :: Number, minor :: Number, patch :: Number }) })) -> Args -> Args
model value (Args values) = Args (Object.insert "model" (inputJson value) values)

openAiApiKey :: Input (Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String })) -> Args -> Args
openAiApiKey value (Args values) = Args (Object.insert "open_ai_api_key" (inputJson value) values)

openAiKeyUuid :: Input String -> Args -> Args
openAiKeyUuid value (Args values) = Args (Object.insert "open_ai_key_uuid" (inputJson value) values)

parentAgents :: Input (Array ({ agentId :: String, anthropicApiKey :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, updatedAt :: String, uuid :: String }), apiKeyInfos :: Array ({ createdAt :: String, createdBy :: String, deletedAt :: String, name :: String, secretKey :: String, uuid :: String }), apiKeys :: Array ({ apiKey :: String }), chatbot :: Array ({ buttonBackgroundColor :: String, logo :: String, name :: String, primaryColor :: String, secondaryColor :: String, startingMessage :: String }), chatbotIdentifiers :: Array ({ chatbotId :: String }), deployment :: Array ({ createdAt :: String, name :: String, status :: String, updatedAt :: String, url :: String, uuid :: String, visibility :: String }), description :: String, instruction :: String, modelUuid :: String, name :: String, projectId :: String, region :: String })) -> Args -> Args
parentAgents value (Args values) = Args (Object.insert "parent_agents" (inputJson value) values)

provideCitations :: Input Boolean -> Args -> Args
provideCitations value (Args values) = Args (Object.insert "provide_citations" (inputJson value) values)

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

workspaceUuid :: Input String -> Args -> Args
workspaceUuid value (Args values) = Args (Object.insert "workspace_uuid" (inputJson value) values)

type GradientaiAgent =
  { resource :: Resource GradientaiAgentResource
  , anthropicKeyUuid :: Expr String
  , createdAt :: Expr String
  , description :: Expr String
  , id :: Expr String
  , ifCase :: Expr String
  , instruction :: Expr String
  , k :: Expr Number
  , knowledgeBaseUuid :: Expr (Array String)
  , maxTokens :: Expr Number
  , modelUuid :: Expr String
  , name :: Expr String
  , openAiKeyUuid :: Expr String
  , projectId :: Expr String
  , provideCitations :: Expr Boolean
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
  , workspaceUuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiAgent
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_agent" logicalName values
  pure
    { resource: handle
    , anthropicKeyUuid: resourceAttr handle [ "anthropic_key_uuid" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , description: resourceAttr handle [ "description" ]
    , id: resourceAttr handle [ "id" ]
    , ifCase: resourceAttr handle [ "if_case" ]
    , instruction: resourceAttr handle [ "instruction" ]
    , k: resourceAttr handle [ "k" ]
    , knowledgeBaseUuid: resourceAttr handle [ "knowledge_base_uuid" ]
    , maxTokens: resourceAttr handle [ "max_tokens" ]
    , modelUuid: resourceAttr handle [ "model_uuid" ]
    , name: resourceAttr handle [ "name" ]
    , openAiKeyUuid: resourceAttr handle [ "open_ai_key_uuid" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , provideCitations: resourceAttr handle [ "provide_citations" ]
    , region: resourceAttr handle [ "region" ]
    , retrievalMethod: resourceAttr handle [ "retrieval_method" ]
    , routeCreatedAt: resourceAttr handle [ "route_created_at" ]
    , routeCreatedBy: resourceAttr handle [ "route_created_by" ]
    , routeName: resourceAttr handle [ "route_name" ]
    , routeUuid: resourceAttr handle [ "route_uuid" ]
    , tags: resourceAttr handle [ "tags" ]
    , temperature: resourceAttr handle [ "temperature" ]
    , topP: resourceAttr handle [ "top_p" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , url: resourceAttr handle [ "url" ]
    , userId: resourceAttr handle [ "user_id" ]
    , workspaceUuid: resourceAttr handle [ "workspace_uuid" ]
    }
