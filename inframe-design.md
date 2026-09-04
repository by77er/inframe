# Design: Pure Functional Infrastructure Frontend for OpenTofu

**Status:** Living architecture and implementation design  
**Project name:** Inframe (`inframe`)  
**Primary implementation language:** Rust  
**Initial frontend language:** PureScript  
**Initial provider target:** `digitalocean/digitalocean`  
**Execution backend:** OpenTofu  
**Initial provider version for reproducible E2E tests:** `2.100.0`  
**Document date:** 2026-09-03

---

## 1. Executive summary

`inframe` is a typed, code-generated frontend for OpenTofu.

It deliberately does **not** replace OpenTofu's planner, provider protocol, resource lifecycle implementation, state format, locking semantics, or provider ecosystem. It replaces HCL as the primary authoring interface and makes desired infrastructure a **first-class immutable graph value**.

The central programming model is:

```text
Config
  │
  ▼
pure frontend program
  │
  ▼
Canonical Graph IR
  │
  ▼
Rust validation + lowering
  │
  ▼
*.tofu.json
  │
  ▼
OpenTofu
  │
  ├── dependency planning
  ├── refresh
  ├── state
  ├── provider execution
  └── apply/destroy
```

Provider APIs are not handwritten. OpenTofu provider schemas are treated as an IDL:

```text
provider binary
     │
     ▼
tofu providers schema -json
     │
     ▼
Provider Schema IR
     │
     ▼
language-neutral Binding Model
     │
     ├──► PureScript emitter
     ├──► TypeScript emitter       (future)
     ├──► Rust emitter             (future)
     └──► other emitters           (future)
```

The initial PureScript SDK constructs infrastructure **purely**. Creating a resource:

- does not contact OpenTofu;
- does not register against a running engine;
- does not perform cloud API calls;
- does not perform filesystem I/O.

It only adds a `ResourceSpec` to a pure builder and returns a typed symbolic handle whose attributes are unresolved expressions such as `Expr String`.

A small outer effect writes the resulting Graph IR. The Rust CLI validates and lowers that IR into deterministic `.tofu.json`, then offers convenient wrappers for `tofu init`, `validate`, `plan`, `apply`, `destroy`, `show`, and `output`.

The most important architecture decision is:

> **Use one language-neutral Graph IR and one set of graph semantics, but do not use one shared cross-language graph-construction runtime.**

Each language gets a thin, idiomatic native library that produces the same canonical IR.

An optional remote-state service can be implemented separately by satisfying OpenTofu's standard HTTP backend protocol. It stores OpenTofu state as an opaque blob, adds locking, immutable version history, authentication, audit, and recovery, and does not invent a second state format.

---

# 2. Motivation

OpenTofu/Terraform already solve the operationally difficult parts of infrastructure-as-code:

- provider discovery and installation;
- provider schemas;
- resource CRUD;
- refresh;
- dependency planning;
- state;
- import;
- moves;
- replacement behavior;
- remote backends;
- locking;
- plan/apply workflows;
- a very large provider ecosystem.

The problem this project addresses is the **authoring abstraction**.

Terraform modules are useful, but rich abstractions tend to collapse into a serialization-shaped interface:

```text
variables -> resources -> outputs
```

As a module grows, domain concepts are often represented as:

- large object variables;
- many optional properties;
- maps of maps;
- `for_each`;
- conditionals;
- flattened outputs;
- indirect conventions that are difficult to express statically.

A general-purpose language gives substantially higher-fidelity abstraction.

Pulumi takes that route, but its ordinary resource constructors perform resource-registration effects during execution. The desired graph is therefore implicit in execution against the Pulumi runtime.

This project instead wants the desired graph itself to be an ordinary value:

```text
Config -> InfrastructureGraph
```

That graph can be:

- unit-tested;
- property-tested;
- transformed;
- inspected;
- serialized;
- visualized;
- statically analyzed;
- subjected to policy;
- compared;
- documented;
- lowered to more than one backend in the future.

OpenTofu remains the production execution engine.

---

# 3. Design principles

## 3.1 Infrastructure construction is pure

This should be a normal valid architecture:

```purescript
infrastructure :: Config -> Graph
```

An ergonomic builder may use PureScript `do` notation, but the builder itself is implemented with a pure state/writer abstraction, not `Effect` or `Aff`.

The resource graph must exist completely before OpenTofu is invoked.

## 3.2 OpenTofu owns operational state

`inframe` must not implement its own resource-state engine.

OpenTofu remains responsible for:

- associating logical resource addresses with remote objects;
- reading prior state;
- refreshing remote state;
- calculating diffs;
- creating plans;
- calling providers;
- writing the new state;
- coordinating backend locking.

`inframe` should treat raw state as an OpenTofu implementation concern.

When machine-readable state or plan information is needed, use supported OpenTofu interfaces such as:

```bash
tofu show -json
tofu output -json
tofu state ...
```

rather than depending on undocumented state internals.

## 3.3 One graph abstraction; native graph builders

The semantics and serialized representation of a graph are shared across all languages.

Graph construction is language-native.

Bad architecture:

```text
PureScript ──RPC──► shared graph daemon
TypeScript ──RPC──► shared graph daemon
Rust       ──RPC──► shared graph daemon
```

Preferred architecture:

```text
PureScript SDK ──┐
TypeScript SDK ──┼──► canonical Graph IR JSON ──► Rust validator/lowerer
Rust SDK       ──┘
```

This preserves:

- PureScript purity;
- static type checking;
- native compiler diagnostics;
- native debugging;
- native IDE support;
- ordinary local unit tests;
- no mandatory daemon;
- no graph-registration effects.

The Rust implementation is the **reference validator and lowerer**, not the only implementation capable of constructing Graph IR.

## 3.4 Provider schemas are the IDL

Generated provider contracts come from:

```bash
tofu providers schema -json
```

No ordinary provider resource API should be maintained manually.

Provider upgrades should look like:

```text
update pinned provider version
       │
       ▼
regenerate bindings
       │
       ▼
review generated diff
       │
       ▼
compile frontend
       │
       ▼
tofu validate
       │
       ▼
tofu plan
```

## 3.5 Narrow but deep modules

The implementation should be decomposed into modules that each own a complete conceptual responsibility.

A good module has:

- a small public surface;
- strong internal invariants;
- a clear input/output contract;
- minimal knowledge of adjacent stages;
- tests that do not require the whole system.

Avoid:

- giant "generator" crates containing every concern;
- dozens of tiny files that require reading the whole repository to understand one concept.

## 3.6 Determinism

Given:

- the same OpenTofu version;
- the same provider binary/version;
- the same generator version;

binding generation should be byte-for-byte deterministic.

Given the same Graph IR, `.tofu.json` lowering should also be byte-for-byte deterministic.

This matters for:

- reviewable diffs;
- caching;
- reproducible CI;
- code generation in source control;
- schema compatibility testing.

## 3.7 Stable resource identity is explicit

