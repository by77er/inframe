-- expect: Constructor for `Inframe.Input` is marked as private
import Inframe
open Inframe

/-! The phantom type of an input cannot be chosen apart from its payload: `Input`'s constructor
is private, so a boolean literal cannot be passed off as an `Input String`. The only ways to
choose the type freely are the generated adapters and the functions named `unsafe…`. -/

def aString : Input String := ⟨.literal (.bool true)⟩
