module Inframe.Core
  ( Expr
  , Input
  , AnyInput
  , TemplatePart
  , Resource
  , DataSource
  , Provider
  , class Dependable
  , lit
  , computed
  , array
  , object
  , index
  , lookup
  , ifThenElse
  , argument
  , call
  , text
  , interpolate
  , template
  , secretEnv
  , inputJson
  , exprJson
  , arrayExprJson
  , objectExprJson
  , resourceHandle
  , dataSourceHandle
  , providerHandle
  , providerAddress
  , dependencyAddress
  , resourceAttr
  , dataSourceAttr
  ) where

import Prelude

import Data.Argonaut.Core (Json, fromArray, fromObject, fromString)
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

-- | A type-erased input for heterogeneous function argument lists.
-- | Construct one with `argument`; the contained value remains symbolic.
newtype AnyInput = AnyInput Json

-- | A part of a symbolic string template. Construct parts with `text` and
-- | `interpolate`.
data TemplatePart
  = TextPart String
  | InterpolationPart Json

-- | A typed handle to a managed-resource address.
newtype Resource :: Type -> Type
newtype Resource r = Resource String

-- | A typed handle to a data-source address.
newtype DataSource :: Type -> Type
newtype DataSource r = DataSource String

-- | A typed handle to a configured provider (including an optional alias).
newtype Provider :: Type -> Type
newtype Provider p = Provider String

class Dependable h where
  dependencyAddress :: h -> String

instance dependableResource :: Dependable (Resource r) where
  dependencyAddress (Resource address) = address

instance dependableDataSource :: Dependable (DataSource r) where
  dependencyAddress (DataSource address) = address

lit :: forall a. EncodeJson a => a -> Input a
lit = Known <<< encodeJson

computed :: forall a. Expr a -> Input a
computed = Computed

array :: forall a. Array (Input a) -> Input (Array a)
array items = symbolic $ arrayExprJson (map inputJson items)

object :: forall a. Object.Object (Input a) -> Input (Object.Object a)
object fields = symbolic $ objectExprJson (map inputJson fields)

index :: forall a. Input (Array a) -> Input Number -> Input a
index collection key = indexExpression (inputJson collection) (inputJson key)

lookup :: forall a. Input (Object.Object a) -> Input String -> Input a
lookup collection key = indexExpression (inputJson collection) (inputJson key)

ifThenElse :: forall a. Input Boolean -> Input a -> Input a -> Input a
ifThenElse condition whenTrue whenFalse = symbolic $ fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "conditional")
  , Tuple "condition" (inputJson condition)
  , Tuple "when_true" (inputJson whenTrue)
  , Tuple "when_false" (inputJson whenFalse)
  ]

argument :: forall a. Input a -> AnyInput
argument = AnyInput <<< inputJson

call :: forall a. String -> Array AnyInput -> Input a
call name arguments = symbolic $ fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "function")
  , Tuple "name" (fromString name)
  , Tuple "args" (fromArray (map anyInputJson arguments))
  ]

text :: String -> TemplatePart
text = TextPart

interpolate :: forall a. Input a -> TemplatePart
interpolate = InterpolationPart <<< inputJson

template :: Array TemplatePart -> Input String
template parts = symbolic $ fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "template")
  , Tuple "parts" (fromArray (map templatePartJson parts))
  ]

-- | Read a secret from the process environment at plan/apply time. The CLI
-- | passes it to OpenTofu as a sensitive variable and never writes its value.
secretEnv :: String -> Input String
secretEnv name = symbolic $ fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "secret_env")
  , Tuple "name" (fromString name)
  ]

inputJson :: forall a. Input a -> Json
inputJson (Known value) =
  fromObject $ Object.fromFoldable
    [ Tuple "kind" (fromString "literal")
    , Tuple "value" value
    ]
inputJson (Computed (Expr expression)) = expression

exprJson :: forall a. Expr a -> Json
exprJson (Expr expression) = expression

-- | Build an array expression from already encoded child expressions.
arrayExprJson :: Array Json -> Json
arrayExprJson items =
  fromObject $ Object.fromFoldable
    [ Tuple "kind" (fromString "array")
    , Tuple "items" (fromArray items)
    ]

-- | Build an object expression from already encoded child expressions.
objectExprJson :: Object.Object Json -> Json
objectExprJson fields =
  fromObject $ Object.fromFoldable
    [ Tuple "kind" (fromString "object")
    , Tuple "fields" (fromObject fields)
    ]

resourceHandle :: forall r. String -> Resource r
resourceHandle = Resource

dataSourceHandle :: forall r. String -> DataSource r
dataSourceHandle = DataSource

providerHandle :: forall p. String -> Provider p
providerHandle = Provider

providerAddress :: forall p. Provider p -> String
providerAddress (Provider address) = address

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

symbolic :: forall a. Json -> Input a
symbolic = Computed <<< Expr

indexExpression :: forall a. Json -> Json -> Input a
indexExpression collection key = symbolic $ fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "index")
  , Tuple "collection" collection
  , Tuple "key" key
  ]

anyInputJson :: AnyInput -> Json
anyInputJson (AnyInput value) = value

templatePartJson :: TemplatePart -> Json
templatePartJson (TextPart value) = fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "literal")
  , Tuple "value" (fromString value)
  ]
templatePartJson (InterpolationPart expression) = fromObject $ Object.fromFoldable
  [ Tuple "kind" (fromString "interpolation")
  , Tuple "expression" expression
  ]
