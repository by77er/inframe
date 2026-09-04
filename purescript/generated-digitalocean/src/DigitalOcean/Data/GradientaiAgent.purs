module DigitalOcean.Data.GradientaiAgent
  ( Args
  , Required
  , GradientaiAgent
  , GradientaiAgentDataSource
  , args
  , read
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
  , chatbotIdentifiersChatbotId
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
  , openAiApiKeyApiKey
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

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, DataSource, dataSourceAttr)

data GradientaiAgentDataSource

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

chatbotIdentifiersChatbotId :: Input String -> ChatbotIdentifiers -> ChatbotIdentifiers
chatbotIdentifiersChatbotId value (ChatbotIdentifiers values) = ChatbotIdentifiers (insertInputField "chatbot_id" (inputJson value) values)

chatbotIdentifiersJson :: ChatbotIdentifiers -> Json
chatbotIdentifiersJson (ChatbotIdentifiers values) = inputObjectJson values

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

openAiApiKeyApiKey :: Input String -> OpenAiApiKey -> OpenAiApiKey
openAiApiKeyApiKey value (OpenAiApiKey values) = OpenAiApiKey (insertInputField "api_key" (inputJson value) values)

openAiApiKeyJson :: OpenAiApiKey -> Json
openAiApiKeyJson (OpenAiApiKey values) = inputObjectJson values

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
  { agentId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "agent_id" (inputJson required.agentId)
  ])

agentGuardrail :: Array AgentGuardrail -> Args -> Args
agentGuardrail value (Args values) = Args (insertInputField "agent_guardrail" (arrayExprJson (map agentGuardrailJson value)) values)

anthropicApiKey :: Array AnthropicApiKey -> Args -> Args
anthropicApiKey value (Args values) = Args (insertInputField "anthropic_api_key" (arrayExprJson (map anthropicApiKeyJson value)) values)

apiKeyInfos :: Array ApiKeyInfos -> Args -> Args
apiKeyInfos value (Args values) = Args (insertInputField "api_key_infos" (arrayExprJson (map apiKeyInfosJson value)) values)

apiKeys :: Array ApiKeys -> Args -> Args
apiKeys value (Args values) = Args (insertInputField "api_keys" (arrayExprJson (map apiKeysJson value)) values)

chatbot :: Array Chatbot -> Args -> Args
chatbot value (Args values) = Args (insertInputField "chatbot" (arrayExprJson (map chatbotJson value)) values)

chatbotIdentifiers :: Array ChatbotIdentifiers -> Args -> Args
chatbotIdentifiers value (Args values) = Args (insertInputField "chatbot_identifiers" (arrayExprJson (map chatbotIdentifiersJson value)) values)

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

knowledgeBases :: Array KnowledgeBases -> Args -> Args
knowledgeBases value (Args values) = Args (insertInputField "knowledge_bases" (arrayExprJson (map knowledgeBasesJson value)) values)

maxTokens :: Input Number -> Args -> Args
maxTokens value (Args values) = Args (insertInputField "max_tokens" (inputJson value) values)

model :: Array Model -> Args -> Args
model value (Args values) = Args (insertInputField "model" (arrayExprJson (map modelJson value)) values)

openAiApiKey :: Array OpenAiApiKey -> Args -> Args
openAiApiKey value (Args values) = Args (insertInputField "open_ai_api_key" (arrayExprJson (map openAiApiKeyJson value)) values)

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
