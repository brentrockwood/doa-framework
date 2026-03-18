---
date: 2026-03-04T18:12:48Z
hash: bootstrap
agent: create-doa-framework.sh
model: n/a
session: bootstrap
startCommit: n/a
---
doa-framework created by consolidation script. Assembled from: new-project
(tool layer and devcontainers), prjTemplate (project template, promoted to
template/), doa (canonical doa.md, installed to project/doa.md and
template/project/doa.md). Script renamed new-project → doa. doa-framework is
itself a DOA project. Branch: main


---
date: 2026-03-04T18:10:37-0500
hash: 8qjjOMfrVGYmRVUC6fMAtI4AsDwLsxs9R0kotyDy1AQ=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: dc0f292f7e79c3ec9818bb19549ea6d0c7f37d55
---

First Claude Code session. Resuming existing project with no prior agent context entries.

Reviewed project state: project.md had uncommitted Task List (3 improvements to add-context). Branch: task/1-add-context-improvements.

Implemented Task 1 (project/scripts/add-context):
- 1a (empty body detection): Already present in consolidated script — no change needed.
- 1b (git-root resolution): OUTPUT_FILE now defaults to $(git rev-parse --show-toplevel)/project/context.md instead of ./context.md. Falls back to context.md outside git repos. --output still overrides.
- 1c (auto-rotate): After each successful write, add-context now calls rotate-context --file on the output file. Exit code 1 (no rotation needed) is silently ignored; exit code 2 (error) emits a warning to stderr.

Next: security scan, commit project.md + add-context changes + this context entry.

EOF


---
date: 2026-03-12T22:57:22-0400
hash: lrUIUCiOGC9eAxPDaJLgUHUfRLfSABWA0sP9rpjzYGM=
agent: HUMAN
model: HUMAN
startCommit: 57f3d346905bd1422d906ea6f2ce9d6aa8840c37
---

Update DOA and gitignore.
date: 2026-03-04T18:58:43-0500
hash: f2RId9CGN0tojq7wAqOeZIY7YUUU+k6QSw7j8AEUMZs=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: 57f3d346905bd1422d906ea6f2ce9d6aa8840c37
---

Task 3: read-context now resolves its default file to $(git rev-parse --show-toplevel)/project/context.md when inside a git repo, falling back to ./context.md outside one. --file still overrides. Same pattern as Task 1b for add-context.

