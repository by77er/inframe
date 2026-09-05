import Lean.Data.Json
import Inframe.Identifier

/-!
# Known values

`Value` is the language-native representation of a JSON literal that is known while the graph
is constructed. It is a plain inductive type (unlike `Lean.Json`, which stores objects in a
red-black tree), so equality is structurally recursive and reduces inside the kernel. That is
what lets policies over literal arguments be proved with `decide`.
-/

namespace Inframe

/-- An exact decimal number, `mantissa × 10^(-exponent)`. Numeric literals such as `2` and
`80.5` elaborate to `Number` directly and serialize without floating-point rounding. -/
abbrev Number := Lean.JsonNumber

inductive Value where
  | null
  | bool (value : Bool)
  | number (value : Number)
  | string (value : String)
  | array (items : List Value)
  | object (fields : List (String × Value))

namespace Value

mutual
  def beq : Value → Value → Bool
    | .null, .null => true
    | .bool a, .bool b => a == b
    | .number a, .number b => a == b
    | .string a, .string b => a == b
    | .array a, .array b => beqList a b
    | .object a, .object b => beqFields a b
    | _, _ => false
  termination_by structural x => x
  def beqList : List Value → List Value → Bool
    | [], [] => true
    | a :: as, b :: bs => beq a b && beqList as bs
    | _, _ => false
  termination_by structural x => x
  def beqFields : List (String × Value) → List (String × Value) → Bool
    | [], [] => true
    | (ka, va) :: as, (kb, vb) :: bs => ka == kb && beq va vb && beqFields as bs
    | _, _ => false
  termination_by structural x => x
end

instance : BEq Value := ⟨beq⟩

mutual
  def toJson : Value → Lean.Json
    | .null => .null
    | .bool value => .bool value
    | .number value => .num value
    | .string value => .str value
    | .array items => .arr (toJsonList items).toArray
    | .object fields => Lean.Json.mkObj (toJsonFields fields)
  termination_by structural x => x
  def toJsonList : List Value → List Lean.Json
    | [] => []
    | item :: rest => toJson item :: toJsonList rest
  termination_by structural x => x
  def toJsonFields : List (String × Value) → List (String × Lean.Json)
    | [] => []
    | (key, value) :: rest => (key, toJson value) :: toJsonFields rest
  termination_by structural x => x
end

/-- Compact JSON text. -/
def render (value : Value) : String :=
  value.toJson.compress

instance : ToString Value := ⟨render⟩
instance : Repr Value := ⟨fun value _ => Std.Format.text value.render⟩
instance : Lean.ToJson Value := ⟨toJson⟩

/-- Look up a field of an object literal. -/
def field? (value : Value) (name : String) : Option Value :=
  match value with
  | .object fields => fields.lookup name
  | _ => none

end Value

/-- Host-language values that can be embedded as known literals with `lit`. -/
class ToValue (α : Type) where
  toValue : α → Value

export ToValue (toValue)

instance : ToValue Value := ⟨id⟩
instance : ToValue String := ⟨.string⟩
instance : ToValue Bool := ⟨.bool⟩
instance : ToValue Number := ⟨.number⟩
instance : ToValue Nat := ⟨fun n => .number (Lean.JsonNumber.fromNat n)⟩
instance : ToValue Int := ⟨fun n => .number (Lean.JsonNumber.fromInt n)⟩
instance [ToValue α] : ToValue (List α) := ⟨fun items => .array (items.map toValue)⟩
instance [ToValue α] : ToValue (Array α) := ⟨fun items => .array (items.toList.map toValue)⟩
instance [ToValue α] : ToValue (Option α) := ⟨fun | none => .null | some value => toValue value⟩

/-- JSON-literal syntax for known values, for provider attributes typed `dynamic` or as
tuples: `value% { team: "core", replicas: 3, tags: ["a", "b"] }`. Braces may hold a Lean term
with `$`, for example `value% { name: $name }` where `name : String`. -/
syntax "value% " json : term

