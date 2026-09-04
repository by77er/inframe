import Inframe.Core

/-!
# Pure graph builder

`Infra α` is a pure state transformer over `Graph`. Despite `do` notation no effect runs:
creating a resource only appends a `ResourceSpec` and returns a typed symbolic handle. The
completed `Graph` is ordinary data, so it can be inspected by policies, compared, and proved
about.
-/

namespace Inframe

/-- Opaque arguments accumulated by generated provider builders. Insertion order is preserved
and inserting an existing key replaces its value. -/
structure InputObject where
  fields : List (String × ExprNode)

namespace InputObject

def empty : InputObject := ⟨[]⟩

def ofList (fields : List (String × ExprNode)) : InputObject := ⟨fields⟩

private def replaceOrAppend (name : String) (value : ExprNode) :
    List (String × ExprNode) → List (String × ExprNode)
  | [] => [(name, value)]
  | (key, existing) :: rest =>
    if key == name then (key, value) :: rest else (key, existing) :: replaceOrAppend name value rest

def insert (name : String) (value : ExprNode) (object : InputObject) : InputObject :=
  ⟨replaceOrAppend name value object.fields⟩

def toExprNode (object : InputObject) : ExprNode :=
  .object object.fields

end InputObject

/-- A phantom-tagged argument accumulator. Generated adapters define each `Args` type and each
nested block builder as `Block "<qualified name>"`, so arguments of different shapes remain
distinct types without paying for a `structure` (and its dozen auxiliary declarations) per
shape; provider schemas can unroll to tens of thousands of shapes in one module. -/
structure Block (tag : String) where
  values : InputObject

/-- Values accepted by `output` and `sensitiveOutput`. -/
class OutputValue (v : Type) where
  outputValueNode : v → ExprNode

instance : OutputValue (Expr α) := ⟨exprNode⟩
instance : OutputValue (Input α) := ⟨inputNode⟩

structure LifecycleOptions where
  createBeforeDestroy : Bool := false
  preventDestroy : Bool := false
  ignoreChanges : List String := []
  replaceTriggeredBy : List Address := []
  deriving DecidableEq, Repr

/-- Distinguishes resource options from data-source options at the type level. -/
inductive Scope where
  | resource
  | dataSource

structure NodeOptions (scope : Scope) (provider : Type) where
  explicitDependencies : List Address := []
  provider : Option String := none
  lifecycle : Option LifecycleOptions := none

abbrev ResourceOptions (provider : Type) := NodeOptions .resource provider
abbrev DataSourceOptions (provider : Type) := NodeOptions .dataSource provider

def resourceOptions : ResourceOptions provider := {}
def dataSourceOptions : DataSourceOptions provider := {}

private def appendUnique [BEq α] (value : α) (values : List α) : List α :=
  if values.contains value then values else values ++ [value]

namespace NodeOptions

/-- Select an explicitly configured (possibly aliased) provider. -/
def withProvider (provider : Provider p) (options : NodeOptions scope p) : NodeOptions scope p :=
  { options with provider := some (providerAddress provider) }

/-- Add an explicit `depends_on` edge for a relationship that is not visible as a reference. -/
def dependsOn [Dependable h] (handle : h) (options : NodeOptions scope p) : NodeOptions scope p :=
  { options with explicitDependencies := appendUnique (Dependable.dependencyAddress handle) options.explicitDependencies }

private def updateLifecycle (transform : LifecycleOptions → LifecycleOptions)
    (options : ResourceOptions p) : ResourceOptions p :=
  { options with lifecycle := some (transform (options.lifecycle.getD {})) }

def createBeforeDestroy (enabled : Bool) (options : ResourceOptions p) : ResourceOptions p :=
  updateLifecycle (fun lifecycle => { lifecycle with createBeforeDestroy := enabled }) options

def preventDestroy (enabled : Bool) (options : ResourceOptions p) : ResourceOptions p :=
  updateLifecycle (fun lifecycle => { lifecycle with preventDestroy := enabled }) options

def ignoreChanges (paths : List String) (options : ResourceOptions p) : ResourceOptions p :=
  updateLifecycle (fun lifecycle => { lifecycle with ignoreChanges := paths }) options

