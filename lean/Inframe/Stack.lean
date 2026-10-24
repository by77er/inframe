import Inframe.Json

/-!
# Stacks and their exports

A stack's public interface is a structure of inputs. The producing program returns it, every
field becomes one root output, and a consuming stack gets the same structure back with each
field a reference into the producer's state. Consumers are therefore plain functions of the
exports: a test passes literals, one combined graph passes the producer's handles
(`platform.program >>= apps`), and a split deployment reads them through remote state, all
without changing the consumer.

```lean
structure Platform where
  clusterEndpoint : Input String       -- the output `cluster_endpoint`
  vpcId : Input String
  deriving StackExports

def platform : Stack Platform :=
  .define "platform" do
    …
    pure { clusterEndpoint := cluster.endpoint, vpcId := network.id }

def apps (p : Platform) : Infra Unit := …
def appsStack : Infra Unit := do apps (← platform.read)
```

The producer's `main` is `platform.emit`. A renamed or retyped field breaks the consumer's build
instead of its plan.

A `Stack` names a stack of `inframe.toml`, and that stack's `[stacks.<name>.backend]` is the only
place its backend is written: the graph records a stack reference and the CLI fills in the
backend (and refuses a name the project does not declare). One stack is one state, so a stack
deployed per environment is one project stack per environment:

```lean
def Environment.platformStack : Environment → Identifier    -- `platform-dev`, `platform-prod`
def platform (env : Environment) : Stack Platform := .define env.platformStack.raw (platformFor env)
def apps (env : Environment) : Infra Unit := do appsFor env (← (platform env).read)
```
-/

namespace Inframe

/-- An exported value held by a sensitive output: published with `sensitiveOutput`, and
redacted by OpenTofu in the consumer too. -/
structure Sensitive (α : Type) where
  input : Input α

/-- `Input.orDefault` for a sensitive value; the result stays sensitive. -/
def Sensitive.orDefault [IntoInput v α] (value : Sensitive α) (default : v) : Sensitive α :=
  ⟨value.input.orDefault default⟩

/-- The field types an exports structure may have: how a value is published, and the value a
consumer sees given the reference to its output. -/
class ExportField (τ : Type) where
  sensitive : Bool
  node : τ → ExprNode
  ofNode : ExprNode → τ

instance : ExportField (Input α) := ⟨false, inputNode, unsafeInput⟩
instance : ExportField (Sensitive α) := ⟨true, fun value => inputNode value.input, fun node => ⟨unsafeInput node⟩⟩

/-- One root output of a stack. -/
structure ExportedOutput where
  name : Identifier
  sensitive : Bool
  value : ExprNode

def ExportedOutput.of [ExportField τ] (name : Identifier) (value : τ) : ExportedOutput :=
  ⟨name, ExportField.sensitive τ, ExportField.node value⟩

/-- A structure that is a stack's exports. `deriving StackExports` writes the instance: output
names are the field names in snake case, so `outputs` and `ofOutputs` cannot disagree. -/
class StackExports (σ : Type) where
  /-- Every output, in field order. -/
  outputs : σ → List ExportedOutput
  /-- The exports, given the reference to each output by name. -/
  ofOutputs : (String → ExprNode) → σ

/-- Declare `outputs` as root outputs. Explicit recursion, so proofs can follow it. -/
def publishOutputs : List ExportedOutput → Infra Unit
  | [] => pure ()
  | exported :: rest => do
    if exported.sensitive then
      sensitiveOutput exported.name.raw (unsafeInput exported.value : Input Value) exported.name.valid
    else
      output exported.name.raw (unsafeInput exported.value : Input Value) exported.name.valid
    publishOutputs rest

/-- Declare every field of `exports` as a root output. -/
def publish [StackExports σ] (exports : σ) : Infra Unit :=
  publishOutputs (StackExports.outputs exports)

@[simp] theorem run_publishOutputs_resources (outputs : List ExportedOutput) (graph : Graph) :
    ((publishOutputs outputs).run graph).2.resources = graph.resources := by
  induction outputs generalizing graph with
  | nil => rfl
  | cons exported rest ih =>
    simp only [publishOutputs]
    split <;> simp [ih]

@[simp] theorem run_publish_resources [StackExports σ] (exports : σ) (graph : Graph) :
    ((publish exports).run graph).2.resources = graph.resources :=
  run_publishOutputs_resources _ graph

/-- The project's stack `name` (its `[stacks.<name>]` table), whose program returns exports
`σ`. -/
structure Stack (σ : Type) where
  name : Identifier
  program : Infra σ

namespace Stack

/-- The project's stack `name`, built by `program`. -/
def define (name : String) (program : Infra σ)
    (valid : validIdentifier name = true := by valid_identifier) : Stack σ :=
  ⟨⟨name, valid⟩, program⟩

/-- The producer's whole program: build the stack and publish its exports. -/
def publishing [StackExports σ] (stack : Stack σ) : Infra Unit :=
  stack.program >>= publish

/-- The producer's Graph IR. -/
def graph [StackExports σ] (stack : Stack σ) : Graph :=
  buildGraph stack.publishing

/-- The producer's `main`: print its Graph IR. -/
def emit [StackExports σ] (stack : Stack σ) : IO Unit :=
  emitGraph stack.publishing

/-- The reference to the output `name` of `stack`'s state. -/
def outputReference (stack : Stack σ) (name : String) : ExprNode :=
  .dataSourceAttribute (.dataSource "terraform_remote_state" stack.name.raw) ["outputs", name]

/-- Read `stack`'s exports from its state through the stack reference
`data.terraform_remote_state.<stack name>`; the CLI supplies the backend. -/
def read [StackExports σ] (stack : Stack σ) : Infra σ := do
  let _ : DataSource Unit ← addStackReference stack.name
  pure (StackExports.ofOutputs stack.outputReference)

@[simp] theorem run_read_fst [StackExports σ] (stack : Stack σ) (graph : Graph) :
    (stack.read.run graph).1 = StackExports.ofOutputs stack.outputReference := rfl

@[simp] theorem run_read_resources [StackExports σ] (stack : Stack σ) (graph : Graph) :
    (stack.read.run graph).2.resources = graph.resources := by
  simp [read]

end Stack

end Inframe
