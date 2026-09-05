module Inframe.Internal.Core
  ( Expr
  , Input
  , ExprNode(..)
  , UnsafeArgument
  , TemplatePart(..)
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
  , attribute
  , splat
  , ifThenElse
  , unsafeArgument
  , unsafeCall
  , text
  , interpolate
  , template
  , secretEnv
  , inputNode
  , exprNode
  , arrayExprNode
  , objectExprNode
  , resourceHandle
  , dataSourceHandle
  , providerHandle
  , providerAddress
  , dependencyAddress
  , resourceAttr
  , dataSourceAttr
  ) where

import Prelude

import Data.Argonaut.Core (Json)
import Data.Argonaut.Encode (class EncodeJson, encodeJson)
import Foreign.Object as Object

-- | The language-native expression representation. Graph IR tags are assigned
-- | only by the encoder in `Inframe.Json` at the serialization boundary.
data ExprNode
  = Literal Json
  | ResourceAttribute String (Array String)
  | DataSourceAttribute String (Array String)
  | ArrayExpression (Array ExprNode)
  | ObjectExpression (Object.Object ExprNode)
  | IndexExpression ExprNode ExprNode
  -- | The attribute `name` of a computed value, `of.name`, for anything that is
  -- | not a plain reference (those carry attributes in their path).
  | AttributeExpression ExprNode String
  -- | The full splat `of[*]`.
  | SplatExpression ExprNode
  | ConditionalExpression ExprNode ExprNode ExprNode
  | FunctionExpression String (Array ExprNode)
  | TemplateExpression (Array TemplatePart)
  | SecretEnvironment String

-- | A serializable expression whose value is resolved by OpenTofu.
newtype Expr :: Type -> Type
newtype Expr a = Expr ExprNode

-- | A provider input is either known now or represented by a symbolic expression.
data Input :: Type -> Type
data Input a
  = Known Json
  | Computed (Expr a)

-- | A type-erased argument accepted only by the explicitly unsafe function API.
newtype UnsafeArgument = UnsafeArgument ExprNode

-- | A part of a symbolic string template. Construct parts with `text` and
-- | `interpolate`.
data TemplatePart
  = TextPart String
  | InterpolationPart ExprNode

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
array items = symbolic $ ArrayExpression (map inputNode items)

object :: forall a. Object.Object (Input a) -> Input (Object.Object a)
object fields = symbolic $ ObjectExpression (map inputNode fields)

index :: forall a. Input (Array a) -> Input Number -> Input a
index collection key = symbolic $ IndexExpression (inputNode collection) (inputNode key)

lookup :: forall a. Input (Object.Object a) -> Input String -> Input a
lookup collection key = symbolic $ IndexExpression (inputNode collection) (inputNode key)

-- | The attribute `name` of a symbolic value, `instance.network_interface[1].network_ip`
-- | for `attribute (index interfaces (lit 1.0)) "network_ip"`. On a plain handle
-- | attribute the reference's path is extended instead. The result type is the
-- | caller's, like `unsafeCall`.
attribute :: forall a b. Input a -> String -> Input b
attribute value name = symbolic case inputNode value of
  ResourceAttribute address path -> ResourceAttribute address (path <> [ name ])
  DataSourceAttribute address path -> DataSourceAttribute address (path <> [ name ])
  node -> AttributeExpression node name

-- | The full splat `items[*]`: attributes taken from it with `attribute` are
-- | taken from every element, so `attribute (splat interfaces) "network_ip"` is
-- | the list of every interface's IP.
splat :: forall a. Input (Array a) -> Input (Array a)
splat items = symbolic $ SplatExpression (inputNode items)

ifThenElse :: forall a. Input Boolean -> Input a -> Input a -> Input a
ifThenElse condition whenTrue whenFalse = symbolic $
  ConditionalExpression (inputNode condition) (inputNode whenTrue) (inputNode whenFalse)

unsafeArgument :: forall a. Input a -> UnsafeArgument
unsafeArgument = UnsafeArgument <<< inputNode

-- | Call an OpenTofu function without a statically checked signature. The
-- | caller chooses the result type, so prefer typed combinators when available.
unsafeCall :: forall a. String -> Array UnsafeArgument -> Input a
unsafeCall name arguments = symbolic $ FunctionExpression name (map unsafeArgumentNode arguments)

text :: String -> TemplatePart
text = TextPart

interpolate :: forall a. Input a -> TemplatePart
interpolate = InterpolationPart <<< inputNode

template :: Array TemplatePart -> Input String
template = symbolic <<< TemplateExpression

-- | Read a secret from the process environment at plan/apply time. The CLI
-- | passes it to OpenTofu as a sensitive variable and never writes its value.
secretEnv :: String -> Input String
secretEnv = symbolic <<< SecretEnvironment

inputNode :: forall a. Input a -> ExprNode
inputNode (Known value) = Literal value
inputNode (Computed expression) = exprNode expression

exprNode :: forall a. Expr a -> ExprNode
exprNode (Expr expression) = expression

arrayExprNode :: Array ExprNode -> ExprNode
arrayExprNode = ArrayExpression

objectExprNode :: Object.Object ExprNode -> ExprNode
objectExprNode = ObjectExpression

resourceHandle :: forall r. String -> Resource r
resourceHandle = Resource

dataSourceHandle :: forall r. String -> DataSource r
dataSourceHandle = DataSource

providerHandle :: forall p. String -> Provider p
providerHandle = Provider

providerAddress :: forall p. Provider p -> String
providerAddress (Provider address) = address

resourceAttr :: forall a r. Resource r -> Array String -> Expr a
resourceAttr (Resource address) path = Expr (ResourceAttribute address path)

dataSourceAttr :: forall a r. DataSource r -> Array String -> Expr a
dataSourceAttr (DataSource address) path = Expr (DataSourceAttribute address path)

symbolic :: forall a. ExprNode -> Input a
symbolic = Computed <<< Expr

unsafeArgumentNode :: UnsafeArgument -> ExprNode
unsafeArgumentNode (UnsafeArgument value) = value
