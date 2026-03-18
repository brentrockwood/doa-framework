# doa-framework

The DOA Framework is a system for structured AI agent collaboration on software
projects. It consolidates the canonical rules document (`doa.md`), project
scaffold (`template/`), and bootstrap script (`doa`) into a single repo that
also governs itself via the DOA process.

This `project.md` covers the current work cycle: **TODOs #10, #14, and #15**
from `notes/TODO-2026-03-18.md`.

---

> **This document is write-locked after the initial planning session.**
> Updates require explicit human authorization. See `doa.md`.

---

## Ratified Decisions (carried forward)

- Single repo. All predecessor repos deprecated.
- Script renamed `new-project` → `doa`.
- `prjTemplate` promoted to `template/` subdirectory.
- Single canonical `doa.md`: `project/doa.md` is the source of truth.
  `template/project/doa.md` is the copy planted into new projects. Both must
  be kept in sync after every change.
- `doa` uses local `template/` when available; falls back to remote clone.
- Testing framework: [BATS](https://github.com/bats-core/bats-core). All tests
  live in `./tests/`.
- `CLAUDE.md` and `AGENTS.md` contain a single line: `Read project/doa.md`.
  No copies, no drift.

---

## Stack & Framework Decisions

### Language & Runtime
- **bash** — all scripts, `postCreate.sh`, `doa` bootstrap script
- **Markdown** — DOA extension modules and documentation

### Testing
- **BATS 1.13.0** (installed via brew)
- Test files: `tests/*.bats`
- Shared helpers: `tests/test_helper.bash`
- No bats-support / bats-assert dependency

### Linting / Formatting
- `shellcheck` on all shell scripts before commit
- `shellcheck` must produce zero warnings

### Security
- `trufflehog` on changed files before push (already in `postCreate.sh`)
- No credentials, tokens, or API keys in source

---

## Open Questions

> These must be resolved before or during the affected phase. Do not begin
> implementation until the relevant question is answered.

All open questions resolved. No blockers to implementation.

1. ~~**[Phase 1] Claude CLI version pin**~~ — **Resolved:** `@latest` for all
   three AI CLIs (claude, codex, coderabbit).

2. ~~**[Phase 1] Codex CLI install method**~~ — **Resolved:** Node.js will be
   installed globally for all stacks in `postCreate.sh`, not only in the
   `typescript` case. Codex CLI (`npm install -g @openai/codex`) can run
   unconditionally after the Node install step.

3. ~~**[Phase 3] NemoClaw lessons learned**~~ — **Resolved:** Proceeding with
   `stack-rust.md` as a first draft. NemoClaw lessons folded in as a follow-up
   after that project is complete.

4. ~~**[Phase 3] `cargo-nextest` vs `cargo test`**~~ — **Resolved:**
   `cargo-nextest` in the gate. It is the de facto standard for serious Rust
   projects — faster, better output. `cargo install cargo-nextest` added to the
   rust devcontainer.

5. ~~**[Phase 3] Workspace-level gate invocation**~~ — **Resolved:** Not an
   issue. `cargo clippy -- -D warnings` and `cargo nextest run` work correctly
   from the workspace root and cover all member crates automatically.

---

## Implementation Phases

### Phase 1 — Task #10: AI CLIs in `postCreate.sh`

Install Claude CLI, Codex CLI, and CodeRabbit CLI in all devcontainers.
Register the CodeRabbit plugin with Claude Code after both are available.

- [ ] Add a dedicated "AI CLIs" section to `postCreate.sh` (runs for all
      stacks, after system packages and `gh` CLI install)
- [ ] Install **Claude CLI** (`claude`). Pin to known-good version; document
      pin rationale in a comment. Fail loudly on error.
- [ ] Install **Codex CLI** (`codex`). Resolve Node dependency (see Open
      Question #2) before this step. Pin version. Fail loudly on error.
- [ ] Install **CodeRabbit CLI** (`coderabbit`) via the official install
      script. Fail loudly on error.
- [ ] After both Claude CLI and CodeRabbit CLI are confirmed installed,
      register the plugin: `claude plugin install coderabbit`. Gate this
      on successful install of both — skip with a warning if either failed.
- [ ] Update summary block at the bottom of `postCreate.sh` to list the
      new tools.
- [ ] `shellcheck` on `postCreate.sh` — zero warnings.
- [ ] BATS tests in `tests/postcreate.bats` (or extend existing suite):
  - AI CLI section is present in the script
  - Plugin registration is gated on prior install steps
  - Failure in any CLI install causes a non-zero exit (mock install steps)

---

### Phase 2 — Task #14: Agent-Initiated CodeRabbit Reviews

Add DOA rules requiring agents to request and act on CodeRabbit reviews after
significant changesets.

- [ ] Add CodeRabbit review rule to `project/doa.md` (after "After every
      interaction" checklist, as a new subsection). Per TODO #14 spec:
  - **Claude Code**: use `/coderabbit:review` (plugin path)
  - **Other agents**: use `coderabbit --prompt-only --type uncommitted`
  - Address all critical and major findings; ignore nits unless time permits
  - One follow-up review after fixes
  - Do not exceed 2 review cycles (rate limit: Pro 8/hour, Free 2/hour)
  - On timeout or rate limit: log in context + notify via `scripts/notify`
- [ ] Sync change to `template/project/doa.md`.
- [ ] Confirm both files are identical after sync (diff must be empty).
- [ ] `shellcheck` unchanged (markdown only, no shell impact).

---

### Phase 3 — Task #15: Rust Stack Support

Four deliverables, sequenced. Resolve Open Questions #3–5 before starting.

#### 3a — `doa/stack-rust.md` (new extension module)

- [ ] Create `template/project/doa/stack-rust.md`
- [ ] Contents (per TODO #15 spec):
  - Detection condition: `Cargo.toml` at repo or workspace root
  - Planning phase decisions (write-locked): crate type, async runtime
    (Tokio default), error handling (`thiserror` for libs, `anyhow` for bins)
  - Research gate: check `crates.io` before hand-rolling anything touching
    parsing, serialization, HTTP, or crypto
  - Coding standards: `clippy` zero warnings, doc comments on all public
    items, no `unwrap()`/`expect()` in library code, no `unsafe` without
    safety comment and human sign-off
  - `rustfmt` clean before every commit
  - `send 'er` gate (in order): `cargo audit`, `cargo fmt --check`,
    `cargo clippy -- -D warnings`, `cargo test` (or `cargo-nextest` per
    Open Question #4), `cargo build --release`
  - Agentic sessions: `AI_SESSION.md` at workspace root
- [ ] Readability bar: passes same review as `stack-go.md`

#### 3b — `devcontainers/rust/devcontainer.json`

- [ ] Create `devcontainers/rust/devcontainer.json` modelled on
      `devcontainers/go/devcontainer.json`
- [ ] Base image: official `rust` devcontainer image with `rustup` and
      stable toolchain
- [ ] `STACK=rust` set in `containerEnv`
- [ ] VS Code extensions: `rust-lang.rust-analyzer`
- [ ] VS Code settings: format on save, clippy as check tool
- [ ] Note: projects that need a specific MSRV add `rust-toolchain.toml`
      at repo root; devcontainer installs stable

#### 3c — `postCreate.sh` — add `rust` case

- [ ] Add `rust)` case to the `case "$STACK" in` block:
  - `cargo install cargo-audit`
  - `cargo install cargo-watch`
  - Verify `rustfmt` and `clippy` are available (they ship with stable
    toolchain via rustup)
  - `ok` messages for each installed tool
- [ ] Update valid STACK values in the `die` message and header comment
- [ ] `shellcheck` clean
- [ ] BATS test: rust case installs expected tools without error

#### 3d — `doa` script — stack detection

- [ ] Add `rust)` case to `check_stack()` function:
      detection signal: `[[ -f "Cargo.toml" ]]`
- [ ] Add `doa/stack-rust.md` to the module-loading section (consistent
      with how Go and TS modules are loaded)
- [ ] Add `target/` block to `step_write_gitignore()` for the rust case
- [ ] `shellcheck` clean on `doa` script
- [ ] BATS test: `doa` detects rust stack from a repo containing `Cargo.toml`

#### 3e — `STACK_MODULE_TEMPLATE.md` (generalization pass)

- [ ] After 3a is written and reviewed, do a generalization pass across
      `stack-go.md`, `stack-rust.md`, and `template/project/doa.md`
- [ ] Create `docs/STACK_MODULE_TEMPLATE.md` with fill-in-the-blank structure
- [ ] Document what is universal (gate structure, planning locks, research
      requirement) vs. what varies per stack (tools, detection signal,
      gitignore patterns)
- [ ] Acceptance criterion: a hypothetical `stack-python.md` could be written
      from the template without referring to any existing stack module

---

## Decisions & Rationale

### Node.js installed globally for all stacks
- **Decision:** Node.js (via nvm) is installed for all stacks in
  `postCreate.sh`, not only the `typescript` case.
- **Rationale:** Codex CLI is npm-distributed and needed in every
  devcontainer. Moving Node install to the common section is cleaner than
  duplicating it or adding a conditional.
- **Impact:** The `typescript` case can drop its nvm/Node install and rely
  on the common section; it only needs to add pnpm, tsc, ts-node, and any
  other TS-specific tools.

### AI CLI install order in `postCreate.sh`
- **Decision:** AI CLIs are installed as a common section after `gh` CLI,
  before stack-specific tools.
- **Rationale:** These tools are agent infrastructure, not stack-specific.
  Every devcontainer should have them regardless of project language.
- **Alternatives considered:** Stack-specific install (rejected — adds
  duplication and means some devcontainers lack the tools).

### CodeRabbit plugin registration gated on both CLI and Claude CLI
- **Decision:** `claude plugin install coderabbit` only runs if both
  `claude` and `coderabbit` binaries are confirmed present after install.
- **Rationale:** Plugin registration against a missing binary produces an
  opaque error. Explicit gating gives a clear failure message.

### Rust async default: Tokio
- **Decision:** Tokio is the assumed async runtime for Rust projects unless
  a planning decision recorded in `project.md` specifies otherwise.
- **Rationale:** Tokio is the dominant runtime in the ecosystem. The
  commitment is harder to reverse in Rust than in Go or Python, so it must
  be locked during planning.
- **Alternatives considered:** `async-std` (smaller ecosystem), no async
  (appropriate only for CPU-bound or synchronous projects — allowed with
  explicit justification).

### `@latest` for AI CLIs
- **Decision:** Install claude, codex, and coderabbit CLIs at `@latest` in
  `postCreate.sh`. No version pins.
- **Rationale:** These tools evolve quickly; pinning creates maintenance
  overhead. Breaking changes are acceptable risk given the devcontainer is
  rebuilt infrequently and issues are caught immediately on first use.

### `cargo-nextest` replaces `cargo test` in Rust gate
- **Decision:** `cargo nextest run` is used in the `send 'er` gate, not
  `cargo test`. `cargo install cargo-nextest` added to the rust devcontainer.
- **Rationale:** Faster parallel execution, cleaner output, de facto standard
  in the Rust ecosystem. No meaningful downside for new projects.

### Error handling crates
- **Decision:** `thiserror` for libraries, `anyhow` for binaries.
- **Rationale:** Library crates should expose typed errors that callers can
  match on; binary crates care about display and context, not type hierarchy.

### `STACK_MODULE_TEMPLATE.md` location
- **Decision:** `docs/STACK_MODULE_TEMPLATE.md`
- **Rationale:** It is developer-facing documentation for framework
  contributors, not an agent instruction file. Lives in `docs/` alongside
  other developer docs.

---

## Known Debt / Deferred Items

- TODO #2 (framework versioning) and TODO #8 (modular DOA architecture)
  are deferred until after this cycle. The module loading mechanism added
  in Phase 3 is a forward-compatible placeholder.
- TODO #11 (persist auth across container rebuilds) and TODO #13
  (env var injection) are prerequisites for full CodeRabbit auth in
  devcontainers. The Phase 1 install work is functional without them but
  auth must be configured manually in new containers until #11/#13 land.
- `cargo-nextest` decision (Open Question #4) deferred to planning
  conversation before Phase 3 begins.
