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

end Identifier

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
    (_validType : validIdentifier resourceType = true := by decide)
    (_validName : validIdentifier name = true := by decide) : Address :=
  .resource resourceType name

/-- A data-source address whose components are checked at compile time. -/
def data (dataSourceType name : String)
    (_validType : validIdentifier dataSourceType = true := by decide)
    (_validName : validIdentifier name = true := by decide) : Address :=
  .dataSource dataSourceType name

end Address

end Inframe