OpenTofu resource address is part of logical resource identity.

Do not generate addresses from builder insertion order.

Good:

```purescript
Tag.create "integration_tag" ...
```

which deterministically becomes:

```text
digitalocean_tag.integration_tag
```

Bad:

```text
digitalocean_tag.resource_00017
```

where a refactor changes the address and accidentally causes replacement.

---

# 4. Goals

Version 1 should:

1. Acquire a provider schema automatically through OpenTofu.
2. Normalize that schema into a stable internal model.
3. Generate a regular importable PureScript provider library.
4. Support provider configuration.
5. Support managed resources.
6. Support data sources.
7. Model required, optional, computed, sensitive, and optional+computed attributes.
8. Model nested blocks and nested attributes.
9. Return typed symbolic resource/data-source handles.
10. Build a concrete infrastructure graph purely.
11. Serialize a versioned, language-neutral Graph IR.
12. Validate Graph IR in Rust.
13. Lower Graph IR to deterministic `.tofu.json`.
14. Infer normal resource dependencies through symbolic references.
15. Support explicit `depends_on`.
16. Support an initial useful subset of lifecycle meta-arguments.
17. Preserve provider source/version requirements.
18. Wrap common OpenTofu commands conveniently.
19. Test schema generation against `digitalocean/digitalocean`.
20. Test generated PureScript compilation.
21. Test `.tofu.json` with `tofu validate`.
22. Run a credentialed DigitalOcean `plan -> apply -> read -> destroy` test using a low/no-cost resource such as a tag.
23. Optionally support a first-party remote-state HTTP backend service without changing OpenTofu's state format.

---

# 5. Non-goals for version 1

Do not initially implement:

- a replacement IaC state engine;
- a Terraform/OpenTofu provider protocol implementation;
- a Pulumi-compatible runtime;
- dynamic graph topology based on unknown provider results;
- arbitrary evaluation of unresolved OpenTofu values inside PureScript;
- arbitrary `Expr a -> Expr b` host-language functions;
- complete static reproduction of provider validation rules;
- Terraform module binding generation;
- every OpenTofu meta-argument;
- provisioners unless an E2E case requires them;
- an HCL parser;
- a custom secret store;
- a long-running graph daemon;
- a language server;
- a remote execution/TACOS platform;
- a provider registry;
- perfect semantic typing of every stringly provider identifier.

These can be future extensions.

---

## 5.1 OpenTofu language compatibility boundary

Inframe is not a general alternative syntax for the entire OpenTofu language.
It constructs a finite, explicit graph and delegates planning and execution of
that graph to OpenTofu. Version 1 supports only the semantics represented by
Graph IR and implemented by both its validator and lowerer.

The graph's cardinality is fixed while the host-language program runs:

- host-language iteration may create one graph node per element when the
  collection is known during graph construction;
- an unresolved `Expr (Array a)` cannot determine how many resources exist;
- native OpenTofu `count` and `for_each` are not represented;
- autoscaling performed by a provider-managed resource remains supported
  because it is an argument of one explicit graph node, not dynamic graph
  topology.

Related boundaries follow from that decision:

- configuration parameters are ordinary typed host-language values; Inframe
  does not expose general OpenTofu input-variable declarations;
- composition uses host-language functions and packages, not OpenTofu module
  blocks or module binding generation;
- host-language conditions may include or omit nodes only when the condition is
  known while constructing the graph;
- `ifThenElse` represents an unresolved value expression, but cannot select
  whether a resource exists;
- nested blocks may be constructed from known host-language collections, but
  OpenTofu `dynamic` blocks are not represented;
- ephemeral resources and provisioners are not represented.

The supported resource meta-arguments are an explicit subset: provider
selection, `depends_on`, `create_before_destroy`, `prevent_destroy`,
`ignore_changes`, and `replace_triggered_by`. Replacement triggers accept only
managed resources, matching OpenTofu's semantics. Other lifecycle features,
including `enabled`, `destroy`, preconditions, and postconditions, are not
currently modeled.

New OpenTofu language features do not become implicitly supported when the
OpenTofu binary is upgraded. Each feature must be added deliberately to Graph
IR, validation, lowering, frontend types, and compatibility tests. Features
that require an unknown value to change graph topology are outside this
architecture unless that finite-graph invariant is reconsidered explicitly.

---

# 6. Three distinct intermediate representations

A major maintainability decision is to **not reuse one representation for every stage**.

Use three principal IRs.

---

## 6.1 Provider Schema IR

Purpose:

> Faithfully normalize the machine-readable OpenTofu provider schema into a representation suitable for generator logic.

Conceptually:

```rust
pub struct ProviderSchema {
    pub source: ProviderSource,
    pub version: ProviderVersion,
    pub provider_config: BlockSchema,
    pub resources: BTreeMap<ResourceTypeName, ResourceSchema>,
    pub data_sources: BTreeMap<DataSourceTypeName, DataSourceSchema>,
}

pub struct BlockSchema {
    pub attributes: BTreeMap<String, AttributeSchema>,
    pub blocks: BTreeMap<String, NestedBlockSchema>,
}

pub struct AttributeSchema {
    pub ty: SchemaType,
    pub required: bool,
    pub optional: bool,
    pub computed: bool,
    pub sensitive: bool,
    pub description: Option<String>,
}
```

The exact raw schema structure should be hidden behind normalization.

This IR should preserve provider/OpenTofu semantics and avoid language-specific concepts.

It must not contain:

- PureScript module names;
- PureScript reserved-word decisions;
- generated filenames;
- Graph IR nodes;
- OpenTofu subprocess behavior.

---

## 6.2 Binding Model

Purpose:

> Convert provider schema semantics into the language-independent API surface that emitters render.

Conceptually:

```rust
pub struct BindingPackage {
    pub provider: BindingProvider,
    pub resources: Vec<BindingResource>,
    pub data_sources: Vec<BindingDataSource>,
    pub types: Vec<BindingTypeDef>,
}

pub struct BindingResource {
    pub provider_type: String,     // digitalocean_droplet
    pub public_name: String,       // Droplet
    pub required_inputs: Vec<BindingField>,
    pub optional_inputs: Vec<BindingField>,
    pub outputs: Vec<BindingField>,
    pub nested_types: Vec<BindingTypeDef>,
}
```

A target-independent type algebra:

```rust
pub enum BindingType {
    String,
    Bool,
    Integer,
    Number,
    List(Box<BindingType>),
    Set(Box<BindingType>),
    Map(Box<BindingType>),
    Object(Vec<BindingField>),
    Tuple(Vec<BindingType>),
    Dynamic,
}
```

This phase decides:

- whether an attribute is an input;
- whether it is an output;
- whether it appears in both;
- required vs optional constructor shape;
- nested type factoring;
- provider-native resource names;
- stable language-neutral public names;
- collisions at the semantic model level.

No emitter should rediscover provider-schema semantics.

This is a particularly important test seam.

---

## 6.3 Graph IR