Also re-applied two changes that were committed locally but not pushed before PR #1 was merged:
- add-context: cache IN_GIT_REPO variable (CodeRabbit finding from PR #1)
- project.md: BATS testing decision + Task 2 + Task 3 task descriptions

Branch: task/3-read-context-git-root

EOF


---
date: 2026-03-05T15:47:19-0500
hash: DcqeCHxOWNabmghuqpLeH+6ngDHw3MgYcXPInKbs4jY=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: 79205c303255f28322f00a0ce0d2b7d6523c8c62
---

Tasks 2 and 3b complete. Wrote 59 passing BATS tests across 5 suites covering all scripts in project/scripts/:

- tests/test_helper.bash: shared helpers (make_git_repo, write_context_entries)
- tests/add-context.bats (18 tests): Task 2 scope (git-root resolution, auto-rotate, empty body) + Task 3b extras (arg validation, body inputs, --session field, entry format, append behaviour)
- tests/read-context.bats (12 tests): git-root resolution, read/header modes, error cases
- tests/rotate-context.bats (11 tests): no-rotation, rotation, overflow correctness, custom flags, error cases
- tests/add-session-entry.bats (12 tests): arg validation, body inputs, file init/append, entry format
- tests/notify.bats (4 tests): no-args guard, mocked curl success/error/empty-response paths

Also updated project.md: merged Tasks 3 and 4 into a single Task 3 (3a: read-context fix [done], 3b: BATS suites). bats-core installed via brew (1.13.0); no bats-support/bats-assert dependency needed.

Branch: task/3-read-context-git-root

EOF


---
date: 2026-03-05T18:54:02-0500
hash: qeMkSQYioL2rBdBko9+K1Gc1NJcBm6lzmLyqP6kYOxs=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: 6a705bc3de87ace4a495fb03f85815967b3ec7f8
---

Address CodeRabbit findings on PR #3.

- project/project.md: corrected description of tests/test_helper.bash — it does not source bats-support/bats-assert; now accurately describes make_git_repo and write_context_entries utilities
- tests/add-context.bats: tightened empty-body assertions to use grep -qi "empty" instead of loose *"mpty"*||*"Error"* pattern

59/59 tests still passing. Branch: task/3-read-context-git-root

EOF


---
date: 2026-03-18T11:36:34-0400
hash: f74eMN8BymICNXvEjKrI6Q/4ltCgjlKAAL1RzDvcik4=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: 5e79692f4ef9815479fc691e70a055f0a487a0ed
---

Planning session for TODOs #10, #14, and #15. Replaced project/project.md with a new plan covering:
- Phase 1 (#10): Install claude, codex, and coderabbit CLIs in postCreate.sh for all stacks; register coderabbit plugin with Claude Code.
- Phase 2 (#14): Add agent-initiated CodeRabbit review rule to doa.md and template.
- Phase 3 (#15): Rust stack support — stack-rust.md, devcontainers/rust/, postCreate.sh rust case, doa script detection, STACK_MODULE_TEMPLATE.md.

Resolved open question: Node.js will be installed globally for all stacks (not typescript-only), which satisfies the Codex CLI npm dependency. Recorded as a ratified decision.

Remaining open questions: (1) Claude CLI version pin, (3) NemoClaw lessons learned (prerequisite for Phase 3), (4) cargo-nextest vs cargo test, (5) Cargo workspace gate invocation.

Branched: feature/ai-clis-coderabbit-rust

EOF


---
date: 2026-03-18T11:46:47-0400
hash: g80cGI89raDjVJC0s55V/hW9ObAbV8bhFX3T5QvVMWw=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: 5e79692f4ef9815479fc691e70a055f0a487a0ed
---

Implemented TODOs #10, #14, and #15. All open questions resolved before coding.

Phase 1 (#10 — AI CLIs in postCreate.sh):
- Node.js/nvm moved to common section (all stacks); resolves Codex npm dependency.
- Added AI CLIs section (all stacks): claude (@latest via npm), codex (@latest via npm), coderabbit (@latest via install script).
- Added CodeRabbit plugin registration with Claude Code, gated on both binaries present.
- Added rust) case: cargo-audit, cargo-nextest --locked, cargo-watch.
- Fixed pre-existing SC2155 shellcheck warning in go) case.
- Updated header comment and footer summary.

Phase 2 (#14 — CodeRabbit DOA rule):
- Inserted step 5 "CodeRabbit review" in "After every interaction" checklist (between "Run tests" and "Commit"). Renumbered Commit → 6, Notify → 7.
- Synced project/doa.md → template/project/doa.md (files identical).

Phase 3 (#15 — Rust stack support):
- Created template/project/doa/stack-rust.md (new extension module). Covers planning locks, coding style, error handling, testing (cargo-nextest), formatting/linting, security, send 'er gate, AI session logging.
- Created devcontainers/rust/devcontainer.json (rust-analyzer, format-on-save, clippy as check command).
- Added rust (option 4) to doa script stack selection menu. Updated commit message template.
- target/ already present in template/.gitignore — no change needed.
- Created docs/STACK_MODULE_TEMPLATE.md: fill-in-the-blank guide for adding future stacks.

project/project.md: all open questions resolved and recorded as decisions.
shellcheck clean on postCreate.sh and doa.

Branch: feature/ai-clis-coderabbit-rust

EOF


---
date: 2026-03-18T11:53:33-0400
hash: 3D6ry2amPLfZ+BLvFDLCZJnxEhFfUIzaZMnATdGlQrw=
agent: Claude Code
model: claude-sonnet-4-6
startCommit: 4abe7096ae14145cc41ddee1b944df70bccd11a9
---

Added trufflehog to send 'er security gate in all three locations:
- Base send 'er (doa.md): step 1 now runs both scripts/security_scan.sh and trufflehog filesystem --only-verified .
- Go stack gate (doa.md appendix): added steps 2 and 3 (security_scan.sh + trufflehog) after gosec; renumbered remaining steps.
- Rust stack gate (stack-rust.md): added steps 2 and 3 after cargo audit; renumbered remaining steps.
Synced project/doa.md → template/project/doa.md (files identical).

Branch: feature/ai-clis-coderabbit-rust

EOF

