module DigitalOcean.Resource.GradientaiAgent
  ( Args
  , Required
  , GradientaiAgent
  , GradientaiAgentResource
  , args
  , create
  , AgentGuardrail
  , AgentGuardrailRequired
  , agentGuardrailArgs
  , agentGuardrailAgentUuid
  , agentGuardrailDefaultResponse
  , agentGuardrailDescription
  , agentGuardrailGuardrailUuid
  , agentGuardrailIsDefault
  , agentGuardrailName
  , agentGuardrailPriority
  , agentGuardrailType
  , agentGuardrailUuid
  , AnthropicApiKey
  , AnthropicApiKeyRequired
  , anthropicApiKeyArgs
  , anthropicApiKeyCreatedBy
  , anthropicApiKeyName
  , anthropicApiKeyUuid
  , ApiKeyInfos
  , ApiKeyInfosRequired
  , apiKeyInfosArgs
  , apiKeyInfosCreatedBy
  , apiKeyInfosName
  , apiKeyInfosSecretKey
  , apiKeyInfosUuid
  , ApiKeys
  , ApiKeysRequired
  , apiKeysArgs
  , apiKeysApiKey
  , Chatbot
  , ChatbotRequired
  , chatbotArgs
  , chatbotButtonBackgroundColor
  , chatbotLogo
  , chatbotName
  , chatbotPrimaryColor
  , chatbotSecondaryColor
  , chatbotStartingMessage
  , ChatbotIdentifiers
  , ChatbotIdentifiersRequired
  , chatbotIdentifiersArgs
  , ChildAgents
  , ChildAgentsRequired
  , childAgentsArgs
  , childAgentsAnthropicApiKey
  , childAgentsApiKeyInfos
  , childAgentsApiKeys
  , childAgentsChatbot
  , childAgentsChatbotIdentifiers
  , childAgentsDeployment
  , childAgentsDescription
  , ChildAgentsAnthropicApiKey
  , ChildAgentsAnthropicApiKeyRequired
  , childAgentsAnthropicApiKeyArgs
  , childAgentsAnthropicApiKeyCreatedBy
  , childAgentsAnthropicApiKeyName
  , childAgentsAnthropicApiKeyUuid
  , ChildAgentsApiKeyInfos
  , ChildAgentsApiKeyInfosRequired
  , childAgentsApiKeyInfosArgs
  , childAgentsApiKeyInfosCreatedBy
  , childAgentsApiKeyInfosName
  , childAgentsApiKeyInfosSecretKey
  , childAgentsApiKeyInfosUuid
  , ChildAgentsApiKeys
  , ChildAgentsApiKeysRequired
  , childAgentsApiKeysArgs
  , childAgentsApiKeysApiKey
  , ChildAgentsChatbot
  , ChildAgentsChatbotRequired
  , childAgentsChatbotArgs
  , childAgentsChatbotButtonBackgroundColor
  , childAgentsChatbotLogo
  , childAgentsChatbotName
  , childAgentsChatbotPrimaryColor
  , childAgentsChatbotSecondaryColor
  , childAgentsChatbotStartingMessage
  , ChildAgentsChatbotIdentifiers
  , ChildAgentsChatbotIdentifiersRequired
  , childAgentsChatbotIdentifiersArgs
  , ChildAgentsDeployment
  , ChildAgentsDeploymentRequired
  , childAgentsDeploymentArgs
  , childAgentsDeploymentName
  , childAgentsDeploymentStatus
  , childAgentsDeploymentUrl
  , childAgentsDeploymentUuid
  , childAgentsDeploymentVisibility
  , Deployment
  , DeploymentRequired
  , deploymentArgs
  , deploymentName
  , deploymentStatus
  , deploymentUrl
  , deploymentUuid
  , deploymentVisibility
  , Functions
  , FunctionsRequired
  , functionsArgs
  , functionsApiKey
  , functionsDescription
  , functionsFaasname
  , functionsFaasnamespace
  , functionsGuardrailUuid
  , functionsName
  , functionsUrl
  , functionsUuid
  , KnowledgeBases
  , KnowledgeBasesRequired
  , knowledgeBasesArgs
  , knowledgeBasesDatabaseId
  , knowledgeBasesEmbeddingModelUuid
  , knowledgeBasesIsPublic
  , knowledgeBasesLastIndexingJob
  , knowledgeBasesName
  , knowledgeBasesProjectId
  , knowledgeBasesRegion
  , knowledgeBasesTags
  , knowledgeBasesUserId
  , KnowledgeBasesLastIndexingJob
  , KnowledgeBasesLastIndexingJobRequired
  , knowledgeBasesLastIndexingJobArgs
  , knowledgeBasesLastIndexingJobCompletedDatasources
  , knowledgeBasesLastIndexingJobDataSourceUuids
  , knowledgeBasesLastIndexingJobPhase
  , knowledgeBasesLastIndexingJobTokens
  , knowledgeBasesLastIndexingJobTotalDatasources
  , knowledgeBasesLastIndexingJobUuid
  , Model
  , ModelRequired
  , modelArgs
  , modelAgreement
  , modelInferenceName
  , modelInferenceVersion
  , modelIsFoundational
  , modelName
  , modelParentUuid
  , modelProvider
  , modelUploadComplete
  , modelUrl
  , modelUsecases
  , modelVersions
  , ModelAgreement
  , ModelAgreementRequired
  , modelAgreementArgs
  , modelAgreementDescription
  , modelAgreementName
  , modelAgreementUrl
  , modelAgreementUuid
  , ModelVersions
  , ModelVersionsRequired
  , modelVersionsArgs
  , modelVersionsMajor
  , modelVersionsMinor
  , modelVersionsPatch
  , OpenAiApiKey
  , OpenAiApiKeyRequired
  , openAiApiKeyArgs
  , openAiApiKeyCreatedBy
  , openAiApiKeyName
  , openAiApiKeyUuid
  , ParentAgents
  , ParentAgentsRequired
  , parentAgentsArgs
  , parentAgentsAnthropicApiKey
  , parentAgentsApiKeyInfos
  , parentAgentsApiKeys
  , parentAgentsChatbot
  , parentAgentsChatbotIdentifiers
  , parentAgentsDeployment
  , parentAgentsDescription
  , ParentAgentsAnthropicApiKey
  , ParentAgentsAnthropicApiKeyRequired
  , parentAgentsAnthropicApiKeyArgs
  , parentAgentsAnthropicApiKeyCreatedBy
  , parentAgentsAnthropicApiKeyName
  , parentAgentsAnthropicApiKeyUuid
  , ParentAgentsApiKeyInfos
  , ParentAgentsApiKeyInfosRequired
  , parentAgentsApiKeyInfosArgs
  , parentAgentsApiKeyInfosCreatedBy
  , parentAgentsApiKeyInfosName
  , parentAgentsApiKeyInfosSecretKey
  , parentAgentsApiKeyInfosUuid
  , ParentAgentsApiKeys
  , ParentAgentsApiKeysRequired
  , parentAgentsApiKeysArgs
  , parentAgentsApiKeysApiKey
  , ParentAgentsChatbot
  , ParentAgentsChatbotRequired
  , parentAgentsChatbotArgs
  , parentAgentsChatbotButtonBackgroundColor
  , parentAgentsChatbotLogo
  , parentAgentsChatbotName
  , parentAgentsChatbotPrimaryColor
  , parentAgentsChatbotSecondaryColor
  , parentAgentsChatbotStartingMessage
  , ParentAgentsChatbotIdentifiers
  , ParentAgentsChatbotIdentifiersRequired
  , parentAgentsChatbotIdentifiersArgs
  , ParentAgentsDeployment
  , ParentAgentsDeploymentRequired
  , parentAgentsDeploymentArgs
  , parentAgentsDeploymentName
  , parentAgentsDeploymentStatus
  , parentAgentsDeploymentUrl
  , parentAgentsDeploymentUuid
  , parentAgentsDeploymentVisibility
  , Template
  , TemplateRequired
  , templateArgs
  , templateDescription
  , templateInstruction
  , templateK
  , templateKnowledgeBases
  , templateMaxTokens
  , templateModel
  , templateName
  , templateTemperature
  , templateTopP
  , templateUuid
  , TemplateKnowledgeBases
  , TemplateKnowledgeBasesRequired
  , templateKnowledgeBasesArgs
  , templateKnowledgeBasesDatabaseId
  , templateKnowledgeBasesEmbeddingModelUuid
  , templateKnowledgeBasesIsPublic
  , templateKnowledgeBasesLastIndexingJob
  , templateKnowledgeBasesName
  , templateKnowledgeBasesProjectId
  , templateKnowledgeBasesRegion
  , templateKnowledgeBasesTags
  , templateKnowledgeBasesUserId
  , TemplateKnowledgeBasesLastIndexingJob
  , TemplateKnowledgeBasesLastIndexingJobRequired
  , templateKnowledgeBasesLastIndexingJobArgs
  , templateKnowledgeBasesLastIndexingJobCompletedDatasources
  , templateKnowledgeBasesLastIndexingJobDataSourceUuids
  , templateKnowledgeBasesLastIndexingJobPhase
  , templateKnowledgeBasesLastIndexingJobTokens
  , templateKnowledgeBasesLastIndexingJobTotalDatasources
  , templateKnowledgeBasesLastIndexingJobUuid
  , TemplateModel
  , TemplateModelRequired
  , templateModelArgs
  , templateModelAgreement
  , templateModelInferenceName
  , templateModelInferenceVersion
  , templateModelIsFoundational
  , templateModelName
  , templateModelParentUuid
  , templateModelProvider
  , templateModelUploadComplete
  , templateModelUrl
  , templateModelUsecases
  , templateModelVersions
  , TemplateModelAgreement
  , TemplateModelAgreementRequired
  , templateModelAgreementArgs
  , templateModelAgreementDescription
  , templateModelAgreementName
  , templateModelAgreementUrl
  , templateModelAgreementUuid
  , TemplateModelVersions
  , TemplateModelVersionsRequired
  , templateModelVersionsArgs
  , templateModelVersionsMajor
  , templateModelVersionsMinor
  , templateModelVersionsPatch
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data GradientaiAgentResource

newtype AgentGuardrail = AgentGuardrail InputObject

type AgentGuardrailRequired =
  {
  }

agentGuardrailArgs :: AgentGuardrailRequired -> AgentGuardrail
agentGuardrailArgs _ = AgentGuardrail (inputObject
  [
  ])

agentGuardrailAgentUuid :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailAgentUuid value (AgentGuardrail values) = AgentGuardrail (insertInputField "agent_uuid" (inputJson value) values)

agentGuardrailDefaultResponse :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailDefaultResponse value (AgentGuardrail values) = AgentGuardrail (insertInputField "default_response" (inputJson value) values)

agentGuardrailDescription :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailDescription value (AgentGuardrail values) = AgentGuardrail (insertInputField "description" (inputJson value) values)

agentGuardrailGuardrailUuid :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailGuardrailUuid value (AgentGuardrail values) = AgentGuardrail (insertInputField "guardrail_uuid" (inputJson value) values)

agentGuardrailIsDefault :: Input Boolean -> AgentGuardrail -> AgentGuardrail
agentGuardrailIsDefault value (AgentGuardrail values) = AgentGuardrail (insertInputField "is_default" (inputJson value) values)

agentGuardrailName :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailName value (AgentGuardrail values) = AgentGuardrail (insertInputField "name" (inputJson value) values)

agentGuardrailPriority :: Input Number -> AgentGuardrail -> AgentGuardrail
agentGuardrailPriority value (AgentGuardrail values) = AgentGuardrail (insertInputField "priority" (inputJson value) values)

agentGuardrailType :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailType value (AgentGuardrail values) = AgentGuardrail (insertInputField "type" (inputJson value) values)

agentGuardrailUuid :: Input String -> AgentGuardrail -> AgentGuardrail
agentGuardrailUuid value (AgentGuardrail values) = AgentGuardrail (insertInputField "uuid" (inputJson value) values)

agentGuardrailJson :: AgentGuardrail -> Json
agentGuardrailJson (AgentGuardrail values) = inputObjectJson values

newtype AnthropicApiKey = AnthropicApiKey InputObject

type AnthropicApiKeyRequired =
  {
  }

anthropicApiKeyArgs :: AnthropicApiKeyRequired -> AnthropicApiKey
anthropicApiKeyArgs _ = AnthropicApiKey (inputObject
  [
  ])

anthropicApiKeyCreatedBy :: Input String -> AnthropicApiKey -> AnthropicApiKey
anthropicApiKeyCreatedBy value (AnthropicApiKey values) = AnthropicApiKey (insertInputField "created_by" (inputJson value) values)

anthropicApiKeyName :: Input String -> AnthropicApiKey -> AnthropicApiKey
anthropicApiKeyName value (AnthropicApiKey values) = AnthropicApiKey (insertInputField "name" (inputJson value) values)

anthropicApiKeyUuid :: Input String -> AnthropicApiKey -> AnthropicApiKey
anthropicApiKeyUuid value (AnthropicApiKey values) = AnthropicApiKey (insertInputField "uuid" (inputJson value) values)

anthropicApiKeyJson :: AnthropicApiKey -> Json
anthropicApiKeyJson (AnthropicApiKey values) = inputObjectJson values

newtype ApiKeyInfos = ApiKeyInfos InputObject

type ApiKeyInfosRequired =
  {
  }

apiKeyInfosArgs :: ApiKeyInfosRequired -> ApiKeyInfos
apiKeyInfosArgs _ = ApiKeyInfos (inputObject
  [
  ])

apiKeyInfosCreatedBy :: Input String -> ApiKeyInfos -> ApiKeyInfos
apiKeyInfosCreatedBy value (ApiKeyInfos values) = ApiKeyInfos (insertInputField "created_by" (inputJson value) values)

apiKeyInfosName :: Input String -> ApiKeyInfos -> ApiKeyInfos
apiKeyInfosName value (ApiKeyInfos values) = ApiKeyInfos (insertInputField "name" (inputJson value) values)

apiKeyInfosSecretKey :: Input String -> ApiKeyInfos -> ApiKeyInfos
apiKeyInfosSecretKey value (ApiKeyInfos values) = ApiKeyInfos (insertInputField "secret_key" (inputJson value) values)

apiKeyInfosUuid :: Input String -> ApiKeyInfos -> ApiKeyInfos
apiKeyInfosUuid value (ApiKeyInfos values) = ApiKeyInfos (insertInputField "uuid" (inputJson value) values)

apiKeyInfosJson :: ApiKeyInfos -> Json
apiKeyInfosJson (ApiKeyInfos values) = inputObjectJson values

newtype ApiKeys = ApiKeys InputObject

type ApiKeysRequired =
  {
  }

apiKeysArgs :: ApiKeysRequired -> ApiKeys
apiKeysArgs _ = ApiKeys (inputObject
  [
  ])

apiKeysApiKey :: Input String -> ApiKeys -> ApiKeys
apiKeysApiKey value (ApiKeys values) = ApiKeys (insertInputField "api_key" (inputJson value) values)

apiKeysJson :: ApiKeys -> Json
apiKeysJson (ApiKeys values) = inputObjectJson values

newtype Chatbot = Chatbot InputObject

type ChatbotRequired =
  {
  }

chatbotArgs :: ChatbotRequired -> Chatbot
chatbotArgs _ = Chatbot (inputObject
  [
  ])

chatbotButtonBackgroundColor :: Input String -> Chatbot -> Chatbot
chatbotButtonBackgroundColor value (Chatbot values) = Chatbot (insertInputField "button_background_color" (inputJson value) values)

chatbotLogo :: Input String -> Chatbot -> Chatbot
chatbotLogo value (Chatbot values) = Chatbot (insertInputField "logo" (inputJson value) values)

chatbotName :: Input String -> Chatbot -> Chatbot
chatbotName value (Chatbot values) = Chatbot (insertInputField "name" (inputJson value) values)

chatbotPrimaryColor :: Input String -> Chatbot -> Chatbot
chatbotPrimaryColor value (Chatbot values) = Chatbot (insertInputField "primary_color" (inputJson value) values)

chatbotSecondaryColor :: Input String -> Chatbot -> Chatbot
chatbotSecondaryColor value (Chatbot values) = Chatbot (insertInputField "secondary_color" (inputJson value) values)

chatbotStartingMessage :: Input String -> Chatbot -> Chatbot
chatbotStartingMessage value (Chatbot values) = Chatbot (insertInputField "starting_message" (inputJson value) values)

chatbotJson :: Chatbot -> Json
chatbotJson (Chatbot values) = inputObjectJson values

newtype ChatbotIdentifiers = ChatbotIdentifiers InputObject

type ChatbotIdentifiersRequired =
  {
  }

chatbotIdentifiersArgs :: ChatbotIdentifiersRequired -> ChatbotIdentifiers
chatbotIdentifiersArgs _ = ChatbotIdentifiers (inputObject
  [
  ])

chatbotIdentifiersJson :: ChatbotIdentifiers -> Json
chatbotIdentifiersJson (ChatbotIdentifiers values) = inputObjectJson values

newtype ChildAgents = ChildAgents InputObject

type ChildAgentsRequired =
  { instruction :: Input String
  , modelUuid :: Input String
  , name :: Input String
  , projectId :: Input String
  , region :: Input String
  }

childAgentsArgs :: ChildAgentsRequired -> ChildAgents
childAgentsArgs required = ChildAgents (inputObject
  [ Tuple "instruction" (inputJson required.instruction)
  , Tuple "model_uuid" (inputJson required.modelUuid)
  , Tuple "name" (inputJson required.name)
  , Tuple "project_id" (inputJson required.projectId)
  , Tuple "region" (inputJson required.region)
  ])

childAgentsAnthropicApiKey :: Array ChildAgentsAnthropicApiKey -> ChildAgents -> ChildAgents
childAgentsAnthropicApiKey value (ChildAgents values) = ChildAgents (insertInputField "anthropic_api_key" (arrayExprJson (map childAgentsAnthropicApiKeyJson value)) values)

childAgentsApiKeyInfos :: Array ChildAgentsApiKeyInfos -> ChildAgents -> ChildAgents
childAgentsApiKeyInfos value (ChildAgents values) = ChildAgents (insertInputField "api_key_infos" (arrayExprJson (map childAgentsApiKeyInfosJson value)) values)

childAgentsApiKeys :: Array ChildAgentsApiKeys -> ChildAgents -> ChildAgents
childAgentsApiKeys value (ChildAgents values) = ChildAgents (insertInputField "api_keys" (arrayExprJson (map childAgentsApiKeysJson value)) values)

childAgentsChatbot :: Array ChildAgentsChatbot -> ChildAgents -> ChildAgents
childAgentsChatbot value (ChildAgents values) = ChildAgents (insertInputField "chatbot" (arrayExprJson (map childAgentsChatbotJson value)) values)

childAgentsChatbotIdentifiers :: Array ChildAgentsChatbotIdentifiers -> ChildAgents -> ChildAgents
childAgentsChatbotIdentifiers value (ChildAgents values) = ChildAgents (insertInputField "chatbot_identifiers" (arrayExprJson (map childAgentsChatbotIdentifiersJson value)) values)

childAgentsDeployment :: Array ChildAgentsDeployment -> ChildAgents -> ChildAgents
childAgentsDeployment value (ChildAgents values) = ChildAgents (insertInputField "deployment" (arrayExprJson (map childAgentsDeploymentJson value)) values)

childAgentsDescription :: Input String -> ChildAgents -> ChildAgents
childAgentsDescription value (ChildAgents values) = ChildAgents (insertInputField "description" (inputJson value) values)

childAgentsJson :: ChildAgents -> Json
childAgentsJson (ChildAgents values) = inputObjectJson values

newtype ChildAgentsAnthropicApiKey = ChildAgentsAnthropicApiKey InputObject

type ChildAgentsAnthropicApiKeyRequired =
  {
  }

childAgentsAnthropicApiKeyArgs :: ChildAgentsAnthropicApiKeyRequired -> ChildAgentsAnthropicApiKey
childAgentsAnthropicApiKeyArgs _ = ChildAgentsAnthropicApiKey (inputObject
  [
  ])

childAgentsAnthropicApiKeyCreatedBy :: Input String -> ChildAgentsAnthropicApiKey -> ChildAgentsAnthropicApiKey
childAgentsAnthropicApiKeyCreatedBy value (ChildAgentsAnthropicApiKey values) = ChildAgentsAnthropicApiKey (insertInputField "created_by" (inputJson value) values)

childAgentsAnthropicApiKeyName :: Input String -> ChildAgentsAnthropicApiKey -> ChildAgentsAnthropicApiKey
childAgentsAnthropicApiKeyName value (ChildAgentsAnthropicApiKey values) = ChildAgentsAnthropicApiKey (insertInputField "name" (inputJson value) values)

childAgentsAnthropicApiKeyUuid :: Input String -> ChildAgentsAnthropicApiKey -> ChildAgentsAnthropicApiKey
childAgentsAnthropicApiKeyUuid value (ChildAgentsAnthropicApiKey values) = ChildAgentsAnthropicApiKey (insertInputField "uuid" (inputJson value) values)

childAgentsAnthropicApiKeyJson :: ChildAgentsAnthropicApiKey -> Json
childAgentsAnthropicApiKeyJson (ChildAgentsAnthropicApiKey values) = inputObjectJson values

newtype ChildAgentsApiKeyInfos = ChildAgentsApiKeyInfos InputObject

type ChildAgentsApiKeyInfosRequired =
  {
  }

childAgentsApiKeyInfosArgs :: ChildAgentsApiKeyInfosRequired -> ChildAgentsApiKeyInfos
childAgentsApiKeyInfosArgs _ = ChildAgentsApiKeyInfos (inputObject
  [
  ])

childAgentsApiKeyInfosCreatedBy :: Input String -> ChildAgentsApiKeyInfos -> ChildAgentsApiKeyInfos
childAgentsApiKeyInfosCreatedBy value (ChildAgentsApiKeyInfos values) = ChildAgentsApiKeyInfos (insertInputField "created_by" (inputJson value) values)

childAgentsApiKeyInfosName :: Input String -> ChildAgentsApiKeyInfos -> ChildAgentsApiKeyInfos
childAgentsApiKeyInfosName value (ChildAgentsApiKeyInfos values) = ChildAgentsApiKeyInfos (insertInputField "name" (inputJson value) values)

childAgentsApiKeyInfosSecretKey :: Input String -> ChildAgentsApiKeyInfos -> ChildAgentsApiKeyInfos
childAgentsApiKeyInfosSecretKey value (ChildAgentsApiKeyInfos values) = ChildAgentsApiKeyInfos (insertInputField "secret_key" (inputJson value) values)

childAgentsApiKeyInfosUuid :: Input String -> ChildAgentsApiKeyInfos -> ChildAgentsApiKeyInfos
childAgentsApiKeyInfosUuid value (ChildAgentsApiKeyInfos values) = ChildAgentsApiKeyInfos (insertInputField "uuid" (inputJson value) values)

childAgentsApiKeyInfosJson :: ChildAgentsApiKeyInfos -> Json
childAgentsApiKeyInfosJson (ChildAgentsApiKeyInfos values) = inputObjectJson values

newtype ChildAgentsApiKeys = ChildAgentsApiKeys InputObject

type ChildAgentsApiKeysRequired =
  {
  }

childAgentsApiKeysArgs :: ChildAgentsApiKeysRequired -> ChildAgentsApiKeys
childAgentsApiKeysArgs _ = ChildAgentsApiKeys (inputObject
  [
  ])

childAgentsApiKeysApiKey :: Input String -> ChildAgentsApiKeys -> ChildAgentsApiKeys
childAgentsApiKeysApiKey value (ChildAgentsApiKeys values) = ChildAgentsApiKeys (insertInputField "api_key" (inputJson value) values)

childAgentsApiKeysJson :: ChildAgentsApiKeys -> Json
childAgentsApiKeysJson (ChildAgentsApiKeys values) = inputObjectJson values

newtype ChildAgentsChatbot = ChildAgentsChatbot InputObject

type ChildAgentsChatbotRequired =
  {
  }

childAgentsChatbotArgs :: ChildAgentsChatbotRequired -> ChildAgentsChatbot
childAgentsChatbotArgs _ = ChildAgentsChatbot (inputObject
  [
  ])

childAgentsChatbotButtonBackgroundColor :: Input String -> ChildAgentsChatbot -> ChildAgentsChatbot
childAgentsChatbotButtonBackgroundColor value (ChildAgentsChatbot values) = ChildAgentsChatbot (insertInputField "button_background_color" (inputJson value) values)

childAgentsChatbotLogo :: Input String -> ChildAgentsChatbot -> ChildAgentsChatbot
childAgentsChatbotLogo value (ChildAgentsChatbot values) = ChildAgentsChatbot (insertInputField "logo" (inputJson value) values)

childAgentsChatbotName :: Input String -> ChildAgentsChatbot -> ChildAgentsChatbot
childAgentsChatbotName value (ChildAgentsChatbot values) = ChildAgentsChatbot (insertInputField "name" (inputJson value) values)

childAgentsChatbotPrimaryColor :: Input String -> ChildAgentsChatbot -> ChildAgentsChatbot
childAgentsChatbotPrimaryColor value (ChildAgentsChatbot values) = ChildAgentsChatbot (insertInputField "primary_color" (inputJson value) values)

childAgentsChatbotSecondaryColor :: Input String -> ChildAgentsChatbot -> ChildAgentsChatbot
childAgentsChatbotSecondaryColor value (ChildAgentsChatbot values) = ChildAgentsChatbot (insertInputField "secondary_color" (inputJson value) values)

childAgentsChatbotStartingMessage :: Input String -> ChildAgentsChatbot -> ChildAgentsChatbot
childAgentsChatbotStartingMessage value (ChildAgentsChatbot values) = ChildAgentsChatbot (insertInputField "starting_message" (inputJson value) values)

childAgentsChatbotJson :: ChildAgentsChatbot -> Json
childAgentsChatbotJson (ChildAgentsChatbot values) = inputObjectJson values

newtype ChildAgentsChatbotIdentifiers = ChildAgentsChatbotIdentifiers InputObject

type ChildAgentsChatbotIdentifiersRequired =
  {
  }

childAgentsChatbotIdentifiersArgs :: ChildAgentsChatbotIdentifiersRequired -> ChildAgentsChatbotIdentifiers
childAgentsChatbotIdentifiersArgs _ = ChildAgentsChatbotIdentifiers (inputObject
  [
  ])

childAgentsChatbotIdentifiersJson :: ChildAgentsChatbotIdentifiers -> Json
childAgentsChatbotIdentifiersJson (ChildAgentsChatbotIdentifiers values) = inputObjectJson values

newtype ChildAgentsDeployment = ChildAgentsDeployment InputObject

type ChildAgentsDeploymentRequired =
  {
  }

childAgentsDeploymentArgs :: ChildAgentsDeploymentRequired -> ChildAgentsDeployment
childAgentsDeploymentArgs _ = ChildAgentsDeployment (inputObject
  [
  ])

childAgentsDeploymentName :: Input String -> ChildAgentsDeployment -> ChildAgentsDeployment
childAgentsDeploymentName value (ChildAgentsDeployment values) = ChildAgentsDeployment (insertInputField "name" (inputJson value) values)

childAgentsDeploymentStatus :: Input String -> ChildAgentsDeployment -> ChildAgentsDeployment
childAgentsDeploymentStatus value (ChildAgentsDeployment values) = ChildAgentsDeployment (insertInputField "status" (inputJson value) values)

childAgentsDeploymentUrl :: Input String -> ChildAgentsDeployment -> ChildAgentsDeployment
childAgentsDeploymentUrl value (ChildAgentsDeployment values) = ChildAgentsDeployment (insertInputField "url" (inputJson value) values)

childAgentsDeploymentUuid :: Input String -> ChildAgentsDeployment -> ChildAgentsDeployment
childAgentsDeploymentUuid value (ChildAgentsDeployment values) = ChildAgentsDeployment (insertInputField "uuid" (inputJson value) values)

childAgentsDeploymentVisibility :: Input String -> ChildAgentsDeployment -> ChildAgentsDeployment
childAgentsDeploymentVisibility value (ChildAgentsDeployment values) = ChildAgentsDeployment (insertInputField "visibility" (inputJson value) values)

childAgentsDeploymentJson :: ChildAgentsDeployment -> Json
childAgentsDeploymentJson (ChildAgentsDeployment values) = inputObjectJson values

newtype Deployment = Deployment InputObject

type DeploymentRequired =
  {
  }

deploymentArgs :: DeploymentRequired -> Deployment
deploymentArgs _ = Deployment (inputObject
  [
  ])

deploymentName :: Input String -> Deployment -> Deployment
deploymentName value (Deployment values) = Deployment (insertInputField "name" (inputJson value) values)

deploymentStatus :: Input String -> Deployment -> Deployment
deploymentStatus value (Deployment values) = Deployment (insertInputField "status" (inputJson value) values)

deploymentUrl :: Input String -> Deployment -> Deployment
deploymentUrl value (Deployment values) = Deployment (insertInputField "url" (inputJson value) values)

deploymentUuid :: Input String -> Deployment -> Deployment
deploymentUuid value (Deployment values) = Deployment (insertInputField "uuid" (inputJson value) values)

deploymentVisibility :: Input String -> Deployment -> Deployment
deploymentVisibility value (Deployment values) = Deployment (insertInputField "visibility" (inputJson value) values)

deploymentJson :: Deployment -> Json
deploymentJson (Deployment values) = inputObjectJson values

newtype Functions = Functions InputObject

type FunctionsRequired =
  {
  }

functionsArgs :: FunctionsRequired -> Functions
functionsArgs _ = Functions (inputObject
  [
  ])

functionsApiKey :: Input String -> Functions -> Functions
functionsApiKey value (Functions values) = Functions (insertInputField "api_key" (inputJson value) values)

functionsDescription :: Input String -> Functions -> Functions
functionsDescription value (Functions values) = Functions (insertInputField "description" (inputJson value) values)

functionsFaasname :: Input String -> Functions -> Functions
functionsFaasname value (Functions values) = Functions (insertInputField "faasname" (inputJson value) values)

functionsFaasnamespace :: Input String -> Functions -> Functions
functionsFaasnamespace value (Functions values) = Functions (insertInputField "faasnamespace" (inputJson value) values)

functionsGuardrailUuid :: Input String -> Functions -> Functions
functionsGuardrailUuid value (Functions values) = Functions (insertInputField "guardrail_uuid" (inputJson value) values)

functionsName :: Input String -> Functions -> Functions
functionsName value (Functions values) = Functions (insertInputField "name" (inputJson value) values)

functionsUrl :: Input String -> Functions -> Functions
functionsUrl value (Functions values) = Functions (insertInputField "url" (inputJson value) values)

functionsUuid :: Input String -> Functions -> Functions
functionsUuid value (Functions values) = Functions (insertInputField "uuid" (inputJson value) values)

functionsJson :: Functions -> Json
functionsJson (Functions values) = inputObjectJson values

newtype KnowledgeBases = KnowledgeBases InputObject

type KnowledgeBasesRequired =
  {
  }

knowledgeBasesArgs :: KnowledgeBasesRequired -> KnowledgeBases
knowledgeBasesArgs _ = KnowledgeBases (inputObject
  [
  ])

knowledgeBasesDatabaseId :: Input String -> KnowledgeBases -> KnowledgeBases
knowledgeBasesDatabaseId value (KnowledgeBases values) = KnowledgeBases (insertInputField "database_id" (inputJson value) values)

knowledgeBasesEmbeddingModelUuid :: Input String -> KnowledgeBases -> KnowledgeBases
knowledgeBasesEmbeddingModelUuid value (KnowledgeBases values) = KnowledgeBases (insertInputField "embedding_model_uuid" (inputJson value) values)

knowledgeBasesIsPublic :: Input Boolean -> KnowledgeBases -> KnowledgeBases
knowledgeBasesIsPublic value (KnowledgeBases values) = KnowledgeBases (insertInputField "is_public" (inputJson value) values)

knowledgeBasesLastIndexingJob :: Array KnowledgeBasesLastIndexingJob -> KnowledgeBases -> KnowledgeBases
knowledgeBasesLastIndexingJob value (KnowledgeBases values) = KnowledgeBases (insertInputField "last_indexing_job" (arrayExprJson (map knowledgeBasesLastIndexingJobJson value)) values)

knowledgeBasesName :: Input String -> KnowledgeBases -> KnowledgeBases
knowledgeBasesName value (KnowledgeBases values) = KnowledgeBases (insertInputField "name" (inputJson value) values)

knowledgeBasesProjectId :: Input String -> KnowledgeBases -> KnowledgeBases
knowledgeBasesProjectId value (KnowledgeBases values) = KnowledgeBases (insertInputField "project_id" (inputJson value) values)

knowledgeBasesRegion :: Input String -> KnowledgeBases -> KnowledgeBases
knowledgeBasesRegion value (KnowledgeBases values) = KnowledgeBases (insertInputField "region" (inputJson value) values)

knowledgeBasesTags :: Input (Array String) -> KnowledgeBases -> KnowledgeBases
knowledgeBasesTags value (KnowledgeBases values) = KnowledgeBases (insertInputField "tags" (inputJson value) values)

knowledgeBasesUserId :: Input String -> KnowledgeBases -> KnowledgeBases
knowledgeBasesUserId value (KnowledgeBases values) = KnowledgeBases (insertInputField "user_id" (inputJson value) values)

knowledgeBasesJson :: KnowledgeBases -> Json
knowledgeBasesJson (KnowledgeBases values) = inputObjectJson values

newtype KnowledgeBasesLastIndexingJob = KnowledgeBasesLastIndexingJob InputObject

type KnowledgeBasesLastIndexingJobRequired =
  {
  }

knowledgeBasesLastIndexingJobArgs :: KnowledgeBasesLastIndexingJobRequired -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobArgs _ = KnowledgeBasesLastIndexingJob (inputObject
  [
  ])

knowledgeBasesLastIndexingJobCompletedDatasources :: Input Number -> KnowledgeBasesLastIndexingJob -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobCompletedDatasources value (KnowledgeBasesLastIndexingJob values) = KnowledgeBasesLastIndexingJob (insertInputField "completed_datasources" (inputJson value) values)

knowledgeBasesLastIndexingJobDataSourceUuids :: Input (Array String) -> KnowledgeBasesLastIndexingJob -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobDataSourceUuids value (KnowledgeBasesLastIndexingJob values) = KnowledgeBasesLastIndexingJob (insertInputField "data_source_uuids" (inputJson value) values)

knowledgeBasesLastIndexingJobPhase :: Input String -> KnowledgeBasesLastIndexingJob -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobPhase value (KnowledgeBasesLastIndexingJob values) = KnowledgeBasesLastIndexingJob (insertInputField "phase" (inputJson value) values)

knowledgeBasesLastIndexingJobTokens :: Input Number -> KnowledgeBasesLastIndexingJob -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobTokens value (KnowledgeBasesLastIndexingJob values) = KnowledgeBasesLastIndexingJob (insertInputField "tokens" (inputJson value) values)

knowledgeBasesLastIndexingJobTotalDatasources :: Input Number -> KnowledgeBasesLastIndexingJob -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobTotalDatasources value (KnowledgeBasesLastIndexingJob values) = KnowledgeBasesLastIndexingJob (insertInputField "total_datasources" (inputJson value) values)

knowledgeBasesLastIndexingJobUuid :: Input String -> KnowledgeBasesLastIndexingJob -> KnowledgeBasesLastIndexingJob
knowledgeBasesLastIndexingJobUuid value (KnowledgeBasesLastIndexingJob values) = KnowledgeBasesLastIndexingJob (insertInputField "uuid" (inputJson value) values)

knowledgeBasesLastIndexingJobJson :: KnowledgeBasesLastIndexingJob -> Json
knowledgeBasesLastIndexingJobJson (KnowledgeBasesLastIndexingJob values) = inputObjectJson values

newtype Model = Model InputObject

type ModelRequired =
  {
  }

modelArgs :: ModelRequired -> Model
modelArgs _ = Model (inputObject
  [
  ])

modelAgreement :: Array ModelAgreement -> Model -> Model
modelAgreement value (Model values) = Model (insertInputField "agreement" (arrayExprJson (map modelAgreementJson value)) values)

modelInferenceName :: Input String -> Model -> Model
modelInferenceName value (Model values) = Model (insertInputField "inference_name" (inputJson value) values)

modelInferenceVersion :: Input String -> Model -> Model
modelInferenceVersion value (Model values) = Model (insertInputField "inference_version" (inputJson value) values)

modelIsFoundational :: Input Boolean -> Model -> Model
modelIsFoundational value (Model values) = Model (insertInputField "is_foundational" (inputJson value) values)

modelName :: Input String -> Model -> Model
modelName value (Model values) = Model (insertInputField "name" (inputJson value) values)

modelParentUuid :: Input String -> Model -> Model
modelParentUuid value (Model values) = Model (insertInputField "parent_uuid" (inputJson value) values)

modelProvider :: Input String -> Model -> Model
modelProvider value (Model values) = Model (insertInputField "provider" (inputJson value) values)

modelUploadComplete :: Input Boolean -> Model -> Model
modelUploadComplete value (Model values) = Model (insertInputField "upload_complete" (inputJson value) values)

modelUrl :: Input String -> Model -> Model
modelUrl value (Model values) = Model (insertInputField "url" (inputJson value) values)

modelUsecases :: Input (Array String) -> Model -> Model
modelUsecases value (Model values) = Model (insertInputField "usecases" (inputJson value) values)

modelVersions :: Array ModelVersions -> Model -> Model
modelVersions value (Model values) = Model (insertInputField "versions" (arrayExprJson (map modelVersionsJson value)) values)

modelJson :: Model -> Json
modelJson (Model values) = inputObjectJson values

newtype ModelAgreement = ModelAgreement InputObject

type ModelAgreementRequired =
  {
  }

modelAgreementArgs :: ModelAgreementRequired -> ModelAgreement
modelAgreementArgs _ = ModelAgreement (inputObject
  [
  ])

modelAgreementDescription :: Input String -> ModelAgreement -> ModelAgreement
modelAgreementDescription value (ModelAgreement values) = ModelAgreement (insertInputField "description" (inputJson value) values)

modelAgreementName :: Input String -> ModelAgreement -> ModelAgreement
modelAgreementName value (ModelAgreement values) = ModelAgreement (insertInputField "name" (inputJson value) values)

modelAgreementUrl :: Input String -> ModelAgreement -> ModelAgreement
modelAgreementUrl value (ModelAgreement values) = ModelAgreement (insertInputField "url" (inputJson value) values)

modelAgreementUuid :: Input String -> ModelAgreement -> ModelAgreement
modelAgreementUuid value (ModelAgreement values) = ModelAgreement (insertInputField "uuid" (inputJson value) values)

modelAgreementJson :: ModelAgreement -> Json
modelAgreementJson (ModelAgreement values) = inputObjectJson values

newtype ModelVersions = ModelVersions InputObject

type ModelVersionsRequired =
  {
  }

modelVersionsArgs :: ModelVersionsRequired -> ModelVersions
modelVersionsArgs _ = ModelVersions (inputObject
  [
  ])

modelVersionsMajor :: Input Number -> ModelVersions -> ModelVersions
modelVersionsMajor value (ModelVersions values) = ModelVersions (insertInputField "major" (inputJson value) values)

modelVersionsMinor :: Input Number -> ModelVersions -> ModelVersions
modelVersionsMinor value (ModelVersions values) = ModelVersions (insertInputField "minor" (inputJson value) values)

modelVersionsPatch :: Input Number -> ModelVersions -> ModelVersions
modelVersionsPatch value (ModelVersions values) = ModelVersions (insertInputField "patch" (inputJson value) values)

modelVersionsJson :: ModelVersions -> Json
modelVersionsJson (ModelVersions values) = inputObjectJson values

newtype OpenAiApiKey = OpenAiApiKey InputObject

type OpenAiApiKeyRequired =
  {
  }

openAiApiKeyArgs :: OpenAiApiKeyRequired -> OpenAiApiKey
openAiApiKeyArgs _ = OpenAiApiKey (inputObject
  [
  ])

openAiApiKeyCreatedBy :: Input String -> OpenAiApiKey -> OpenAiApiKey
openAiApiKeyCreatedBy value (OpenAiApiKey values) = OpenAiApiKey (insertInputField "created_by" (inputJson value) values)

openAiApiKeyName :: Input String -> OpenAiApiKey -> OpenAiApiKey
openAiApiKeyName value (OpenAiApiKey values) = OpenAiApiKey (insertInputField "name" (inputJson value) values)

openAiApiKeyUuid :: Input String -> OpenAiApiKey -> OpenAiApiKey
openAiApiKeyUuid value (OpenAiApiKey values) = OpenAiApiKey (insertInputField "uuid" (inputJson value) values)

openAiApiKeyJson :: OpenAiApiKey -> Json
openAiApiKeyJson (OpenAiApiKey values) = inputObjectJson values

newtype ParentAgents = ParentAgents InputObject

type ParentAgentsRequired =
  { instruction :: Input String
  , modelUuid :: Input String
  , name :: Input String
  , projectId :: Input String
  , region :: Input String
  }

parentAgentsArgs :: ParentAgentsRequired -> ParentAgents
parentAgentsArgs required = ParentAgents (inputObject
  [ Tuple "instruction" (inputJson required.instruction)
  , Tuple "model_uuid" (inputJson required.modelUuid)
  , Tuple "name" (inputJson required.name)
  , Tuple "project_id" (inputJson required.projectId)
  , Tuple "region" (inputJson required.region)
  ])

parentAgentsAnthropicApiKey :: Array ParentAgentsAnthropicApiKey -> ParentAgents -> ParentAgents
parentAgentsAnthropicApiKey value (ParentAgents values) = ParentAgents (insertInputField "anthropic_api_key" (arrayExprJson (map parentAgentsAnthropicApiKeyJson value)) values)

parentAgentsApiKeyInfos :: Array ParentAgentsApiKeyInfos -> ParentAgents -> ParentAgents
parentAgentsApiKeyInfos value (ParentAgents values) = ParentAgents (insertInputField "api_key_infos" (arrayExprJson (map parentAgentsApiKeyInfosJson value)) values)

parentAgentsApiKeys :: Array ParentAgentsApiKeys -> ParentAgents -> ParentAgents
parentAgentsApiKeys value (ParentAgents values) = ParentAgents (insertInputField "api_keys" (arrayExprJson (map parentAgentsApiKeysJson value)) values)

parentAgentsChatbot :: Array ParentAgentsChatbot -> ParentAgents -> ParentAgents
parentAgentsChatbot value (ParentAgents values) = ParentAgents (insertInputField "chatbot" (arrayExprJson (map parentAgentsChatbotJson value)) values)

parentAgentsChatbotIdentifiers :: Array ParentAgentsChatbotIdentifiers -> ParentAgents -> ParentAgents
parentAgentsChatbotIdentifiers value (ParentAgents values) = ParentAgents (insertInputField "chatbot_identifiers" (arrayExprJson (map parentAgentsChatbotIdentifiersJson value)) values)

parentAgentsDeployment :: Array ParentAgentsDeployment -> ParentAgents -> ParentAgents
parentAgentsDeployment value (ParentAgents values) = ParentAgents (insertInputField "deployment" (arrayExprJson (map parentAgentsDeploymentJson value)) values)

parentAgentsDescription :: Input String -> ParentAgents -> ParentAgents
parentAgentsDescription value (ParentAgents values) = ParentAgents (insertInputField "description" (inputJson value) values)

parentAgentsJson :: ParentAgents -> Json
parentAgentsJson (ParentAgents values) = inputObjectJson values

newtype ParentAgentsAnthropicApiKey = ParentAgentsAnthropicApiKey InputObject

type ParentAgentsAnthropicApiKeyRequired =
  {
  }

parentAgentsAnthropicApiKeyArgs :: ParentAgentsAnthropicApiKeyRequired -> ParentAgentsAnthropicApiKey
parentAgentsAnthropicApiKeyArgs _ = ParentAgentsAnthropicApiKey (inputObject
  [
  ])

parentAgentsAnthropicApiKeyCreatedBy :: Input String -> ParentAgentsAnthropicApiKey -> ParentAgentsAnthropicApiKey
parentAgentsAnthropicApiKeyCreatedBy value (ParentAgentsAnthropicApiKey values) = ParentAgentsAnthropicApiKey (insertInputField "created_by" (inputJson value) values)

parentAgentsAnthropicApiKeyName :: Input String -> ParentAgentsAnthropicApiKey -> ParentAgentsAnthropicApiKey
parentAgentsAnthropicApiKeyName value (ParentAgentsAnthropicApiKey values) = ParentAgentsAnthropicApiKey (insertInputField "name" (inputJson value) values)

parentAgentsAnthropicApiKeyUuid :: Input String -> ParentAgentsAnthropicApiKey -> ParentAgentsAnthropicApiKey
parentAgentsAnthropicApiKeyUuid value (ParentAgentsAnthropicApiKey values) = ParentAgentsAnthropicApiKey (insertInputField "uuid" (inputJson value) values)

parentAgentsAnthropicApiKeyJson :: ParentAgentsAnthropicApiKey -> Json
parentAgentsAnthropicApiKeyJson (ParentAgentsAnthropicApiKey values) = inputObjectJson values

newtype ParentAgentsApiKeyInfos = ParentAgentsApiKeyInfos InputObject

type ParentAgentsApiKeyInfosRequired =
  {
  }

parentAgentsApiKeyInfosArgs :: ParentAgentsApiKeyInfosRequired -> ParentAgentsApiKeyInfos
parentAgentsApiKeyInfosArgs _ = ParentAgentsApiKeyInfos (inputObject
  [
  ])

parentAgentsApiKeyInfosCreatedBy :: Input String -> ParentAgentsApiKeyInfos -> ParentAgentsApiKeyInfos
parentAgentsApiKeyInfosCreatedBy value (ParentAgentsApiKeyInfos values) = ParentAgentsApiKeyInfos (insertInputField "created_by" (inputJson value) values)

parentAgentsApiKeyInfosName :: Input String -> ParentAgentsApiKeyInfos -> ParentAgentsApiKeyInfos
parentAgentsApiKeyInfosName value (ParentAgentsApiKeyInfos values) = ParentAgentsApiKeyInfos (insertInputField "name" (inputJson value) values)

parentAgentsApiKeyInfosSecretKey :: Input String -> ParentAgentsApiKeyInfos -> ParentAgentsApiKeyInfos
parentAgentsApiKeyInfosSecretKey value (ParentAgentsApiKeyInfos values) = ParentAgentsApiKeyInfos (insertInputField "secret_key" (inputJson value) values)

parentAgentsApiKeyInfosUuid :: Input String -> ParentAgentsApiKeyInfos -> ParentAgentsApiKeyInfos
parentAgentsApiKeyInfosUuid value (ParentAgentsApiKeyInfos values) = ParentAgentsApiKeyInfos (insertInputField "uuid" (inputJson value) values)

parentAgentsApiKeyInfosJson :: ParentAgentsApiKeyInfos -> Json
parentAgentsApiKeyInfosJson (ParentAgentsApiKeyInfos values) = inputObjectJson values

newtype ParentAgentsApiKeys = ParentAgentsApiKeys InputObject

type ParentAgentsApiKeysRequired =
  {
  }

parentAgentsApiKeysArgs :: ParentAgentsApiKeysRequired -> ParentAgentsApiKeys
parentAgentsApiKeysArgs _ = ParentAgentsApiKeys (inputObject
  [
  ])

parentAgentsApiKeysApiKey :: Input String -> ParentAgentsApiKeys -> ParentAgentsApiKeys
parentAgentsApiKeysApiKey value (ParentAgentsApiKeys values) = ParentAgentsApiKeys (insertInputField "api_key" (inputJson value) values)

parentAgentsApiKeysJson :: ParentAgentsApiKeys -> Json
parentAgentsApiKeysJson (ParentAgentsApiKeys values) = inputObjectJson values

newtype ParentAgentsChatbot = ParentAgentsChatbot InputObject

type ParentAgentsChatbotRequired =
  {
  }

parentAgentsChatbotArgs :: ParentAgentsChatbotRequired -> ParentAgentsChatbot
parentAgentsChatbotArgs _ = ParentAgentsChatbot (inputObject
  [
  ])

parentAgentsChatbotButtonBackgroundColor :: Input String -> ParentAgentsChatbot -> ParentAgentsChatbot
parentAgentsChatbotButtonBackgroundColor value (ParentAgentsChatbot values) = ParentAgentsChatbot (insertInputField "button_background_color" (inputJson value) values)

parentAgentsChatbotLogo :: Input String -> ParentAgentsChatbot -> ParentAgentsChatbot
parentAgentsChatbotLogo value (ParentAgentsChatbot values) = ParentAgentsChatbot (insertInputField "logo" (inputJson value) values)

parentAgentsChatbotName :: Input String -> ParentAgentsChatbot -> ParentAgentsChatbot
parentAgentsChatbotName value (ParentAgentsChatbot values) = ParentAgentsChatbot (insertInputField "name" (inputJson value) values)

parentAgentsChatbotPrimaryColor :: Input String -> ParentAgentsChatbot -> ParentAgentsChatbot
parentAgentsChatbotPrimaryColor value (ParentAgentsChatbot values) = ParentAgentsChatbot (insertInputField "primary_color" (inputJson value) values)

parentAgentsChatbotSecondaryColor :: Input String -> ParentAgentsChatbot -> ParentAgentsChatbot
parentAgentsChatbotSecondaryColor value (ParentAgentsChatbot values) = ParentAgentsChatbot (insertInputField "secondary_color" (inputJson value) values)

parentAgentsChatbotStartingMessage :: Input String -> ParentAgentsChatbot -> ParentAgentsChatbot
parentAgentsChatbotStartingMessage value (ParentAgentsChatbot values) = ParentAgentsChatbot (insertInputField "starting_message" (inputJson value) values)

parentAgentsChatbotJson :: ParentAgentsChatbot -> Json
parentAgentsChatbotJson (ParentAgentsChatbot values) = inputObjectJson values

newtype ParentAgentsChatbotIdentifiers = ParentAgentsChatbotIdentifiers InputObject

type ParentAgentsChatbotIdentifiersRequired =
  {
  }

parentAgentsChatbotIdentifiersArgs :: ParentAgentsChatbotIdentifiersRequired -> ParentAgentsChatbotIdentifiers
parentAgentsChatbotIdentifiersArgs _ = ParentAgentsChatbotIdentifiers (inputObject
  [
  ])

parentAgentsChatbotIdentifiersJson :: ParentAgentsChatbotIdentifiers -> Json
parentAgentsChatbotIdentifiersJson (ParentAgentsChatbotIdentifiers values) = inputObjectJson values

newtype ParentAgentsDeployment = ParentAgentsDeployment InputObject

type ParentAgentsDeploymentRequired =
  {
  }

parentAgentsDeploymentArgs :: ParentAgentsDeploymentRequired -> ParentAgentsDeployment
parentAgentsDeploymentArgs _ = ParentAgentsDeployment (inputObject
  [
  ])

parentAgentsDeploymentName :: Input String -> ParentAgentsDeployment -> ParentAgentsDeployment
parentAgentsDeploymentName value (ParentAgentsDeployment values) = ParentAgentsDeployment (insertInputField "name" (inputJson value) values)

parentAgentsDeploymentStatus :: Input String -> ParentAgentsDeployment -> ParentAgentsDeployment
parentAgentsDeploymentStatus value (ParentAgentsDeployment values) = ParentAgentsDeployment (insertInputField "status" (inputJson value) values)

parentAgentsDeploymentUrl :: Input String -> ParentAgentsDeployment -> ParentAgentsDeployment
parentAgentsDeploymentUrl value (ParentAgentsDeployment values) = ParentAgentsDeployment (insertInputField "url" (inputJson value) values)

parentAgentsDeploymentUuid :: Input String -> ParentAgentsDeployment -> ParentAgentsDeployment
parentAgentsDeploymentUuid value (ParentAgentsDeployment values) = ParentAgentsDeployment (insertInputField "uuid" (inputJson value) values)

parentAgentsDeploymentVisibility :: Input String -> ParentAgentsDeployment -> ParentAgentsDeployment
parentAgentsDeploymentVisibility value (ParentAgentsDeployment values) = ParentAgentsDeployment (insertInputField "visibility" (inputJson value) values)

parentAgentsDeploymentJson :: ParentAgentsDeployment -> Json
parentAgentsDeploymentJson (ParentAgentsDeployment values) = inputObjectJson values

newtype Template = Template InputObject

type TemplateRequired =
  {
  }

templateArgs :: TemplateRequired -> Template
templateArgs _ = Template (inputObject
  [
  ])

templateDescription :: Input String -> Template -> Template
templateDescription value (Template values) = Template (insertInputField "description" (inputJson value) values)

templateInstruction :: Input String -> Template -> Template
templateInstruction value (Template values) = Template (insertInputField "instruction" (inputJson value) values)

templateK :: Input Number -> Template -> Template
templateK value (Template values) = Template (insertInputField "k" (inputJson value) values)

templateKnowledgeBases :: Array TemplateKnowledgeBases -> Template -> Template
templateKnowledgeBases value (Template values) = Template (insertInputField "knowledge_bases" (arrayExprJson (map templateKnowledgeBasesJson value)) values)

templateMaxTokens :: Input Number -> Template -> Template
templateMaxTokens value (Template values) = Template (insertInputField "max_tokens" (inputJson value) values)

templateModel :: Array TemplateModel -> Template -> Template
templateModel value (Template values) = Template (insertInputField "model" (arrayExprJson (map templateModelJson value)) values)

templateName :: Input String -> Template -> Template
templateName value (Template values) = Template (insertInputField "name" (inputJson value) values)

templateTemperature :: Input Number -> Template -> Template
templateTemperature value (Template values) = Template (insertInputField "temperature" (inputJson value) values)

templateTopP :: Input Number -> Template -> Template
templateTopP value (Template values) = Template (insertInputField "top_p" (inputJson value) values)

templateUuid :: Input String -> Template -> Template
templateUuid value (Template values) = Template (insertInputField "uuid" (inputJson value) values)

templateJson :: Template -> Json
templateJson (Template values) = inputObjectJson values

newtype TemplateKnowledgeBases = TemplateKnowledgeBases InputObject

type TemplateKnowledgeBasesRequired =
  {
  }

templateKnowledgeBasesArgs :: TemplateKnowledgeBasesRequired -> TemplateKnowledgeBases
templateKnowledgeBasesArgs _ = TemplateKnowledgeBases (inputObject
  [
  ])

templateKnowledgeBasesDatabaseId :: Input String -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesDatabaseId value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "database_id" (inputJson value) values)

