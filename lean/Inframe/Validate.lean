import Inframe.Builder

/-!
# Graph validation

A Lean port of the Rust reference validator (`inframe graph validate`). Because the checks are
structurally recursive, `Graph.Valid graph` is decidable and can be proved with `decide`: a
graph that the CLI would reject fails to compile instead.
-/

namespace Inframe

instance [DecidableEq ε] [DecidableEq α] : DecidableEq (Except ε α)
  | .error a, .error b =>
    if h : a = b then isTrue (h ▸ rfl) else isFalse (fun e => h (Except.error.inj e))
  | .ok a, .ok b =>
    if h : a = b then isTrue (h ▸ rfl) else isFalse (fun e => h (Except.ok.inj e))
  | .error _, .ok _ => isFalse nofun
  | .ok _, .error _ => isFalse nofun

inductive ValidationError where
  | invalidIdentifier (path : String) (value : String)
  | duplicateProviderConfig (address : String)
  | duplicateAddress (address : Address)
  | missingReference (owner : String) (target : Address)
  | selfDependency (owner : Address)
  | referenceKind (owner : String) (target : Address)
  | invalidSecretEnvironment (path : String) (value : String)
  | missingProviderConfig (owner : String) (provider : String)
  | invalidReplaceTriggeredBy (owner : Address) (target : Address)
  | missingMoveTarget (target : Address)
  | duplicateMoveTarget (target : Address)
  deriving DecidableEq, Repr

namespace ValidationError

def message : ValidationError → String
  | .invalidIdentifier path value => s!"invalid identifier `{value}` at {path}"
  | .duplicateProviderConfig address => s!"duplicate provider configuration `{address}`"
  | .duplicateAddress address => s!"duplicate address `{address}`"
  | .missingReference owner target => s!"`{owner}` references missing node `{target}`"
  | .selfDependency owner => s!"`{owner}` depends on itself"
  | .referenceKind owner target => s!"`{owner}` references `{target}` with the wrong node kind"
  | .invalidSecretEnvironment path value => s!"invalid secret environment name `{value}` at {path}"
  | .missingProviderConfig owner provider => s!"`{owner}` selects unconfigured provider `{provider}`"
  | .invalidReplaceTriggeredBy owner target =>
      s!"`{owner}` lists non-resource `{target}` in replace_triggered_by"
  | .missingMoveTarget target => s!"move target `{target}` does not exist"
  | .duplicateMoveTarget target => s!"duplicate move target `{target}`"

instance : ToString ValidationError := ⟨message⟩

end ValidationError

namespace ExprNode

mutual
  /-- Every node address referenced anywhere inside the expression. -/
  def references : ExprNode → List Address
    | .literal _ => []
    | .resourceAttribute address _ => [address]
    | .dataSourceAttribute address _ => [address]
    | .array items => referencesList items
    | .object fields => referencesFields fields
    | .index collection key => references collection ++ references key
    | .conditional condition whenTrue whenFalse =>
        references condition ++ references whenTrue ++ references whenFalse
    | .function _ args => referencesList args
    | .template parts => referencesParts parts
    | .secretEnvironment _ => []
  termination_by structural x => x
  def referencesList : List ExprNode → List Address
    | [] => []
    | item :: rest => references item ++ referencesList rest
  termination_by structural x => x
  def referencesFields : List (String × ExprNode) → List Address
    | [] => []
    | (_, value) :: rest => references value ++ referencesFields rest
  termination_by structural x => x
  def referencesParts : List TemplatePart → List Address
    | [] => []
    | .text _ :: rest => referencesParts rest
    | .interpolation expression :: rest => references expression ++ referencesParts rest
  termination_by structural x => x
end

