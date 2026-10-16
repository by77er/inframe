//! Plumbing shared by the frontend emitters.
//!
//! A large provider renders to hundreds of megabytes (the AWS provider's PureScript package is
//! over 300 MB, one module alone 86 MB), so files are never assembled in memory on the way to
//! disk: each one is rendered straight into an [`Output`] that flushes to its file in fixed-size
//! chunks, and the files of a package are rendered on every core, largest first.

use std::cmp::Reverse;
use std::collections::{BTreeMap, BTreeSet};
use std::fmt;
use std::fs::{self, File};
use std::io::{self, Write as _};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::thread;

/// How much rendered text an [`Output`] holds before handing it to its file.
const FLUSH_THRESHOLD: usize = 256 * 1024;

/// The text of one generated file, either collected in memory or streamed to a writer.
/// Write to it with `write!` or [`Output::push_str`]; I/O errors are kept until
/// [`Output::finish`], so rendering code stays free of error plumbing.
pub struct Output<'w> {
    buffer: String,
    sink: Option<&'w mut dyn io::Write>,
    error: Option<io::Error>,
}

impl Output<'static> {
    #[must_use]
    pub fn in_memory() -> Self {
        Self {
            buffer: String::new(),
            sink: None,
            error: None,
        }
    }
}

impl<'w> Output<'w> {
    pub fn streaming(sink: &'w mut dyn io::Write) -> Self {
        Self {
            buffer: String::with_capacity(FLUSH_THRESHOLD + FLUSH_THRESHOLD / 4),
            sink: Some(sink),
            error: None,
        }
    }

    #[inline]
    pub fn push_str(&mut self, text: &str) {
        self.buffer.push_str(text);
        if self.buffer.len() >= FLUSH_THRESHOLD && self.sink.is_some() {
            self.flush_buffer();
        }
    }

    #[inline]
    pub fn push(&mut self, character: char) {
        self.buffer.push(character);
    }

    fn flush_buffer(&mut self) {
        if let Some(sink) = self.sink.as_deref_mut() {
            if self.error.is_none() {
                if let Err(error) = sink.write_all(self.buffer.as_bytes()) {
                    self.error = Some(error);
                }
            }
            self.buffer.clear();
        }
    }

    /// Writes what is still buffered and reports the first I/O error, if any.
    pub fn finish(mut self) -> io::Result<()> {
        self.flush_buffer();
        match self.error {
            Some(error) => Err(error),
            None => Ok(()),
        }
    }

    /// The collected text of an in-memory output.
    #[must_use]
    pub fn into_string(self) -> String {
        debug_assert!(self.sink.is_none(), "a streaming output holds no text");
        self.buffer
    }
}

impl fmt::Write for Output<'_> {
    #[inline]
    fn write_str(&mut self, text: &str) -> fmt::Result {
        self.push_str(text);
        Ok(())
    }

    #[inline]
    fn write_char(&mut self, character: char) -> fmt::Result {
        self.push(character);
        Ok(())
    }
}

/// One file of a generated package: where it goes and how to render it.
pub struct FileJob<'a> {
    pub path: PathBuf,
    /// A rough measure of the file's size, used only to start the largest files first.
    pub weight: usize,
    pub render: Box<dyn Fn(&mut Output<'_>) + Send + Sync + 'a>,
}

impl<'a> FileJob<'a> {
    pub fn new(
        path: impl Into<PathBuf>,
        weight: usize,
        render: impl Fn(&mut Output<'_>) + Send + Sync + 'a,
    ) -> Self {
        Self {
            path: path.into(),
            weight,
            render: Box::new(render),
        }
    }

    /// A file whose contents are already known.
    pub fn text(path: impl Into<PathBuf>, contents: String) -> Self {
        Self::new(path, 0, move |output| output.push_str(&contents))
    }
}

/// Every file of a generated package, rendered in memory.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct GeneratedPackage {
    pub files: BTreeMap<PathBuf, String>,
}

impl GeneratedPackage {
    #[must_use]
    pub fn render(jobs: &[FileJob<'_>]) -> Self {
        let files = jobs
            .iter()
            .map(|job| {
                let mut output = Output::in_memory();
                (job.render)(&mut output);
                (job.path.clone(), output.into_string())
            })
            .collect();
        Self { files }
    }

    pub fn write_to(&self, output: &Path) -> io::Result<()> {
        for (relative_path, contents) in &self.files {
            let path = output.join(relative_path);
            if let Some(parent) = path.parent() {
                fs::create_dir_all(parent)?;
            }
            fs::write(path, contents)?;
        }
        Ok(())
    }
}

/// Renders every job into its file under `root`, on as many threads as there are cores.
/// Files are claimed largest first, so the biggest module starts at once instead of being
/// left for last. Existing files are overwritten, other files are left alone; on an error the
/// remaining jobs are abandoned and the first error is returned.
pub fn write_files(mut jobs: Vec<FileJob<'_>>, root: &Path) -> io::Result<()> {
    let directories: BTreeSet<PathBuf> = jobs
        .iter()
        .filter_map(|job| root.join(&job.path).parent().map(Path::to_path_buf))
        .collect();
    for directory in directories {
        fs::create_dir_all(directory)?;
    }
    jobs.sort_by_key(|job| Reverse(job.weight));

    let next = AtomicUsize::new(0);
    let failed = AtomicBool::new(false);
    let work = || -> io::Result<()> {
        while !failed.load(Ordering::Relaxed) {
            let Some(job) = jobs.get(next.fetch_add(1, Ordering::Relaxed)) else {
                break;
            };
            let result = File::create(root.join(&job.path)).and_then(|mut file| {
                let mut output = Output::streaming(&mut file);
                (job.render)(&mut output);
                output.finish()?;
                file.flush()
            });
            if result.is_err() {
                failed.store(true, Ordering::Relaxed);
                return result;
            }
        }
        Ok(())
    };
    let workers = thread::available_parallelism()
        .map_or(1, std::num::NonZero::get)
        .min(jobs.len());
    thread::scope(|scope| {
        let handles: Vec<_> = (1..workers).map(|_| scope.spawn(work)).collect();
        let mut result = work();
        for handle in handles {
            let joined = handle
                .join()
                .unwrap_or_else(|panic| std::panic::resume_unwind(panic));
            result = result.and(joined);
        }
        result
    })
}

#[cfg(test)]
mod tests {
    use std::fmt::Write as _;

    use super::*;

    #[test]
    fn streamed_and_in_memory_files_agree() {
        let big = |output: &mut Output<'_>| {
            for line in 0..100_000 {
                let _ = writeln!(output, "line {line}");
            }
        };
        let jobs = || {
            vec![
                FileJob::text("a/small.txt", "small\n".into()),
                FileJob::new("b/c/big.txt", 100_000, big),
            ]
        };
        let directory = tempfile::tempdir().unwrap();
        write_files(jobs(), directory.path()).unwrap();
        let package = GeneratedPackage::render(&jobs());
        for (path, contents) in &package.files {
            assert_eq!(
                &fs::read_to_string(directory.path().join(path)).unwrap(),
                contents
            );
        }
        assert!(package.files[Path::new("b/c/big.txt")].ends_with("line 99999\n"));
    }
}
