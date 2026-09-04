import Lean.Data.Json

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

end Inframe