mutual
  /-- Every `secretEnv` name used inside the expression. -/
  def secretNames : ExprNode → List String
    | .literal _ => []
    | .resourceAttribute _ _ => []
    | .dataSourceAttribute _ _ => []
    | .array items => secretNamesList items
    | .object fields => secretNamesFields fields
    | .index collection key => secretNames collection ++ secretNames key
    | .conditional condition whenTrue whenFalse =>
        secretNames condition ++ secretNames whenTrue ++ secretNames whenFalse
    | .function _ args => secretNamesList args
    | .template parts => secretNamesParts parts
    | .secretEnvironment name => [name]
  termination_by structural x => x
  def secretNamesList : List ExprNode → List String
    | [] => []
    | item :: rest => secretNames item ++ secretNamesList rest
  termination_by structural x => x
  def secretNamesFields : List (String × ExprNode) → List String
    | [] => []
    | (_, value) :: rest => secretNames value ++ secretNamesFields rest
  termination_by structural x => x
  def secretNamesParts : List TemplatePart → List String
    | [] => []
    | .text _ :: rest => secretNamesParts rest
    | .interpolation expression :: rest => secretNames expression ++ secretNamesParts rest
  termination_by structural x => x
end

/-- Whether the expression references `address` anywhere. -/
def references? (expression : ExprNode) (address : Address) : Bool :=
  expression.references.contains address

end ExprNode

private def validateIdentifier (path value : String) : Except ValidationError Unit :=
  if validIdentifier value then .ok () else throw (.invalidIdentifier path value)

private def validatePath (owner : String) : List String → Except ValidationError Unit
  | [] => .ok ()
  | element :: rest => do
    validateIdentifier owner element
    validatePath owner rest

namespace ExprNode

mutual
  /-- Checks that need no knowledge of the rest of the graph: reference kinds, attribute
  paths, function names, and secret environment names. -/
  def validateStructure (owner : String) : ExprNode → Except ValidationError Unit
    | .literal _ => .ok ()
    | .resourceAttribute address path =>
        if address.isResource then validatePath owner path
        else throw (.referenceKind owner address)
    | .dataSourceAttribute address path =>
        if address.isResource then throw (.referenceKind owner address)
        else validatePath owner path
    | .array items => validateStructureList owner items
    | .object fields => validateStructureFields owner fields
    | .index collection key => do
        validateStructure owner collection
        validateStructure owner key
    | .conditional condition whenTrue whenFalse => do
        validateStructure owner condition
        validateStructure owner whenTrue
        validateStructure owner whenFalse
    | .function name args => do
        validateIdentifier owner name
        validateStructureList owner args
    | .template parts => validateStructureParts owner parts
    | .secretEnvironment name =>
        if validEnvironmentName name then .ok () else throw (.invalidSecretEnvironment owner name)
  termination_by structural x => x
  def validateStructureList (owner : String) : List ExprNode → Except ValidationError Unit
    | [] => .ok ()
    | item :: rest => do
        validateStructure owner item
        validateStructureList owner rest
  termination_by structural x => x
  def validateStructureFields (owner : String) :
      List (String × ExprNode) → Except ValidationError Unit
    | [] => .ok ()
    | (_, value) :: rest => do
        validateStructure owner value
        validateStructureFields owner rest
  termination_by structural x => x
  def validateStructureParts (owner : String) : List TemplatePart → Except ValidationError Unit
    | [] => .ok ()
    | .text _ :: rest => validateStructureParts owner rest
    | .interpolation expression :: rest => do
        validateStructure owner expression
        validateStructureParts owner rest
  termination_by structural x => x
end

end ExprNode

/-- A derived edge: `downstream` must be created after `upstream`. -/
structure Dependency where
  upstream : Address
  downstream : Address
  explicit : Bool
  deriving DecidableEq, Repr

namespace Graph

private def validateExpr (owner : String) (addresses : List Address) (expression : ExprNode) :
    Except ValidationError Unit := do
  expression.validateStructure owner
  validateReferences owner addresses expression.references
where
  validateReferences (owner : String) (addresses : List Address) :
      List Address → Except ValidationError Unit
    | [] => .ok ()
    | target :: rest =>
      if addresses.contains target then validateReferences owner addresses rest
      else throw (.missingReference owner target)

private def validateArguments (owner : String) (addresses : List Address) :
    List (String × ExprNode) → Except ValidationError Unit
  | [] => .ok ()
  | (_, expression) :: rest => do
    validateExpr owner addresses expression
    validateArguments owner addresses rest

