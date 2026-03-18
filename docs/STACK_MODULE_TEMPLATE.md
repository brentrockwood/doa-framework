# Stack Module Template

This template is the canonical starting point for any new `doa/stack-<name>.md`
extension module. Adding Rust support took about 15 minutes using this template.
Adding the next stack should take the same.

Fill in every `[PLACEHOLDER]`. Sections marked **universal** are identical
across all stacks — copy verbatim and update tool names only. Sections marked
**varies** require stack-specific knowledge.

---

## File location

```
template/project/doa/stack-<name>.md
```

Detection condition (add to `doa` script `check_stack()` / stack menu and to
`postCreate.sh` `case "$STACK" in`):

```
[PLACEHOLDER: detection signal, e.g. Cargo.toml | go.mod | package.json | pyproject.toml]
```

---

## Module header **[varies]**

```markdown
# DOA Extension — [STACK NAME] Stack

This module supplements the DOA for projects using [STACK NAME]. It is
authoritative for any [STACK NAME] project and must be followed alongside the
base `doa.md` rules.

Detection condition: `[DETECTION FILE]` present at the repo root.
```

---

## Planning phase additions **[varies]**

List every decision that must be locked during planning and recorded in
`project.md`. These become write-locked after planning.

Universally applicable questions to ask for every stack:

- Runtime version (pin it)
- Async strategy (if applicable — this decision is often hard to reverse)
- Error handling approach (typed errors vs. context-rich wrapping)
- HTTP framework / router (if applicable)
- Whether a multi-stage Docker / container build is needed

Stack-specific questions:

```
[PLACEHOLDER: what else must be decided before coding begins?]
```

Research gate (universal — copy verbatim, update domains as needed):

> Before hand-rolling anything touching parsing, serialization, HTTP, or
> crypto, check `[PLACEHOLDER: package registry, e.g. crates.io / pkg.go.dev / PyPI / npm]`.
> The ecosystem has excellent, well-audited packages for these domains.

---

## Coding style **[varies]**

Reference the canonical style guide for the stack:

```
[PLACEHOLDER: link to official or widely-adopted style guide]
```

Universal rules (copy verbatim):

- All public items MUST have doc comments. No exceptions.
- No global mutable state. Pass state through constructors or function arguments.
- Pure functions are preferred. They are easier to test.

Stack-specific rules:

```
[PLACEHOLDER: e.g. interface placement, unwrap policy, allow suppressions policy]
```

---

## Error handling **[varies]**

Universal principle (copy verbatim):

- Never swallow errors silently. If you choose to ignore an error, add a
  comment explaining why.

Stack-specific approach:

```
[PLACEHOLDER: e.g. thiserror/anyhow, fmt.Errorf %w, exception hierarchy]
```

---

## Testing **[varies]**

Universal rules (copy verbatim):

- Use table-driven / parametrised tests as the default pattern.
- Tests that require external services must be guarded so the suite passes
  cleanly without them.

Stack-specific:

```
[PLACEHOLDER: test runner, file placement convention, parallelism flag]
```

---

## Formatting and linting **[varies]**

Universal rule (copy verbatim):

- The formatter MUST be clean before every commit. This is non-negotiable.
- The linter must produce zero warnings and zero errors before every commit.

Stack-specific tools:

| Role       | Tool                                        |
|------------|---------------------------------------------|
| Formatter  | `[PLACEHOLDER]`                             |
| Linter     | `[PLACEHOLDER]`                             |
| Type check | `[PLACEHOLDER, or "n/a — types are static"]`|
| Security   | `[PLACEHOLDER]`                             |

---

## `send 'er` gate **[varies — structure is universal]**

The gate always runs in this order. Fill in the stack-specific commands.

```
1. Security scanner   — [PLACEHOLDER: e.g. cargo audit / gosec / pip-audit]
2. Formatter check    — [PLACEHOLDER: e.g. cargo fmt --check / goimports -l .]
3. Static analysis    — [PLACEHOLDER: e.g. cargo clippy / go vet / mypy]
4. Linter             — [PLACEHOLDER: e.g. golangci-lint / eslint / ruff]
5. Tests              — [PLACEHOLDER: e.g. cargo nextest run / go test -race ./...]
6. Build              — [PLACEHOLDER: e.g. cargo build --release / go build ./...]
7. add-context entry  — project/scripts/add-context ...
8. add-session-entry  — project/scripts/add-session-entry --type summary
9. Show branch, files changed, commits to push
10. Prompt "Ready to push to origin? (y/n)"
11. Push + open PR
```

---

## AI Session Logging **[universal — copy verbatim]**

For any project using agentic development tools (Claude Code, Codex, etc.),
`AI_SESSION.md` is a required artifact subject to the same rules as
`context.md`:

- Managed exclusively through `project/scripts/add-session-entry`.
- Append-only. Entries are never edited after being written.
- Every prompt received from a human must be logged verbatim before work begins.
- Every meaningful unit of work must be followed by a summary entry.
- Included in every commit alongside the work it documents.

---

## Checklist before submitting a new stack module

- [ ] All `[PLACEHOLDER]` strings replaced
- [ ] Detection condition added to `doa` script stack menu
- [ ] `postCreate.sh` case added with stack-specific tool installs
- [ ] `devcontainers/<stack>/devcontainer.json` created
- [ ] `STACK_MODULE_TEMPLATE.md` updated if a new universal pattern was identified
- [ ] Module passes the same readability bar as `stack-go.md` and `stack-rust.md`
- [ ] A hypothetical next stack could be written from this template without
      consulting any existing module
