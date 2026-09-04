module DigitalOcean.Resource.GradientaiOpenaiApiKey
  ( Args
  , Required
  , GradientaiOpenaiApiKey
  , GradientaiOpenaiApiKeyResource
  , args
  , create
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
  , id
  , model
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data GradientaiOpenaiApiKeyResource

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

type Required =
  { apiKey :: Input String
  , name :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "api_key" (inputJson required.apiKey)
  , Tuple "name" (inputJson required.name)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

model :: Array Model -> Args -> Args
model value (Args values) = Args (insertInputField "model" (arrayExprJson (map modelJson value)) values)

type GradientaiOpenaiApiKey =
  { resource :: Resource GradientaiOpenaiApiKeyResource
  , apiKey :: Expr String
  , createdAt :: Expr String
  , createdBy :: Expr String
  , deletedAt :: Expr String
  , id :: Expr String
  , name :: Expr String
  , updatedAt :: Expr String
  , uuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiOpenaiApiKey
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_openai_api_key" logicalName values
  pure
    { resource: handle
    , apiKey: resourceAttr handle [ "api_key" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , createdBy: resourceAttr handle [ "created_by" ]
    , deletedAt: resourceAttr handle [ "deleted_at" ]
    , id: resourceAttr handle [ "id" ]
    , name: resourceAttr handle [ "name" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , uuid: resourceAttr handle [ "uuid" ]
    }