templateKnowledgeBasesEmbeddingModelUuid :: Input String -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesEmbeddingModelUuid value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "embedding_model_uuid" (inputJson value) values)

templateKnowledgeBasesIsPublic :: Input Boolean -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesIsPublic value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "is_public" (inputJson value) values)

templateKnowledgeBasesLastIndexingJob :: Array TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesLastIndexingJob value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "last_indexing_job" (arrayExprJson (map templateKnowledgeBasesLastIndexingJobJson value)) values)

templateKnowledgeBasesName :: Input String -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesName value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "name" (inputJson value) values)

templateKnowledgeBasesProjectId :: Input String -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesProjectId value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "project_id" (inputJson value) values)

templateKnowledgeBasesRegion :: Input String -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesRegion value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "region" (inputJson value) values)

templateKnowledgeBasesTags :: Input (Array String) -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesTags value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "tags" (inputJson value) values)

templateKnowledgeBasesUserId :: Input String -> TemplateKnowledgeBases -> TemplateKnowledgeBases
templateKnowledgeBasesUserId value (TemplateKnowledgeBases values) = TemplateKnowledgeBases (insertInputField "user_id" (inputJson value) values)

templateKnowledgeBasesJson :: TemplateKnowledgeBases -> Json
templateKnowledgeBasesJson (TemplateKnowledgeBases values) = inputObjectJson values

