-- expect: infrastructure is implemented by rogue
import Inframe
open Inframe

/-! The kernel proves facts about a definition's body; `implemented_by` makes compiled code,
`main` included, run another one, so a gate would prove one graph and deploy another. The
deployment gate refuses it. -/

def rogue : Infra Unit := pure ()

@[implemented_by rogue]
def infrastructure : Infra Unit := pure ()

#assert_compiled_as_proved
