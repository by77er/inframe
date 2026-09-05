import Inframe.Identifier
import Inframe.Value

/-!
# Expression algebra

`ExprNode` is the language-native expression tree. Graph IR wire tags such as `resource_attr`
are assigned only by the encoder in `Inframe.Json`. The typed wrapper `Input α` carries a
phantom result type; the only ways to build an input whose phantom type is chosen freely are
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

/-- A provider input: either a value known while the graph is built, or a symbolic
expression that OpenTofu resolves. Handle attributes are symbolic inputs; literals coerce
(`region := "nyc3"`, `nodeCount := 1`), so `lit` is only needed in polymorphic positions. -/
inductive Input (α : Type) where
  | known (value : Value)
  | symbolic (node : ExprNode)

/-- A type-erased argument accepted only by the explicitly unsafe function API. -/
structure UnsafeArgument where
  node : ExprNode

/-- A typed handle to a managed resource. It keeps the validated identifiers it was created
with, so combinators can derive further names (an assignment, an attachment) from a handle
without re-validating strings at run time. -/
structure Resource (r : Type) where
  resourceType : Identifier
  name : Identifier

/-- A typed handle to a data source. -/
structure DataSource (r : Type) where
  dataSourceType : Identifier
  name : Identifier

def Resource.address (handle : Resource r) : Address :=
  .resource handle.resourceType.raw handle.name.raw

def DataSource.address (handle : DataSource r) : Address :=
  .dataSource handle.dataSourceType.raw handle.name.raw

/-- A typed handle to a configured provider (including an optional alias). -/
structure Provider (p : Type) where
  address : String

/-- Anything that can be named in `dependsOn` or `moved`: raw handles and generated handle
records alike. -/
class Dependable (h : Type) where
  dependencyAddress : h → Address

/-- Handles of managed resources (not data sources), as required by `replaceTriggeredBy`. -/
class Managed (h : Type) where
  resourceAddress : h → Address

instance : Dependable (Resource r) := ⟨Resource.address⟩
instance : Dependable (DataSource r) := ⟨DataSource.address⟩
instance : Managed (Resource r) := ⟨Resource.address⟩

/-- Embed a value that is known while the graph is constructed. -/
def lit [ToValue α] (value : α) : Input α :=
  .known (toValue value)

/-- Known values coerce to inputs, so provider arguments can be written as plain literals. -/
instance [ToValue α] : Coe α (Input α) := ⟨lit⟩

/-- Any typed input is acceptable where a provider takes a `dynamic` value. -/
instance : CoeOut (Input α) (Input Value) :=
  ⟨fun | .known value => .known value | .symbolic node => .symbolic node⟩
instance : OfNat (Input Number) n := ⟨lit (OfNat.ofNat n)⟩
instance : OfScientific (Input Number) := ⟨fun m e d => lit (OfScientific.ofScientific m e d)⟩

def inputNode : Input α → ExprNode
  | .known value => .literal value
  | .symbolic node => node

/-- Either an input or a plain value that can become one. Combinators whose parameter would
otherwise be a bare `Input ?α` (where coercions cannot fire) take this instead, so
`output "ip" web.ipv4Address` works for a decoded `String` as well as for a symbolic input. -/
class IntoInput (v : Type) (α : outParam Type) where
  toInput : v → Input α

instance : IntoInput (Input α) α := ⟨id⟩
instance [ToValue α] : IntoInput α α := ⟨lit⟩

export IntoInput (toInput)

/-- Marshal state straight back into inputs: values become known literals and absent optional
attributes become an OpenTofu `null`. `Attributes.ofValue (f := Input)` therefore turns a
`tofu show -json` object into a handle-shaped record of literal inputs. -/
instance : Marshal Input Resolved where
  required object name :=
    match object.field? name with
    | some .null | none => throw s!"attribute `{name}` is null or missing"
    | some value => pure (.known value)
  optional object name :=
    match object.field? name with
    | some .null | none => pure (.known .null)
    | some value => pure (.known value)

/-- Inputs are compared by the expression they denote. -/
instance : BEq (Input α) := ⟨fun left right => inputNode left == inputNode right⟩

/-- The literal value, if the input is known now. -/
def Input.known? : Input α → Option Value
  | .known value => some value
  | .symbolic _ => none