Purpose:

> Represent one concrete desired infrastructure configuration produced by a frontend program.

Conceptually:

```rust
pub struct GraphDocument {
    pub format_version: GraphFormatVersion,
    pub required_providers: BTreeMap<String, ProviderRequirement>,
    pub provider_configs: Vec<ProviderConfig>,
    pub resources: Vec<ResourceSpec>,
    pub data_sources: Vec<DataSourceSpec>,
    pub outputs: BTreeMap<String, Expr>,
    pub moves: Vec<MoveSpec>,
}
```

Graph IR is independent from:

- PureScript;
- provider schema parsing;
- provider code generation.

It should be serialized as versioned JSON initially.

Generate and commit a JSON Schema for Graph IR from the Rust model, e.g. with `schemars`.

The Graph IR JSON Schema becomes a useful cross-language compatibility artifact.

---

# 7. Rust workspace decomposition

Recommended initial workspace:

```text
/
├── Cargo.toml
├── crates/
│   ├── provider-schema/
│   ├── binding-model/
│   ├── graph-ir/
│   ├── emit-purescript/
│   ├── opentofu/
│   ├── remote-state/          # optional after core E2E works
│   └── cli/
├── purescript/
│   ├── graph-core/
│   ├── .generated/digitalocean/ # ignored generated adapter
│   └── integration-digitalocean/
├── fixtures/
│   ├── provider-schema/
│   ├── graph-ir/
│   └── tofu-json/
└── tests/
```

This is intentionally a modest number of crates.

---

## 7.1 `provider-schema`

**Owns:** provider schema acquisition and normalization.

Suggested internal modules:

```text
provider-schema/
├── src/
│   ├── raw.rs
│   ├── model.rs
│   ├── normalize.rs
│   ├── acquire.rs
│   └── error.rs
```

### Responsibilities

- Deserialize `tofu providers schema -json`.
- Check supported schema `format_version`.
- Preserve unknown compatible fields where practical.
- Normalize OpenTofu cty/type representations.
- Normalize nested block/attribute shape.
- Preserve:
  - required;
  - optional;
  - computed;
  - sensitive;
  - descriptions.
- Acquire schemas through a temporary OpenTofu bootstrap directory.
- Return a clean `ProviderSchema`.

### Public API

Keep it small:

```rust
pub fn acquire_provider_schema(
    tofu: &TofuBinary,
    request: ProviderRequest,
) -> Result<ProviderSchema>;

pub fn normalize_schema(
    raw: RawProviderSchemas,
    request: &ProviderRequest,
) -> Result<ProviderSchema>;
```

### Must not

- render PureScript;
- know Graph IR;
- run plans or applies;
- implement the CLI;
- contain DigitalOcean-specific logic.

---

## 7.2 `binding-model`

**Owns:** translating Provider Schema IR into generated API semantics.

Suggested internal modules:

```text
binding-model/
├── src/
│   ├── model.rs
│   ├── derive.rs
│   ├── naming.rs
│   ├── types.rs
│   └── error.rs
```

### Responsibilities

- `ProviderSchema -> BindingPackage`.
- Determine input/output surfaces.
- Factor nested reusable types.
- Create stable neutral names.
- Detect collisions.
- Preserve documentation.
- Record provider-native names separately from public names.
- Mark identifiers that need target-language escaping.

### Why this is separate

Without this layer, each emitter will eventually contain subtly different interpretations of:

- optional+computed;
- nested blocks;
- map/set semantics;
- names;
- fields exposed on handles.

That would make multi-language support difficult to reason about.

---

## 7.3 `graph-ir`

**Owns:** canonical graph semantics and serialization.

Suggested modules:

```text
graph-ir/
├── src/
│   ├── document.rs
│   ├── address.rs
│   ├── expr.rs
│   ├── resource.rs
│   ├── provider.rs
│   ├── lifecycle.rs
│   ├── validate.rs
│   ├── canonical_json.rs
│   └── version.rs
```

### Responsibilities

- resource addresses;
- data-source addresses;
- provider references;
- expressions;
- graph-local outputs;
- explicit dependencies;
- lifecycle settings;
- moved-resource declarations;
- versioning;
- canonical serialization;
- structural validation;
- duplicate-address detection;
- reference validation;
- extraction of inferred graph edges from expressions.

### Critical invariant

**References are the source of truth for inferred dataflow dependencies.**

Do not maintain a duplicated explicit DAG for ordinary resource references.

This:

```text
digitalocean_droplet.web.tags
    contains
Ref(digitalocean_tag.app.id)
```

is sufficient.

A graph visualization can derive:

```text
digitalocean_tag.app -> digitalocean_droplet.web
```

by walking expression trees.

Only `depends_on` relationships that are not represented by dataflow need an explicit edge.

### Must have no subprocess code

This crate should be easy to:

- fuzz;
- property-test;
- use in standalone tooling.

---

## 7.4 `emit-purescript`

**Owns:** rendering a `BindingPackage` into an importable PureScript library.

Suggested modules:

```text
emit-purescript/
├── src/
│   ├── lib.rs
│   ├── names.rs
│   ├── types.rs
│   ├── module.rs
│   ├── resource.rs
│   ├── data_source.rs
│   ├── provider.rs
│   ├── docs.rs
│   └── render.rs
```

### Responsibilities

- PureScript-safe naming.
- Module decomposition.
- Type rendering.
- Imports.
- Required-argument constructors.
- Optional-argument setters.
- Resource/data-source handle generation.
- Provider configuration.
- Nested block builders.
- Documentation comments.
- Package metadata.

### Must not

- parse raw OpenTofu JSON;
- spawn OpenTofu;
- contain graph lowering;
- know remote state;
- contain provider-specific hacks unless expressed as explicit compatibility rules.

Future emitters become peers:

```text
emit-typescript/
emit-rust/
emit-kotlin/
...
```

They consume exactly the same `BindingPackage`.

---

## 7.5 `opentofu`

**Owns:** lowering Graph IR and executing the OpenTofu CLI.

Keep pure and effectful responsibilities separated internally:

```text
opentofu/
├── src/
│   ├── lower/
│   ├── runner/
│   ├── workspace/
│   └── version.rs
```

### `lower`

Pure:

```rust
pub fn lower(graph: &GraphDocument) -> Result<TofuJsonDocument>;
```

No processes. No filesystem.

### `runner`

Thin process adapter:

```rust
pub trait OpenTofuRunner {
    fn init(&self, workspace: &Workspace, args: &[OsString]) -> Result<Exit>;
    fn validate(&self, workspace: &Workspace, args: &[OsString]) -> Result<Exit>;
    fn plan(&self, workspace: &Workspace, args: &[OsString]) -> Result<Exit>;
    fn apply(&self, workspace: &Workspace, args: &[OsString]) -> Result<Exit>;
    fn destroy(&self, workspace: &Workspace, args: &[OsString]) -> Result<Exit>;
    fn show_json(&self, workspace: &Workspace, args: &[OsString]) -> Result<Value>;
    fn output_json(&self, workspace: &Workspace, args: &[OsString]) -> Result<Value>;
}
```