newtype TemplateKnowledgeBasesLastIndexingJob = TemplateKnowledgeBasesLastIndexingJob InputObject

type TemplateKnowledgeBasesLastIndexingJobRequired =
  {
  }

templateKnowledgeBasesLastIndexingJobArgs :: TemplateKnowledgeBasesLastIndexingJobRequired -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobArgs _ = TemplateKnowledgeBasesLastIndexingJob (inputObject
  [
  ])

templateKnowledgeBasesLastIndexingJobCompletedDatasources :: Input Number -> TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobCompletedDatasources value (TemplateKnowledgeBasesLastIndexingJob values) = TemplateKnowledgeBasesLastIndexingJob (insertInputField "completed_datasources" (inputJson value) values)

templateKnowledgeBasesLastIndexingJobDataSourceUuids :: Input (Array String) -> TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobDataSourceUuids value (TemplateKnowledgeBasesLastIndexingJob values) = TemplateKnowledgeBasesLastIndexingJob (insertInputField "data_source_uuids" (inputJson value) values)

templateKnowledgeBasesLastIndexingJobPhase :: Input String -> TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobPhase value (TemplateKnowledgeBasesLastIndexingJob values) = TemplateKnowledgeBasesLastIndexingJob (insertInputField "phase" (inputJson value) values)

