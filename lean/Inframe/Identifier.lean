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

/-- `parent-suffix`, with the suffix's validity discharged from its literal: `site.child "network"`
names the network of a site whose identifier is a run-time value. -/
def Identifier.child (parent : Identifier) (suffix : String)
    (valid : validIdentifier suffix = true := by valid_identifier) : Identifier :=
  parent.join ⟨suffix, valid⟩

/-! ### Suffixes that are not identifiers themselves

`join` and `child` need a suffix that could stand alone, so it must start with a letter. The
names infrastructure actually derives are often index- or CIDR-shaped (`fwd-1`,
`net-10-192-0-0-16`): after a `-`, any identifier-tail characters keep an identifier valid, and
`append`, `indexed`, and `slug` carry that proof. -/

/-- Appending `-` and any run of identifier-tail characters (letters, digits, `_`, `-`) to an
identifier keeps it valid; the suffix need not start with a letter. -/
theorem validIdentifier_append (a suffix : String) (ha : validIdentifier a = true)
    (hs : suffix.toList.all isIdentifierChar = true) :
    validIdentifier (a ++ "-" ++ suffix) = true := by
  unfold validIdentifier at *
  have expand : (a ++ "-" ++ suffix).toList = a.toList ++ '-' :: suffix.toList := by simp
  rw [expand]
  cases ha' : a.toList with
  | nil => simp [ha'] at ha
  | cons c rest =>
    simp only [ha'] at ha
    simp only [List.cons_append, List.all_append, List.all_cons, Bool.and_eq_true] at ha ⊢
    exact ⟨ha.1, ha.2, by decide, hs⟩

/-- Every character that cannot continue an identifier replaced by `-`:
`identifierTail "10.192.0.0/16" = "10-192-0-0-16"`. Total, so run-time text such as a CIDR
or a hostname can always become part of a name. -/
def identifierTail (text : String) : String :=
  String.ofList (text.toList.map fun c => if isIdentifierChar c then c else '-')

theorem identifierTail_all (text : String) :
    (identifierTail text).toList.all isIdentifierChar = true := by
  simp only [identifierTail, String.toList_ofList, List.all_map, List.all_eq_true]
  intro c _
  simp only [Function.comp]
  split
  · assumption
  · decide

theorem isIdentifierChar_digitChar (k : Nat) (h : k < 10) :
    isIdentifierChar (Nat.digitChar k) = true := by
  match k, h with
  | 0, _ | 1, _ | 2, _ | 3, _ | 4, _ | 5, _ | 6, _ | 7, _ | 8, _ | 9, _ => decide

theorem toDigitsCore_all (fuel n : Nat) (acc : List Char)
    (hacc : acc.all isIdentifierChar = true) :
    (Nat.toDigitsCore 10 fuel n acc).all isIdentifierChar = true := by
  induction fuel generalizing n acc with
  | zero => simpa [Nat.toDigitsCore] using hacc
  | succ fuel ih =>
    simp only [Nat.toDigitsCore]
    have digit : isIdentifierChar (Nat.digitChar (n % 10)) = true :=
      isIdentifierChar_digitChar _ (Nat.mod_lt _ (by decide))
    split
    · simp [digit, hacc]
    · exact ih _ _ (by simp [digit, hacc])

/-- The decimal digits of a natural number are identifier-tail characters. -/
theorem repr_all_identifierChar (n : Nat) : (Nat.repr n).toList.all isIdentifierChar = true := by
  simpa [Nat.repr, Nat.toDigits, String.toList_ofList] using toDigitsCore_all (n + 1) n [] rfl

/-- Discharges `suffix.toList.all isIdentifierChar = true`: a literal by `decide`, a sanitized
string by `identifierTail_all`, a decimal number by `repr_all_identifierChar`. -/
macro "identifier_tail" : tactic =>
  `(tactic| first
    | decide
    | exact Inframe.identifierTail_all _
    | exact Inframe.repr_all_identifierChar _
    | fail "the suffix must consist of letters, digits, `_`, and `-`; pass `identifierTail s` for arbitrary text")

/-- `a-suffix`, where the suffix is any run of identifier-tail characters, so unlike `child` it
may start with a digit: `rule.append "1"` is `rule-1`, `net.append "10-192-0-0-16"`. A
literal suffix is checked at compile time; run-time text goes through `slug`. -/
def Identifier.append (a : Identifier) (suffix : String)
    (valid : suffix.toList.all isIdentifierChar = true := by identifier_tail) : Identifier :=
  ⟨a.raw ++ "-" ++ suffix, validIdentifier_append a.raw suffix a.valid valid⟩

/-- `a-<index>` for a run-time index: `(Identifier.mk "fwd").indexed 1` is `fwd-1`. -/
def Identifier.indexed (a : Identifier) (index : Nat) : Identifier :=
  a.append (Nat.repr index) (repr_all_identifierChar index)

/-- `a-<slug>` for run-time text of any shape, with characters that cannot appear in an
identifier replaced by `-`: `net.slug "10.192.0.0/16"` is `net-10-192-0-0-16`. -/
def Identifier.slug (a : Identifier) (text : String) : Identifier :=
  a.append (identifierTail text) (identifierTail_all text)

@[simp] theorem Identifier.raw_append (a : Identifier) (suffix : String)
    (valid : suffix.toList.all isIdentifierChar = true) :
    (a.append suffix valid).raw = a.raw ++ "-" ++ suffix := rfl

@[simp] theorem Identifier.raw_indexed (a : Identifier) (index : Nat) :
    (a.indexed index).raw = a.raw ++ "-" ++ Nat.repr index := rfl

@[simp] theorem Identifier.raw_slug (a : Identifier) (text : String) :
    (a.slug text).raw = a.raw ++ "-" ++ identifierTail text := rfl

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