def replaceTriggeredBy (handle : Resource r) (options : ResourceOptions p) : ResourceOptions p :=
  updateLifecycle
    (fun lifecycle =>
      { lifecycle with replaceTriggeredBy := appendUnique handle.address lifecycle.replaceTriggeredBy })
    options

end NodeOptions

export NodeOptions (withProvider dependsOn createBeforeDestroy preventDestroy ignoreChanges replaceTriggeredBy)

structure ProviderRequirement where
  source : String
  version : String
  deriving DecidableEq, Repr

structure ProviderConfigSpec where
  provider : String
  alias : Option String
  arguments : List (String × ExprNode)
  deriving Repr

structure ResourceSpec where
  resourceType : String
  name : String
  arguments : List (String × ExprNode)
  dependsOn : List Address
  provider : Option String
  lifecycle : Option LifecycleOptions
  deriving Repr

structure DataSourceSpec where
  dataSourceType : String
  name : String
  arguments : List (String × ExprNode)
  dependsOn : List Address
  provider : Option String
  deriving Repr

structure OutputSpec where
  value : ExprNode
  sensitive : Bool
  deriving Repr

structure MoveSpec where
  origin : Address
  destination : Address
  deriving DecidableEq, Repr

/-- The completed desired-infrastructure graph. -/
structure Graph where
  requiredProviders : List (String × ProviderRequirement) := []
  providerConfigs : List ProviderConfigSpec := []
  resources : List ResourceSpec := []
  dataSources : List DataSourceSpec := []
  outputs : List (String × OutputSpec) := []
  moves : List MoveSpec := []
  deriving Repr

namespace ProviderConfigSpec

def address (config : ProviderConfigSpec) : String :=
  match config.alias with
  | none => config.provider
  | some alias => config.provider ++ "." ++ alias

def argument? (config : ProviderConfigSpec) (name : String) : Option ExprNode :=
  config.arguments.lookup name

end ProviderConfigSpec

namespace ResourceSpec

def address (resource : ResourceSpec) : Address :=
  .resource resource.resourceType resource.name

def argument? (resource : ResourceSpec) (name : String) : Option ExprNode :=
  resource.arguments.lookup name

/-- Whether `argument` is set to a direct reference to `path` of `address`. -/
def argumentRefersTo (resource : ResourceSpec) (argument : String) (address : Address)
    (path : List String) : Bool :=
  match resource.argument? argument with
  | some expression => expression.refersTo address path
  | none => false

/-- Whether `argument` is set to the known literal `value`. -/
def argumentIs [ToValue α] (resource : ResourceSpec) (argument : String) (value : α) : Bool :=
  match resource.argument? argument with
  | some (.literal known) => known == toValue value
  | _ => false

end ResourceSpec

namespace DataSourceSpec

def address (dataSource : DataSourceSpec) : Address :=
  .dataSource dataSource.dataSourceType dataSource.name

def argument? (dataSource : DataSourceSpec) (name : String) : Option ExprNode :=
  dataSource.arguments.lookup name

end DataSourceSpec

namespace Graph

def resource? (graph : Graph) (address : Address) : Option ResourceSpec :=
  graph.resources.find? (·.address == address)

def dataSource? (graph : Graph) (address : Address) : Option DataSourceSpec :=
  graph.dataSources.find? (·.address == address)

def output? (graph : Graph) (name : String) : Option OutputSpec :=
  graph.outputs.lookup name

/-- Every resource of one provider type. -/
def resourcesOfType (graph : Graph) (resourceType : String) : List ResourceSpec :=
  graph.resources.filter (·.resourceType == resourceType)

/-- Every node address in the graph. -/
def addresses (graph : Graph) : List Address :=
  graph.resources.map ResourceSpec.address ++ graph.dataSources.map DataSourceSpec.address

end Graph

/-- A pure infrastructure program: a state transformer over `Graph`. -/
structure Infra (α : Type) where
  run : Graph → α × Graph

namespace Infra

instance : Monad Infra where
  pure value := ⟨fun graph => (value, graph)⟩
  bind program next := ⟨fun graph =>
    let (value, graph) := program.run graph
    (next value).run graph⟩

private def modify (transform : Graph → Graph) : Infra Unit :=
  ⟨fun graph => ((), transform graph)⟩