templateKnowledgeBasesLastIndexingJobTokens :: Input Number -> TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobTokens value (TemplateKnowledgeBasesLastIndexingJob values) = TemplateKnowledgeBasesLastIndexingJob (insertInputField "tokens" (inputJson value) values)

templateKnowledgeBasesLastIndexingJobTotalDatasources :: Input Number -> TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobTotalDatasources value (TemplateKnowledgeBasesLastIndexingJob values) = TemplateKnowledgeBasesLastIndexingJob (insertInputField "total_datasources" (inputJson value) values)

templateKnowledgeBasesLastIndexingJobUuid :: Input String -> TemplateKnowledgeBasesLastIndexingJob -> TemplateKnowledgeBasesLastIndexingJob
templateKnowledgeBasesLastIndexingJobUuid value (TemplateKnowledgeBasesLastIndexingJob values) = TemplateKnowledgeBasesLastIndexingJob (insertInputField "uuid" (inputJson value) values)

templateKnowledgeBasesLastIndexingJobJson :: TemplateKnowledgeBasesLastIndexingJob -> Json
templateKnowledgeBasesLastIndexingJobJson (TemplateKnowledgeBasesLastIndexingJob values) = inputObjectJson values

newtype TemplateModel = TemplateModel InputObject

type TemplateModelRequired =
  {
  }