Use `std::process::Command` directly, not a shell.

Preserve:

- exit status;
- stdout/stderr streaming;
- environment;
- Ctrl-C behavior where possible.

### `workspace`

Owns generated OpenTofu working directories:

```text
.inframe/
└── stacks/
    └── prod/
        ├── main.tofu.json
        ├── backend.tofu.json
        ├── .terraform/
        └── .terraform.lock.hcl
```

The workspace layer can cache provider initialization safely.

---

## 7.6 `cli`

**Owns:** orchestration and UX only.

Suggested command tree:

```text
inframe
├── provider
│   ├── generate
│   └── inspect
├── graph
│   ├── validate
│   ├── inspect
│   └── render
├── init
├── validate
├── plan
├── apply
├── destroy
├── show
├── output
└── state
    ├── history      # when first-party remote state is configured
    ├── lock
    └── restore
```

The CLI should contain very little domain logic.

If a command has complex behavior, that behavior belongs in a lower crate.

---

# 8. PureScript graph runtime

The term "runtime" here means a **library representation**, not a running service.

Recommended PureScript package split:

```text
Inframe.Core
Inframe.Builder
Inframe.Json
```

Generated provider libraries import only stable public APIs from these modules.

---

## 8.1 Core types

Conceptually:

```purescript
newtype Resource r = Resource ResourceAddress
newtype DataSource r = DataSource DataSourceAddress

newtype Expr a = Expr ExprNode

data Input a
  = Known a
  | Computed (Expr a)
```

Constructors for low-level address/reference values should generally be hidden from provider users.

Generated resources may define phantom resource tags:

```purescript
data TagResource
data DropletResource
data VpcResource
```

A generated handle might be:

```purescript
type Tag =
  { resource :: Resource TagResource
  , id :: Expr String
  , name :: Expr String
  , totalResourceCount :: Expr Int
  }
```

`tag.id` is not a DigitalOcean ID yet.

It is a symbolic expression:

```text
ResourceAttr(
    address = digitalocean_tag.integration_tag,
    path = ["id"]
)
```

---

## 8.2 Pure builder

A builder can use a pure state representation:

```purescript
newtype Infra a = Infra (State GraphBuilderState a)
```

or an equivalent representation with explicit error accumulation.

Example:

```purescript
program :: Infra Unit
program = do
  tag <-
    Tag.args
      { name: lit "inframe-e2e" }
      # Tag.create "integration_tag"

  info <-
    TagData.args
      { name: tag.name }
      # TagData.read "integration_tag_read"

  output "tag_id" info.id
```

Despite the `do` notation:

- no network call occurs;
- no OpenTofu process is running;
- no resource is registered externally.

The computation only creates a graph value.

```purescript
buildGraph :: Infra a -> Either BuildError Graph
```

is pure.

---

## 8.3 Dependency representation

Dependencies should be expressed primarily through typed symbolic values.

Example:

```purescript
droplet <-
  Droplet.args
    { name: lit "web"
    , image: lit "ubuntu-24-04-x64"
    , region: lit "nyc3"
    , size: lit "s-1vcpu-1gb"
    }
  # Droplet.tags (array [ tag.id ])
  # Droplet.create "web"
```

The `tag.id` expression points to:

```text
digitalocean_tag.integration_tag.id
```

Therefore the resulting `.tofu.json` contains a normal OpenTofu reference and OpenTofu derives the dependency.

No separate `dependsOn tag` is necessary.

Explicit dependency API exists for non-dataflow relationships:

```purescript
withDependsOn
  [ resourceRef bootstrapThing ]
```

---

# 9. Expression algebra

This is the most important semantic boundary in the frontend.

---

## 9.1 Known versus unresolved values

A known frontend value:

```purescript
Array String
```

can be manipulated with arbitrary PureScript.

An unresolved OpenTofu value:

```purescript
Expr (Array String)
```

cannot.

These two are intentionally different.

Similarly:

```text
Array (Expr SubnetId)
```

means PureScript knows how many symbolic subnet values exist.

```text
Expr (Array SubnetId)
```

means the collection itself is unresolved until OpenTofu evaluation.

Graph topology may depend on the first form.

It must not depend on the second form.

---

## 9.2 No arbitrary host-language mapping over `Expr`

Do not expose:

```purescript
mapExpr :: (a -> b) -> Expr a -> Expr b
```

An arbitrary PureScript closure cannot be serialized into OpenTofu's expression language.

Instead expose a serializable expression algebra.

Initial Graph IR expression nodes:

```rust
pub enum Expr {
    Literal(Value),

    ResourceAttr {
        address: ResourceAddress,
        path: Vec<TraversalStep>,
    },

    DataSourceAttr {
        address: DataSourceAddress,
        path: Vec<TraversalStep>,
    },

    Array(Vec<Expr>),

    Object(BTreeMap<String, Expr>),

    Index {
        collection: Box<Expr>,
        key: Box<Expr>,
    },

    Conditional {
        condition: Box<Expr>,
        when_true: Box<Expr>,
        when_false: Box<Expr>,
    },

    Function {
        name: String,
        args: Vec<Expr>,
    },

    Template {
        parts: Vec<TemplatePart>,
    },
}
```

Later additions can include:

- operators;
- `for` expressions;
- splats;
- collection conversions;
- provider-defined functions if useful.

The PureScript API wraps these with typed functions such as:

```purescript
index
conditional
concat
join
format
length
lookup
interpolate
```

Only operations that the lowerer knows how to serialize are allowed on unresolved expressions.

---

## 9.3 Unsafe escape hatch

Eventually a raw expression may be necessary.

Make it explicit:

```purescript
unsafeRawTofuExpr :: String -> Expr a
```

It must not be the ordinary path.

The Graph IR node should preserve the fact that this expression was unsafe so validators/policy can flag it.

---

# 10. Generated PureScript API shape

PureScript does not make hundreds of optional record fields especially pleasant.

Avoid generating a record where callers must write `Nothing` repeatedly.

Prefer:

- one record of required inputs;
- an opaque `Args`;
- pure setters for optional inputs.

Example generated API:

```purescript
module DigitalOcean.Resource.Droplet where

type Required =
  { name :: Input String
  , region :: Input String
  , size :: Input String
  , image :: Input String
  }

newtype Args = Args InternalArgs

args :: Required -> Args

monitoring :: Input Boolean -> Args -> Args
backups :: Input Boolean -> Args -> Args
tags :: Input (Array String) -> Args -> Args
vpcUuid :: Input String -> Args -> Args

create
  :: ResourceName
  -> Args
  -> Infra Droplet
```

Usage:

```purescript
web <-
  Droplet.args
    { name: lit "web-1"
    , region: lit "nyc3"
    , size: lit "s-1vcpu-1gb"
    , image: lit "ubuntu-24-04-x64"
    }
  # Droplet.monitoring (lit true)
  # Droplet.tags (array [ appTag.id ])
  # Droplet.create "web"
```

