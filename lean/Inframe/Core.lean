import Inframe.Identifier
import Inframe.Value

/-!
# Expression algebra

`ExprNode` is the language-native expression tree. Graph IR wire tags such as `resource_attr`
are assigned only by the encoder in `Inframe.Json`. Typed wrappers (`Expr α`, `Input α`) carry
a phantom result type; the only ways to build an `Expr` whose phantom type is chosen freely are
the generated provider adapters and the explicitly unsafe `unsafeCall`.
-/

namespace Inframe

mutual
  inductive ExprNode where
    | literal (value : Value)
    | resourceAttribute (address : Address) (path : List String)
    | dataSourceAttribute (address : Address) (path : List String)
    | array (items : List ExprNode)
    | object (fields : List (String × ExprNode))
    | index (collection : ExprNode) (key : ExprNode)
    | conditional (condition : ExprNode) (whenTrue : ExprNode) (whenFalse : ExprNode)
    | function (name : String) (args : List ExprNode)
    | template (parts : List TemplatePart)
    | secretEnvironment (name : String)
  /-- A part of a symbolic string template. Construct parts with `text` and `interpolate`. -/
  inductive TemplatePart where
    | text (value : String)
    | interpolation (expression : ExprNode)
end

namespace ExprNode

mutual
  def beq : ExprNode → ExprNode → Bool
    | .literal a, .literal b => a == b
    | .resourceAttribute a p, .resourceAttribute b q => a == b && p == q
    | .dataSourceAttribute a p, .dataSourceAttribute b q => a == b && p == q
    | .array a, .array b => beqList a b
    | .object a, .object b => beqFields a b
    | .index c k, .index d l => beq c d && beq k l
    | .conditional c t e, .conditional d u f => beq c d && beq t u && beq e f
    | .function n a, .function m b => n == m && beqList a b
    | .template a, .template b => beqParts a b
    | .secretEnvironment a, .secretEnvironment b => a == b
    | _, _ => false
  termination_by structural x => x
  def beqList : List ExprNode → List ExprNode → Bool
    | [], [] => true
    | a :: as, b :: bs => beq a b && beqList as bs
    | _, _ => false
  termination_by structural x => x
  def beqFields : List (String × ExprNode) → List (String × ExprNode) → Bool
    | [], [] => true
    | (ka, va) :: as, (kb, vb) :: bs => ka == kb && beq va vb && beqFields as bs
    | _, _ => false
  termination_by structural x => x
  def beqParts : List TemplatePart → List TemplatePart → Bool
    | [], [] => true
    | .text a :: as, .text b :: bs => a == b && beqParts as bs
    | .interpolation a :: as, .interpolation b :: bs => beq a b && beqParts as bs
    | _, _ => false
  termination_by structural x => x
end

instance : BEq ExprNode := ⟨beq⟩
instance : BEq TemplatePart := ⟨fun a b => beqParts [a] [b]⟩

def renderReference (address : Address) (path : List String) : String :=
  ".".intercalate (address.toString :: path)

mutual
  /-- A human-readable rendering in OpenTofu-like notation, used by `Repr` and policy reports. -/
  def render : ExprNode → String
    | .literal value => value.render
    | .resourceAttribute address path => renderReference address path
    | .dataSourceAttribute address path => renderReference address path
    | .array items => "[" ++ ", ".intercalate (renderList items) ++ "]"
    | .object fields => "{" ++ ", ".intercalate (renderFields fields) ++ "}"
    | .index collection key => render collection ++ "[" ++ render key ++ "]"
    | .conditional condition whenTrue whenFalse =>
        "(" ++ render condition ++ " ? " ++ render whenTrue ++ " : " ++ render whenFalse ++ ")"
    | .function name args => name ++ "(" ++ ", ".intercalate (renderList args) ++ ")"
    | .template parts => "\"" ++ String.join (renderParts parts) ++ "\""
    | .secretEnvironment name => "secretEnv(\"" ++ name ++ "\")"
  termination_by structural x => x
  def renderList : List ExprNode → List String
    | [] => []
    | item :: rest => render item :: renderList rest
  termination_by structural x => x
  def renderFields : List (String × ExprNode) → List String
    | [] => []
    | (key, value) :: rest => (key ++ ": " ++ render value) :: renderFields rest
  termination_by structural x => x
  def renderParts : List TemplatePart → List String
    | [] => []
    | .text value :: rest => value :: renderParts rest
    | .interpolation expression :: rest => ("${" ++ render expression ++ "}") :: renderParts rest
  termination_by structural x => x
end

instance : ToString ExprNode := ⟨render⟩
instance : Repr ExprNode := ⟨fun expression _ => Std.Format.text expression.render⟩
instance : Repr TemplatePart := ⟨fun part _ => Std.Format.text (String.join (renderParts [part]))⟩

/-- The address a reference expression points at, if it is a direct attribute reference. -/
def referencedAddress? : ExprNode → Option Address
  | .resourceAttribute address _ => some address
  | .dataSourceAttribute address _ => some address
  | _ => none

