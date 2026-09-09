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

/// `OpenTofu` rejects this graph only at plan time (`Cycle: terraform_data.b, terraform_data.a`);
/// the validators reject it first, so `Valid` and `inframe graph validate` agree with the
/// planner.
#[test]
fn rejects_dependency_cycles_before_open_tofu() {
    let workspace = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    let graph = workspace.join("fixtures/graph-ir/dependency-cycle.json");

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["graph", "validate"])
        .arg(&graph)
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "dependency cycle: terraform_data.a -> terraform_data.b -> terraform_data.a",
        ));

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["init", "--stack", "cycle", "--graph"])
        .arg(&graph)
        .args(["--tofu-binary", "/nonexistent/tofu"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("dependency cycle"));
}

#[test]
fn inspects_the_last_built_stack_graph_with_no_build() {
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
        .args(["graph", "inspect", "--stack", "dev", "--no-build"])
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

/// Template markers inside literal collections, object keys, and interpolated literals are
/// escaped at every depth; `scripts/check-template-escapes.sh` applies this fixture with
/// `OpenTofu` and checks the resolved values match `fixtures/tofu-output/template-escapes.json`.
#[test]
fn template_escapes_fixture_matches_golden_output() {
    let workspace = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    let graph = workspace.join("fixtures/graph-ir/template-escapes.json");
    let golden =
        fs::read_to_string(workspace.join("fixtures/tofu-json/template-escapes.json")).unwrap();

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
    let provider = fs::read_to_string(
        directory
            .path()
            .join("src/.generated/digitalocean/src/DigitalOcean/Provider.purs"),
    )
    .unwrap();
    assert!(
        provider.contains(
            "-- | The token key for API operations.\ntoken :: Input String -> Args -> Args"
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

#[test]
fn generates_lean_bindings_with_a_relative_core_dependency() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::write(
        &project,
        r#"[lean]
directory = "infra"
core = { path = "core" }

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
            "generated 79 resources and 77 data sources for `digitalocean` (Lean)",
        ));

    let package = directory.path().join("infra/.generated/digitalocean");
    let resource = fs::read_to_string(package.join("DigitalOcean/Resource/Tag.lean")).unwrap();
    assert!(resource.contains(
        "requireProvider (Identifier.mk \"digitalocean\") \"digitalocean/digitalocean\" \"= 2.100.0\""
    ));
    assert!(resource.contains(
        "def create (name : String) (a : Args) (valid : validIdentifier name = true := by valid_identifier)"
    ));
    let lakefile = fs::read_to_string(package.join("lakefile.toml")).unwrap();
    assert!(lakefile.contains("[[require]]\nname = \"inframe\"\npath = \"../../../core\""));
    assert!(package.join("lake-manifest.json").is_file());
    assert!(package.join("lean-toolchain").is_file());
    assert!(!directory.path().join("purescript").exists());
}

#[test]
fn generates_both_frontends_from_one_fixture() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::write(
        &project,
        r#"[purescript]
package = "example"

[lean]

[providers.digitalocean]
source = "digitalocean/digitalocean"
version = "2.100.0"

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
        .arg(&fixture)
        .assert()
        .success()
        .stdout(predicate::str::contains("(PureScript) in"))
        .stdout(predicate::str::contains("(Lean) in"));
    assert!(
        directory
            .path()
            .join("purescript/.generated/digitalocean/src/Digitalocean/Resource/Tag.purs")
            .is_file()
    );
    let lakefile = fs::read_to_string(
        directory
            .path()
            .join("lean/.generated/digitalocean/lakefile.toml"),
    )
    .unwrap();
    assert!(lakefile.contains("git = \"https://github.com/by77er/inframe\""));
    assert!(lakefile.contains("subDir = \"lean\""));

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["provider", "generate", "--schema-json"])
        .arg(&fixture)
        .arg("--output")
        .arg(directory.path().join("elsewhere"))
        .assert()
        .failure()
        .stderr(predicate::str::contains("--output requires --frontend"));
}

#[test]
fn requires_a_frontend_per_stack_when_both_are_configured() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::write(
        &project,
        r#"[purescript]
package = "example"

[lean]

[stacks.dev.backend]
type = "local"

[stacks.typed]
frontend = "lean"
test = "policies"

[stacks.typed.backend]
type = "local"
"#,
    )
    .unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "stack `dev` must set `frontend = \"purescript\"` or `frontend = \"lean\"`",
        ));

    fs::write(
        &project,
        r#"[purescript]
package = "example"

[stacks.dev]
frontend = "lean"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "selects the lean frontend but [lean] is not configured",
        ));
}

