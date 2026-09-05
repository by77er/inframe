import Inframe.Builder

/-!
# Remote state

`terraform_remote_state` belongs to OpenTofu's builtin `terraform` provider, which never appears
in a provider schema, so no generated adapter can offer it. Cross-stack composition needs it
all the same: this module adds the data source directly to the graph, one constructor per
backend, and exposes the other stack's outputs as typed inputs.

```lean
let platform ← RemoteState.read "platform" (.gcs "acme-state" (prefix_ := "platform"))
let cluster : Input String := platform.output "cluster_endpoint"
```

No provider is required or configured for it, and the builtin provider needs no
`required_providers` entry.
-/

namespace Inframe

/-- Where another stack keeps its state: the backend `type` and the same `config` keys that
stack's `[stacks.<name>.backend]` table (or `terraform { backend "…" {} }` block) uses. Keep
credentials out of it, as with any backend configuration; the backend's environment
variables are read at plan time. -/
structure RemoteBackend where
  type : String
  config : List (String × ExprNode)
  deriving Repr

namespace RemoteBackend

private def known (value : String) : ExprNode :=
  .literal (.string value)

private def optional (name : String) : Option String → List (String × ExprNode)
  | none => []
  | some value => [(name, known value)]

/-- A state file on the local filesystem (the `local` backend; `local` is a Lean keyword). -/
def localFile (path : String) : RemoteBackend :=
  ⟨"local", [("path", known path)]⟩

/-- Google Cloud Storage: `bucket` plus the optional object `prefix`. -/
def gcs (bucket : String) (prefix_ : Option String := none) : RemoteBackend :=
  ⟨"gcs", ("bucket", known bucket) :: optional "prefix" prefix_⟩

/-- Amazon S3 (and compatible stores through `endpoint`): `bucket`, object `key`, `region`. -/
def s3 (bucket key region : String) (endpoint : Option String := none) : RemoteBackend :=
  ⟨"s3", [("bucket", known bucket), ("key", known key), ("region", known region)]
    ++ optional "endpoint" endpoint⟩

/-- Azure Blob Storage. -/
def azurerm (resourceGroupName storageAccountName containerName key : String) : RemoteBackend :=
  ⟨"azurerm",
    [ ("resource_group_name", known resourceGroupName)
    , ("storage_account_name", known storageAccountName)
    , ("container_name", known containerName)
    , ("key", known key) ]⟩

/-- An HTTP state server; credentials come from `TF_HTTP_USERNAME`/`TF_HTTP_PASSWORD`. -/
def http (address : String) : RemoteBackend :=
  ⟨"http", [("address", known address)]⟩

/-- A Kubernetes secret named `tfstate-<suffix>`. -/
def kubernetes (secretSuffix : String) (namespace_ : Option String := none) : RemoteBackend :=
  ⟨"kubernetes", ("secret_suffix", known secretSuffix) :: optional "namespace" namespace_⟩

/-- A Consul KV path. -/
def consul (path : String) (address : Option String := none) : RemoteBackend :=
  ⟨"consul", ("path", known path) :: optional "address" address⟩

/-- Any other backend, with its configuration as known values. -/
def other (type : String) (config : List (String × Value))
    (_valid : validIdentifier type = true := by valid_identifier) : RemoteBackend :=
  ⟨type, config.map fun (key, value) => (key, .literal value)⟩

end RemoteBackend

/-- Phantom type tagging `terraform_remote_state` handles. -/
inductive RemoteStateSource

/-- Another stack's state, read through `terraform_remote_state`. -/
structure RemoteState where
  dataSource : DataSource RemoteStateSource
  /-- Every root output of the other stack, as one symbolic object. -/
  outputs : Input (Map Value)

instance : Dependable RemoteState := ⟨fun state => state.dataSource.address⟩

namespace RemoteState

/-- The arguments of the data source for `backend` and `workspace`. -/
def arguments (backend : RemoteBackend) (workspace : Option String) : InputObject :=
  InputObject.ofList <|
    [("backend", .literal (.string backend.type)), ("config", .object backend.config)]
      ++ match workspace with
        | none => []
        | some name => [("workspace", .literal (.string name))]

/-- Add `data.terraform_remote_state.<name>` reading the state kept in `backend` (of the
default workspace unless `workspace` is given) and return its outputs. The logical name is
validated at compile time. -/
def read (name : String) (backend : RemoteBackend) (workspace : Option String := none)
    (options : DataSourceOptions Unit := dataSourceOptions)
    (valid : validIdentifier name = true := by valid_identifier) : Infra RemoteState := do
  let handle ← addDataSource options (Identifier.mk "terraform_remote_state") ⟨name, valid⟩
    (arguments backend workspace)
  pure { dataSource := handle, outputs := dataSourceAttr handle ["outputs"] }

/-- One output of the other stack, `data.terraform_remote_state.<name>.outputs.<output>`. The
type is the caller's claim about what the other stack exports; the output name is validated
at compile time. -/
def output (state : RemoteState) (output : String)
    (valid : validIdentifier output = true := by valid_identifier) : Input α :=
  let _ := valid
  dataSourceAttr state.dataSource ["outputs", output]

/-- Like `output`, but `default` when the other stack does not export it (OpenTofu's `try`),
so a consumer can be planned before its producer exports a new value. -/
def outputOr [IntoInput v α] (state : RemoteState) (output : String) (default : v)
    (valid : validIdentifier output = true := by valid_identifier) : Input α :=
  unsafeCall "try" [unsafeArgument (state.output output valid (α := α)), unsafeArgument default]

@[simp] theorem run_read_fst (name : String) (backend : RemoteBackend) (workspace : Option String)
    (options : DataSourceOptions Unit) (valid : validIdentifier name = true) (graph : Graph) :
    ((read name backend workspace options valid).run graph).1
      = { dataSource :=
            dataSourceHandle (r := RemoteStateSource) (Identifier.mk "terraform_remote_state")
              ⟨name, valid⟩
          outputs := dataSourceAttr
            (dataSourceHandle (r := RemoteStateSource) (Identifier.mk "terraform_remote_state")
              ⟨name, valid⟩)
            ["outputs"] } := rfl

@[simp] theorem run_read_resources (name : String) (backend : RemoteBackend)
    (workspace : Option String) (options : DataSourceOptions Unit)
    (valid : validIdentifier name = true) (graph : Graph) :
    ((read name backend workspace options valid).run graph).2.resources = graph.resources := rfl

end RemoteState

end Inframe
