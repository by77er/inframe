/-!
# Identifiers and addresses

OpenTofu identifiers are validated with the same rule as the Rust reference validator. In
Lean the rule is a decidable predicate, so string literals are checked while the module is
compiled: `Identifier.mk "digitalocean_tag"` elaborates, `Identifier.mk "bad name"` is a
type error.
-/

namespace Inframe

/-- Whether `c` may begin an OpenTofu identifier: `_` or an ASCII letter. -/
def isIdentifierStart (c : Char) : Bool :=
  c == '_' || c.isAlpha

/-- Whether `c` may continue an OpenTofu identifier: `_`, `-`, or an ASCII letter or digit. -/
def isIdentifierChar (c : Char) : Bool :=
  c == '_' || c == '-' || c.isAlphanum

/-- The identifier rule shared with the Rust validator. It covers resource types, logical
names, provider names and aliases, attribute path elements, output names, and function
names. -/
def validIdentifier (s : String) : Bool :=
  match s.toList with
  | [] => false
  | c :: rest => isIdentifierStart c && rest.all isIdentifierChar

/-- Whether `c` may continue an environment variable name: `_` or an ASCII letter or digit. -/
def isEnvironmentChar (c : Char) : Bool :=
  c == '_' || c.isAlphanum

/-- The rule for `secretEnv` names: `_` or an ASCII letter, then `_` or ASCII alphanumerics. -/
def validEnvironmentName (s : String) : Bool :=
  match s.toList with
  | [] => false
  | c :: rest => isIdentifierStart c && rest.all isEnvironmentChar

/-- A string that is known to satisfy `validIdentifier`. The proof is discharged by `decide`
when the string is a literal, so invalid names fail at compile time rather than at
`inframe graph validate`. -/
structure Identifier where
  raw : String
  valid : validIdentifier raw = true := by decide

namespace Identifier

/-- Validate a string that is only known at run time. -/
def ofString? (s : String) : Option Identifier :=
  if h : validIdentifier s = true then some ⟨s, h⟩ else none

instance : DecidableEq Identifier := fun a b =>
  if h : a.raw = b.raw then
    isTrue (by cases a; cases b; cases h; rfl)
  else
    isFalse (fun e => h (congrArg Identifier.raw e))

instance : ToString Identifier := ⟨Identifier.raw⟩
instance : Repr Identifier := ⟨fun i _ => repr i.raw⟩
instance : Coe Identifier String := ⟨Identifier.raw⟩

theorem isIdentifierChar_of_start {c : Char} (h : isIdentifierStart c = true) :
    isIdentifierChar c = true := by
  simp [isIdentifierStart, isIdentifierChar, Char.isAlphanum] at *
  rcases h with h | h <;> simp [h]

/-- Identifiers compose: `a-b` is an identifier whenever `a` and `b` are. -/
theorem validIdentifier_join (a b : String) (ha : validIdentifier a = true)
    (hb : validIdentifier b = true) : validIdentifier (a ++ "-" ++ b) = true := by
  unfold validIdentifier at *
  have expand : (a ++ "-" ++ b).toList = a.toList ++ '-' :: b.toList := by simp
  rw [expand]
  cases ha' : a.toList with
  | nil => simp [ha'] at ha
  | cons c rest =>
    cases hb' : b.toList with
    | nil => simp [hb'] at hb
    | cons d rest' =>
      simp only [ha'] at ha
      simp only [hb'] at hb
      simp only [List.cons_append, List.all_append, List.all_cons, Bool.and_eq_true] at ha hb ⊢
      exact ⟨ha.1, ha.2, by decide, isIdentifierChar_of_start hb.1, hb.2⟩

/-- `a-b`, valid because `a` and `b` are: names derived from other names need no `decide`. -/
def join (a b : Identifier) : Identifier :=
  ⟨a.raw ++ "-" ++ b.raw, validIdentifier_join a.raw b.raw a.valid b.valid⟩

end Identifier

/-- Discharges `validIdentifier s = true`: when `s` is the `raw` of an `Identifier` its proof
is reused, otherwise `s` must be a literal and `decide` checks it. Every name parameter with
this auto-param therefore accepts both a string literal and an `Identifier`. -/
macro "valid_identifier" : tactic =>
  `(tactic| first | exact Inframe.Identifier.valid _ | decide)

/-- The address of a graph node. Addresses are structural so that policies and proofs can
match on them without parsing strings. -/
inductive Address where
  | resource (resourceType : String) (name : String)
  | dataSource (dataSourceType : String) (name : String)
  deriving DecidableEq, Repr

namespace Address

/-- The OpenTofu address syntax: `type.name` or `data.type.name`. -/
def toString : Address → String
  | .resource resourceType name => resourceType ++ "." ++ name
  | .dataSource dataSourceType name => "data." ++ dataSourceType ++ "." ++ name

instance : ToString Address := ⟨Address.toString⟩

def isResource : Address → Bool
  | .resource .. => true
  | .dataSource .. => false

def isDataSource (address : Address) : Bool :=
  !address.isResource

/-- A managed-resource address whose components are checked at compile time. -/
def res (resourceType name : String)
    (_validType : validIdentifier resourceType = true := by valid_identifier)
    (_validName : validIdentifier name = true := by valid_identifier) : Address :=
  .resource resourceType name

/-- A data-source address whose components are checked at compile time. -/
def data (dataSourceType name : String)
    (_validType : validIdentifier dataSourceType = true := by valid_identifier)
    (_validName : validIdentifier name = true := by valid_identifier) : Address :=
  .dataSource dataSourceType name

end Address

end Inframe