templateModelArgs :: TemplateModelRequired -> TemplateModel
templateModelArgs _ = TemplateModel (inputObject
  [
  ])

templateModelAgreement :: Array TemplateModelAgreement -> TemplateModel -> TemplateModel
templateModelAgreement value (TemplateModel values) = TemplateModel (insertInputField "agreement" (arrayExprJson (map templateModelAgreementJson value)) values)

templateModelInferenceName :: Input String -> TemplateModel -> TemplateModel
templateModelInferenceName value (TemplateModel values) = TemplateModel (insertInputField "inference_name" (inputJson value) values)

templateModelInferenceVersion :: Input String -> TemplateModel -> TemplateModel
templateModelInferenceVersion value (TemplateModel values) = TemplateModel (insertInputField "inference_version" (inputJson value) values)

templateModelIsFoundational :: Input Boolean -> TemplateModel -> TemplateModel
templateModelIsFoundational value (TemplateModel values) = TemplateModel (insertInputField "is_foundational" (inputJson value) values)

templateModelName :: Input String -> TemplateModel -> TemplateModel
templateModelName value (TemplateModel values) = TemplateModel (insertInputField "name" (inputJson value) values)

templateModelParentUuid :: Input String -> TemplateModel -> TemplateModel
templateModelParentUuid value (TemplateModel values) = TemplateModel (insertInputField "parent_uuid" (inputJson value) values)

