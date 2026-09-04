module DigitalOcean.Resource.GradientaiAgentKnowledgeBaseAttachment
  ( Args
  , Required
  , GradientaiAgentKnowledgeBaseAttachment
  , GradientaiAgentKnowledgeBaseAttachmentResource
  , args
  , create
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, Resource, resourceAttr)

data GradientaiAgentKnowledgeBaseAttachmentResource

type Required =
  { agentUuid :: Input String
  , knowledgeBaseUuid :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "agent_uuid" (inputJson required.agentUuid)
  , Tuple "knowledge_base_uuid" (inputJson required.knowledgeBaseUuid)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type GradientaiAgentKnowledgeBaseAttachment =
  { resource :: Resource GradientaiAgentKnowledgeBaseAttachmentResource
  , agentUuid :: Expr String
  , id :: Expr String
  , knowledgeBaseUuid :: Expr String
  }

create :: String -> Args -> Infra GradientaiAgentKnowledgeBaseAttachment
create logicalName (Args values) = do
  handle <- addResource "digitalocean_gradientai_agent_knowledge_base_attachment" logicalName values
  pure
    { resource: handle
    , agentUuid: resourceAttr handle [ "agent_uuid" ]
    , id: resourceAttr handle [ "id" ]
    , knowledgeBaseUuid: resourceAttr handle [ "knowledge_base_uuid" ]
    }