Nested blocks should receive generated typed builders rather than raw JSON.

---

# 11. Generated package layout

For DigitalOcean:

```text
purescript/.generated/digitalocean/
├── spago.yaml
├── src/
│   └── DigitalOcean/
│       ├── Provider.purs
│       ├── Resource/
│       │   ├── Tag.purs
│       │   ├── Droplet.purs
│       │   ├── Vpc.purs
│       │   └── ...
│       ├── Data/
│       │   ├── Tag.purs
│       │   ├── Region.purs
│       │   └── ...
│       └── Internal/
│           └── Generated.purs
└── provider-manifest.json
```

`provider-manifest.json` should include:

```json
{
  "provider_source": "digitalocean/digitalocean",
  "provider_version": "2.100.0",
  "schema_sha256": "...",
  "generator_version": "...",
  "binding_model_version": "...",
  "graph_ir_version": "1.0"
}
```

This makes codegen provenance explicit.

---

# 12. Provider schema acquisition

For:

```text
source  = digitalocean/digitalocean
version = 2.100.0
```

the generator should:

1. create a temporary directory;
2. write a minimal OpenTofu configuration containing `required_providers`;
3. run:

   ```bash
   tofu init -backend=false
   ```

4. run:

   ```bash
   tofu providers schema -json
   ```

5. record:
   - OpenTofu version;
   - provider source;
   - resolved provider version;
   - lockfile checksum information where useful;
6. normalize the returned schema;
7. generate bindings.

The project declares the generation inputs once:

```toml
[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"
module_root = "DigitalOcean"
```

The normal command uses the conventional output directory derived from the
project's PureScript directory and provider name:

```bash
inframe provider generate
```

Generated constructors bake the source and version into the adapter. Creating
a resource with the default provider therefore records its requirement lazily;
explicit provider configuration is needed only for arguments, aliases, or
typed provider selection. Version pinning is required for reproducible
generation. CLI flags remain available as overrides.

---

# 13. Graph IR wire format

Version 1 should use ordinary JSON.

The file should be boring, diffable, inspectable, and easy for other languages to emit.

Example:

```json
{
  "format_version": "1.0",
  "required_providers": {
    "digitalocean": {
      "source": "digitalocean/digitalocean",
      "version": "= 2.100.0"
    }
  },
  "provider_configs": [
    {
      "provider": "digitalocean",
      "alias": null,
      "arguments": {}
    }
  ],
  "resources": [
    {
      "type": "digitalocean_tag",
      "name": "integration_tag",
      "arguments": {
        "name": {
          "kind": "literal",
          "value": "inframe-e2e"
        }
      },
      "depends_on": []
    }
  ],
  "data_sources": [
    {
      "type": "digitalocean_tag",
      "name": "integration_tag_read",
      "arguments": {
        "name": {
          "kind": "resource_attr",
          "address": "digitalocean_tag.integration_tag",
          "path": ["name"]
        }
      }
    }
  ],
  "outputs": {
    "tag_id": {
      "kind": "data_source_attr",
      "address": "data.digitalocean_tag.integration_tag_read",
      "path": ["id"]
    }
  }
}
```

## Important decision

Do not store an inferred edge separately for:

```text
digitalocean_tag.integration_tag.name
```

The reference is the source of truth.

A `dependencies(graph)` function derives graph edges by walking expressions.

---

# 14. OpenTofu JSON lowering

Lowering is a pure Rust transformation:

```rust
pub fn lower(graph: &GraphDocument) -> Result<serde_json::Value>;
```

OpenTofu JSON configuration is deliberately designed for machine-generated configuration.

The lowerer converts Graph IR symbolic expressions to OpenTofu expression syntax.

For example:

```text
ResourceAttr(
  digitalocean_tag.integration_tag,
  ["name"]
)
```

lowers in an expression position to:

```json
"${digitalocean_tag.integration_tag.name}"
```

A JSON string consisting of one interpolation can evaluate directly to the referenced non-string value, which is important for generic typed expressions.

The lowerer, not frontend SDKs, owns expression escaping.

## Lowering invariants

It must:

- sort keys deterministically;
- emit `.tofu.json`;
- reject duplicate resource/data-source addresses;
- reject invalid graph-local references;
- correctly distinguish resource vs data-source traversals;
- preserve literal JSON values where possible;
- correctly render nested blocks;
- correctly render provider meta-arguments;
- render explicit `depends_on` using OpenTofu's JSON special form;
- lower supported lifecycle options;
- preserve required provider source/version information;
- never inspect or mutate OpenTofu state.

---

# 15. Graph config versus deployment/run config

Do not put every operational setting into Graph IR.

A useful separation is:

```text
Graph IR
    desired infrastructure

Run Config
    how this graph is executed
```

Graph IR contains:

- provider requirements;
- provider configurations that are semantically part of infrastructure;
- resources;
- data sources;
- outputs.

Run configuration contains:

- stack name;
- generated workspace directory;
- backend type/address;
- remote-state namespace;
- OpenTofu binary path;
- CLI arguments;
- non-secret runtime settings.

Secrets should normally come from process environment, cloud-native credential discovery, or a secret manager.

This separation means switching:

```text
local backend -> S3 backend -> first-party HTTP backend
```

does not modify the desired infrastructure graph.

---

# 16. OpenTofu convenience wrappers

The same Rust binary should make the generated configuration convenient to execute.

Suggested commands:

```bash
# provider binding generation from inframe.toml
inframe provider generate

# graph-only operations
inframe graph validate --stack prod
inframe graph inspect --stack prod

# lower without executing
inframe render \
  --graph build/prod.graph.json \
  --out .inframe/stacks/prod/main.tofu.json

# lower + OpenTofu
inframe init     --stack prod --graph build/prod.graph.json
inframe validate --stack prod --graph build/prod.graph.json
inframe plan     --stack prod --graph build/prod.graph.json
inframe apply    --stack prod --graph build/prod.graph.json
inframe destroy  --stack prod --graph build/prod.graph.json
inframe show     --stack prod
inframe output   --stack prod
```

Raw OpenTofu arguments pass after `--`:

```bash
inframe plan \
  --stack prod \
  --graph build/prod.graph.json \
  -- -out=plan.bin
```

Also support stdin:

```bash
spago run --main Infra.Prod \
  | inframe plan --stack prod --graph -
```

This is a good language-neutral contract:

> A frontend program may emit Graph IR JSON to stdout.

The CLI does not need to know how to build/run PureScript.

---

# 17. Stable identity and moves

Resource address stability is one of the few OpenTofu state concerns that intentionally leaks into the frontend.

Example original address:

```text
digitalocean_tag.integration_tag
```

If source refactoring changes that to:

```text
digitalocean_tag.e2e_tag
```

OpenTofu may interpret it as destroy/create unless told it is a move.