#[cfg(unix)]
#[test]
fn runs_the_configured_lean_test_and_preserves_its_exit_code() {
    use std::os::unix::fs::PermissionsExt;

    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let bin = directory.path().join("bin");
    let lake = bin.join("lake");
    let invocation = directory.path().join("lake-args");
    fs::create_dir(&bin).unwrap();
    fs::create_dir(directory.path().join("lean")).unwrap();
    fs::write(
        &project,
        r#"[lean]
directory = "lean"

[stacks.dev]
test = "policies"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    fs::write(
        &lake,
        "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$INFRAME_TEST_ARGS\"\npwd >> \"$INFRAME_TEST_ARGS\"\nexit 23\n",
    )
    .unwrap();
    let mut permissions = fs::metadata(&lake).unwrap().permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&lake, permissions).unwrap();
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

    let recorded = fs::read_to_string(invocation).unwrap();
    assert!(recorded.starts_with("-q\nexe\npolicies\n"));
    assert!(recorded.trim_end().ends_with("/lean"));
}

/// Lifecycle commands run the configured test entry point after building and refuse to run
/// `OpenTofu` when it fails, so a policy suite in a separate executable gates deployment.
#[cfg(unix)]
#[test]
fn lifecycle_commands_require_the_stack_tests_to_pass() {
    use std::os::unix::fs::PermissionsExt;

    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let bin = directory.path().join("bin");
    let lake = bin.join("lake");
    fs::create_dir(&bin).unwrap();
    fs::create_dir(directory.path().join("lean")).unwrap();
    fs::write(
        &project,
        r#"[lean]
main = "graph"
test = "policies"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    fs::write(
        &lake,
        format!(
            "#!/bin/sh\ncase \"$3\" in\n  graph) cat <<'GRAPH'\n{GRAPH}\nGRAPH\n  ;;\n  policies) exit \"$INFRAME_TEST_POLICY_EXIT\" ;;\n  *) exit 9 ;;\nesac\n"
        ),
    )
    .unwrap();
    let mut permissions = fs::metadata(&lake).unwrap().permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&lake, permissions).unwrap();
    let path = std::env::join_paths(std::iter::once(bin).chain(std::env::split_paths(
        &std::env::var_os("PATH").unwrap_or_default(),
    )))
    .unwrap();
    let plan = |policy_exit: &str, extra: &[&str]| {
        let mut command = Command::cargo_bin("inframe").unwrap();
        command
            .arg("--project")
            .arg(&project)
            .args([
                "plan",
                "--stack",
                "dev",
                "--tofu-binary",
                "/nonexistent/tofu",
            ])
            .args(extra)
            .env("PATH", &path)
            .env("INFRAME_TEST_POLICY_EXIT", policy_exit);
        command
    };

    // A failing suite stops before OpenTofu is even started.
    plan("7", &[])
        .assert()
        .failure()
        .stderr(predicate::str::contains("tests for stack `dev` failed"))
        .stderr(predicate::str::contains("was not found; install OpenTofu").not());

    // A passing suite, or an explicit override, reaches OpenTofu.
    plan("0", &[])
        .assert()
        .failure()
        .stderr(predicate::str::contains("tests for stack `dev` passed"))
        .stderr(predicate::str::contains("was not found; install OpenTofu"));
    plan("7", &["--skip-tests"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "skipping the tests of stack `dev`",
        ))
        .stderr(predicate::str::contains("was not found; install OpenTofu"));
}

