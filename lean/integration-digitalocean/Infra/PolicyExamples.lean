import Inframe
import DigitalOcean.Provider
import DigitalOcean.Resource.DatabaseCluster
import DigitalOcean.Resource.DatabaseFirewall
import DigitalOcean.Resource.Droplet
import DigitalOcean.Resource.Firewall
import DigitalOcean.Resource.SpacesBucket
import DigitalOcean.Resource.SpacesBucketObject
import DigitalOcean.Resource.Vpc

/-!
Policies that look across the whole graph rather than at one resource, each checked against a
small stack built for them, along with a broken variant of that stack each policy rejects:

* every database cluster has a database firewall, and every droplet is in a firewall;
* VPC address ranges never overlap;
* no two resources of one type share a `name`;
* no public object depends on a database, directly or through other resources.

HCL validation sees one value or one resource at a time, and plan-based tools see values, not
the references between resources; each of these needs the graph.
-/

open Inframe
open DigitalOcean
open DigitalOcean.Resource

/-! ### Every resource of one type has a matching resource of another -/

/-- The managed resources of one type. -/
def resourcesOf (graph : Graph) (resourceType : String) : List ResourceSpec :=
  graph.resources.filter (·.resourceType == resourceType)

/-- Every resource of type `resourceType` is mentioned in `argument` of some resource of type
`coverType`: a firewall's `cluster_id` or `droplet_ids`, for example. -/
def coveredBy (name resourceType coverType argument : String) : Policy :=
  ⟨name, fun graph =>
    (resourcesOf graph resourceType).filterMap fun resource =>
      if (resourcesOf graph coverType).any (·.argumentMentions argument resource.address) then none
      else some ⟨name, resource.address.toString, s!"no {coverType} names it in {argument}", .violated⟩⟩

def databasesHaveFirewalls : Policy :=
  coveredBy "databases-have-firewalls" "digitalocean_database_cluster"
    "digitalocean_database_firewall" DatabaseFirewall.names.clusterId

def dropletsHaveFirewalls : Policy :=
  coveredBy "droplets-have-firewalls" "digitalocean_droplet" "digitalocean_firewall"
    Firewall.names.dropletIds

/-! ### VPC address ranges never overlap -/

/-- Read a decimal number, at least one digit. -/
def readNat (acc : Nat) (seen : Bool) : List Char → Option (Nat × List Char)
  | [] => if seen then some (acc, []) else none
  | c :: rest =>
    if c.isDigit then readNat (acc * 10 + (c.toNat - '0'.toNat)) true rest
    else if seen then some (acc, c :: rest) else none

def expectChar (expected : Char) : List Char → Option (List Char)
  | c :: rest => if c == expected then some rest else none
  | [] => none

/-- The first address and the size of an IPv4 CIDR block such as `10.10.0.0/16`. -/
def parseCidr (text : String) : Option (Nat × Nat) := do
  let (a, rest) ← readNat 0 false text.toList
  let (b, rest) ← readNat 0 false (← expectChar '.' rest)
  let (c, rest) ← readNat 0 false (← expectChar '.' rest)
  let (d, rest) ← readNat 0 false (← expectChar '.' rest)
  let (bits, rest) ← readNat 0 false (← expectChar '/' rest)
  if rest.isEmpty && a < 256 && b < 256 && c < 256 && d < 256 && bits ≤ 32 then
    let size := 2 ^ (32 - bits)
    some ((((a * 256 + b) * 256 + c) * 256 + d) / size * size, size)
  else none

/-- The first pair of blocks that overlap, by address. -/
def firstOverlap : List (String × Nat × Nat) → Option String
  | [] => none
  | (address, start, size) :: rest =>
    match rest.find? fun (_, start', size') => start < start' + size' && start' < start + size with
    | some (other, _) => some s!"{address} overlaps {other}"
    | none => firstOverlap rest

/-- No two VPCs' `ip_range` overlap. A range from a reference is unknown until plan, and one
that is not an IPv4 CIDR block is a violation. -/
def vpcRangesDisjoint : Policy :=
  Policy.argumentValues "vpc-ranges-disjoint" Vpc.names.ipRange fun ranges =>
    let vpcs := ranges.filter (·.1.resourceType == "digitalocean_vpc")
    let parsed := vpcs.map fun (vpc, range) =>
      match range with
      | .string text => (vpc.address.toString, parseCidr text)
      | _ => (vpc.address.toString, none)
    match parsed.find? (·.2.isNone) with
    | some (address, _) => some s!"{address}: ip_range is not an IPv4 CIDR block"
    | none => firstOverlap (parsed.filterMap fun (address, block) => block.map (address, ·))

/-! ### Names are unique per resource type -/