Therefore Graph IR should eventually support:

```rust
pub struct MoveSpec {
    pub from: Address,
    pub to: Address,
}
```

which lowers to an OpenTofu `moved` block.

Do not derive logical names from:

- source line number;
- call order;
- random UUID;
- generated sequence number.

---

# 18. Remote state service

A first-party remote state system fits this architecture well, but it should be a **separate optional service**.

The fundamental rule:

> **Do not invent a new state format. Store the OpenTofu state payload as an opaque blob and satisfy OpenTofu's HTTP backend protocol.**

OpenTofu's HTTP backend supports:

- `GET` to fetch state;
- `POST` by default to update state;
- `DELETE` to purge state;
- `LOCK`;
- `UNLOCK`;
- lock-conflict responses using HTTP 423 or 409.

That is enough for a useful state service without modifying OpenTofu.

---

## 18.1 State-service architecture

```text
OpenTofu HTTP backend client
          │
          ▼
    HTTP protocol adapter
          │
          ▼
      State domain
     ┌────┼─────────┐
     │    │         │
     ▼    ▼         ▼
 versions locks    audit
     │    │
     └────┼───────────────┐
          ▼               ▼
      metadata DB      blob store
```

Suggested Rust decomposition if/when added:

```text
remote-state/
├── src/
│   ├── protocol.rs
│   ├── domain.rs
│   ├── store.rs
│   ├── postgres.rs
│   ├── blob.rs
│   ├── auth.rs
│   ├── audit.rs
│   └── server.rs
```

Keep protocol adaptation separate from state invariants.

---

## 18.2 Namespace model

A state key could be:

```text
organization / project / stack
```

Example:

```text
acme / edge-platform / prod
```

HTTP endpoint:

```text
/v1/state/acme/edge-platform/prod
```

The state service treats this as a logical state object.

The OpenTofu backend address can point directly at this endpoint.

---

## 18.3 State storage model

Every successful state write creates an immutable version.

Conceptually:

```text
State
  key
  current_version_id

StateVersion
  id
  state_key
  sequence
  sha256
  byte_length
  blob_location
  created_at
  actor
  run_id
  previous_version_id

StateLock
  state_key
  lock_id
  raw_lock_info
  acquired_at
  actor

AuditEvent
  id
  state_key
  operation
  actor
  timestamp
  metadata
```

The state blob itself should be opaque bytes.

The service does not need to parse it to fulfill the backend contract.

---

## 18.4 Atomic write algorithm

On state update:

1. authenticate caller;
2. resolve the state namespace;
3. check authorization;
4. verify lock ownership if locking is required;
5. compute hash of received bytes;
6. write immutable blob/version;
7. atomically update the current-version pointer;
8. append audit event;
9. return success.

If using object storage plus PostgreSQL:

```text
write object first
    ↓
DB transaction:
  insert version
  update current pointer
  write audit
    ↓
commit
```

A failed DB transaction can leave an unreachable object that a garbage collector later removes.

The current-state pointer must never refer to an incompletely written blob.

For a simpler V1 implementation, storing state bytes directly in PostgreSQL is acceptable and gives straightforward transactional semantics. Object storage can be introduced once real state sizes or cost justify it.

---

## 18.5 Lock semantics

Locking is mandatory for the first-party service.

OpenTofu sends lock information in the request body and expects the conflicting lock information back when a lock cannot be acquired.

Important decision:

> **Do not use a silently expiring lock TTL by default.**

The HTTP backend protocol does not provide a standard heartbeat from a long-running `apply`.

If the server expires a lock after 15 minutes while a 40-minute apply is still running, a second writer could begin.

Safer behavior:

- lock persists until `UNLOCK`;
- stale locks require explicit force-unlock;
- force-unlock is separately authorized;
- every force-unlock is audited.

A future enhanced CLI can offer an administrator-friendly force-unlock workflow.

---

## 18.6 Lock enforcement on writes

If a state namespace is configured to require locking:

- `POST` without the active lock ID is rejected;
- `POST` with a different lock ID is rejected;
- `POST` with the matching lock ID succeeds.

This prevents accidental clients from bypassing the normal OpenTofu lock discipline.

Do not rely on optimistic versioning alone because the standard HTTP backend contract is lock-oriented and does not provide a complete compare-and-swap version exchange.

---

## 18.7 Version history and recovery

The state service should retain prior immutable versions.

Useful administrative API:

```text
GET  /v1/admin/state/.../versions
GET  /v1/admin/state/.../versions/:id
POST /v1/admin/state/.../restore/:id
```

Restore should not overwrite history.

It should:

1. select an old version;
2. create a new version whose bytes equal the selected old snapshot;
3. make that new version current;
4. record the restore action.

That gives an append-only history:

```text
v17
v18
v19
v20 = restore(v17)
```

rather than mutating history.

---

## 18.8 DELETE semantics

OpenTofu's HTTP backend supports `DELETE`.

Internally, prefer a tombstone rather than physical immediate deletion.

The service can return "no current state" after deletion while retaining recoverable version history according to retention policy.

Permanent purge should be a separate administrative action.

---

## 18.9 Encryption

Treat all state as sensitive.

There are two independent useful encryption layers:

### Client-side OpenTofu state encryption

Modern OpenTofu supports state/plan encryption.

If enabled, the remote-state server receives ciphertext and remains unable to inspect sensitive state contents.

This is highly desirable.

### Server-side storage encryption

The service should still encrypt blobs at rest, preferably using envelope encryption backed by a cloud KMS.

These layers protect against different failures.

The service should not require parsing cleartext state.

Hashing/version IDs should work against the stored opaque payload.

---

## 18.10 Authentication

OpenTofu's HTTP backend supports:

- HTTP basic authentication;
- custom request headers;
- mTLS.

Avoid embedding long-lived secrets in generated backend configuration because backend configuration can be copied into OpenTofu local metadata and plan files.

For the first-party service, the simplest safe integration is:

```text
TF_HTTP_USERNAME
TF_HTTP_PASSWORD
```

where the password is an API token obtained by the user/CI.

For CI, mTLS or short-lived tokens can be supported later.

The `inframe` CLI may eventually provide:

```bash
inframe state login
```

which obtains/stores a credential outside the OpenTofu configuration and supplies it to the child process environment.

---

## 18.11 Authorization model

At minimum:

```text
state:read
state:write
state:lock
state:unlock
state:history
state:restore
state:purge
```

scoped to:

```text
organization/project/stack
```

A normal deployment role should not have:

```text
state:restore
state:purge
force-unlock
```

unless explicitly needed.

---

## 18.12 Audit

Audit metadata should include:

- actor;
- state key;
- operation;
- timestamp;
- lock ID;
- resulting version;
- prior version;
- payload hash;
- request/run ID;
- client metadata if available.

Do **not** put raw state content into audit logs.

---

## 18.13 Remote state is not remote execution

Keep these separate.

Version 1 state service:

