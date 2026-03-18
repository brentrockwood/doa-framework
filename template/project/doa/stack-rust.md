# DOA Extension — Rust Stack

This module supplements the DOA for projects using Rust. It is authoritative
for any Rust project and must be followed alongside the base `doa.md` rules.

Detection condition: `Cargo.toml` present at the repo or workspace root.

---

## Planning phase additions

During planning, in addition to the standard decisions, the following must be
decided and recorded in `project.md`. These are write-locked after planning.

- **Crate type**: binary, library, or Cargo workspace
- **Async runtime**: Tokio (default) or none — with explicit justification if
  none. Rust's async runtime commitment is harder to reverse than Go or Python;
  this decision MUST be locked during planning, not discovered mid-implementation.
- **Error handling crates**:
  - Libraries: `thiserror` (typed, matchable errors for callers)
  - Binaries: `anyhow` (context-rich display, not type hierarchy)
- **MSRV** (minimum supported Rust version): if the project has one, add
  `rust-toolchain.toml` at the repo root. Devcontainer installs stable by default.
- **Research gate**: before hand-rolling anything touching parsing,
  serialization, HTTP, or crypto, check `crates.io`. The ecosystem has
  excellent, well-audited crates for these domains.

---

## Coding style

Follow idiomatic Rust as described in
[The Rust API Guidelines](https://rust-lang.github.io/api-guidelines/). In
addition:

- All public items (types, functions, methods, constants, modules) MUST have
  doc comments (`///`). No exceptions.
- No `unwrap()` or `expect()` in library code. In binary code, `expect()` is
  allowed only at startup before any user interaction begins — include a
  descriptive message.
- No `unsafe` without a `// SAFETY:` comment explaining the invariant and
  explicit human sign-off recorded in `project.md`.
- No global mutable state. Pass state through constructors or function
  arguments.
- `#[allow(...)]` suppressions require an explanatory comment. Zero-tolerance
  policy for unexplained silenced warnings.
- Pure functions are preferred. They are easier to test.

---

## Error handling

- Use `thiserror` for library crates; `anyhow` for binary crates.
- Wrap errors with context at every layer: `context("loading config")` in
  `anyhow`; `#[error("loading config: {source}")]` in `thiserror`.
- Never swallow errors silently. If you choose to ignore an error, add a
  comment explaining why.
- Prefer typed errors over `Box<dyn Error>` in library public APIs.

---

## Testing

- Use `cargo nextest run` as the test runner (faster, better output).
- Use table-driven tests as the default pattern.
- Test files live alongside source: `foo.rs` → `foo_test` module at the bottom
  of the same file (unit tests), or `tests/` for integration tests.
- Integration tests that require external services should be gated with
  `#[ignore]` or a feature flag so `cargo nextest run` passes cleanly without
  external dependencies.
- Property-based testing with `proptest` or `quickcheck` is encouraged for
  parsing and data transformation code.

---

## Formatting and linting

- `rustfmt` MUST be clean before every commit. Run `cargo fmt --check` to
  verify. This is non-negotiable.
- `cargo clippy -- -D warnings` must produce zero warnings and zero errors
  before every commit. Run from the workspace root to cover all member crates.
- `cargo vet ./...` must be clean.

---

## Security

- `cargo audit` is part of the `send 'er` gate. All moderate-severity and above
  findings must be resolved or explicitly documented before pushing.
- API keys and secrets are loaded exclusively from environment variables.
  Never hardcode credentials.
- Sanitize all user-provided input before passing to external services or
  shell commands.

---

## `send 'er` gate (Rust)

When the human says "send 'er", execute in this order:

1. `cargo audit` — exit 0. Moderate+ findings must be resolved or documented.
2. `bash scripts/security_scan.sh` — must exit 0.
3. `trufflehog filesystem --only-verified .` — must exit 0.
4. `cargo fmt --check` — must produce no output (all files formatted).
5. `cargo clippy -- -D warnings` — zero warnings, zero errors.
6. `cargo nextest run` — all tests must pass.
7. `cargo build --release` — must succeed with no errors or warnings.
8. Add context entry via `project/scripts/add-context`.
9. Add session summary via `project/scripts/add-session-entry --type summary`.
10. Show: branch name, files changed, commits to push.
11. Prompt: "Ready to push to origin? (y/n)" — wait for confirmation.
12. Push to origin. Open a pull request.

---

## AI Session Logging

For any project using agentic development tools (Claude Code, Codex, etc.),
`AI_SESSION.md` is a required artifact subject to the same rules as
`context.md`:

- Managed exclusively through `project/scripts/add-session-entry`.
- Append-only. Entries are never edited after being written.
- Every prompt received from a human must be logged verbatim before work begins.
- Every meaningful unit of work must be followed by a summary entry.
- Included in every commit alongside the work it documents.