/-- The first literal `name` used twice by resources of one type. -/
def firstDuplicateName : List (ResourceSpec × Value) → Option String
  | [] => none
  | (resource, name) :: rest =>
    match rest.find? fun (other, name') => other.resourceType == resource.resourceType && name' == name with
    | some (other, _) => some s!"{resource.address} and {other.address} share a name"
    | none => firstDuplicateName rest

/-- No two resources of the same type share a `name`, across every module that adds to the
graph. A name from a reference is unknown until plan. -/
def uniqueNames : Policy :=
  Policy.argumentValues "unique-names" "name" firstDuplicateName

/-! ### Nothing public depends on a database -/

/-- No object readable by anyone depends on a database cluster, directly or through other
resources, so no value derived from a database (its URI, its password) can be published. -/
def publicObjectsAvoidDatabases : Policy :=
  ⟨"public-objects-avoid-databases", fun graph =>
    (resourcesOf graph "digitalocean_spaces_bucket_object").filterMap fun object =>
      if object.argumentIs SpacesBucketObject.names.acl "public-read" then
        match (resourcesOf graph "digitalocean_database_cluster").find?
            (graph.dependsOnTransitively object.address ·.address) with
        | some database =>
          some ⟨"public-objects-avoid-databases", object.address.toString,
            s!"public-read object depends on {database.address}", .violated⟩
        | none => none
      else none⟩

def examplePolicies : Policy :=
  Policy.all "examples"
    [Policy.validGraph, databasesHaveFirewalls, dropletsHaveFirewalls, vpcRangesDisjoint,
      uniqueNames, publicObjectsAvoidDatabases]

/-! ### The stack

A web droplet and a database on one VPC, a second VPC for the edge, a public site object, and
a private report object that embeds the database's URI. -/

/-- What the broken variants change. -/
structure Mistakes where
  skipDatabaseFirewall : Bool := false
  skipDropletFirewall : Bool := false
  edgeRange : String := "10.20.0.0/16"
  edgeName : String := "edge"
  reportAcl : String := "private"

def exampleStack (mistakes : Mistakes := {}) : Infra Unit := do
  let platform ← Vpc.create "platform" { name := "platform", region := "nyc3", ipRange := some (lit "10.10.0.0/16") }
  let _ ← Vpc.create "edge"
    { name := lit mistakes.edgeName, region := "nyc3", ipRange := some (lit mistakes.edgeRange) }
  let web ← Droplet.create "web"
    { image := "ubuntu-24-04-x64", name := "web", size := "s-1vcpu-1gb", region := some (lit "nyc3")
      vpcUuid := some platform.id }
  let database ← DatabaseCluster.create "orders"
    { engine := "pg", name := "orders", nodeCount := 1, region := "nyc3", size := "db-s-1vcpu-1gb"
      privateNetworkUuid := some platform.id }
  unless mistakes.skipDatabaseFirewall do
    let _ ← DatabaseFirewall.create "orders"
      { clusterId := database.id, rule := [{ type := "droplet", value := web.id }] }
  unless mistakes.skipDropletFirewall do
    let _ ← Firewall.create "web"
      { name := "web", dropletIds := some (array [web.id.tonumber])
        inboundRule := [{ protocol := "tcp", portRange := some (lit "443")
                          sourceAddresses := some (lit ["0.0.0.0/0"]) }] }
  let bucket ← SpacesBucket.create "site" { name := "example-site", region := "nyc3" }
  let _ ← SpacesBucketObject.create "index"
    { bucket := bucket.name, key := "index.html", region := "nyc3", acl := some (lit "public-read")
      content := some (lit "<h1>hello</h1>") }
  let _ ← SpacesBucketObject.create "report"
    { bucket := bucket.name, key := "report.txt", region := "nyc3", acl := some (lit mistakes.reportAcl)
      content := some database.uri }
  pure ()

theorem example_valid : (buildGraph (exampleStack)).Valid := by decide

theorem example_policies : examplePolicies.Holds (buildGraph (exampleStack)) := by decide

/-! ### Each policy rejects the mistake it is for -/

theorem missing_database_firewall :
    (databasesHaveFirewalls.violations (buildGraph (exampleStack { skipDatabaseFirewall := true }))).map
      (·.address) = ["digitalocean_database_cluster.orders"] := by decide

theorem missing_droplet_firewall :
    (dropletsHaveFirewalls.violations (buildGraph (exampleStack { skipDropletFirewall := true }))).map
      (·.address) = ["digitalocean_droplet.web"] := by decide

theorem overlapping_vpcs :
    (vpcRangesDisjoint.violations (buildGraph (exampleStack { edgeRange := "10.10.128.0/20" }))).map
      (·.message) = ["digitalocean_vpc.platform overlaps digitalocean_vpc.edge"] := by decide

theorem malformed_vpc_range :
    ¬ vpcRangesDisjoint.Holds (buildGraph (exampleStack { edgeRange := "10.20.0.0/33" })) := by decide

theorem duplicate_names :
    (uniqueNames.violations (buildGraph (exampleStack { edgeName := "platform" }))).map (·.message)
      = ["digitalocean_vpc.platform and digitalocean_vpc.edge share a name"] := by
  decide

/-- The report reaches the database through its `content`, the URI. Making it public is caught
even though the object never names the database's address in an argument a reviewer would
check, such as a network or a firewall. -/
theorem public_report_leaks_database :
    (publicObjectsAvoidDatabases.violations (buildGraph (exampleStack { reportAcl := "public-read" }))).map
      (·.message) = ["public-read object depends on digitalocean_database_cluster.orders"] := by
  decide