/// `inframe tofu` runs any subcommand in the stack's workspace, so state, import, and
/// recovery operations go through the same prepared configuration as `plan` and `apply`.
#[cfg(unix)]
#[test]
fn tofu_passthrough_runs_any_subcommand_in_the_stack_workspace() {
    use std::os::unix::fs::PermissionsExt;

    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    let tofu = directory.path().join("tofu");
    let recorded = directory.path().join("tofu-args");
    fs::write(&graph, GRAPH).unwrap();
    fs::write(
        &tofu,
        "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"$INFRAME_TEST_ARGS\"\npwd >> \"$INFRAME_TEST_ARGS\"\n",
    )
    .unwrap();
    let mut permissions = fs::metadata(&tofu).unwrap().permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&tofu, permissions).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["tofu", "--stack", "dev", "--graph"])
        .arg(&graph)
        .arg("--workspace")
        .arg(directory.path().join("work"))
        .arg("--tofu-binary")
        .arg(&tofu)
        .args(["--", "state", "list"])
        .env("INFRAME_TEST_ARGS", &recorded)
        .assert()
        .success();
    let recorded = fs::read_to_string(recorded).unwrap();
    assert!(recorded.starts_with("state\nlist\n"));
    assert!(recorded.trim_end().ends_with("/work/stacks/dev"));

    Command::cargo_bin("inframe")
        .unwrap()
        .args(["tofu", "--stack", "dev", "--graph"])
        .arg(&graph)
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "pass the tofu subcommand after `--`",
        ));
}

#[cfg(unix)]
#[test]
fn builds_a_lean_stack_from_the_executable_output() {
    use std::os::unix::fs::PermissionsExt;

    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let bin = directory.path().join("bin");
    let lake = bin.join("lake");
    fs::create_dir(&bin).unwrap();
    fs::create_dir(directory.path().join("lean")).unwrap();
    fs::write(
        &project,
        r#"[lean]
main = "graph"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    fs::write(
        &lake,
        format!(
            "#!/bin/sh\n[ \"$1 $2 $3\" = \"-q exe graph\" ] || exit 9\necho 'building...' >&2\ncat <<'GRAPH'\n{GRAPH}\nGRAPH\n"
        ),
    )
    .unwrap();
    let mut permissions = fs::metadata(&lake).unwrap().permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&lake, permissions).unwrap();
    let path = std::env::join_paths(std::iter::once(bin).chain(std::env::split_paths(
        &std::env::var_os("PATH").unwrap_or_default(),
    )))
    .unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .env("PATH", &path)
        .assert()
        .success()
        .stdout(predicate::str::contains("built stack `dev`"));
    let built = fs::read_to_string(directory.path().join(".inframe/graphs/dev.json")).unwrap();
    assert!(built.contains("\"answer\""));

    // Graph commands build the stack first rather than reading a stale artifact.
    fs::write(directory.path().join(".inframe/graphs/dev.json"), "{}").unwrap();
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["graph", "inspect", "--stack", "dev"])
        .env("PATH", path)
        .assert()
        .success()
        .stderr(predicate::str::contains("built stack `dev`"))
        .stdout(predicate::str::contains("answer: 42"));
}

/// A fake `lake` on PATH that runs `script`, so a build's failure modes can be staged.
#[cfg(unix)]
fn fake_lake(directory: &std::path::Path, script: &str) -> std::ffi::OsString {
    use std::os::unix::fs::PermissionsExt;

    let bin = directory.join("bin");
    fs::create_dir_all(&bin).unwrap();
    let lake = bin.join("lake");
    fs::write(&lake, script).unwrap();
    let mut permissions = fs::metadata(&lake).unwrap().permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&lake, permissions).unwrap();
    std::env::join_paths(std::iter::once(bin).chain(std::env::split_paths(
        &std::env::var_os("PATH").unwrap_or_default(),
    )))
    .unwrap()
}

