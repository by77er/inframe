module DigitalOcean.Resource.GradientaiFunction
  ( Args
  , Required
  , GradientaiFunction
  , GradientaiFunctionResource
  , args
  , create
  , faasName
  , id
  , outputSchema
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data GradientaiFunctionResource

type Required =
  { agentId :: Input String
  , description :: Input String
  , faasNamespace :: Input String
  , functionName :: Input String
  , inputSchema :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "agent_id" (inputJson required.agentId)
  , Tuple "description" (inputJson required.description)
  , Tuple "faas_namespace" (inputJson required.faasNamespace)
  , Tuple "function_name" (inputJson required.functionName)
  , Tuple "input_schema" (inputJson required.inputSchema)
  ])

faasName :: Input String -> Args -> Args
faasName value (Args values) = Args (insertInputField "faas_name" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

outputSchema :: Input String -> Args -> Args
outputSchema value (Args values) = Args (insertInputField "output_schema" (inputJson value) values)

type GradientaiFunction =
  { resource :: Resource GradientaiFunctionResource
  , agentId :: Expr String
  , description :: Expr String
  , faasName :: Expr String
  , faasNamespace :: Expr String
  , functionName :: Expr String
  , functionUuid :: Expr String
  , id :: Expr String
  , inputSchema :: Expr String
  , outputSchema :: Expr String
  }

create :: String -> Args -> Infra GradientaiFunction
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_function" logicalName values
  pure
    { resource: handle
    , agentId: resourceAttr handle [ "agent_id" ]
    , description: resourceAttr handle [ "description" ]
    , faasName: resourceAttr handle [ "faas_name" ]
    , faasNamespace: resourceAttr handle [ "faas_namespace" ]
    , functionName: resourceAttr handle [ "function_name" ]
    , functionUuid: resourceAttr handle [ "function_uuid" ]
    , id: resourceAttr handle [ "id" ]
    , inputSchema: resourceAttr handle [ "input_schema" ]
    , outputSchema: resourceAttr handle [ "output_schema" ]
    }
