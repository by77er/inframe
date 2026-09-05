-- expect: Type mismatch
import Inframe
import DigitalOcean.Resource.SpacesBucket
open Inframe DigitalOcean.Resource

/-! `versioning` is allowed at most once on a Spaces bucket, so the field is an `Option`
record: a list of two blocks does not type-check. -/

def doubled : Infra Unit := do
  let _ ← SpacesBucket.create "assets"
    { name := "assets", region := "nyc3", versioning := [{ enabled := true }, { enabled := false }] }
  pure ()