```text
local tofu process
      │
      ▼
remote state service
```

A TACOS-like platform:

```text
client
  │
  ▼
remote run scheduler
  │
  ▼
remote tofu worker
  │
  ▼
state + policy + approvals + logs
```

Remote execution is a much larger product and should not leak into the initial state backend design.

---

## 18.14 Cross-stack outputs

OpenTofu's built-in `terraform_remote_state` data source can consume root outputs from another state.

However, a reader with enough access to retrieve outputs through that backend necessarily has access to the full state snapshot at the storage layer.

Therefore:

- support `terraform_remote_state` if users want it;
- do not make it the only long-term cross-stack interface;
- consider explicit publication of non-sensitive shared values to a separate store for least-privilege architectures.

Do not force the state service to parse outputs, especially if client-side state encryption is enabled.

---

# 19. Backend configuration generation

Remote backend configuration belongs in **run config**, not Graph IR.

Example generated `.tofu.json`:

```json
{
  "terraform": {
    "backend": {
      "http": {}
    }
  }
}
```

Then the CLI supplies addresses and credentials through environment:

```text
TF_HTTP_ADDRESS
TF_HTTP_LOCK_ADDRESS
TF_HTTP_UNLOCK_ADDRESS
TF_HTTP_USERNAME
TF_HTTP_PASSWORD
```

This minimizes backend-secret persistence.

A non-secret project config might contain:

```toml
[state]
kind = "http"
address = "https://state.example.com/v1/state/acme/platform/prod"
```

The CLI maps that into environment for OpenTofu.

---

# 20. Testing strategy

The project should test each seam independently before the real DigitalOcean apply.

---

## 20.1 Provider schema fixture tests

Acquire and commit a normalized fixture for:

```text
digitalocean/digitalocean 2.100.0
```

Tests:

- raw schema parses;
- normalized schema is deterministic;
- known resources exist;
- `digitalocean_tag.name` is a required string input;
- known computed outputs appear correctly;
- nested block examples normalize correctly.

Do not make most generator unit tests require network access.

---

## 20.2 Binding Model tests

Given a small synthetic Provider Schema IR, assert exact `BindingPackage`.

Cover:

- required;
- optional;
- computed;
- optional+computed;
- sensitive;
- list;
- set;
- map;
- object;
- nested block;
- name collisions;
- reserved words.

These tests should not render source code.

---

## 20.3 PureScript emitter golden tests

Render small fixture bindings and compare against committed `.purs` golden files.

Then compile generated modules with `spago build`.

The golden tests catch formatting/shape regressions.

Compilation catches invalid PureScript.

---

## 20.4 Graph IR tests

Unit and property tests:

- duplicate address rejection;
- invalid local reference rejection;
- canonical ordering;
- JSON round-trip;
- dependency extraction;
- move validation;
- lifecycle validation.

Fuzz Graph IR deserialization and validation.

---

### 20.4.1 User infrastructure policy tests

Infrastructure tests should primarily enforce cross-cutting invariants rather
than repeat individual resource declarations. A policy evaluates the completed
graph, reports every violating address, and does not contact a provider.

For example, a repository can build its production graph and assert that every
DigitalOcean database's `private_network_uuid` is a symbolic reference to a
managed `digitalocean_vpc` resource. The README contains a runnable version of
that test using today's Graph IR. A native policy API should eventually make
the same rule reusable and provide structured diagnostics.

Policies over symbolic expressions need three outcomes: pass, violation, and
unknown. Unknown rules can be evaluated against machine-readable OpenTofu plan
JSON once provider defaults and computed values are available.

---

## 20.5 OpenTofu lowering golden tests

For small Graph IR fixtures, compare exact `.tofu.json`.

Then execute:

```bash
tofu init -backend=false
tofu validate
```

against the generated configuration.

This is the key semantic integration test for lowering.

---

## 20.6 Provider codegen smoke test

Fresh temporary environment:

1. generate DigitalOcean schema;
2. generate PureScript provider library;
3. build the generated package;
4. compile the integration program;
5. emit Graph IR;
6. lower it;
7. `tofu init -backend=false`;
8. `tofu validate`.

This requires no cloud mutation.

---

## 20.7 Credentialed DigitalOcean E2E

Use an isolated DigitalOcean account/project token in CI.

Prefer a no-cost/minimal-risk resource.

Initial test:

```text
digitalocean_tag
```

Flow:

1. generate bindings from provider `2.100.0`;
2. compile PureScript frontend;
3. construct a uniquely named tag;
4. optionally read it back through a generated data source;
5. emit an output using a symbolic resource/data reference;
6. serialize Graph IR;
7. lower to `.tofu.json`;
8. `tofu init`;
9. `tofu plan`;
10. `tofu apply -auto-approve`;
11. `tofu output -json`;
12. assert output shape/value;
13. `tofu plan` again and assert no changes;
14. `tofu destroy -auto-approve`;
15. ensure cleanup runs even if intermediate assertions fail.

Never use a Droplet as the first E2E test if a free metadata/tag resource can prove the same integration.

---

## 20.8 Remote state E2E

Once the remote-state service exists:

1. start the server with ephemeral PostgreSQL/SQLite storage;
2. configure OpenTofu HTTP backend;
3. run apply;
4. assert the server holds one current version;
5. run a no-op apply;
6. inspect history;
7. simulate a second lock and assert conflict;
8. destroy;
9. test historical restore;
10. ensure OpenTofu reads the restored current state.

Also test process failure while a lock is held and explicit force-unlock recovery.

---

# 21. Error design

Each module should own typed errors.

Examples:

```text
SchemaAcquireError
SchemaNormalizeError
BindingDeriveError
PureScriptEmitError
GraphValidationError
TofuLowerError
TofuProcessError
RemoteStateError
```

Do not flatten all errors to strings early.

CLI rendering can add contextual chains:

```text
failed to generate DigitalOcean bindings
  caused by: failed to normalize resource digitalocean_foo
  caused by: unsupported nested type shape ...
```

Generated-code errors should include provider-native paths:

```text
digitalocean_droplet.backup_policy.weekday
```

whenever possible.

---

# 22. Compatibility and versioning

Version separately:

1. CLI version.
2. Provider schema normalization version.
3. Binding Model version.
4. Graph IR wire-format version.
5. PureScript core-library version.
6. Generated provider version.

Graph IR uses semantic compatibility rules:

```text
1.x:
  backward-compatible readers where possible

2.0:
  required for breaking wire/semantic changes
```

Generated provider manifests record all relevant versions.

The Rust CLI should reject unsupported Graph IR major versions rather than guessing.

---

# 23. Security posture

Important rules:

- Treat Graph IR as potentially sensitive because literal provider configuration may contain sensitive values.
- Prefer provider credentials from environment rather than graph literals.
- Never log provider tokens.
- Treat OpenTofu state as highly sensitive.
- Prefer remote state for teams.
- Prefer client-side OpenTofu state encryption where feasible.
- Use TLS for remote state.
- Keep state write/restore/purge permissions distinct.
- Never log raw state blobs.
- Keep generated temporary directories private to the user.
- Avoid putting backend credentials into generated `.tofu.json` or command-line arguments.
- Sanitize subprocess diagnostic logging.