open Lean.Json in
macro_rules
  | `(value% null) => `(Inframe.Value.null)
  | `(value% true) => `(Inframe.Value.bool Bool.true)
  | `(value% false) => `(Inframe.Value.bool Bool.false)
  | `(value% $n:str) => `(Inframe.Value.string $n)
  | `(value% $n:num) => `(Inframe.Value.number $n)
  | `(value% $n:scientific) => `(Inframe.Value.number $n)
  | `(value% -$n:num) => `(Inframe.Value.number (-$n))
  | `(value% -$n:scientific) => `(Inframe.Value.number (-$n))
  | `(value% [$[$xs],*]) => `(Inframe.Value.array [$[value% $xs],*])
  | `(value% {$[$ks:jsonIdent : $vs:json],*}) => do
    let ks : Array (Lean.TSyntax `term) ← ks.mapM fun
      | `(jsonIdent| $k:ident) => pure (Lean.quote (toString k.getId))
      | `(jsonIdent| $k:str) => pure k
      | _ => Lean.Macro.throwUnsupported
    `(Inframe.Value.object [$[($ks, value% $vs)],*])
  | `(value% $stx) =>
    if stx.raw.isAntiquot then
      let stx : Lean.Term := ⟨stx.raw.getAntiquotTerm⟩
      `(Inframe.toValue $stx)
    else
      Lean.Macro.throwUnsupported

/-- A string-keyed map, the host representation of an OpenTofu `map(...)` value. -/
structure Map (α : Type) where
  entries : List (String × α)

namespace Map

def ofList (entries : List (String × α)) : Map α := ⟨entries⟩

instance [ToValue α] : ToValue (Map α) :=
  ⟨fun map => .object (map.entries.map fun (key, value) => (key, toValue value))⟩

end Map

/-! ## Marshalling resolved values

`tofu show -json` and `tofu output -json` carry the values OpenTofu actually resolved. They
are decoded through `FromValue` into the generated attribute structures, which are
higher-kinded: `Attributes Input` is the symbolic handle, `Attributes Resolved` holds plain
values, `Attributes Option` tolerates nulls. -/

/-- Host values that can be decoded from a known `Value`. -/
class FromValue (α : Type) where
  fromValue : Value → Except String α

export FromValue (fromValue)

instance : FromValue Value := ⟨pure⟩
instance : FromValue String :=
  ⟨fun | .string value => pure value | other => throw s!"expected a string, found {other}"⟩
instance : FromValue Bool :=
  ⟨fun | .bool value => pure value | other => throw s!"expected a boolean, found {other}"⟩
instance : FromValue Number :=
  ⟨fun | .number value => pure value | other => throw s!"expected a number, found {other}"⟩
instance [FromValue α] : FromValue (List α) :=
  ⟨fun | .array items => items.mapM fromValue | other => throw s!"expected an array, found {other}"⟩
instance [FromValue α] : FromValue (Map α) :=
  ⟨fun
    | .object fields => do
      let entries ← fields.mapM fun (key, value) => do pure (key, ← fromValue value)
      pure ⟨entries⟩
    | other => throw s!"expected an object, found {other}"⟩
instance [FromValue α] : FromValue (Option α) :=
  ⟨fun | .null => pure none | value => some <$> fromValue value⟩

/-- Plain values: `Resolved α` is `α`. Instantiating a generated `Attributes` at `Resolved`
gives the resolved state of a resource. -/
abbrev Resolved (α : Type) : Type := α

instance : Functor Resolved where
  map transform value := transform value

/-- How the containers of a generated `Attributes f o` obtain one attribute from a resolved
object. `f` says how every value is held and `o` whether a non-required attribute may be
absent: OpenTofu leaves unset optional and unknown computed attributes as `null`, so resolved
state is `Attributes Resolved Option`, a symbolic handle is `Attributes Input Resolved`, and a
fully tolerant view is `Attributes Option Resolved`. Generated decoders are written once
against this class. -/
class Marshal (f o : Type → Type) where
  /-- A required attribute or a nested block: always present. -/
  required [FromValue α] (object : Value) (name : String) : Except String (f α)
  /-- Any other attribute: may be `null` or missing. -/
  optional [FromValue α] (object : Value) (name : String) : Except String (f (o α))

private def presentField [FromValue α] (object : Value) (name : String) : Except String α :=
  match object.field? name with
  | some .null | none => throw s!"attribute `{name}` is null or missing"
  | some value => (fromValue value).mapError fun error => s!"attribute `{name}`: {error}"

private def optionalField [FromValue α] (object : Value) (name : String) :
    Except String (Option α) :=
  match object.field? name with
  | some .null | none => pure none
  | some value => (some <$> fromValue value).mapError fun error => s!"attribute `{name}`: {error}"

/-- Resolved state: required attributes must be present, the rest are `Option`. -/
instance : Marshal Resolved Option where
  required := presentField
  optional := optionalField

/-- A tolerant view: every attribute is `Option`. -/
instance : Marshal Option Resolved where
  required := optionalField
  optional := optionalField

instance : Inhabited Value := ⟨.null⟩

namespace Value

/-- Convert parsed JSON. Run-time only: `Lean.Json` objects are ordered trees. -/
partial def ofJson : Lean.Json → Value
  | .null => .null
  | .bool value => .bool value
  | .num value => .number value
  | .str value => .string value
  | .arr items => .array (items.toList.map ofJson)
  | .obj fields => .object (fields.toList.map fun (key, value) => (key, ofJson value))

/-- Parse JSON text into a known value. -/
def parse (text : String) : Except String Value :=
  ofJson <$> Lean.Json.parse text

end Value

/-! ### OpenTofu documents -/

/-- The document printed by `tofu show -json` (and `inframe show`). -/
structure ShowDocument where
  document : Value

namespace ShowDocument

def parse (text : String) : Except String ShowDocument :=
  ShowDocument.mk <$> Value.parse text

private def rootResources (document : Value) : List Value :=
  match (document.field? "values").bind (·.field? "root_module") |>.bind (·.field? "resources") with
  | some (.array resources) => resources
  | _ => []

/-- The resolved attribute values of the resource at `address`, if it is in the state. -/
def resource? (show_ : ShowDocument) (address : Address) : Option Value :=
  (rootResources show_.document).find? (fun resource =>
      resource.field? "address" == some (.string address.toString))
    |>.bind (·.field? "values")

/-- Decode the resource at `address` into a generated attribute structure. -/
def decode? [FromValue α] (show_ : ShowDocument) (address : Address) : Except String α :=
  match show_.resource? address with
  | some values => fromValue values
  | none => throw s!"resource `{address}` is not in the state"

end ShowDocument

/-- The document printed by `tofu output -json` (and `inframe output`). Sensitive outputs are
refused by `value?`; `sensitiveValue?` reads them deliberately. -/
structure OutputsDocument where
  document : Value

namespace OutputsDocument

def parse (text : String) : Except String OutputsDocument :=
  OutputsDocument.mk <$> Value.parse text

private def entry? (outputs : OutputsDocument) (name : String) : Except String Value :=
  match outputs.document.field? name with
  | some entry => pure entry
  | none => throw s!"output `{name}` is not in the document"

/-- A non-sensitive output, decoded. -/
def value? [FromValue α] (outputs : OutputsDocument) (name : String) : Except String α := do
  let entry ← outputs.entry? name
  if entry.field? "sensitive" == some (.bool true) then
    throw s!"output `{name}` is sensitive; read it with sensitiveValue? if that is intended"
  match entry.field? "value" with
  | some value => fromValue value
  | none => throw s!"output `{name}` has no value"

/-- A sensitive output, decoded deliberately. Whatever it is marshalled into becomes part of
Graph IR and the lowered configuration, so prefer `secretEnv` for secrets. -/
def sensitiveValue? [FromValue α] (outputs : OutputsDocument) (name : String) :
    Except String α := do
  let entry ← outputs.entry? name
  match entry.field? "value" with
  | some value => fromValue value
  | none => throw s!"output `{name}` has no value"

end OutputsDocument

end Inframe
