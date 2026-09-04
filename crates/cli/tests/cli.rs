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

#[test]
fn validates_a_graph() {
    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    fs::write(&graph, GRAPH).unwrap();

    Command::cargo_bin("tofu-dag")
        .unwrap()
        .args(["graph", "validate"])
        .arg(graph)
        .assert()
        .success()
        .stdout(predicate::str::contains("valid Graph IR 1.0"));
}

#[test]
fn renders_open_tofu_json() {
    let directory = tempdir().unwrap();
    let graph = directory.path().join("graph.json");
    fs::write(&graph, GRAPH).unwrap();

    Command::cargo_bin("tofu-dag")
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

    Command::cargo_bin("tofu-dag")
        .unwrap()
        .args(["render", "--graph"])
        .arg(graph)
        .args(["--output", "-"])
        .assert()
        .success()
        .stdout(golden);
}