templateModelProvider :: Input String -> TemplateModel -> TemplateModel
templateModelProvider value (TemplateModel values) = TemplateModel (insertInputField "provider" (inputJson value) values)

templateModelUploadComplete :: Input Boolean -> TemplateModel -> TemplateModel
templateModelUploadComplete value (TemplateModel values) = TemplateModel (insertInputField "upload_complete" (inputJson value) values)

templateModelUrl :: Input String -> TemplateModel -> TemplateModel
templateModelUrl value (TemplateModel values) = TemplateModel (insertInputField "url" (inputJson value) values)

templateModelUsecases :: Input (Array String) -> TemplateModel -> TemplateModel
templateModelUsecases value (TemplateModel values) = TemplateModel (insertInputField "usecases" (inputJson value) values)

templateModelVersions :: Array TemplateModelVersions -> TemplateModel -> TemplateModel
templateModelVersions value (TemplateModel values) = TemplateModel (insertInputField "versions" (arrayExprJson (map templateModelVersionsJson value)) values)

templateModelJson :: TemplateModel -> Json
templateModelJson (TemplateModel values) = inputObjectJson values

newtype TemplateModelAgreement = TemplateModelAgreement InputObject

type TemplateModelAgreementRequired =
  {
  }

templateModelAgreementArgs :: TemplateModelAgreementRequired -> TemplateModelAgreement
templateModelAgreementArgs _ = TemplateModelAgreement (inputObject
  [
  ])

