module DigitalOcean.Data.PartnerAttachmentServiceKey
  ( Args
  , Required
  , PartnerAttachmentServiceKey
  , PartnerAttachmentServiceKeyDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data PartnerAttachmentServiceKeyDataSource

type Required =
  { attachmentId :: Input String
  }

newtype Args = Args InputObject

args :: Required -> Args
args required = Args (inputObject
  [ Tuple "attachment_id" (inputJson required.attachmentId)
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type PartnerAttachmentServiceKey =
  { dataSource :: DataSource PartnerAttachmentServiceKeyDataSource
  , attachmentId :: Expr String
  , createdAt :: Expr String
  , id :: Expr String
  , state :: Expr String
  , value :: Expr String
  }

read :: String -> Args -> Infra PartnerAttachmentServiceKey
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_partner_attachment_service_key" logicalName values
  pure
    { dataSource: handle
    , attachmentId: dataSourceAttr handle [ "attachment_id" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , id: dataSourceAttr handle [ "id" ]
    , state: dataSourceAttr handle [ "state" ]
    , value: dataSourceAttr handle [ "value" ]
    }
