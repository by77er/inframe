import Lean.Elab.Deriving.Basic
import Inframe.Stack

/-!
# `deriving StackExports`

For a structure with no parameters whose fields are `ExportField`s (`Input α` or
`Sensitive α`), the handler writes

```lean
instance : StackExports Platform where
  outputs exports := [ExportedOutput.of (Identifier.mk "cluster_endpoint") exports.clusterEndpoint, …]
  ofOutputs reference := { clusterEndpoint := ExportField.ofNode (reference "cluster_endpoint"), … }
```

Output names are the field names in snake case (`vpcID` is `vpc_id`); a field whose name is not
an OpenTofu identifier that way, or two fields with the same output name, are compile errors.
-/

namespace Inframe

/-- `clusterEndpoint` is `cluster_endpoint`, `vpcID` is `vpc_id`, `httpURLPath` is
`http_url_path`; snake case is unchanged. -/
def snakeCase (name : String) : String := Id.run do
  let chars := name.toList.toArray
  let mut result := ""
  for h : i in [:chars.size] do
    let c := chars[i]
    if c.isUpper then
      let previous := if i = 0 then none else chars[i - 1]?
      let next := chars[i + 1]?
      let afterLower := previous.any fun p => p.isLower || p.isDigit
      let endsAcronym := previous.any Char.isUpper && next.any Char.isLower
      if afterLower || endsAcronym then
        result := result.push '_'
      result := result.push c.toLower
    else
      result := result.push c
  return result

open Lean Elab Command Meta

private def mkStackExportsInstance (declName : Name) : CommandElabM Unit := do
  let env ← getEnv
  unless isStructure env declName do
    throwError "`deriving StackExports` needs a structure; `{declName}` is not one"
  let fields := getStructureFieldsFlattened env declName (includeSubobjectFields := false)
  if fields.isEmpty then
    throwError "`{declName}` has no fields to export"
  let indVal ← getConstInfoInduct declName
  if indVal.numParams != 0 then
    throwError "`deriving StackExports` needs a structure without parameters; `{declName}` has {indVal.numParams}"
  let mut seen : Std.HashMap String Name := {}
  let mut outputs : Array Term := #[]
  let mut fieldIdents : Array Ident := #[]
  let mut readers : Array Term := #[]
  for field in fields do
    let outputName := snakeCase (field.toString (escape := false))
    unless validIdentifier outputName do
      throwError "field `{field}` of `{declName}` would be exported as `{outputName}`, which is not an OpenTofu identifier"
    if let some other := seen[outputName]? then
      throwError "fields `{other}` and `{field}` of `{declName}` would both be exported as `{outputName}`"
    seen := seen.insert outputName field
    let fieldIdent := mkIdent field
    let nameLit := Syntax.mkStrLit outputName
    outputs := outputs.push
      (← `(Inframe.ExportedOutput.of (Inframe.Identifier.mk $nameLit) (exports.$fieldIdent:ident)))
    fieldIdents := fieldIdents.push fieldIdent
    readers := readers.push (← `(Inframe.ExportField.ofNode (reference $nameLit)))
  let typeIdent := mkCIdent declName
  let instanceCommand ← `(command|
    instance : Inframe.StackExports $typeIdent where
      outputs exports := [$outputs,*]
      ofOutputs reference := { $[$fieldIdents:ident := $readers],* })
  elabCommand instanceCommand

private def mkStackExportsInstances (declNames : Array Name) : CommandElabM Bool := do
  for declName in declNames do
    mkStackExportsInstance declName
  return true

initialize registerDerivingHandler ``StackExports mkStackExportsInstances

end Inframe
