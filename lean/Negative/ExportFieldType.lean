-- expect: ExportField String
import Inframe
open Inframe

/-! An exported field is an input: a plain value would publish as a literal but read back as a
reference, so the two sides would not agree on its type. -/

structure Exports where
  region : String
  deriving StackExports
