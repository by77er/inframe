# DigitalOcean platform

[`Main.purs`](Main.purs) builds a graph for:

- an autoscaling managed Kubernetes cluster whose version is selected from a
  data source;
- a versioned Spaces bucket; and
- a PostgreSQL database with storage autoscaling.

The cluster and database share a VPC, so the example also demonstrates typed
references and inferred dependency edges. It intentionally renders and
validates configuration without applying it; applying creates billable cloud
resources. Replace the Spaces name with a globally unique value before use.

The same graph is wired into the PureScript integration package as
`Infra.Platform`, where CI compiles it and validates the emitted Graph IR. Its
Lean 4 twin lives in `lean/integration-digitalocean/Infra/Platform.lean`, with
compile-time policy proofs in `Infra/PlatformTest.lean`; CI checks that both
frontends render byte-identical Graph IR.