---

# 24. Implementation milestones

## Milestone 0 — repository skeleton

Deliver:

- Rust workspace;
- CI;
- formatting/linting;
- PureScript workspace;
- fixture layout;
- architecture README.

No provider integration yet.

## Milestone 1 — provider schema acquisition

Deliver:

- OpenTofu binary wrapper sufficient for schema acquisition;
- temporary bootstrap config;
- raw schema parsing;
- normalized Provider Schema IR;
- DigitalOcean `2.100.0` fixture.

Acceptance:

```text
inframe provider inspect digitalocean/digitalocean@2.100.0
```

prints normalized resource/data-source counts and deterministic hash.

## Milestone 2 — Binding Model

Deliver:

- schema -> language-neutral bindings;
- type algebra;
- naming;
- unit tests.

No PureScript rendering yet.

## Milestone 3 — Graph IR

Deliver:

- canonical model;
- expression algebra;
- validation;
- JSON serialization;
- JSON Schema;
- dependency extraction.

## Milestone 4 — PureScript core

Deliver:

- `Expr a`;
- `Input a`;
- `Resource r`;
- `DataSource r`;
- pure `Infra a`;
- graph serialization;
- basic expression combinators.

Handwrite one tiny resource test fixture before codegen.

## Milestone 5 — PureScript generator

Deliver:

- provider module;
- resource modules;
- data-source modules;
- required args;
- optional setters;
- handles;
- nested blocks;
- generated package manifest.

Acceptance:

DigitalOcean generated package builds.

## Milestone 6 — OpenTofu lowering

Deliver:

- Graph IR -> `.tofu.json`;
- provider requirements;
- resources;
- data;
- outputs;
- symbolic references;
- `depends_on`;
- initial lifecycle options.

Acceptance:

generated DigitalOcean integration graph passes `tofu validate`.

## Milestone 7 — CLI workflow

Deliver:

```text
provider generate
graph validate
render
init
validate
plan
apply
destroy
show
output
```

with `--graph -` stdin support and raw `--` pass-through arguments.

## Milestone 8 — DigitalOcean E2E

Deliver credentialed tag lifecycle test:

```text
generate -> compile -> graph -> lower -> plan -> apply -> no-op plan -> destroy
```

## Milestone 9 — optional remote state

Deliver:

- HTTP backend server;
- locking;
- version history;
- auth;
- audit;
- restore;
- E2E with OpenTofu HTTP backend.

---

# 25. Important implementation constraints for Codex

When implementing:

1. Do not shortcut provider bindings by hand-coding DigitalOcean resources.
2. DigitalOcean is an integration target, not a special case.
3. Keep provider schema parsing and language emission in different crates.
4. Keep Graph IR independent of provider schema IR.
5. Keep OpenTofu lowering pure and separate from process execution.
6. Do not implement cloud state management.
7. Do not let PureScript resource creation invoke an effect.
8. Do not maintain a duplicated inferred dependency DAG; derive it from `Expr` references.
9. Make resource addresses explicit and deterministic.
10. Prefer small stable public APIs over exposing internal structs directly.
11. Add tests at every representation boundary.
12. Commit representative fixtures and golden outputs.
13. Keep generated provider code deterministic.
14. Do not use arbitrary raw OpenTofu expressions unless clearly marked unsafe.
15. Do not begin remote execution/TACOS work while remote state is still being built.
16. Do not make the Rust CLI a required in-process dependency of frontend graph construction.

---

# 26. Open design questions

These should be resolved during implementation with small prototypes rather than speculation.

## 26.1 PureScript optional-field ergonomics

Likely default:

```text
required record + opaque Args + optional setters
```

Prototype this against `digitalocean_droplet`, which has enough fields to expose ergonomic problems.

## 26.2 Refined identifier types

Generated raw provider types may initially keep:

```purescript
Expr String
```

for provider string fields.

A future annotation layer could refine:

```text
DropletId
VpcId
TagId
Arn a
```

The raw provider schema usually does not contain enough semantic metadata to infer all of these reliably.

## 26.3 Terraform/OpenTofu functions

Start with a small manually modeled set required by tests.

Do not prematurely generate the entire function universe.

## 26.4 `for_each` and `count`

The frontend expands known host-language collections into explicit resources.
Native `for_each` and `count` are deliberately unsupported because an
OpenTofu-computed collection would make graph cardinality unknown during graph
construction. Adding either requires an explicit revision of the finite-graph
boundary in section 5.1, not just a lowering shortcut.

## 26.5 Module support

OpenTofu modules are deliberately unsupported; host-language functions and
packages are Inframe's composition mechanism. Any future module-introspection
feature would require a separately designed schema source and compatibility
contract. It must not be mixed into provider-schema normalization.

## 26.6 Graph IR format

JSON is correct for V1.

If size/performance becomes material, a binary representation can be introduced later while retaining JSON as the debug/interchange format.

---

# 27. Why this architecture is worth preserving

The project should remain conceptually:

```text
     FRONTEND LANGUAGE

arbitrary pure computation over
known configuration
        │
        ▼
typed symbolic infrastructure
        │
        ▼
canonical graph value


       COMPILER BOUNDARY

validate
normalize
lower
        │
        ▼
OpenTofu JSON


       OPERATIONAL ENGINE

OpenTofu
  ├── plan
  ├── state
  ├── locking
  ├── provider execution
  └── reconciliation
```

The frontend is free to be expressive because unknown infrastructure values remain symbolic.

The backend remains reliable because OpenTofu still sees an ordinary declarative configuration before planning.

This preserves the strongest properties of both models:

- real programming-language abstraction;
- a first-class immutable graph;
- explicit effect boundaries;
- static planning;
- Terraform/OpenTofu provider maturity;
- standard OpenTofu state;
- no custom cloud lifecycle engine.

---

# 28. References consulted for this design

- OpenTofu JSON Configuration Syntax  
  https://opentofu.org/docs/language/syntax/json/

- OpenTofu provider schema command  
  https://opentofu.org/docs/cli/commands/providers/schema/

- OpenTofu backends: state storage and locking  
  https://opentofu.org/docs/language/state/backends/

- OpenTofu HTTP backend  
  https://opentofu.org/docs/language/settings/backends/http/

- OpenTofu remote state  
  https://opentofu.org/docs/language/state/remote/

- OpenTofu state and plan encryption  
  https://opentofu.org/docs/language/state/encryption/

- OpenTofu `terraform_remote_state` data source  
  https://opentofu.org/docs/language/state/remote-state-data/

- DigitalOcean provider registry  
  https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs

At the time of writing, the Terraform Registry listed `digitalocean/digitalocean` version `2.100.0` as the latest release (published 2026-08-18).
