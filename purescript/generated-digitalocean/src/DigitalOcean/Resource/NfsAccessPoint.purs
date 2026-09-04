module DigitalOcean.Resource.NfsAccessPoint
  ( Args
  , Required
  , NfsAccessPoint
  , NfsAccessPointResource
  , args
  , create
  , AccessPolicy
  , AccessPolicyRequired
  , accessPolicyArgs
  , accessPolicyAnongid
  , accessPolicyAnonuid
  , accessPolicyIdentityEnforcementEnabled
  , accessPolicyProtocols
  , accessPolicySquashConfig
  , id
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data NfsAccessPointResource

newtype AccessPolicy = AccessPolicy InputObject

type AccessPolicyRequired =
  {
  }

accessPolicyArgs :: AccessPolicyRequired -> AccessPolicy
accessPolicyArgs _ = AccessPolicy (inputObject
  [
  ])

accessPolicyAnongid :: Input Number -> AccessPolicy -> AccessPolicy
accessPolicyAnongid value (AccessPolicy values) = AccessPolicy (insertInputField "anongid" (inputJson value) values)

accessPolicyAnonuid :: Input Number -> AccessPolicy -> AccessPolicy
accessPolicyAnonuid value (AccessPolicy values) = AccessPolicy (insertInputField "anonuid" (inputJson value) values)

accessPolicyIdentityEnforcementEnabled :: Input Boolean -> AccessPolicy -> AccessPolicy
accessPolicyIdentityEnforcementEnabled value (AccessPolicy values) = AccessPolicy (insertInputField "identity_enforcement_enabled" (inputJson value) values)

accessPolicyProtocols :: Input (Array String) -> AccessPolicy -> AccessPolicy
accessPolicyProtocols value (AccessPolicy values) = AccessPolicy (insertInputField "protocols" (inputJson value) values)

accessPolicySquashConfig :: Input String -> AccessPolicy -> AccessPolicy
accessPolicySquashConfig value (AccessPolicy values) = AccessPolicy (insertInputField "squash_config" (inputJson value) values)

accessPolicyJson :: AccessPolicy -> Json
accessPolicyJson (AccessPolicy values) = inputObjectJson values

type Required =
  { accessPolicy :: Array AccessPolicy
  , name :: Input String
  , path :: Input String
  , shareId :: Input String
  , vpcId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "access_policy" (arrayExprJson (map accessPolicyJson required.accessPolicy))
  , Tuple "name" (inputJson required.name)
  , Tuple "path" (inputJson required.path)
  , Tuple "share_id" (inputJson required.shareId)
  , Tuple "vpc_id" (inputJson required.vpcId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type NfsAccessPoint =
  { resource :: Resource NfsAccessPointResource
  , createdAt :: Expr String
  , id :: Expr String
  , isDefault :: Expr Boolean
  , name :: Expr String
  , path :: Expr String
  , shareId :: Expr String
  , status :: Expr String
  , updatedAt :: Expr String
  , vpcId :: Expr String
  }

create :: String -> Args -> Infra NfsAccessPoint
create logicalName (Args values) = do
  handle <- addResource "digitalocean_nfs_access_point" logicalName values
  pure
    { resource: handle
    , createdAt: resourceAttr handle [ "created_at" ]
    , id: resourceAttr handle [ "id" ]
    , isDefault: resourceAttr handle [ "is_default" ]
    , name: resourceAttr handle [ "name" ]
    , path: resourceAttr handle [ "path" ]
    , shareId: resourceAttr handle [ "share_id" ]
    , status: resourceAttr handle [ "status" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , vpcId: resourceAttr handle [ "vpc_id" ]
    }
