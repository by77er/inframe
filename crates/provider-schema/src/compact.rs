//! Reading JSON without its insignificant whitespace.

use std::io;

/// Reads JSON without the whitespace between its tokens. A pretty-printed normalized schema
/// is mostly indentation (AWS: 154 MB, 24 MB without it), and reading it compacted keeps the
/// buffer at the smaller size: the whitespace is dropped chunk by chunk as it is read.
///
/// Whitespace between two number or literal tokens is kept as one space, so the compacted
/// text holds exactly the original tokens: a valid document decodes to the same values, an
/// invalid one still fails, only with positions in the compacted text.
pub fn read_compact_json(mut reader: impl io::Read) -> io::Result<Vec<u8>> {
    let mut compact = Vec::new();
    let mut chunk = vec![0; 1 << 16];
    let mut state = Compacting::default();
    let mut first = true;
    loop {
        let read = match reader.read(&mut chunk) {
            Ok(0) => return Ok(compact),
            Ok(read) => read,
            Err(error) if error.kind() == io::ErrorKind::Interrupted => continue,
            Err(error) => return Err(error),
        };
        state.push(&chunk[..read], &mut compact);
        // `OpenTofu` writes its schemas on one line: when the start has nothing to drop, the
        // rest is copied as it is (keeping whitespace is always correct, only larger).
        if std::mem::take(&mut first) && state.dropped == 0 {
            reader.read_to_end(&mut compact)?;
            return Ok(compact);
        }
    }
}

/// Where [`read_compact_json`] is between chunks.
#[derive(Default)]
struct Compacting {
    in_string: bool,
    /// Inside a string, just after a backslash.
    escaped: bool,
    /// Whitespace was dropped since the last byte kept.
    pending: bool,
    /// How many bytes of whitespace were dropped.
    dropped: usize,
}

impl Compacting {
    fn push(&mut self, bytes: &[u8], compact: &mut Vec<u8>) {
        let mut at = 0;
        while at < bytes.len() {
            if self.in_string {
                if std::mem::take(&mut self.escaped) {
                    compact.push(bytes[at]);
                    at += 1;
                    continue;
                }
                // Copy through the next quote or backslash.
                let Some(offset) = memchr::memchr2(b'"', b'\\', &bytes[at..]) else {
                    compact.extend_from_slice(&bytes[at..]);
                    return;
                };
                let end = at + offset;
                compact.extend_from_slice(&bytes[at..=end]);
                if bytes[end] == b'"' {
                    self.in_string = false;
                } else {
                    self.escaped = true;
                }
                at = end + 1;
            } else {
                let whitespace = whitespace_run(&bytes[at..]);
                if whitespace > 0 {
                    self.pending = true;
                    self.dropped += whitespace;
                    at += whitespace;
                    continue;
                }
                let byte = bytes[at];
                if std::mem::take(&mut self.pending)
                    && compact.last().is_some_and(|&last| atom_byte(last))
                    && atom_byte(byte)
                {
                    compact.push(b' ');
                }
                compact.push(byte);
                self.in_string = byte == b'"';
                at += 1;
            }
        }
    }
}

/// The length of the whitespace `bytes` start with. Indentation is long runs of spaces, which
/// are stepped over eight at a time.
fn whitespace_run(bytes: &[u8]) -> usize {
    let mut run = 0;
    loop {
        if bytes.get(run..run + 8) == Some(b"        ") {
            run += 8;
        } else if bytes
            .get(run)
            .is_some_and(|byte| matches!(byte, b' ' | b'\t' | b'\n' | b'\r'))
        {
            run += 1;
        } else {
            return run;
        }
    }
}

/// A byte that can be part of a number or a `true`/`false`/`null` literal.
fn atom_byte(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || matches!(byte, b'-' | b'+' | b'.')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn compacting_keeps_tokens_apart() {
        let compact = |json: &str| {
            // Odd chunk boundaries must not matter.
            let mut reader = io::BufReader::with_capacity(3, json.as_bytes());
            String::from_utf8(read_compact_json(&mut reader).unwrap()).unwrap()
        };
        assert_eq!(
            compact("{\n  \"a b\": [ 1 , 2 ],\n  \"c\\\" \": true }\n"),
            r#"{"a b":[1,2],"c\" ":true}"#
        );
        // Tokens that whitespace alone separates stay separate.
        assert_eq!(
            compact("[1 2, true  false, 1\n-2]"),
            "[1 2,true false,1 -2]"
        );
        assert_eq!(compact("\"x\\\\\" \"y\""), r#""x\\""y""#);
    }
}
