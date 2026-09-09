import Inframe.Builder

/-!
# Graph IR encoding

The single place where Graph IR 1.0 wire tags are assigned. `renderGraph` prints the document
that `inframe build` reads.
-/

namespace Inframe

open Lean (Json)

namespace ExprNode

private def tagged (kind : String) (fields : List (String × Json)) : Json :=
  Json.mkObj (("kind", .str kind) :: fields)

private def reference (kind : String) (address : Address) (path : List String) : Json :=
  tagged kind [("address", .str address.toString), ("path", .arr (path.map Json.str).toArray)]

mutual
  def toJson : ExprNode → Json
    | .literal value => tagged "literal" [("value", value.toJson)]
    | .resourceAttribute address path => reference "resource_attr" address path
    | .dataSourceAttribute address path => reference "data_source_attr" address path
    | .array items => tagged "array" [("items", .arr (toJsonList items).toArray)]
    | .object fields => tagged "object" [("fields", Json.mkObj (toJsonFields fields))]
    | .index collection key =>
        tagged "index" [("collection", toJson collection), ("key", toJson key)]
    | .attribute of name => tagged "attribute" [("of", toJson of), ("name", .str name)]
    | .splat of => tagged "splat" [("of", toJson of)]
    | .conditional condition whenTrue whenFalse =>
        tagged "conditional"
          [("condition", toJson condition), ("when_true", toJson whenTrue),
            ("when_false", toJson whenFalse)]
    | .function name args =>
        tagged "function" [("name", .str name), ("args", .arr (toJsonList args).toArray)]
    | .template parts => tagged "template" [("parts", .arr (toJsonParts parts).toArray)]
    | .secretEnvironment name => tagged "secret_env" [("name", .str name)]
  termination_by structural x => x
  def toJsonList : List ExprNode → List Json
    | [] => []
    | item :: rest => toJson item :: toJsonList rest
  termination_by structural x => x
  def toJsonFields : List (String × ExprNode) → List (String × Json)
    | [] => []
    | (key, value) :: rest => (key, toJson value) :: toJsonFields rest
  termination_by structural x => x
  def toJsonParts : List TemplatePart → List Json
    | [] => []
    | .text value :: rest => tagged "literal" [("value", .str value)] :: toJsonParts rest
    | .interpolation expression :: rest =>
        tagged "interpolation" [("expression", toJson expression)] :: toJsonParts rest
  termination_by structural x => x
end

instance : Lean.ToJson ExprNode := ⟨toJson⟩

end ExprNode

private def optionalField (name : String) (value : Option Json) : List (String × Json) :=
  match value with
  | none => []
  | some json => [(name, json)]

private def addressList (addresses : List Address) : Json :=
  .arr (addresses.map fun address => Json.str address.toString).toArray

def encodeArguments (arguments : List (String × ExprNode)) : Json :=
  Json.mkObj (arguments.map fun (key, value) => (key, value.toJson))

def encodeProviderRequirement (requirement : ProviderRequirement) : Json :=
  Json.mkObj [("source", .str requirement.source), ("version", .str requirement.version)]

def encodeProviderConfig (config : ProviderConfigSpec) : Json :=
  Json.mkObj <|
    optionalField "alias" (config.alias.map Json.str)
      ++ [("provider", .str config.provider), ("arguments", encodeArguments config.arguments)]

def encodeLifecycle (lifecycle : LifecycleOptions) : Json :=
  Json.mkObj
    [ ("create_before_destroy", .bool lifecycle.createBeforeDestroy)
    , ("prevent_destroy", .bool lifecycle.preventDestroy)
    , ("ignore_changes", .arr (lifecycle.ignoreChanges.map Json.str).toArray)
    , ("replace_triggered_by", addressList lifecycle.replaceTriggeredBy) ]

def encodeResource (resource : ResourceSpec) : Json :=
  Json.mkObj <|
    optionalField "lifecycle" (resource.lifecycle.map encodeLifecycle)
      ++ optionalField "provider" (resource.provider.map Json.str)
      ++ [ ("type", .str resource.resourceType)
         , ("name", .str resource.name)
         , ("arguments", encodeArguments resource.arguments)
         , ("depends_on", addressList resource.dependsOn) ]

def encodeDataSource (dataSource : DataSourceSpec) : Json :=
  Json.mkObj <|
    optionalField "provider" (dataSource.provider.map Json.str)
      ++ [ ("type", .str dataSource.dataSourceType)
         , ("name", .str dataSource.name)
         , ("arguments", encodeArguments dataSource.arguments)
         , ("depends_on", addressList dataSource.dependsOn) ]

def encodeOutput (output : OutputSpec) : Json :=
  Json.mkObj [("value", output.value.toJson), ("sensitive", .bool output.sensitive)]

def encodeMove (move : MoveSpec) : Json :=
  Json.mkObj [("from", .str move.origin.toString), ("to", .str move.destination.toString)]

def encodeImport (import_ : ImportSpec) : Json :=
  Json.mkObj [("to", .str import_.destination.toString), ("id", .str import_.id)]

/-- Encode a completed graph as a Graph IR 1.0 document. -/
def encodeGraph (graph : Graph) : Json :=
  Json.mkObj <|
    [ ("format_version", .str "1.0")
    , ("required_providers",
        Json.mkObj (graph.requiredProviders.map fun (name, requirement) =>
          (name, encodeProviderRequirement requirement)))
    , ("provider_configs", .arr (graph.providerConfigs.map encodeProviderConfig).toArray)
    , ("resources", .arr (graph.resources.map encodeResource).toArray)
    , ("data_sources", .arr (graph.dataSources.map encodeDataSource).toArray)
    , ("outputs", Json.mkObj (graph.outputs.map fun (name, output) => (name, encodeOutput output)))
    , ("moves", .arr (graph.moves.map encodeMove).toArray) ]
    ++ match graph.imports with
      | [] => []
      | imports => [("imports", Json.arr (imports.map encodeImport).toArray)]

instance : Lean.ToJson Graph := ⟨encodeGraph⟩

/-- Build a program and render its Graph IR document as one line of compact JSON. Compact
rather than pretty-printed on purpose: `Lean.Json.pretty` goes through `Std.Format`, whose
recursion has overflowed the stack of compiled executables on graphs with a few dozen
resources and multi-kilobyte literals, while `compress` is a loop. The CLI reads either. -/
def renderGraph (program : Infra α) : String :=
  (encodeGraph (buildGraph program)).compress

/-- Pretty-printed Graph IR, for reading by eye. Not for a stack's `main`; see `renderGraph`. -/
def renderGraphPretty (program : Infra α) : String :=
  (encodeGraph (buildGraph program)).pretty

/-- Print a program's Graph IR document on stdout, the whole of a stack's `main`:

```lean
def main : IO Unit := emitGraph infrastructure
```

The document is rendered compactly, written to the stream with `putStr`, and flushed, so no
stack `main` has to know which printing path survives a large graph. -/
def emitGraph (program : Infra α) : IO Unit := do
  let stdout ← IO.getStdout
  stdout.putStr (renderGraph program)
  stdout.putStr "\n"
  stdout.flush

end Inframe
