import Infra.Platform

open Inframe

/-- The whole of a stack's `main`: `emitGraph` renders compact Graph IR and writes it out. -/
def main : IO Unit :=
  emitGraph infrastructure