templateModelAgreementDescription :: Input String -> TemplateModelAgreement -> TemplateModelAgreement
templateModelAgreementDescription value (TemplateModelAgreement values) = TemplateModelAgreement (insertInputField "description" (inputJson value) values)

templateModelAgreementName :: Input String -> TemplateModelAgreement -> TemplateModelAgreement
templateModelAgreementName value (TemplateModelAgreement values) = TemplateModelAgreement (insertInputField "name" (inputJson value) values)

templateModelAgreementUrl :: Input String -> TemplateModelAgreement -> TemplateModelAgreement
templateModelAgreementUrl value (TemplateModelAgreement values) = TemplateModelAgreement (insertInputField "url" (inputJson value) values)

templateModelAgreementUuid :: Input String -> TemplateModelAgreement -> TemplateModelAgreement
templateModelAgreementUuid value (TemplateModelAgreement values) = TemplateModelAgreement (insertInputField "uuid" (inputJson value) values)

templateModelAgreementJson :: TemplateModelAgreement -> Json
templateModelAgreementJson (TemplateModelAgreement values) = inputObjectJson values

newtype TemplateModelVersions = TemplateModelVersions InputObject

type TemplateModelVersionsRequired =
  {
  }

templateModelVersionsArgs :: TemplateModelVersionsRequired -> TemplateModelVersions
templateModelVersionsArgs _ = TemplateModelVersions (inputObject
  [
  ])