private def validateExplicit (owner : Address) (addresses : List Address) :
    List Address → Except ValidationError Unit
  | [] => .ok ()
  | target :: rest =>
    if target == owner then throw (.selfDependency owner)
    else if addresses.contains target then validateExplicit owner addresses rest
    else throw (.missingReference owner.toString target)

private def splitProvider : List Char → List Char → Option (List Char × List Char)
  | [], _ => none
  | '.' :: rest, acc => some (acc.reverse, rest)
  | c :: rest, acc => splitProvider rest (c :: acc)

private def validIdentifierChars (chars : List Char) : Bool :=
  match chars with
  | [] => false
  | c :: rest => isIdentifierStart c && rest.all isIdentifierChar

private def validProviderSelector (provider : String) : Bool :=
  match splitProvider provider.toList [] with
  | none => validIdentifier provider
  | some (localName, alias) => validIdentifierChars localName && validIdentifierChars alias

private def validateSelectedProvider (owner : String) (configured : List String) :
    Option String → Except ValidationError Unit
  | none => .ok ()
  | some provider =>
    if !validProviderSelector provider then throw (.invalidIdentifier (owner ++ ".provider") provider)
    else if configured.contains provider then .ok ()
    else throw (.missingProviderConfig owner provider)

private def validateReplacementTriggers (owner : Address) (addresses : List Address) :
    List Address → Except ValidationError Unit
  | [] => .ok ()
  | target :: rest =>
    if !target.isResource then throw (.invalidReplaceTriggeredBy owner target)
    else if addresses.contains target then validateReplacementTriggers owner addresses rest
    else throw (.missingReference owner.toString target)

private def validateProviderNames : List (String × ProviderRequirement) → Except ValidationError Unit
  | [] => .ok ()
  | (name, _) :: rest => do
    validateIdentifier "required_providers" name
    validateProviderNames rest

private def validateProviderConfigs (index : Nat) (seen : List String) :
    List ProviderConfigSpec → Except ValidationError Unit
  | [] => .ok ()
  | config :: rest => do
    validateIdentifier s!"provider_configs[{index}].provider" config.provider
    match config.alias with
    | none => pure ()
    | some alias => validateIdentifier s!"provider_configs[{index}].alias" alias
    if seen.contains config.address then throw (.duplicateProviderConfig config.address)
    validateProviderConfigs (index + 1) (config.address :: seen) rest

private def validateResourceNames (seen : List Address) :
    List ResourceSpec → Except ValidationError (List Address)
  | [] => .ok seen
  | resource :: rest => do
    validateIdentifier "resources[].type" resource.resourceType
    validateIdentifier "resources[].name" resource.name
    if seen.contains resource.address then throw (.duplicateAddress resource.address)
    validateResourceNames (seen ++ [resource.address]) rest

private def validateDataSourceNames (seen : List Address) :
    List DataSourceSpec → Except ValidationError (List Address)
  | [] => .ok seen
  | dataSource :: rest => do
    validateIdentifier "data_sources[].type" dataSource.dataSourceType
    validateIdentifier "data_sources[].name" dataSource.name
    if seen.contains dataSource.address then throw (.duplicateAddress dataSource.address)
    validateDataSourceNames (seen ++ [dataSource.address]) rest

private def validateResources (addresses : List Address) (configured : List String) :
    List ResourceSpec → Except ValidationError Unit
  | [] => .ok ()
  | resource :: rest => do
    let owner := resource.address
    validateArguments owner.toString addresses resource.arguments
    validateExplicit owner addresses resource.dependsOn
    validateSelectedProvider owner.toString configured resource.provider
    match resource.lifecycle with
    | none => pure ()
    | some lifecycle => validateReplacementTriggers owner addresses lifecycle.replaceTriggeredBy
    validateResources addresses configured rest