/-- Whether the expression is a direct reference to `attribute` of `address`. -/
def refersTo (expression : ExprNode) (address : Address) (path : List String) : Bool :=
  match expression with
  | .resourceAttribute a p => a == address && p == path
  | .dataSourceAttribute a p => a == address && p == path
  | _ => false

/-- The literal value if the expression is known while the graph is constructed. -/
def literal? : ExprNode → Option Value
  | .literal value => some value
  | _ => none

end ExprNode

/-- A serializable expression whose value is resolved by OpenTofu. -/
structure Expr (α : Type) where
  node : ExprNode

/-- A provider input is either known now or represented by a symbolic expression. -/
inductive Input (α : Type) where
  | known (value : Value)
  | computed (expression : Expr α)

/-- A type-erased argument accepted only by the explicitly unsafe function API. -/
structure UnsafeArgument where
  node : ExprNode

/-- A typed handle to a managed-resource address. -/
structure Resource (r : Type) where
  address : Address

/-- A typed handle to a data-source address. -/
structure DataSource (r : Type) where
  address : Address

/-- A typed handle to a configured provider (including an optional alias). -/
structure Provider (p : Type) where
  address : String

/-- Handles that can be named in `dependsOn`. -/
class Dependable (h : Type) where
  dependencyAddress : h → Address

instance : Dependable (Resource r) := ⟨Resource.address⟩
instance : Dependable (DataSource r) := ⟨DataSource.address⟩

/-- Embed a value that is known while the graph is constructed. -/
def lit [ToValue α] (value : α) : Input α :=
  .known (toValue value)

/-- Use a symbolic expression as an input. `Expr α` also coerces to `Input α` implicitly. -/
def computed (expression : Expr α) : Input α :=
  .computed expression

instance : Coe (Expr α) (Input α) := ⟨computed⟩

def inputNode : Input α → ExprNode
  | .known value => .literal value
  | .computed expression => expression.node

def exprNode (expression : Expr α) : ExprNode :=
  expression.node

private def symbolic (node : ExprNode) : Input α :=
  .computed ⟨node⟩

/-- A collection whose length is known now but whose elements may be symbolic. -/
def array (items : List (Input α)) : Input (List α) :=
  symbolic (.array (items.map inputNode))

/-- An object whose keys are known now but whose values may be symbolic. -/
def object (fields : List (String × Input α)) : Input (Map α) :=
  symbolic (.object (fields.map fun (key, value) => (key, inputNode value)))

def index (collection : Input (List α)) (key : Input Number) : Input α :=
  symbolic (.index (inputNode collection) (inputNode key))

def lookup (collection : Input (Map α)) (key : Input String) : Input α :=
  symbolic (.index (inputNode collection) (inputNode key))

def ifThenElse (condition : Input Bool) (whenTrue whenFalse : Input α) : Input α :=
  symbolic (.conditional (inputNode condition) (inputNode whenTrue) (inputNode whenFalse))

def unsafeArgument (value : Input α) : UnsafeArgument :=
  ⟨inputNode value⟩

/-- Call an OpenTofu function without a statically checked signature. The caller chooses the
result type, so prefer typed combinators when available. The function name is validated at
compile time. -/
def unsafeCall (name : String) (args : List UnsafeArgument)
    (_valid : validIdentifier name = true := by decide) : Input α :=
  symbolic (.function name (args.map UnsafeArgument.node))

def text (value : String) : TemplatePart :=
  .text value

def interpolate (value : Input α) : TemplatePart :=
  .interpolation (inputNode value)

def template (parts : List TemplatePart) : Input String :=
  symbolic (.template parts)

/-- Read a secret from the process environment at plan/apply time. The CLI passes it to
OpenTofu as a sensitive variable and never writes its value. The variable name is validated
at compile time. -/
def secretEnv (name : String) (_valid : validEnvironmentName name = true := by decide) :
    Input String :=
  symbolic (.secretEnvironment name)

def resourceHandle (address : Address) : Resource r := ⟨address⟩
def dataSourceHandle (address : Address) : DataSource r := ⟨address⟩
def providerHandle (address : String) : Provider p := ⟨address⟩
def providerAddress (provider : Provider p) : String := provider.address

def resourceAttr (handle : Resource r) (path : List String) : Expr α :=
  ⟨.resourceAttribute handle.address path⟩

def dataSourceAttr (handle : DataSource r) (path : List String) : Expr α :=
  ⟨.dataSourceAttribute handle.address path⟩

/-- Traverse further into a symbolic value, for example an element of a nested block. The
result type is chosen by the caller, so this is an escape hatch like `unsafeCall`. -/
def unsafeTraverse (expression : Expr α) (step : String)
    (_valid : validIdentifier step = true := by decide) : Expr β :=
  match expression.node with
  | .resourceAttribute address path => ⟨.resourceAttribute address (path ++ [step])⟩
  | .dataSourceAttribute address path => ⟨.dataSourceAttribute address (path ++ [step])⟩
  | node => ⟨.index node (.literal (.string step))⟩

end Inframe
