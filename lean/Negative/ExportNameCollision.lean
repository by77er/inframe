-- expect: fields `fooBar` and `foo_bar` of `Exports` would both be exported as `foo_bar`
import Inframe
open Inframe

/-! Output names come from field names, so two fields cannot claim the same output. -/

structure Exports where
  fooBar : Input String
  foo_bar : Input String
  deriving StackExports