private def validateDataSources (addresses : List Address) (configured : List String) :
    List DataSourceSpec → Except ValidationError Unit
  | [] => .ok ()
  | dataSource :: rest => do
    let owner := dataSource.address
    validateArguments owner.toString addresses dataSource.arguments
    validateExplicit owner addresses dataSource.dependsOn
    validateSelectedProvider owner.toString configured dataSource.provider
    validateDataSources addresses configured rest

private def validateOutputs (addresses : List Address) :
    List (String × OutputSpec) → Except ValidationError Unit
  | [] => .ok ()
  | (name, output) :: rest => do
    validateIdentifier "outputs" name
    validateExpr ("output." ++ name) addresses output.value
    validateOutputs addresses rest

private def validateProviderArguments (index : Nat) (addresses : List Address) :
    List ProviderConfigSpec → Except ValidationError Unit
  | [] => .ok ()
  | config :: rest => do
    validateArguments s!"provider_configs[{index}]" addresses config.arguments
    validateProviderArguments (index + 1) addresses rest

private def validateMoves (addresses : List Address) (targets : List Address) :
    List MoveSpec → Except ValidationError Unit
  | [] => .ok ()
  | move :: rest =>
    if !addresses.contains move.destination then throw (.missingMoveTarget move.destination)
    else if targets.contains move.destination then throw (.duplicateMoveTarget move.destination)
    else validateMoves addresses (move.destination :: targets) rest

/-- The reference validation rules, ported from the Rust `GraphDocument::validate`. -/
def validate (graph : Graph) : Except ValidationError Unit := do
  validateProviderNames graph.requiredProviders
  validateProviderConfigs 0 [] graph.providerConfigs
  let configured := graph.providerConfigs.map ProviderConfigSpec.address
  let addresses ← validateResourceNames [] graph.resources
  let addresses ← validateDataSourceNames addresses graph.dataSources
  validateResources addresses configured graph.resources
  validateDataSources addresses configured graph.dataSources
  validateOutputs addresses graph.outputs
  validateProviderArguments 0 addresses graph.providerConfigs
  validateMoves addresses [] graph.moves

/-- The graph passes every validation rule. Decidable, so `by decide` proves it for a
concrete graph. -/
abbrev Valid (graph : Graph) : Prop :=
  graph.validate = .ok ()

/-- The validation error, if any, as human-readable text. -/
def validationError? (graph : Graph) : Option String :=
  match graph.validate with
  | .ok () => none
  | .error error => some error.message

private def addDependencies (owner : Address) (arguments : List (String × ExprNode))
    (explicit : List Address) : List Dependency :=
  (arguments.flatMap fun (_, expression) =>
    expression.references.map fun upstream => ⟨upstream, owner, false⟩)
    ++ explicit.map fun upstream => ⟨upstream, owner, true⟩

/-- Every edge in the graph: implicit edges derived from references plus explicit
`depends_on` edges. References are the source of truth; no separate DAG is stored. -/
def dependencies (graph : Graph) : List Dependency :=
  (graph.resources.flatMap fun resource =>
      addDependencies resource.address resource.arguments resource.dependsOn)
    ++ (graph.dataSources.flatMap fun dataSource =>
      addDependencies dataSource.address dataSource.arguments dataSource.dependsOn)
  |>.eraseDups

/-- Whether `downstream` must be created after `upstream`, directly. -/
def dependsOn (graph : Graph) (downstream upstream : Address) : Bool :=
  graph.dependencies.any fun edge => edge.downstream == downstream && edge.upstream == upstream

/-- Every `secretEnv` name the graph needs at plan or apply time. -/
def secretEnvironmentNames (graph : Graph) : List String :=
  ((graph.providerConfigs.flatMap fun config =>
      config.arguments.flatMap fun (_, expression) => expression.secretNames)
    ++ (graph.resources.flatMap fun resource =>
      resource.arguments.flatMap fun (_, expression) => expression.secretNames)
    ++ (graph.dataSources.flatMap fun dataSource =>
      dataSource.arguments.flatMap fun (_, expression) => expression.secretNames)
    ++ (graph.outputs.flatMap fun (_, output) => output.value.secretNames))
  |>.eraseDups

end Graph

end Inframe
