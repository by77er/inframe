//! Where a stack's source declared each node of its graph.
//!
//! Origins are a companion to Graph IR, not a part of it: a frontend that records them
//! writes this document beside the graph when asked (the Lean core does, to the file named
//! by `INFRAME_ORIGINS`), and no validator, policy or lowering reads it. Tools that show a
//! graph use it to say which module and definition a node belongs to.

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};

/// The environment variable a stack's entry point reads the origins path from.
pub const ORIGINS_VARIABLE: &str = "INFRAME_ORIGINS";

/// Where the stack's source declared one node.
#[derive(Debug, Clone, PartialEq, Eq, Deserialize, Serialize)]
pub struct Origin {
    /// The source module, for example `Infra.Platform`.
    pub module: String,
    /// The declaration the node is added in; empty at the top level of a module.
    #[serde(default)]
    pub declaration: String,
    /// The one-based line of the call; `0` when unknown.
    #[serde(default)]
    pub line: u32,
}

/// Origins by node: a graph address, `provider.<address>`, or `output.<name>`.
pub type Origins = BTreeMap<String, Origin>;

/// The document a stack's entry point writes. Unknown fields are ignored so that a newer
/// frontend can say more than this build reads.
#[derive(Debug, Deserialize)]
struct Document {
    #[serde(default)]
    origins: Origins,
}

/// Decode an origins document.
pub fn decode(bytes: &[u8]) -> Result<Origins, serde_json::Error> {
    serde_json::from_slice::<Document>(bytes).map(|document| document.origins)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn decodes_origins_and_ignores_what_it_does_not_know() {
        let origins = decode(
            br#"{"format_version":"1.0","later":true,"origins":{"aws_vpc.cell":{"module":"Cell.Stack","declaration":"Cell.cell","line":7,"column":3},"output.id":{"module":"Cell.Stack"}}}"#,
        )
        .unwrap();
        assert_eq!(origins["aws_vpc.cell"].declaration, "Cell.cell");
        assert_eq!(origins["aws_vpc.cell"].line, 7);
        assert_eq!(origins["output.id"].declaration, "");
        assert!(decode(b"{}").unwrap().is_empty());
    }
}
