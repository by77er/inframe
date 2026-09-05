import Inframe

/-!
A graph the size of a real deployment: sixty instances, each carrying a four-kilobyte startup
script, nested blocks, and references. It guards the paths that only break at scale: the
policy and validator checks go through `#assert_policy`/`#assert_valid` (evaluation, not
kernel reduction), and `main` is the blessed `emitGraph`, whose output the Makefile pipes
through `inframe graph validate`.
-/

open Inframe

def startupScript : String := "#!/bin/bash\nset -euo pipefail\nexport DEBIAN_FRONTEND=noninteractive\necho 'line 3: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 4: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 5: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 6: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 7: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 8: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 9: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 10: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 11: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 12: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 13: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 14: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 15: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 16: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 17: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 18: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 19: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 20: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 21: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 22: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 23: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 24: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 25: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 26: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 27: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 28: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 29: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 30: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 31: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 32: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 33: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 34: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 35: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 36: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 37: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 38: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 39: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 40: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 41: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 42: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 43: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 44: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log\necho 'line 45: ${HOSTNAME} $${literal} %{escaped} configuring the service' >> /var/log/boot.log"

def instanceArguments (index : Nat) (network : Resource Unit) : InputObject :=
  InputObject.ofList
    [ ("name", inputNode (lit s!"vm-{index}"))
    , ("machine_type", inputNode (lit "e2-medium"))
    , ("zone", inputNode (lit "us-central1-a"))
    , ("metadata_startup_script", inputNode (lit startupScript))
    , ("tags", inputNode (lit ["web", "ssh"]))
    , ("labels", inputNode (object [("env", lit "staging"), ("index", lit (toString index))]))
    , ("network_interface", inputNode (array [object
        [ ("network", ((resourceAttr network ["self_link"] : Input String) : Input Value))
        , ("access_config", ((array [object [("network_tier", (lit "PREMIUM" : Input String))]]
            : Input (List (Map String))) : Input Value)) ]]))
    , ("boot_disk", inputNode (array [object
        [("initialize_params", (object [("image", lit "debian-12")] : Input (Map String)))]])) ]

/-- One instance per index, named `vm-<index>` through `Identifier.indexed`. -/
def createInstances (network : Resource Unit) : Nat → Infra Unit
  | 0 => pure ()
  | index + 1 => do
    createInstances network index
    let _ : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
      (Identifier.mk "google_compute_instance") ((Identifier.mk "vm").indexed index)
      (instanceArguments index network)

def infrastructure : Infra Unit := do
  requireProvider (Identifier.mk "google") "hashicorp/google" "= 6.0.0"
  let network : Resource Unit ← addResource (resourceOptions : ResourceOptions Unit)
    (Identifier.mk "google_compute_network") (Identifier.mk "main")
    (InputObject.ofList [("name", inputNode (lit "main")), ("auto_create_subnetworks", inputNode (lit true))])
  createInstances network 60
  output "network" (resourceAttr network ["self_link"] : Input String)

def graph : Graph := buildGraph infrastructure

def instancesHaveScripts : Policy :=
  Policy.resourcesOfType "instances-have-scripts" "google_compute_instance" fun resource =>
    match resource.argument? "metadata_startup_script" with
    | some (.literal (.string _)) => none
    | _ => some "instances need a startup script"

def instancesUseTheNetwork : Policy :=
  Policy.resourcesOfType "instances-use-the-network" "google_compute_instance" fun resource =>
    if (resource.argument? "network_interface").any (·.references? (.res "google_compute_network" "main"))
    then none
    else some "instances must attach to google_compute_network.main"

#assert_valid graph
#assert_policy (Policy.all "scale" [instancesHaveScripts, instancesUseTheNetwork]) graph

/-- The blessed `main` of a stack. -/
def main : IO Unit := emitGraph infrastructure
