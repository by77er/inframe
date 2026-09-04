use std::fs;
use std::path::PathBuf;

use assert_cmd::Command;
use predicates::prelude::*;
use tempfile::tempdir;

const GRAPH: &str = r#"{
  "format_version": "1.0",
  "required_providers": {},
  "provider_configs": [],
  "resources": [],
  "data_sources": [],
  "outputs": {
    "answer": {
      "value": { "kind": "literal", "value": 42 }
    }
  },
  "moves": []
}"#;

const SECRET_GRAPH: &str = r#"{
  "format_version": "1.0",
  "required_providers": {},
  "provider_configs": [],
  "resources": [],
  "data_sources": [],
  "outputs": {
    "secret": {
      "value": { "kind": "secret_env", "name": "INFRAME_TEST_SECRET" },
      "sensitive": true
    }
  },
  "moves": []
}"#;

#[test]
fn validates_a_graph() {
    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    fs::write(&graph, GRAPH).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["graph", "validate"])
        .arg(graph)
        .assert()
        .success()
        .stdout(predicate::str::contains("valid Graph IR 1.0"));
}

#[test]
fn inspects_the_configured_stack_graph_without_a_path() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let graph_directory = directory.path().join(".inframe/graphs");
    fs::create_dir_all(&graph_directory).unwrap();
    fs::write(graph_directory.join("dev.json"), GRAPH).unwrap();
    fs::write(
        &project,
        r#"[purescript]
package = "example"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["graph", "inspect", "--stack", "dev"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Outputs\n└── answer: 42"))
        .stdout(predicate::str::contains(
            "Summary: 0 providers, 0 resources, 0 data sources, 1 output, 0 dependencies",
        ));
}

#[test]
fn inspects_provider_resources_arguments_and_symbolic_outputs() {
    let workspace = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    let graph = workspace.join("fixtures/graph-ir/digitalocean-tag.json");

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["graph", "inspect"])
        .arg(graph)
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "digitalocean: digitalocean/digitalocean = 2.100.0",
        ))
        .stdout(predicate::str::contains("digitalocean_tag.smoke"))
        .stdout(predicate::str::contains("name: \"inframe-smoke\""))
        .stdout(predicate::str::contains(
            "tag_id: digitalocean_tag.smoke.id",
        ));
}

#[test]
fn inspection_never_resolves_secret_environment_values() {
    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    fs::write(&graph, SECRET_GRAPH).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["graph", "inspect"])
        .arg(graph)
        .env("INFRAME_TEST_SECRET", "actual-secret-value")
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "secret: secretEnv(\"INFRAME_TEST_SECRET\") (sensitive)",
        ))
        .stdout(predicate::str::contains("actual-secret-value").not());
}

#[test]
fn renders_open_tofu_json() {
    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    fs::write(&graph, GRAPH).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["render", "--graph"])
        .arg(graph)
        .args(["--output", "-"])
        .assert()
        .success()
        .stdout(predicate::str::contains("\"value\": 42"));
}

#[test]
fn digitalocean_fixture_matches_golden_output() {
    let workspace = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    let graph = workspace.join("fixtures/graph-ir/digitalocean-tag.json");
    let golden =
        fs::read_to_string(workspace.join("fixtures/tofu-json/digitalocean-tag.json")).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["render", "--graph"])
        .arg(graph)
        .args(["--output", "-"])
        .assert()
        .success()
        .stdout(golden);
}

#[test]
fn initializes_a_project_without_overwriting_it() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["project", "init"])
        .assert()
        .success();
    assert!(
        fs::read_to_string(&project)
            .unwrap()
            .contains("[stacks.dev.backend]")
    );
    assert!(
        fs::read_to_string(&project)
            .unwrap()
            .contains("[providers.digitalocean]")
    );

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["project", "init"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("refusing to overwrite"));
}

#[test]
fn generates_configured_providers_to_the_conventional_directory() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::write(
        &project,
        r#"[purescript]
directory = "src"
package = "example"

[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"
module_root = "DigitalOcean"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    let fixture = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../fixtures/provider-schema/digitalocean-2.100.0.normalized.json");

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["provider", "generate", "--schema-json"])
        .arg(fixture)
        .assert()
        .success()
        .stdout(predicate::str::contains(
            "generated 79 resources and 77 data sources",
        ));

    let resource = fs::read_to_string(
        directory
            .path()
            .join("src/.generated/digitalocean/src/DigitalOcean/Resource/Tag.purs"),
    )
    .unwrap();
    assert!(
        resource.contains(
            "requireProvider \"digitalocean\" \"digitalocean/digitalocean\" \"= 2.100.0\""
        )
    );
}

#[test]
fn reports_a_missing_purescript_test_entry_point() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::write(
        &project,
        r#"[purescript]
directory = "."
package = "infra"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["test", "--stack", "dev"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "set `stacks.dev.test` or `purescript.test`",
        ));
}

#[cfg(unix)]
#[test]
fn runs_the_configured_purescript_test_and_preserves_its_exit_code() {
    use std::os::unix::fs::PermissionsExt;

    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let bin = directory.path().join("bin");
    let spago = bin.join("spago");
    let invocation = directory.path().join("spago-args");
    fs::create_dir(&bin).unwrap();
    fs::write(
        &project,
        r#"[purescript]
directory = "."
package = "infra"

[stacks.dev]
test = "Infra.PolicyTest"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    fs::write(
        &spago,
        "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$INFRAME_TEST_ARGS\"\nexit 23\n",
    )
    .unwrap();
    let mut permissions = fs::metadata(&spago).unwrap().permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&spago, permissions).unwrap();
    let path = std::env::join_paths(std::iter::once(bin).chain(std::env::split_paths(
        &std::env::var_os("PATH").unwrap_or_default(),
    )))
    .unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["test", "--stack", "dev"])
        .env("PATH", path)
        .env("INFRAME_TEST_ARGS", &invocation)
        .assert()
        .code(23);

    assert_eq!(
        fs::read_to_string(invocation).unwrap(),
        "test\n-p\ninfra\n--main\nInfra.PolicyTest\n--quiet\n"
    );
}

#[test]
fn requires_secrets_only_at_plan_execution_and_never_writes_their_values() {
    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    let workspace = directory.path().join("workspace");
    fs::write(&graph, SECRET_GRAPH).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["--tofu-binary", "true", "plan", "--stack", "dev", "--graph"])
        .arg(&graph)
        .arg("--workspace")
        .arg(&workspace)
        .env_remove("INFRAME_TEST_SECRET")
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "required secret environment variable `INFRAME_TEST_SECRET` is not set",
        ));

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["--tofu-binary", "true", "plan", "--stack", "dev", "--graph"])
        .arg(&graph)
        .arg("--workspace")
        .arg(&workspace)
        .env("INFRAME_TEST_SECRET", "actual-secret-value")
        .assert()
        .success();

    let rendered = fs::read_to_string(workspace.join("stacks/dev/main.tofu.json")).unwrap();
    assert!(rendered.contains("inframe_secret_INFRAME_TEST_SECRET"));
    assert!(!rendered.contains("actual-secret-value"));
}