/-- A collection whose length is known now but whose elements may be symbolic. -/
def array (items : List (Input α)) : Input (List α) :=
  .symbolic (.array (items.map inputNode))

/-- An object whose keys are known now but whose values may be symbolic. -/
def object (fields : List (String × Input α)) : Input (Map α) :=
  .symbolic (.object (fields.map fun (key, value) => (key, inputNode value)))

def index (collection : Input (List α)) (key : Input Number) : Input α :=
  .symbolic (.index (inputNode collection) (inputNode key))

def lookup (collection : Input (Map α)) (key : Input String) : Input α :=
  .symbolic (.index (inputNode collection) (inputNode key))

/-- `xs[i]` on a symbolic list and `m[k]` on a symbolic map, with a known or symbolic index. -/
instance : GetElem (Input (List α)) (Input Number) (Input α) (fun _ _ => True) :=
  ⟨fun collection key _ => index collection key⟩
instance : GetElem (Input (List α)) Nat (Input α) (fun _ _ => True) :=
  ⟨fun collection key _ => index collection (lit (Lean.JsonNumber.fromNat key))⟩
instance : GetElem (Input (Map α)) (Input String) (Input α) (fun _ _ => True) :=
  ⟨fun collection key _ => lookup collection key⟩
instance : GetElem (Input (Map α)) String (Input α) (fun _ _ => True) :=
  ⟨fun collection key _ => lookup collection (lit key)⟩

/-- Traversing a `dynamic` value yields another `dynamic` value. -/
instance : GetElem (Input Value) String (Input Value) (fun _ _ => True) :=
  ⟨fun collection key _ => .symbolic (.index (inputNode collection) (.literal (.string key)))⟩
instance : GetElem (Input Value) Nat (Input Value) (fun _ _ => True) :=
  ⟨fun collection key _ =>
    .symbolic (.index (inputNode collection) (.literal (.number (Lean.JsonNumber.fromNat key))))⟩

def ifThenElse (condition : Input Bool) (whenTrue whenFalse : Input α) : Input α :=
  .symbolic (.conditional (inputNode condition) (inputNode whenTrue) (inputNode whenFalse))

def unsafeArgument [IntoInput v α] (value : v) : UnsafeArgument :=
  ⟨inputNode (toInput value : Input α)⟩

/-- Call an OpenTofu function without a statically checked signature. The caller chooses the
result type, so prefer the typed `Input.*` functions when one exists. The function name is
validated at compile time. -/
def unsafeCall (name : String) (args : List UnsafeArgument)
    (_valid : validIdentifier name = true := by decide) : Input α :=
  .symbolic (.function name (args.map UnsafeArgument.node))

def text (value : String) : TemplatePart :=
  .text value

def interpolate [IntoInput v α] (value : v) : TemplatePart :=
  .interpolation (inputNode (toInput value : Input α))

def template (parts : List TemplatePart) : Input String :=
  .symbolic (.template parts)

/-- Read a secret from the process environment at plan/apply time. The CLI passes it to
OpenTofu as a sensitive variable and never writes its value. The variable name is validated
at compile time. -/
def secretEnv (name : String) (_valid : validEnvironmentName name = true := by decide) :
    Input String :=
  .symbolic (.secretEnvironment name)

namespace Input

/-! Typed wrappers for OpenTofu functions with fixed signatures, as dot-notation on inputs
(`droplet.id.tonumber`, `name.replace " " "-"`). Provider schemas sometimes type the same
value differently on two resources (a droplet's `id` is a string, an attachment's
`droplet_id` a number); these convert without giving up typing. Anything not listed here goes
through `unsafeCall`, which keeps the loss of typing visible. -/

private def call (name : String) (args : List ExprNode) : Input α :=
  .symbolic (.function name args)

def tonumber (value : Input String) : Input Number :=
  call "tonumber" [inputNode value]

def tostring (value : Input α) : Input String :=
  call "tostring" [inputNode value]

def tobool (value : Input String) : Input Bool :=
  call "tobool" [inputNode value]

def lower (value : Input String) : Input String :=
  call "lower" [inputNode value]

def upper (value : Input String) : Input String :=
  call "upper" [inputNode value]