const LEAN_PROJECT: &str = r#"[lean]
main = "graph"

[stacks.dev.backend]
type = "local"
"#;

/// A failing child process is reported with its command line, exit status, and stderr
/// verbatim; an empty stderr is said out loud instead of leaving a blank line.
#[cfg(unix)]
#[test]
fn reports_a_failed_build_verbatim_even_when_stderr_is_empty() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::create_dir(directory.path().join("lean")).unwrap();
    fs::write(&project, LEAN_PROJECT).unwrap();

    let silent = fake_lake(directory.path(), "#!/bin/sh\nexit 3\n");
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .env("PATH", silent)
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "`lake` failed while building stack `dev` (exit status: 3)",
        ))
        .stderr(predicate::str::contains("command: lake -q exe graph"))
        .stderr(predicate::str::contains("stderr: (empty)"));

    let loud = fake_lake(
        directory.path(),
        "#!/bin/sh\necho 'error: Infra/Main.lean:3:0: unknown identifier `droplet`' >&2\nexit 1\n",
    );
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .env("PATH", loud)
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "stderr:\nerror: Infra/Main.lean:3:0: unknown identifier `droplet`",
        ));
}

#[test]
fn reports_a_missing_frontend_tool_by_name() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let empty = directory.path().join("empty-bin");
    fs::create_dir_all(&empty).unwrap();
    fs::create_dir(directory.path().join("lean")).unwrap();
    fs::write(&project, LEAN_PROJECT).unwrap();

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .env("PATH", &empty)
        .assert()
        .failure()
        .stderr(predicate::str::contains("`lake` was not found on PATH"))
        .stderr(predicate::str::contains("elan"));

    // Lifecycle commands name a missing OpenTofu binary once the graph itself is fine.
    let workspace = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../..");
    Command::cargo_bin("inframe")
        .unwrap()
        .args([
            "--tofu-binary",
            "definitely-not-tofu",
            "init",
            "--stack",
            "dev",
            "--graph",
        ])
        .arg(workspace.join("fixtures/graph-ir/digitalocean-tag.json"))
        .arg("--workspace")
        .arg(directory.path().join(".inframe"))
        .env("PATH", &empty)
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "`definitely-not-tofu` was not found; install OpenTofu",
        ));
}

/// `--no-build` reads the last artifact, and says so when sources changed after it was
/// written, so a stale graph is never mistaken for evidence about the current program.
#[test]
fn warns_when_no_build_reads_a_graph_older_than_the_sources() {
    use std::time::{Duration, SystemTime};

    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let sources = directory.path().join("purescript/src");
    let graph_directory = directory.path().join(".inframe/graphs");
    fs::create_dir_all(&sources).unwrap();
    fs::create_dir_all(&graph_directory).unwrap();
    fs::write(
        &project,
        r#"[purescript]
package = "example"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    let artifact = graph_directory.join("dev.json");
    fs::write(&artifact, GRAPH).unwrap();
    fs::write(sources.join("Main.purs"), "module Main where\n").unwrap();

    let an_hour_ago = SystemTime::now() - Duration::from_secs(3600);
    fs::OpenOptions::new()
        .write(true)
        .open(&artifact)
        .unwrap()
        .set_modified(an_hour_ago)
        .unwrap();
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["graph", "validate", "--stack", "dev", "--no-build"])
        .assert()
        .success()
        .stderr(predicate::str::contains("warning: sources under"))
        .stderr(predicate::str::contains("changed after"))
        .stderr(predicate::str::contains(
            "drop --no-build to rebuild stack `dev`",
        ));

    // Sources older than the artifact: no warning.
    fs::OpenOptions::new()
        .write(true)
        .open(sources.join("Main.purs"))
        .unwrap()
        .set_modified(an_hour_ago - Duration::from_secs(3600))
        .unwrap();
    fs::OpenOptions::new()
        .write(true)
        .open(&artifact)
        .unwrap()
        .set_modified(an_hour_ago)
        .unwrap();
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["graph", "validate", "--stack", "dev", "--no-build"])
        .assert()
        .success()
        .stderr(predicate::str::contains("warning").not());
}

