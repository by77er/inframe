-- expect: which is not an OpenTofu identifier
import Inframe
open Inframe

/-! A field whose snake-case name is not an OpenTofu identifier cannot be exported. -/

structure Exports where
  endpoint' : Input String
  deriving StackExports