def trimspace (value : Input String) : Input String :=
  call "trimspace" [inputNode value]

def length (value : Input (List α)) : Input Number :=
  call "length" [inputNode value]

def join (items : Input (List String)) (separator : Input String) : Input String :=
  call "join" [inputNode separator, inputNode items]

def split (value : Input String) (separator : Input String) : Input (List String) :=
  call "split" [inputNode separator, inputNode value]

def replace (value search replacement : Input String) : Input String :=
  call "replace" [inputNode value, inputNode search, inputNode replacement]

def substr (value : Input String) (offset length : Input Number) : Input String :=
  call "substr" [inputNode value, inputNode offset, inputNode length]

def startswith (value prefix_ : Input String) : Input Bool :=
  call "startswith" [inputNode value, inputNode prefix_]

def endswith (value suffix : Input String) : Input Bool :=
  call "endswith" [inputNode value, inputNode suffix]

def strcontains (value needle : Input String) : Input Bool :=
  call "strcontains" [inputNode value, inputNode needle]

/-- The template parts of a string input: a known string is text, a template is spliced. -/
def parts : Input String → List TemplatePart
  | .known (.string value) => [.text value]
  | .known value => [.interpolation (.literal value)]
  | .symbolic (.template parts) => parts
  | .symbolic node => [.interpolation node]

/-- Concatenate string inputs. Two known strings stay a known string; otherwise the result is
one flat template. -/
def append (left right : Input String) : Input String :=
  match left, right with
  | .known (.string x), .known (.string y) => .known (.string (x ++ y))
  | _, _ => .symbolic (.template (left.parts ++ right.parts))

instance : HAppend (Input String) (Input String) (Input String) := ⟨append⟩
instance : HAppend (Input String) String (Input String) := ⟨fun left right => append left (lit right)⟩
instance : HAppend String (Input String) (Input String) := ⟨fun left right => append (lit left) right⟩

end Input

/-- Values that `tf!"…{x}…"` can interpolate. -/
class Interpolated (v : Type) where
  toInput : v → Input String

instance : Interpolated (Input String) := ⟨id⟩
instance : Interpolated String := ⟨lit⟩
instance : Interpolated (Input Number) := ⟨Input.tostring⟩
instance : Interpolated Number := ⟨fun n => lit (toString n)⟩

/-- String interpolation into a symbolic template: `tf!"web-{droplet.id}.internal"` is the
template `text "web-", interpolate droplet.id, text ".internal"`. Braces hold any
`Interpolated` value; an all-known string folds to a plain literal. -/
syntax:max "tf!" interpolatedStr(term) : term

macro_rules
  | `(tf! $interpolated) => do
    let result ← Lean.TSyntax.expandInterpolatedStrChunks interpolated.raw.getArgs
      (fun left right => `(Inframe.Input.append $(⟨left⟩) $(⟨right⟩)))
      (fun element => `(Inframe.Interpolated.toInput $(⟨element⟩)))
      (fun literal => `(Inframe.lit $(Lean.Syntax.mkStrLit literal)))
    `(($(⟨result⟩) : Inframe.Input String))

def resourceHandle (resourceType name : Identifier) : Resource r := ⟨resourceType, name⟩
def dataSourceHandle (dataSourceType name : Identifier) : DataSource r := ⟨dataSourceType, name⟩
def providerHandle (address : String) : Provider p := ⟨address⟩
def providerAddress (provider : Provider p) : String := provider.address

def resourceAttr (handle : Resource r) (path : List String) : Input α :=
  .symbolic (.resourceAttribute handle.address path)

def dataSourceAttr (handle : DataSource r) (path : List String) : Input α :=
  .symbolic (.dataSourceAttribute handle.address path)

/-- Traverse further into a symbolic value, for example an element of a nested block. The
result type is chosen by the caller, so this is an escape hatch like `unsafeCall`. -/
def unsafeTraverse (value : Input α) (step : String)
    (_valid : validIdentifier step = true := by decide) : Input β :=
  match inputNode value with
  | .resourceAttribute address path => .symbolic (.resourceAttribute address (path ++ [step]))
  | .dataSourceAttribute address path => .symbolic (.dataSourceAttribute address (path ++ [step]))
  | node => .symbolic (.index node (.literal (.string step)))

end Inframe