const GOOGLE_BETA_SCHEMA: &str = r#"{
  "format_version": "1.0",
  "provider_schemas": {
    "registry.opentofu.org/hashicorp/google-beta": {
      "provider": { "version": 0, "block": { "attributes": {} } },
      "resource_schemas": {
        "google_compute_instance": {
          "version": 0,
          "block": {
            "attributes": {
              "id": { "type": "string", "computed": true },
              "name": { "type": "string", "required": true }
            }
          }
        }
      },
      "data_source_schemas": {}
    }
  }
}"#;

/// A `-beta` provider names its types after the base provider; the inferred prefix and an
/// explicit `strip_prefix` both keep module names from stuttering.
#[test]
fn strips_the_base_provider_prefix_for_beta_providers() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    let fixture = directory.path().join("google-beta.json");
    fs::write(&fixture, GOOGLE_BETA_SCHEMA).unwrap();
    fs::write(
        &project,
        r#"[purescript]
package = "example"

[providers.google-beta]
source = "hashicorp/google-beta"
version = "6.0.0"
module_root = "GoogleBeta"

[stacks.dev.backend]
type = "local"
"#,
    )
    .unwrap();
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["provider", "generate", "google-beta", "--schema-json"])
        .arg(&fixture)
        .assert()
        .success();
    let generated = directory
        .path()
        .join("purescript/.generated/google-beta/src/GoogleBeta/Resource");
    assert!(generated.join("ComputeInstance.purs").is_file());

    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args([
            "provider",
            "generate",
            "google-beta",
            "--strip-prefix",
            "google_compute_",
            "--schema-json",
        ])
        .arg(&fixture)
        .assert()
        .success();
    assert!(generated.join("Instance.purs").is_file());
}

/// `--quiet` keeps Inframe's own notes off stderr; a mismatched Lean toolchain pin is named.
#[cfg(unix)]
#[test]
fn quiet_lifecycle_runs_and_toolchain_pins_are_checked() {
    let directory = tempdir().unwrap();
    let project = directory.path().join("inframe.toml");
    fs::create_dir(directory.path().join("lean")).unwrap();
    fs::write(&project, LEAN_PROJECT).unwrap();
    let path = fake_lake(
        directory.path(),
        &format!("#!/bin/sh\ncat <<'GRAPH'\n{GRAPH}\nGRAPH\n"),
    );

    let run = |quiet: bool| {
        let mut command = Command::cargo_bin("inframe").unwrap();
        command.arg("--project").arg(&project).args([
            "--tofu-binary",
            "true",
            "init",
            "--stack",
            "dev",
            "--skip-tests",
        ]);
        if quiet {
            command.arg("--quiet");
        }
        command.env("PATH", &path);
        command
    };
    run(false)
        .assert()
        .success()
        .stderr(predicate::str::contains("built stack `dev`"))
        .stderr(predicate::str::contains(
            "skipping the tests of stack `dev`",
        ));
    run(true)
        .assert()
        .success()
        .stderr(predicate::str::contains("built stack").not())
        .stderr(predicate::str::contains("skipping the tests").not());

    fs::write(
        directory.path().join("lean/lean-toolchain"),
        "leanprover/lean4:v4.0.0\n",
    )
    .unwrap();
    Command::cargo_bin("inframe")
        .unwrap()
        .arg("--project")
        .arg(&project)
        .args(["build", "--stack", "dev"])
        .env("PATH", &path)
        .assert()
        .success()
        .stderr(predicate::str::contains("warning:"))
        .stderr(predicate::str::contains("pins `leanprover/lean4:v4.0.0`"));
}