templateModelVersionsMajor :: Input Number -> TemplateModelVersions -> TemplateModelVersions
templateModelVersionsMajor value (TemplateModelVersions values) = TemplateModelVersions (insertInputField "major" (inputJson value) values)

templateModelVersionsMinor :: Input Number -> TemplateModelVersions -> TemplateModelVersions
templateModelVersionsMinor value (TemplateModelVersions values) = TemplateModelVersions (insertInputField "minor" (inputJson value) values)

templateModelVersionsPatch :: Input Number -> TemplateModelVersions -> TemplateModelVersions
templateModelVersionsPatch value (TemplateModelVersions values) = TemplateModelVersions (insertInputField "patch" (inputJson value) values)

templateModelVersionsJson :: TemplateModelVersions -> Json
templateModelVersionsJson (TemplateModelVersions values) = inputObjectJson values

type Required =
  { instruction :: Input String
  , modelUuid :: Input String
  , name :: Input String
  , projectId :: Input String
  , region :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "instruction" (inputJson required.instruction)
  , Tuple "model_uuid" (inputJson required.modelUuid)
  , Tuple "name" (inputJson required.name)
  , Tuple "project_id" (inputJson required.projectId)
  , Tuple "region" (inputJson required.region)
  ])

agentGuardrail :: Array AgentGuardrail -> Args -> Args
agentGuardrail value (Args values) = Args (insertInputField "agent_guardrail" (arrayExprJson (map agentGuardrailJson value)) values)

anthropicApiKey :: Array AnthropicApiKey -> Args -> Args
anthropicApiKey value (Args values) = Args (insertInputField "anthropic_api_key" (arrayExprJson (map anthropicApiKeyJson value)) values)

anthropicKeyUuid :: Input String -> Args -> Args
anthropicKeyUuid value (Args values) = Args (insertInputField "anthropic_key_uuid" (inputJson value) values)

apiKeyInfos :: Array ApiKeyInfos -> Args -> Args
apiKeyInfos value (Args values) = Args (insertInputField "api_key_infos" (arrayExprJson (map apiKeyInfosJson value)) values)

apiKeys :: Array ApiKeys -> Args -> Args
apiKeys value (Args values) = Args (insertInputField "api_keys" (arrayExprJson (map apiKeysJson value)) values)

chatbot :: Array Chatbot -> Args -> Args
chatbot value (Args values) = Args (insertInputField "chatbot" (arrayExprJson (map chatbotJson value)) values)

chatbotIdentifiers :: Array ChatbotIdentifiers -> Args -> Args
chatbotIdentifiers value (Args values) = Args (insertInputField "chatbot_identifiers" (arrayExprJson (map chatbotIdentifiersJson value)) values)

childAgents :: Array ChildAgents -> Args -> Args
childAgents value (Args values) = Args (insertInputField "child_agents" (arrayExprJson (map childAgentsJson value)) values)

createdAt :: Input String -> Args -> Args
createdAt value (Args values) = Args (insertInputField "created_at" (inputJson value) values)

deployment :: Array Deployment -> Args -> Args
deployment value (Args values) = Args (insertInputField "deployment" (arrayExprJson (map deploymentJson value)) values)

description :: Input String -> Args -> Args
description value (Args values) = Args (insertInputField "description" (inputJson value) values)

functions :: Array Functions -> Args -> Args
functions value (Args values) = Args (insertInputField "functions" (arrayExprJson (map functionsJson value)) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

ifCase :: Input String -> Args -> Args
ifCase value (Args values) = Args (insertInputField "if_case" (inputJson value) values)

k :: Input Number -> Args -> Args
k value (Args values) = Args (insertInputField "k" (inputJson value) values)

knowledgeBaseUuid :: Input (Array String) -> Args -> Args
knowledgeBaseUuid value (Args values) = Args (insertInputField "knowledge_base_uuid" (inputJson value) values)

knowledgeBases :: Array KnowledgeBases -> Args -> Args
knowledgeBases value (Args values) = Args (insertInputField "knowledge_bases" (arrayExprJson (map knowledgeBasesJson value)) values)

maxTokens :: Input Number -> Args -> Args
maxTokens value (Args values) = Args (insertInputField "max_tokens" (inputJson value) values)

model :: Array Model -> Args -> Args
model value (Args values) = Args (insertInputField "model" (arrayExprJson (map modelJson value)) values)

openAiApiKey :: Array OpenAiApiKey -> Args -> Args
openAiApiKey value (Args values) = Args (insertInputField "open_ai_api_key" (arrayExprJson (map openAiApiKeyJson value)) values)

openAiKeyUuid :: Input String -> Args -> Args
openAiKeyUuid value (Args values) = Args (insertInputField "open_ai_key_uuid" (inputJson value) values)

parentAgents :: Array ParentAgents -> Args -> Args
parentAgents value (Args values) = Args (insertInputField "parent_agents" (arrayExprJson (map parentAgentsJson value)) values)

provideCitations :: Input Boolean -> Args -> Args
provideCitations value (Args values) = Args (insertInputField "provide_citations" (inputJson value) values)

retrievalMethod :: Input String -> Args -> Args
retrievalMethod value (Args values) = Args (insertInputField "retrieval_method" (inputJson value) values)

routeCreatedBy :: Input String -> Args -> Args
routeCreatedBy value (Args values) = Args (insertInputField "route_created_by" (inputJson value) values)

routeName :: Input String -> Args -> Args
routeName value (Args values) = Args (insertInputField "route_name" (inputJson value) values)

routeUuid :: Input String -> Args -> Args
routeUuid value (Args values) = Args (insertInputField "route_uuid" (inputJson value) values)

tags :: Input (Array String) -> Args -> Args
tags value (Args values) = Args (insertInputField "tags" (inputJson value) values)

temperature :: Input Number -> Args -> Args
temperature value (Args values) = Args (insertInputField "temperature" (inputJson value) values)

template :: Array Template -> Args -> Args
template value (Args values) = Args (insertInputField "template" (arrayExprJson (map templateJson value)) values)

topP :: Input Number -> Args -> Args
topP value (Args values) = Args (insertInputField "top_p" (inputJson value) values)

url :: Input String -> Args -> Args
url value (Args values) = Args (insertInputField "url" (inputJson value) values)

userId :: Input String -> Args -> Args
userId value (Args values) = Args (insertInputField "user_id" (inputJson value) values)

workspaceUuid :: Input String -> Args -> Args
workspaceUuid value (Args values) = Args (insertInputField "workspace_uuid" (inputJson value) values)

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
