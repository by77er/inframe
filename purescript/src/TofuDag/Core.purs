module TofuDag.Core
  ( Expr
  , Input
  , Resource
  , DataSource
  , lit
  , computed
  , inputJson
  , exprJson
  , resourceHandle
  , dataSourceHandle
  , resourceAttr
  , dataSourceAttr
  ) where

import Prelude

import Data.Argonaut.Core (Json, fromObject, fromString)
import Data.Argonaut.Encode (class EncodeJson, encodeJson)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object

-- | A serializable expression whose value is resolved by OpenTofu.
newtype Expr :: Type -> Type
newtype Expr a = Expr Json

-- | A provider input is either known now or represented by a symbolic expression.
data Input :: Type -> Type
data Input a
  = Known Json
  | Computed (Expr a)

-- | A typed handle to a managed-resource address.
newtype Resource :: Type -> Type
newtype Resource r = Resource String

-- | A typed handle to a data-source address.
newtype DataSource :: Type -> Type
newtype DataSource r = DataSource String

lit :: forall a. EncodeJson a => a -> Input a
lit = Known <<< encodeJson

computed :: forall a. Expr a -> Input a
computed = Computed

inputJson :: forall a. Input a -> Json
inputJson (Known value) =
  fromObject $ Object.fromFoldable
    [ Tuple "kind" (fromString "literal")
    , Tuple "value" value
    ]
inputJson (Computed (Expr expression)) = expression

exprJson :: forall a. Expr a -> Json
exprJson (Expr expression) = expression

resourceHandle :: forall r. String -> Resource r
resourceHandle = Resource

dataSourceHandle :: forall r. String -> DataSource r
dataSourceHandle = DataSource

resourceAttr :: forall a r. Resource r -> Array String -> Expr a
resourceAttr (Resource address) path =
  Expr $ reference "resource_attr" address path

dataSourceAttr :: forall a r. DataSource r -> Array String -> Expr a
dataSourceAttr (DataSource address) path =
  Expr $ reference "data_source_attr" address path

reference :: String -> String -> Array String -> Json
reference kind address path =
  fromObject $ Object.fromFoldable
    [ Tuple "kind" (fromString kind)
    , Tuple "address" (fromString address)
    , Tuple "path" (encodeJson path)
    ]