private def replaceOrAppend [BEq κ] (key : κ) (value : α) : List (κ × α) → List (κ × α)
  | [] => [(key, value)]
  | (existing, current) :: rest =>
    if existing == key then (existing, value) :: rest
    else (existing, current) :: replaceOrAppend key value rest

end Infra

/-- Record a provider requirement without configuring the provider. Generated adapters call
this so that using a resource is enough to pin its provider. -/
def requireProvider (localName : Identifier) (source version : String) : Infra Unit :=
  Infra.modify fun graph =>
    { graph with
      requiredProviders := Infra.replaceOrAppend localName.raw ⟨source, version⟩ graph.requiredProviders }

/-- Configure a provider, optionally under an alias, and return a typed handle. -/
def addProvider (provider : Identifier) (source version : String) (alias : Option Identifier)
    (values : InputObject) : Infra (Provider p) :=
  ⟨fun graph =>
    let address := match alias with
      | none => provider.raw
      | some name => provider.raw ++ "." ++ name.raw
    (providerHandle address,
      { graph with
        requiredProviders := Infra.replaceOrAppend provider.raw ⟨source, version⟩ graph.requiredProviders
        providerConfigs := graph.providerConfigs ++ [⟨provider.raw, alias.map Identifier.raw, values.fields⟩] })⟩

/-- Append a managed resource and return its typed handle. -/
def addResource (options : ResourceOptions p) (resourceType name : Identifier)
    (values : InputObject) : Infra (Resource r) :=
  ⟨fun graph =>
    let spec : ResourceSpec :=
      { resourceType := resourceType.raw
        name := name.raw
        arguments := values.fields
        dependsOn := options.explicitDependencies
        provider := options.provider
        lifecycle := options.lifecycle }
    (resourceHandle spec.address, { graph with resources := graph.resources ++ [spec] })⟩

/-- Append a data source and return its typed handle. -/
def addDataSource (options : DataSourceOptions p) (dataSourceType name : Identifier)
    (values : InputObject) : Infra (DataSource r) :=
  ⟨fun graph =>
    let spec : DataSourceSpec :=
      { dataSourceType := dataSourceType.raw
        name := name.raw
        arguments := values.fields
        dependsOn := options.explicitDependencies
        provider := options.provider }
    (dataSourceHandle spec.address, { graph with dataSources := graph.dataSources ++ [spec] })⟩

private def outputWithSensitivity [OutputValue v] (sensitive : Bool) (name : String) (value : v) :
    Infra Unit :=
  Infra.modify fun graph =>
    { graph with
      outputs := Infra.replaceOrAppend name ⟨OutputValue.outputValueNode value, sensitive⟩ graph.outputs }

/-- Declare a root output. The name is validated at compile time. -/
def output [OutputValue v] (name : String) (value : v)
    (_valid : validIdentifier name = true := by decide) : Infra Unit :=
  outputWithSensitivity false name value

/-- Declare a root output that OpenTofu must redact. -/
def sensitiveOutput [OutputValue v] (name : String) (value : v)
    (_valid : validIdentifier name = true := by decide) : Infra Unit :=
  outputWithSensitivity true name value

/-- Declare that the node now at `destination` previously lived at `origin`, lowering to an
OpenTofu `moved` block so the refactor does not replace the object. -/
def moved (origin : Address) [Dependable h] (destination : h) : Infra Unit :=
  Infra.modify fun graph =>
    { graph with moves := graph.moves ++ [⟨origin, Dependable.dependencyAddress destination⟩] }

/-- Run `program` and also return the managed resources it added, in creation order. This is
the primitive for scope combinators that post-process everything created inside a block, for
example assigning it all to a cloud project. -/
def Infra.capture (program : Infra α) : Infra (α × List ResourceSpec) :=
  ⟨fun graph =>
    let (value, next) := program.run graph
    ((value, next.resources.drop graph.resources.length), next)⟩

/-- A symbolic attribute of an already-added resource. The caller chooses the result type, so
this is an escape hatch like `unsafeCall`; generated handles are the typed path. -/
def ResourceSpec.unsafeAttr (resource : ResourceSpec) (path : List String) : Expr α :=
  ⟨.resourceAttribute resource.address path⟩

/-- Run a program against the empty graph and keep only the graph. Pure. -/
def buildGraph (program : Infra α) : Graph :=
  (program.run {}).2

end Inframe
